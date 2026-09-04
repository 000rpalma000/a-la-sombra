import 'package:latlong2/latlong.dart';

/// Nivel de exposición al sol de un tramo.
enum ShadeLevel { sol, sombra }

ShadeLevel shadeLevelFromSunFraction(double sunFraction) =>
    sunFraction >= 0.5 ? ShadeLevel.sol : ShadeLevel.sombra;

/// Un tramo de la ruta, con su nivel de sombra (para colorearlo).
class RouteSegment {
  final List<LatLng> points;
  final ShadeLevel level;
  const RouteSegment({required this.points, required this.level});
}

/// Resultado de calcular una ruta a la sombra.
class RouteResult {
  /// Trazado completo, punto a punto.
  final List<LatLng> polyline;

  /// Tramos por nivel de sombra.
  final List<RouteSegment> segments;

  final double distanceM;

  /// Fracción del recorrido que va en sombra (0..1).
  final double shadedFraction;

  /// Tiempo estimado a pie (~1,35 m/s).
  final Duration walkTime;

  /// Ruta más corta ignorando la sombra, para comparar el desvío.
  final double shortestDistanceM;

  const RouteResult({
    required this.polyline,
    required this.segments,
    required this.distanceM,
    required this.shadedFraction,
    required this.walkTime,
    required this.shortestDistanceM,
  });

  /// Metros de más respecto a la ruta directa.
  double get desvioM => (distanceM - shortestDistanceM).clamp(0, double.infinity);

  int get shadedPercent => (shadedFraction * 100).round();
}
