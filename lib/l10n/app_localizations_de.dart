// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'A la sombra';

  @override
  String get exampleRoute => 'Beispielroute';

  @override
  String get clearPoints => 'Punkte löschen';

  @override
  String get tapForStart => 'Tippe auf die Karte, um den Start zu setzen.';

  @override
  String get tapForEnd => 'Jetzt tippe auf das Ziel.';

  @override
  String get departNow => 'Jetzt losgehen';

  @override
  String departAt(String time) {
    return 'Abfahrt $time';
  }

  @override
  String get changeTime => 'Zeit ändern';

  @override
  String get now => 'Jetzt';

  @override
  String get departureTimeTitle => 'Abfahrtszeit';

  @override
  String get directLabel => 'Direkt';

  @override
  String get shadeLabel => 'Schatten';

  @override
  String get sliderShortest => 'kürzeste Route';

  @override
  String sliderPreferShade(String factor) {
    return 'Schatten bevorzugen ×$factor';
  }

  @override
  String get noRoute => 'Zwischen diesen Punkten wurde kein Fußweg gefunden.';

  @override
  String get nightShortest =>
      'Es ist Nacht: die kürzeste Route wird angezeigt.';

  @override
  String get networkError =>
      'Kartendaten konnten nicht geladen werden. Prüfe die Verbindung und versuche es erneut.';

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
    return '$value Min.';
  }

  @override
  String statShade(int percent) {
    return '$percent % im Schatten';
  }

  @override
  String statDetour(int meters) {
    return '+$meters m ggü. direkt';
  }

  @override
  String get statCache => 'Cache';

  @override
  String get calculating => 'Berechnung…';

  @override
  String get searchRoute => 'Route suchen';

  @override
  String get language => 'Sprache';

  @override
  String get languageSystem => 'Automatisch (System)';

  @override
  String get legendShade => 'Im Schatten';

  @override
  String get legendSun => 'In der Sonne';

  @override
  String routeTimeNow(String time) {
    return 'jetzt, $time';
  }

  @override
  String get recalculate => 'Neu berechnen';

  @override
  String get about => 'Über die App';

  @override
  String get dataSources => 'Datenquellen';

  @override
  String get openSourceLicenses => 'Open-Source-Lizenzen';

  @override
  String get aboutIntro =>
      'Fußrouten, die je nach Jahreszeit den Schatten – oder die Sonne – suchen.';

  @override
  String get creditMap =>
      'Straßen und Gebäude: © OpenStreetMap-Mitwirkende (ODbL).';

  @override
  String get creditTiles => 'Kartenkacheln: OpenStreetMap.';

  @override
  String get creditSun => 'Sonnenstand: Algorithmus von Jean Meeus.';

  @override
  String get removeAdsButton => 'Werbung entfernen · 1,99 €';

  @override
  String get adsSectionTitle => 'Werbung';

  @override
  String get adsAlreadyRemoved =>
      'Du hast die Werbung bereits entfernt. Danke!';

  @override
  String get removeAdsPromptTitle => 'Ohne Werbung?';

  @override
  String get removeAdsPromptBody =>
      'Entferne sie dauerhaft mit einer einmaligen Zahlung.';

  @override
  String get notNow => 'Jetzt nicht';

  @override
  String get adsRemovedMockDone => 'Werbung entfernt (simuliert).';

  @override
  String get introTitle => 'Schatten oder Sonne?';

  @override
  String get introBody1 =>
      'Setze Start und Ziel: Die App berechnet einen Fußweg, der so weit wie möglich im Schatten bleibt – oder in der Sonne, wenn du das möchtest.';

  @override
  String get introBody2 =>
      'Schatten im Sommer, Sonne im Winter. Schiebe den Regler in die eine oder andere Richtung, je nach Lust. Straßen und Gebäude: Daten von OpenStreetMap.';

  @override
  String get introButton => 'Verstanden';

  @override
  String get showIntro => 'Einführung anzeigen';

  @override
  String get sunLabel => 'Sonne';

  @override
  String sliderPreferSun(String factor) {
    return 'Sonne bevorzugen ×$factor';
  }
}
