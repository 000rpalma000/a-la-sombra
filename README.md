# ruta_sombra

App Flutter que calcula rutas a pie **priorizando ir por la sombra** durante las horas de sol. Proyecto hermano de `places_barcelona`.

## Estado: esqueleto funcional

Todo compila (`flutter analyze` limpio, `flutter test` y `flutter build web` OK). La tubería completa está conectada; falta afinar el modelo y la UI.

## Cómo funciona

1. Marcas **inicio** y **destino** tocando el mapa; eliges hora de salida (ahora o más tarde) y cuánta prioridad das a la sombra (slider `Directa ↔ Sombra`).
2. Se descarga de OSM (Overpass) el **viario peatonal** y los **edificios** del rectángulo que une los dos puntos (+300 m de margen).
3. `ShadowService` proyecta la sombra de cada edificio: cada vértice de la planta se desplaza `altura / tan(elevación_solar)` en dirección opuesta al sol; la sombra se aproxima por el **casco convexo** de {planta ∪ planta desplazada}.
4. `RouterService` marca cada tramo con su **fracción al sol** (muestreo cada 15 m) y busca ruta con **A\*** minimizando `longitud · (1 + w · fracciónAlSol)`. De noche → ruta más corta.
5. El mapa dibuja la ruta en **verde** (sombra) / **naranja** (sol) y muestra distancia, tiempo, % en sombra y desvío respecto a la directa.

## Estructura

```
lib/
  models/   geo.dart          haversine, destino, punto-en-polígono, casco convexo, bounds
            walk_graph.dart   grafo peatonal (nodos/aristas)
            shadow_map.dart   plantas de edificios + polígonos de sombra + test enSombra
            route_result.dart resultado (polilínea, tramos, métricas)
  services/ location_service.dart   ubicación (geolocator)
            sun_service.dart        posición del sol (solar_calculator)
            osm_walk_service.dart   Overpass: viario + edificios
            shadow_service.dart     proyección de sombras
            router_service.dart     A* con coste ponderado por sol + min-heap
  screens/  route_screen.dart       mapa, pines, hora, slider, resultado
```

## Pendiente / ideas de mejora

- **Sombras más realistas**: unir polígonos (dart_jts), tener en cuenta que un edificio tapa la sombra de otro, sombras no convexas.
- **Grafo**: fusionar cadenas de nodos de grado 2 en una sola arista; índice espacial para `nodoMasCercano`.
- **Nubosidad**: si está muy nublado (AEMET), desactivar la penalización por sol.
- **Varias franjas horarias** para paseos largos (la sombra cambia por el camino).
- **Cachear** las descargas de Overpass por zona.
- Altura por defecto de edificios sin dato (`12 m`) — ajustar por barrio.
