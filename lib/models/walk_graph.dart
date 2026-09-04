import 'package:latlong2/latlong.dart';

import 'geo.dart';

/// Nodo del grafo peatonal (una intersección o el extremo de una calle).
class GraphNode {
  final int id;
  final LatLng pos;
  final List<int> edgeIds = [];

  GraphNode(this.id, this.pos);
}

/// Arista: un tramo de calle transitable entre dos nodos.
class GraphEdge {
  final int id;
  final int fromNode;
  final int toNode;

  /// Geometría real del tramo (para dibujar y para muestrear sombra).
  final List<LatLng> geometry;
  final double lengthM;

  /// Fracción del tramo expuesta al sol (0 = toda en sombra). La rellena
  /// [ShadowService] / [RouterService] antes de calcular la ruta.
  double sunExposedFraction;

  GraphEdge({
    required this.id,
    required this.fromNode,
    required this.toNode,
    required this.geometry,
    required this.lengthM,
    this.sunExposedFraction = 1,
  });
}

/// Grafo peatonal de un área. Construido a partir de OSM (ver [OsmWalkService]).
class WalkGraph {
  final Map<int, GraphNode> nodes = {};
  final Map<int, GraphEdge> edges = {};

  int _nextEdgeId = 0;

  GraphNode nodoOCrea(int osmNodeId, LatLng pos) {
    return nodes.putIfAbsent(osmNodeId, () => GraphNode(osmNodeId, pos));
  }

  void addEdge(GraphNode a, GraphNode b, List<LatLng> geometry) {
    if (a.id == b.id) return;
    final length = Geo.longitudPolilinea(geometry);
    if (length <= 0) return;

    final id = _nextEdgeId++;
    edges[id] = GraphEdge(
      id: id,
      fromNode: a.id,
      toNode: b.id,
      geometry: geometry,
      lengthM: length,
    );
    a.edgeIds.add(id);
    b.edgeIds.add(id);
  }

  /// Nodo más cercano a [p] (búsqueda lineal; suficiente para un corredor).
  GraphNode? nodoMasCercano(LatLng p) {
    GraphNode? mejor;
    var mejorD = double.infinity;
    for (final n in nodes.values) {
      final d = Geo.distancia(p, n.pos);
      if (d < mejorD) {
        mejorD = d;
        mejor = n;
      }
    }
    return mejor;
  }

  /// El otro extremo de [edge] partiendo de [nodeId].
  int otroExtremo(GraphEdge edge, int nodeId) =>
      edge.fromNode == nodeId ? edge.toNode : edge.fromNode;

  bool get vacio => edges.isEmpty;
}
