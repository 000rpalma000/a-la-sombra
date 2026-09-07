import 'package:latlong2/latlong.dart';

import '../models/geo.dart';
import '../models/route_result.dart';
import '../models/shadow_map.dart';
import '../models/walk_graph.dart';

/// Calcula una ruta a pie que prioriza ir por la sombra **o por el sol**.
///
/// Coste de cada tramo: `longitud * (1 + |w| * exposición)`, con `w` =
/// [prioridad]:
///  * `w > 0` → busca sombra: `exposición` = fracción del tramo al sol.
///  * `w < 0` → busca sol: `exposición` = fracción del tramo en sombra.
///  * `w = 0` → ruta más corta.
/// Cuanto mayor es `|w|`, más desvío se acepta. De noche todos los tramos
/// tienen la misma exposición y sale la más corta en cualquier caso.
class RouterService {
  const RouterService();

  RouteResult? calcular({
    required WalkGraph graph,
    required ShadowMap shadow,
    required LatLng inicio,
    required LatLng fin,
    double prioridad = 3,
  }) {
    if (graph.vacio) return null;
    final origen = graph.nodoMasCercano(inicio);
    final destino = graph.nodoMasCercano(fin);
    if (origen == null || destino == null) return null;

    // Exposición solar de cada arista (se calcula una sola vez).
    for (final e in graph.edges.values) {
      final muestras = Geo.muestrear(e.geometry, pasoM: 15);
      e.sunExposedFraction = 1 - shadow.fraccionEnSombra(muestras);
    }

    final w = prioridad.abs();
    final buscaSol = prioridad < 0;
    final ruta = _astar(
      graph,
      origen.id,
      destino.id,
      (e) {
        final exposicion =
            buscaSol ? 1 - e.sunExposedFraction : e.sunExposedFraction;
        return e.lengthM * (1 + w * exposicion);
      },
    );
    if (ruta == null) return null;

    final masCorta = _astar(graph, origen.id, destino.id, (e) => e.lengthM);

    return _montarResultado(
      graph,
      ruta,
      origen.id,
      shortestDistanceM: masCorta == null
          ? _distanciaDeCamino(graph, ruta, origen.id)
          : _distanciaDeCamino(graph, masCorta, origen.id),
    );
  }

  // --- A* -------------------------------------------------------------------

  List<int>? _astar(
    WalkGraph graph,
    int origenId,
    int destinoId,
    double Function(GraphEdge) coste,
  ) {
    if (origenId == destinoId) return const [];
    final destinoPos = graph.nodes[destinoId]!.pos;
    double heur(int id) => Geo.distancia(graph.nodes[id]!.pos, destinoPos);

    final gScore = <int, double>{origenId: 0};
    final cameFrom = <int, int>{}; // nodo -> arista usada para llegar
    final abiertos = _MinHeap()..add(origenId, heur(origenId));
    final cerrados = <int>{};

    while (abiertos.isNotEmpty) {
      final actual = abiertos.removeMin();
      if (actual == destinoId) break;
      if (!cerrados.add(actual)) continue;

      for (final edgeId in graph.nodes[actual]!.edgeIds) {
        final e = graph.edges[edgeId]!;
        final vecino = graph.otroExtremo(e, actual);
        if (cerrados.contains(vecino)) continue;
        final tentativo = gScore[actual]! + coste(e);
        if (tentativo < (gScore[vecino] ?? double.infinity)) {
          gScore[vecino] = tentativo;
          cameFrom[vecino] = edgeId;
          abiertos.add(vecino, tentativo + heur(vecino));
        }
      }
    }

    if (!cameFrom.containsKey(destinoId)) return null;

    final aristas = <int>[];
    var cur = destinoId;
    while (cur != origenId) {
      final eid = cameFrom[cur];
      if (eid == null) return null;
      aristas.add(eid);
      cur = graph.otroExtremo(graph.edges[eid]!, cur);
    }
    return aristas.reversed.toList();
  }

  // --- Reconstrucción -----------------------------------------------------

  RouteResult _montarResultado(
    WalkGraph graph,
    List<int> aristas,
    int origenId, {
    required double shortestDistanceM,
  }) {
    final polyline = <LatLng>[];
    final segments = <RouteSegment>[];
    var distancia = 0.0;
    var distanciaSombra = 0.0;
    var nodoActual = origenId;

    for (final eid in aristas) {
      final e = graph.edges[eid]!;
      var geom = e.geometry;
      if (e.toNode == nodoActual) geom = geom.reversed.toList();

      if (polyline.isEmpty) {
        polyline.addAll(geom);
      } else {
        polyline.addAll(geom.skip(1));
      }

      final level = shadeLevelFromSunFraction(e.sunExposedFraction);
      distancia += e.lengthM;
      distanciaSombra += e.lengthM * (1 - e.sunExposedFraction);

      if (segments.isNotEmpty && segments.last.level == level) {
        segments.last.points.addAll(geom.skip(1));
      } else {
        segments.add(RouteSegment(points: List.of(geom), level: level));
      }

      nodoActual = graph.otroExtremo(e, nodoActual);
    }

    return RouteResult(
      polyline: polyline,
      segments: segments,
      distanceM: distancia,
      shadedFraction: distancia == 0 ? 0 : distanciaSombra / distancia,
      walkTime: Duration(seconds: (distancia / 1.35).round()),
      shortestDistanceM: shortestDistanceM,
    );
  }

  double _distanciaDeCamino(WalkGraph graph, List<int> aristas, int origenId) {
    var d = 0.0;
    for (final eid in aristas) {
      d += graph.edges[eid]!.lengthM;
    }
    return d;
  }
}

/// Montículo binario mínimo indexado por prioridad (double).
class _MinHeap {
  final List<int> _ids = [];
  final List<double> _prio = [];

  bool get isNotEmpty => _ids.isNotEmpty;

  void add(int id, double prio) {
    _ids.add(id);
    _prio.add(prio);
    var i = _ids.length - 1;
    while (i > 0) {
      final padre = (i - 1) >> 1;
      if (_prio[padre] <= _prio[i]) break;
      _swap(i, padre);
      i = padre;
    }
  }

  int removeMin() {
    final min = _ids.first;
    final ultimo = _ids.length - 1;
    _swap(0, ultimo);
    _ids.removeLast();
    _prio.removeLast();
    var i = 0;
    final n = _ids.length;
    while (true) {
      final l = 2 * i + 1, r = 2 * i + 2;
      var menor = i;
      if (l < n && _prio[l] < _prio[menor]) menor = l;
      if (r < n && _prio[r] < _prio[menor]) menor = r;
      if (menor == i) break;
      _swap(i, menor);
      i = menor;
    }
    return min;
  }

  void _swap(int a, int b) {
    final ti = _ids[a];
    _ids[a] = _ids[b];
    _ids[b] = ti;
    final tp = _prio[a];
    _prio[a] = _prio[b];
    _prio[b] = tp;
  }
}
