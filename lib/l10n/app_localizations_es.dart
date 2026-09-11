// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'A la sombra';

  @override
  String get exampleRoute => 'Ruta de ejemplo';

  @override
  String get clearPoints => 'Borrar puntos';

  @override
  String get tapForStart => 'Toca el mapa para marcar el inicio.';

  @override
  String get tapForEnd => 'Ahora toca el destino.';

  @override
  String get departNow => 'Salir ahora';

  @override
  String departAt(String time) {
    return 'Salida $time';
  }

  @override
  String get changeTime => 'Cambiar hora';

  @override
  String get now => 'Ahora';

  @override
  String get departureTimeTitle => 'Hora de salida';

  @override
  String get directLabel => 'Directa';

  @override
  String get shadeLabel => 'Sombra';

  @override
  String get sliderShortest => 'ruta más corta';

  @override
  String sliderPreferShade(String factor) {
    return 'prioriza sombra ×$factor';
  }

  @override
  String get noRoute =>
      'No se ha encontrado ninguna ruta peatonal entre esos puntos.';

  @override
  String get nightShortest => 'Es de noche: se muestra la ruta más corta.';

  @override
  String get networkError =>
      'No se han podido descargar los datos del mapa. Revisa la conexión e inténtalo de nuevo.';

  @override
  String statKm(String value) {
    return '$value km';
  }

  @override
  String statM(int value) {
    return '$value m';
  }

  @override
  String statMinutes(int value) {
    return '$value min';
  }

  @override
  String statShade(int percent) {
    return '$percent % en sombra';
  }

  @override
  String statDetour(int meters) {
    return '+$meters m vs directa';
  }

  @override
  String get statCache => 'caché';

  @override
  String get calculating => 'Calculando…';

  @override
  String get searchRoute => 'Buscar ruta';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Automático (sistema)';

  @override
  String get legendShade => 'En sombra';

  @override
  String get legendSun => 'Al sol';

  @override
  String routeTimeNow(String time) {
    return 'ahora, $time';
  }

  @override
  String get recalculate => 'Recalcular';

  @override
  String get about => 'Acerca de';

  @override
  String get dataSources => 'Fuentes de datos';

  @override
  String get openSourceLicenses => 'Licencias de código abierto';

  @override
  String get aboutIntro =>
      'Rutas a pie que buscan la sombra —o el sol— según la época del año.';

  @override
  String get creditMap =>
      'Calles y edificios: © colaboradores de OpenStreetMap (ODbL).';

  @override
  String get creditTiles => 'Teselas del mapa: OpenStreetMap.';

  @override
  String get creditSun => 'Posición del sol: algoritmo de Jean Meeus.';

  @override
  String get removeAdsButton => 'Quitar anuncios · 1,99 €';

  @override
  String get adsSectionTitle => 'Anuncios';

  @override
  String get adsAlreadyRemoved => 'Ya has quitado los anuncios. ¡Gracias!';

  @override
  String get removeAdsPromptTitle => '¿Sin anuncios?';

  @override
  String get removeAdsPromptBody => 'Quítalos para siempre con un único pago.';

  @override
  String get notNow => 'Ahora no';

  @override
  String get adsRemovedMockDone => 'Anuncios quitados (simulado).';

  @override
  String get introTitle => '¿A la sombra o al sol?';

  @override
  String get introBody1 =>
      'Marca un inicio y un destino: te calcula una ruta a pie que va lo más posible por la sombra… o por el sol, si lo que quieres es que te dé.';

  @override
  String get introBody2 =>
      'A la sombra en verano; al sol en invierno. Mueve la barra hacia un lado u otro según te apetezca. Calles y edificios: datos de OpenStreetMap.';

  @override
  String get introButton => 'Entendido';

  @override
  String get showIntro => 'Ver la introducción';

  @override
  String get sunLabel => 'Al sol';

  @override
  String sliderPreferSun(String factor) {
    return 'prioriza sol ×$factor';
  }

  @override
  String get shareApp => 'Compartir esta app';
}
