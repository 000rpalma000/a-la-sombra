import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';

import '../models/building_height.dart';
import '../models/geo.dart';
import '../models/shadow_map.dart';
import '../models/tesela.dart';
import '../models/walk_graph.dart';
import 'overpass.dart';

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
/// que rodean una ruta.
///
///  - Los datos se piden y se guardan **por teselas** de ~550 m (como en
///    Terrazeo): dos rutas por la misma zona comparten caché, y la segunda
///    pasada a lo largo de la ruta casi nunca necesita red.
///  - Overpass con reintentos y un servidor cada vez (ver [Overpass]).
///  - Caché en disco por tesela (14 días): calles y edificios apenas cambian.
class OsmWalkService {
  OsmWalkService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  late final _op = Overpass(_client, userAgent: _userAgent);
  static const _userAgent = 'alombra/1.0 (Flutter)';

  static const _highwaysCaminables =
      'footway|path|pedestrian|living_street|steps|residential|service|'
      'unclassified|tertiary|tertiary_link|secondary|secondary_link|track|road';

  static const Duration _ttlCache = Duration(days: 14);

  /// Teselas por petición a Overpass (consultas pequeñas responden antes).
  static const _teselasPorPeticion = 6;

  /// Formato de la caché: los ficheros que no empiezan así se borran.
  static const _prefijoCache = 'w1_';

  /// Calles + edificios alrededor de [polilinea]: todas las teselas cuyo
  /// centro queda a menos de [radioEdificiosM] (+ media diagonal de tesela)
  /// de la línea.
  ///
  /// Pasada 1: `polilinea = [inicio, fin]` (banda alrededor de la línea recta).
  /// Pasada 2: `polilinea = ruta provisional` (a lo largo de la ruta real,
  /// para garantizar que TODO el recorrido tiene sus fachadas).
  ///
  /// [radioCallesM] se mantiene por compatibilidad: con teselas, calles y
  /// edificios llegan juntos y cubren lo mismo.
  Future<CorredorOsm> descargarCorredor(
    List<LatLng> polilinea, {
    double radioCallesM = 200,
    double radioEdificiosM = 260,
    double alturaGlobalPorDefectoM = 10,
  }) async {
    final poli = Geo.decimar(polilinea, 40).take(80).toList();
    final teselas = teselasDelCorredor(poli, radioEdificiosM);

    final guardadas = await _leerGuardadas(teselas);
    final faltan = [
      for (final t in teselas)
        if (!guardadas.containsKey(t)) t,
    ];
    final porTesela = <Tesela, List<dynamic>>{...guardadas};
    for (var k = 0; k < faltan.length; k += _teselasPorPeticion) {
      final lote = faltan.sublist(
          k, math.min(k + _teselasPorPeticion, faltan.length));
      porTesela.addAll(await _descargar(lote));
    }

    // Una vía puede estar en varias teselas: se junta sin repetir.
    final vistos = <int>{};
    final elementos = <Map<String, dynamic>>[
      for (final lista in porTesela.values)
        for (final el in lista.cast<Map<String, dynamic>>())
          if (vistos.add((el['id'] as num).toInt())) el,
    ];
    return _construir(elementos, alturaGlobalPorDefectoM,
        desdeCache: faltan.isEmpty);
  }

  /// Teselas cuyo centro queda a menos de [radioM] + media diagonal de
  /// tesela (~390 m) de [poli]: así toda la banda de [radioM] queda cubierta.
  static List<Tesela> teselasDelCorredor(List<LatLng> poli, double radioM) {
    const mediaDiagonalM = 390.0;
    final margenLat = radioM / 111320.0 + Tesela.tamLat;
    final margenLon = radioM / 84000.0 + Tesela.tamLon;
    final s = poli.map((p) => p.latitude).reduce(math.min) - margenLat;
    final n = poli.map((p) => p.latitude).reduce(math.max) + margenLat;
    final w = poli.map((p) => p.longitude).reduce(math.min) - margenLon;
    final e = poli.map((p) => p.longitude).reduce(math.max) + margenLon;
    final candidatas = Tesela.cubriendo(s, w, n, e);
    final ts = [
      for (final t in candidatas)
        if ((poli.length == 1
                ? Geo.distancia(t.centro, poli.first)
                : Geo.distanciaAPolilinea(t.centro, poli)) <=
            radioM + mediaDiagonalM)
          t,
    ];
    // Lo más cercano al inicio, primero.
    ts.sort((a, b) => Geo.distancia(poli.first, a.centro)
        .compareTo(Geo.distancia(poli.first, b.centro)));
    return ts;
  }

  /// Grafo peatonal + edificios a partir de elementos de Overpass.
  static CorredorOsm _construir(
    List<Map<String, dynamic>> elements,
    double alturaGlobalPorDefectoM, {
    required bool desdeCache,
  }) {
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

    // Altura de cada edificio: se calibra con la muestra local de esta zona.
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

  // --- Descarga por teselas -----------------------------------------------

  /// Descarga [lote] en una sola consulta (la caja que lo envuelve), lo
  /// reparte por teselas y lo guarda en disco. Lanza si Overpass falla.
  Future<Map<Tesela, List<dynamic>>> _descargar(List<Tesela> lote) async {
    final s = lote.map((t) => t.sur).reduce(math.min);
    final w = lote.map((t) => t.oeste).reduce(math.min);
    final n = lote.map((t) => t.norte).reduce(math.max);
    final e = lote.map((t) => t.este).reduce(math.max);
    final bb = '$s,$w,$n,$e';
    final query = """
[out:json][timeout:25];
(
  way["highway"~"^($_highwaysCaminables)\$"]["foot"!~"no|private"]["access"!~"private|no"]($bb);
  way["building"]($bb);
);
out geom qt;
""";
    final cuerpo = await _op.consultar(query);
    final claves = [for (final t in lote) (t.i, t.j)];
    final reparto = await _repartirEnIsolate(cuerpo, claves);
    final res = <Tesela, List<dynamic>>{};
    final dir = await _cacheDir();
    for (final t in lote) {
      final els = reparto[t.clave] ?? const [];
      res[t] = els;
      if (dir != null) {
        try {
          await File('${dir.path}/$_prefijoCache${t.clave}.json')
              .writeAsString(jsonEncode(els));
        } catch (_) {}
      }
    }
    return res;
  }

  static Future<Map<String, List<dynamic>>> _repartirEnIsolate(
          String cuerpo, List<(int, int)> claves) =>
      Isolate.run(() => repartir(cuerpo, claves));

  /// Reparte los elementos de una respuesta de Overpass entre las teselas
  /// pedidas: cada vía va a **todas** las teselas que toca su caja (así una
  /// calle larga no se pierde en ninguna de ellas).
  @visibleForTesting
  static Map<String, List<dynamic>> repartir(
      String cuerpo, List<(int, int)> claves) {
    final data = jsonDecode(cuerpo) as Map<String, dynamic>;
    final teselas = [for (final (i, j) in claves) Tesela(i, j)];
    final salida = {for (final t in teselas) t.clave: <dynamic>[]};
    for (final el in (data['elements'] as List? ?? const [])) {
      final b = (el as Map)['bounds'] as Map?;
      if (b == null) continue;
      final s = (b['minlat'] as num).toDouble(),
          w = (b['minlon'] as num).toDouble(),
          n = (b['maxlat'] as num).toDouble(),
          e = (b['maxlon'] as num).toDouble();
      for (final t in teselas) {
        if (t.toca(s, w, n, e)) salida[t.clave]!.add(el);
      }
    }
    return salida;
  }

  // --- Caché en disco ---------------------------------------------------

  Directory? _dirCache;

  Future<Directory?> _cacheDir() async {
    if (_dirCache != null) return _dirCache;
    try {
      final base = await getApplicationSupportDirectory();
      final d = Directory('${base.path}/overpass_cache');
      if (!await d.exists()) await d.create(recursive: true);
      // Fuera la caché por corredores del formato anterior.
      await for (final f in d.list()) {
        if (f is File && !f.uri.pathSegments.last.startsWith(_prefijoCache)) {
          try {
            await f.delete();
          } catch (_) {}
        }
      }
      return _dirCache = d;
    } catch (_) {
      return null; // sin caché disponible: se sigue funcionando online
    }
  }

  /// Teselas guardadas y vigentes, leídas en un solo isolate.
  Future<Map<Tesela, List<dynamic>>> _leerGuardadas(List<Tesela> ts) async {
    final dir = await _cacheDir();
    if (dir == null) return {};
    final vigentes = <Tesela>[];
    for (final t in ts) {
      final f = File('${dir.path}/$_prefijoCache${t.clave}.json');
      try {
        if (!await f.exists()) continue;
        if (DateTime.now().difference(await f.lastModified()) < _ttlCache) {
          vigentes.add(t);
        }
      } catch (_) {}
    }
    if (vigentes.isEmpty) return {};
    final listas = await _leerEnIsolate([
      for (final t in vigentes) '${dir.path}/$_prefijoCache${t.clave}.json',
    ]);
    return {
      for (var k = 0; k < vigentes.length; k++)
        if (listas[k] != null) vigentes[k]: listas[k]!,
    };
  }

  static Future<List<List<dynamic>?>> _leerEnIsolate(List<String> rutas) =>
      Isolate.run(() => [
            for (final r in rutas)
              () {
                try {
                  return jsonDecode(File(r).readAsStringSync()) as List;
                } catch (_) {
                  return null;
                }
              }(),
          ]);

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
