import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Cuadrícula fija del mundo (~550 × 550 m en Barcelona), la misma que usa
/// Terrazeo. Los datos de OpenStreetMap se descargan y se guardan por
/// teselas, así que dos rutas por la misma zona comparten caché.
class Tesela {
  final int i, j;

  static const double tamLat = 0.005;
  static const double tamLon = 0.0066;

  const Tesela(this.i, this.j);

  factory Tesela.de(LatLng p) => Tesela(
        (p.latitude / tamLat).floor(),
        (p.longitude / tamLon).floor(),
      );

  String get clave => '${i}_$j';
  double get sur => i * tamLat;
  double get oeste => j * tamLon;
  double get norte => (i + 1) * tamLat;
  double get este => (j + 1) * tamLon;
  LatLng get centro => LatLng((i + 0.5) * tamLat, (j + 0.5) * tamLon);

  /// ¿La caja [s, w, n, e] toca esta tesela?
  bool toca(double s, double w, double n, double e) =>
      s <= norte && n >= sur && w <= este && e >= oeste;

  /// Teselas que cubren la caja [s, w, n, e].
  static List<Tesela> cubriendo(double s, double w, double n, double e) {
    final a = Tesela.de(LatLng(s, w)), b = Tesela.de(LatLng(n, e));
    return [
      for (var i = math.min(a.i, b.i); i <= math.max(a.i, b.i); i++)
        for (var j = math.min(a.j, b.j); j <= math.max(a.j, b.j); j++)
          Tesela(i, j),
    ];
  }

  @override
  bool operator ==(Object other) =>
      other is Tesela && other.i == i && other.j == j;

  @override
  int get hashCode => Object.hash(i, j);

  @override
  String toString() => 'Tesela($clave)';
}
