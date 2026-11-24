# Monetización (apagada hoy)

Alombra se publica **sin anuncios y sin cobros**.

## Anuncios (AdMob)

El código completo con anuncios está guardado en la rama
**`con-anuncios-admob`**: un intersticial antes de cada nueva búsqueda de
ruta, oferta de "quitar anuncios" y sección en Acerca de. Usa los IDs de
prueba de Google.

Para recuperarlo:

```sh
git checkout con-anuncios-admob -- lib/services/ads_service.dart lib/services/search_gate.dart
# y volver a añadir en pubspec.yaml:  google_mobile_ads: ^9.1.0
```

Después, revisar el diff de la rama para restaurar:
- `lib/screens/route_screen.dart`: `AdsService.instancia.inicializar()`, el
  anuncio "armado" en `_buscar()` y `_ofrecerQuitarAnuncios()`.
- `lib/screens/about_screen.dart`: sección de anuncios.
- `ios/Runner/Info.plist`: `GADApplicationIdentifier`.
- `android/app/src/main/AndroidManifest.xml`: meta-data
  `com.google.android.gms.ads.APPLICATION_ID`.

Antes de publicar con anuncios, ver la lista de pasos de Terrazeo
(`MONETIZACION.md` del repo `terrazeo`): IDs reales de AdMob, compra real de
"quitar anuncios", política de privacidad y formularios de las tiendas,
consentimiento en la UE y alta de autónomo.
