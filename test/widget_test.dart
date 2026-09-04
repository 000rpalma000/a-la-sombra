import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:ruta_sombra/models/geo.dart';
import 'package:ruta_sombra/models/shadow_map.dart';
import 'package:ruta_sombra/services/shadow_service.dart';

void main() {
  test('ShadowMap: índice espacial y punto-en-sombra', () {
    final poly = ShadowPolygon([
      LatLng(41.3870, 2.1680),
      LatLng(41.3870, 2.1684),
      LatLng(41.3873, 2.1684),
      LatLng(41.3873, 2.1680),
    ]);
    final mapa = ShadowMap(
      instante: DateTime(2026, 6, 21, 12),
      sunAzimuthDeg: 180,
      sunElevationDeg: 45,
      polygons: [poly],
    );
    expect(mapa.enSombra(LatLng(41.38715, 2.1682)), isTrue);
    expect(mapa.enSombra(LatLng(41.3860, 2.1682)), isFalse);
    expect(
      mapa.fraccionEnSombra(
          [LatLng(41.38715, 2.1682), LatLng(41.3860, 2.1682)]),
      0.5,
    );
  });

  test('distanciaAPolilinea mide bien el alejamiento de un tramo', () {
    final linea = [LatLng(41.3874, 2.1686), LatLng(41.3809, 2.1734)];
    expect(Geo.distanciaAPolilinea(LatLng(41.3874, 2.1686), linea),
        lessThan(1));
    // ~1 km al norte del primer punto
    expect(Geo.distanciaAPolilinea(LatLng(41.3964, 2.1686), linea),
        greaterThan(700));
  });

  test('cascoConvexo envuelve un cuadrado desplazado', () {
    final base = [
      LatLng(41.3870, 2.1680),
      LatLng(41.3870, 2.1682),
      LatLng(41.3872, 2.1682),
      LatLng(41.3872, 2.1680),
    ];
    final casco = Geo.cascoConvexo(base);
    expect(casco.length, greaterThanOrEqualTo(4));
  });

  test('dentroDePoligono acierta dentro y fuera', () {
    final anillo = [
      LatLng(0, 0),
      LatLng(0, 2),
      LatLng(2, 2),
      LatLng(2, 0),
    ];
    expect(Geo.dentroDePoligono(LatLng(1, 1), anillo), isTrue);
    expect(Geo.dentroDePoligono(LatLng(3, 3), anillo), isFalse);
  });

  test('ShadowService de noche no genera sombras y marca noche', () {
    final edificio = BuildingFootprint(
      ring: [
        LatLng(41.3870, 2.1680),
        LatLng(41.3870, 2.1682),
        LatLng(41.3872, 2.1682),
      ],
      heightM: 20,
    );
    final mapa = const ShadowService().construir(
      [edificio],
      LatLng(41.3874, 2.1686),
      DateTime(2026, 1, 15, 2), // madrugada
    );
    expect(mapa.esDeNoche, isTrue);
    expect(mapa.polygons, isEmpty);
  });

  test('ShadowService a media mañana proyecta sombra hacia el oeste-ish', () {
    final edificio = BuildingFootprint(
      ring: [
        LatLng(41.3870, 2.1680),
        LatLng(41.3870, 2.1682),
        LatLng(41.3872, 2.1682),
        LatLng(41.3872, 2.1680),
      ],
      heightM: 30,
    );
    final mapa = const ShadowService().construir(
      [edificio],
      LatLng(41.3874, 2.1686),
      DateTime(2026, 6, 21, 10),
    );
    expect(mapa.esDeNoche, isFalse);
    expect(mapa.polygons, isNotEmpty);
  });
}
