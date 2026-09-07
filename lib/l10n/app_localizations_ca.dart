// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Catalan Valencian (`ca`).
class AppLocalizationsCa extends AppLocalizations {
  AppLocalizationsCa([String locale = 'ca']) : super(locale);

  @override
  String get appTitle => 'A la sombra';

  @override
  String get exampleRoute => 'Ruta d\'exemple';

  @override
  String get clearPoints => 'Esborra els punts';

  @override
  String get tapForStart => 'Toca el mapa per marcar l\'inici.';

  @override
  String get tapForEnd => 'Ara toca la destinació.';

  @override
  String get departNow => 'Surt ara';

  @override
  String departAt(String time) {
    return 'Sortida $time';
  }

  @override
  String get changeTime => 'Canvia l\'hora';

  @override
  String get now => 'Ara';

  @override
  String get departureTimeTitle => 'Hora de sortida';

  @override
  String get directLabel => 'Directa';

  @override
  String get shadeLabel => 'Ombra';

  @override
  String get sliderShortest => 'ruta més curta';

  @override
  String sliderPreferShade(String factor) {
    return 'prioritza l\'ombra ×$factor';
  }

  @override
  String get noRoute => 'No s\'ha trobat cap ruta a peu entre aquests punts.';

  @override
  String get nightShortest => 'És de nit: es mostra la ruta més curta.';

  @override
  String get networkError =>
      'No s\'han pogut baixar les dades del mapa. Comprova la connexió i torna-ho a provar.';

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
    return '$percent % a l\'ombra';
  }

  @override
  String statDetour(int meters) {
    return '+$meters m vs directa';
  }

  @override
  String get statCache => 'memòria cau';

  @override
  String get calculating => 'Calculant…';

  @override
  String get searchRoute => 'Cerca ruta';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Automàtic (sistema)';

  @override
  String get legendShade => 'A l\'ombra';

  @override
  String get legendSun => 'Al sol';

  @override
  String routeTimeNow(String time) {
    return 'ara, $time';
  }

  @override
  String get recalculate => 'Recalcula';

  @override
  String get about => 'Sobre l\'app';

  @override
  String get dataSources => 'Fonts de dades';

  @override
  String get openSourceLicenses => 'Llicències de codi obert';

  @override
  String get aboutIntro =>
      'Rutes a peu que busquen l\'ombra —o el sol— segons l\'època de l\'any.';

  @override
  String get creditMap =>
      'Carrers i edificis: © col·laboradors d’OpenStreetMap (ODbL).';

  @override
  String get creditTiles => 'Tessel·les del mapa: OpenStreetMap.';

  @override
  String get creditSun => 'Posició del sol: algorisme de Jean Meeus.';

  @override
  String get removeAdsButton => 'Treu anuncis · 1,99 €';

  @override
  String get adsSectionTitle => 'Anuncis';

  @override
  String get adsAlreadyRemoved => 'Ja has tret els anuncis. Gràcies!';

  @override
  String get removeAdsPromptTitle => 'Sense anuncis?';

  @override
  String get removeAdsPromptBody => 'Treu-los per sempre amb un únic pagament.';

  @override
  String get notNow => 'Ara no';

  @override
  String get adsRemovedMockDone => 'Anuncis trets (simulat).';

  @override
  String get introTitle => 'A l\'ombra o al sol?';

  @override
  String get introBody1 =>
      'Marca un inici i una destinació: et calcula una ruta a peu que va tant com pot per l\'ombra… o pel sol, si el que vols és que et toqui.';

  @override
  String get introBody2 =>
      'A l\'ombra a l\'estiu; al sol a l\'hivern. Mou la barra cap a un costat o cap a l\'altre segons et vingui de gust. Carrers i edificis: dades d\'OpenStreetMap.';

  @override
  String get introButton => 'Entesos';

  @override
  String get showIntro => 'Mostra la introducció';

  @override
  String get sunLabel => 'Al sol';

  @override
  String sliderPreferSun(String factor) {
    return 'prioritza sol ×$factor';
  }
}
