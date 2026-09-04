import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';

import '../models/building_height.dart';
import '../models/geo.dart';
import '../models/shadow_map.dart';
import '../models/walk_graph.dart';

/// Resultado de descargar el corredor de una ruta: viario + edificios.
class CorredorOsm {
  final WalkGraph grafo;
  final List<BuildingFootprint> edificios;
  final bool desdeCache;

  /// Plantas típicas de la zona usadas como referencia (diagnóstico).
  final double? medianaPlantasZona;

  const CorredorOsm(
    this.grafo,
    this.edificios, {
    this.desdeCache = false,
    this.medianaPlantasZona,
  });
}

/// Descarga de OpenStreetMap (Overpass) el viario peatonal y los edificios
/// dentro de una banda alrededor de la línea inicio→destino.
///
/// Optimizaciones para no depender de infraestructura propia:
///  - consulta por *corredor* (`around` sobre la polilínea), no por rectángulo;
///  - se lanza a varios espejos públicos a la vez y gana el primero que responde;
///  - caché en disco por zona (14 días): calles y edificios apenas cambian.
class OsmWalkService {
  OsmWalkService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Espejos públicos de Overpass. Se consultan en paralelo (carrera).
  static const _endpoints = [
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass-api.de/api/interpreter',
    'https://overpass.private.coffee/api/interpreter',
  ];
  static const _userAgent = 'ruta_sombra/0.1 (Flutter)';

  static const _highwaysCaminables =
      'footway|path|pedestrian|living_street|steps|residential|service|'
      'unclassified|tertiary|tertiary_link|secondary|secondary_link|track|road';

  static const Duration _ttlCache = Duration(days: 14);

  /// Descarga calles + edificios en una banda alrededor de [polilinea].
  ///
  /// Pasada 1: `polilinea = [inicio, fin]` (banda alrededor de la línea recta).
  /// Pasada 2: `polilinea = ruta provisional` (banda a lo largo de la ruta real,
  /// para garantizar que TODO el recorrido tiene sus fachadas).
  Future<CorredorOsm> descargarCorredor(
    List<LatLng> polilinea, {
    double radioCallesM = 200,
    // Los edificios se piden en una banda MÁS ANCHA que las calles: así una
    // calle al borde del corredor todavía tiene sus fachadas (y su sombra).
    double radioEdificiosM = 260,
    double alturaGlobalPorDefectoM = 10,
  }) async {
    final poli = Geo.decimar(polilinea, 40).take(80).toList();
    final around = _polilineaAround(poli);
    final query = '''
[out:json][timeout:25];
(
  way["highway"~"^($_highwaysCaminables)\$"]["foot"!~"no|private"]["access"!~"private|no"](around:${radioCallesM.round()},$around);
  way["building"](around:${radioEdificiosM.round()},$around);
);
out geom;
''';

    final clave = _claveCache(poli, radioCallesM, radioEdificiosM);
    final (data, desdeCache) = await _fetchConCache(query, clave);

    final elements =
        (data['elements'] as List? ?? const []).cast<Map<String, dynamic>>();

    final grafo = WalkGraph();
    final edificiosCrudos =
        <({List<LatLng> ring, Map<String, dynamic> tags})>[];

    for (final el in elements) {
      if (el['type'] != 'way') continue;
      final tags = (el['tags'] as Map?)?.cast<String, dynamic>() ?? const {};
      final geom = (el['geometry'] as List?)?.cast<Map>();
      if (geom == null || geom.length < 2) continue;

      final pts = [
        for (final g in geom)
          LatLng((g['lat'] as num).toDouble(), (g['lon'] as num).toDouble()),
      ];

      if (tags.containsKey('building')) {
        if (pts.length >= 3) edificiosCrudos.add((ring: pts, tags: tags));
        continue;
      }

      final nodeIds = (el['nodes'] as List?)?.cast<num>();
      if (nodeIds == null || nodeIds.length != pts.length) continue;
      for (var i = 0; i < pts.length - 1; i++) {
        final a = grafo.nodoOCrea(nodeIds[i].toInt(), pts[i]);
        final bn = grafo.nodoOCrea(nodeIds[i + 1].toInt(), pts[i + 1]);
        grafo.addEdge(a, bn, [pts[i], pts[i + 1]]);
      }
    }

    // Altura de cada edificio: se calibra con la muestra local de esta descarga.
    final estimador =
        BuildingHeightEstimator(alturaGlobalM: alturaGlobalPorDefectoM)
          ..calibrar(edificiosCrudos.map((e) => e.tags));
    final edificios = [
      for (final e in edificiosCrudos)
        BuildingFootprint(ring: e.ring, heightM: estimador.estimar(e.tags)),
    ];

    return CorredorOsm(
      grafo,
      edificios,
      desdeCache: desdeCache,
      medianaPlantasZona: estimador.medianaPlantasLocal,
    );
  }

  // --- Consulta -----------------------------------------------------------

  String _polilineaAround(List<LatLng> pts) => pts
      .map((p) =>
          '${p.latitude.toStringAsFixed(6)},${p.longitude.toStringAsFixed(6)}')
      .join(',');

  /// Lanza la consulta a todos los espejos a la vez y devuelve el primero que
  /// responde 200 con JSON válido.
  Future<Map<String, dynamic>> _overpassRace(String query) async {
    final completer = Completer<Map<String, dynamic>>();
    final errores = <String>[];
    var pendientes = _endpoints.length;

    void fallo(String msg) {
      errores.add(msg);
      if (--pendientes == 0 && !completer.isCompleted) {
        completer.completeError(
          Exception('Overpass no disponible: ${errores.join(' | ')}'),
        );
      }
    }

    for (final endpoint in _endpoints) {
      _client
          .post(
            Uri.parse(endpoint),
            headers: {
              'User-Agent': _userAgent,
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {'data': query},
          )
          .timeout(const Duration(seconds: 40))
          .then((resp) {
        if (completer.isCompleted) return;
        if (resp.statusCode == 200) {
          try {
            completer.complete(
              jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>,
            );
          } catch (e) {
            fallo('json $endpoint: $e');
          }
        } else {
          fallo('HTTP ${resp.statusCode} $endpoint');
        }
      }).catchError((Object e) {
        if (!completer.isCompleted) fallo('$e ($endpoint)');
      });
    }

    return completer.future
        .timeout(const Duration(seconds: 45), onTimeout: () {
      throw Exception('Overpass no respondió a tiempo (${errores.join(' | ')})');
    });
  }

  // --- Caché en disco ---------------------------------------------------

  Directory? _dirCache;

  Future<Directory?> _cacheDir() async {
    if (_dirCache != null) return _dirCache;
    try {
      final base = await getApplicationSupportDirectory();
      final d = Directory('${base.path}/overpass_cache');
      if (!await d.exists()) await d.create(recursive: true);
      return _dirCache = d;
    } catch (_) {
      return null; // sin caché disponible: se sigue funcionando online
    }
  }

  String _claveCache(List<LatLng> poli, double rC, double rE) {
    // Cuantiza cada punto a ~0.0006° (~65 m) para que consultas casi iguales
    // compartan caché.
    final q = poli
        .map((p) =>
            '${(p.latitude / 0.0006).round()}_${(p.longitude / 0.0006).round()}')
        .join('|');
    return 'c${'$q|${rC.round()}|${rE.round()}'.hashCode}';
  }

  Future<(Map<String, dynamic>, bool)> _fetchConCache(
    String query,
    String clave,
  ) async {
    final dir = await _cacheDir();
    final file = dir == null ? null : File('${dir.path}/$clave.json');

    if (file != null && await file.exists()) {
      final edad = DateTime.now().difference(await file.lastModified());
      if (edad < _ttlCache) {
        try {
          final txt = await file.readAsString();
          return (jsonDecode(txt) as Map<String, dynamic>, true);
        } catch (_) {
          // caché corrupta: se ignora y se vuelve a pedir
        }
      }
    }

    final data = await _overpassRace(query);
    if (file != null) {
      try {
        await file.writeAsString(jsonEncode(data));
      } catch (_) {}
    }
    return (data, false);
  }

  /// Borra toda la caché de Overpass.
  Future<void> limpiarCache() async {
    final dir = await _cacheDir();
    if (dir != null && await dir.exists()) {
      await dir.delete(recursive: true);
      _dirCache = null;
    }
  }

  void dispose() => _client.close();
}
