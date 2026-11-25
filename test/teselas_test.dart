import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:ruta_sombra/models/geo.dart';
import 'package:ruta_sombra/models/tesela.dart';
import 'package:ruta_sombra/services/osm_walk_service.dart';

void main() {
  test('Tesela.de y cubriendo', () {
    const p = LatLng(41.3842, 2.1710);
    final t = Tesela.de(p);
    expect(p.latitude, inInclusiveRange(t.sur, t.norte));
    expect(p.longitude, inInclusiveRange(t.oeste, t.este));
    expect(Tesela.cubriendo(41.380, 2.165, 41.389, 2.177), hasLength(2 * 2));
  });

  test('repartir: una calle larga va a todas las teselas que cruza', () {
    final a = const Tesela(8276, 328), b = const Tesela(8276, 329),
        c = const Tesela(8276, 330);
    final cuerpo = jsonEncode({
      'elements': [
        {
          'type': 'way', 'id': 1, 'tags': {'highway': 'residential'},
          'bounds': {
            'minlat': 41.3820, 'maxlat': 41.3822,
            'minlon': a.oeste + 0.001, 'maxlon': c.oeste + 0.001,
          },
        },
        {
          'type': 'way', 'id': 2, 'tags': {'building': 'yes'},
          'bounds': {
            'minlat': 41.3820, 'maxlat': 41.3821,
            'minlon': b.oeste + 0.001, 'maxlon': b.oeste + 0.0012,
          },
        },
      ],
    });
    final r = OsmWalkService.repartir(cuerpo, [(a.i, a.j), (b.i, b.j), (c.i, c.j)]);
    List<int> ids(Tesela t) =>
        [for (final e in r[t.clave]!) (e as Map)['id'] as int];
    expect(ids(a), [1]);
    expect(ids(b), [1, 2]);
    expect(ids(c), [1]);
  });

  test('teselasDelCorredor cubre toda la banda alrededor de la ruta', () {
    const inicio = LatLng(41.3874, 2.1686), fin = LatLng(41.3809, 2.1734);
    const radio = 400.0;
    final ts = OsmWalkService.teselasDelCorredor([inicio, fin], radio).toSet();
    // Puntos a ≤ 400 m de la línea: todos en alguna tesela elegida.
    for (var k = 0; k <= 40; k++) {
      final f = k / 40;
      final base = LatLng(inicio.latitude + (fin.latitude - inicio.latitude) * f,
          inicio.longitude + (fin.longitude - inicio.longitude) * f);
      for (final rumbo in [0.0, 90.0, 180.0, 270.0, 45.0, 225.0]) {
        final q = Geo.destino(base, rumbo, radio * 0.98);
        expect(ts.contains(Tesela.de(q)), isTrue, reason: '$q');
      }
    }
    // Y no pide medio Barcelona: una ruta de ~830 m cabe en unas pocas.
    expect(ts.length, lessThan(25));
  });
}
