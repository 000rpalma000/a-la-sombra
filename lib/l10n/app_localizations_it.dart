// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'A la sombra';

  @override
  String get exampleRoute => 'Percorso di esempio';

  @override
  String get clearPoints => 'Cancella i punti';

  @override
  String get tapForStart => 'Tocca la mappa per impostare la partenza.';

  @override
  String get tapForEnd => 'Ora tocca la destinazione.';

  @override
  String get departNow => 'Parti ora';

  @override
  String departAt(String time) {
    return 'Partenza $time';
  }

  @override
  String get changeTime => 'Cambia orario';

  @override
  String get now => 'Ora';

  @override
  String get departureTimeTitle => 'Orario di partenza';

  @override
  String get directLabel => 'Diretto';

  @override
  String get shadeLabel => 'Ombra';

  @override
  String get sliderShortest => 'percorso più breve';

  @override
  String sliderPreferShade(String factor) {
    return 'prediligi l\'ombra ×$factor';
  }

  @override
  String get noRoute => 'Nessun percorso pedonale trovato tra quei punti.';

  @override
  String get nightShortest => 'È notte: viene mostrato il percorso più breve.';

  @override
  String get networkError =>
      'Impossibile scaricare i dati della mappa. Controlla la connessione e riprova.';

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
    return '$percent% all\'ombra';
  }

  @override
  String statDetour(int meters) {
    return '+$meters m vs diretto';
  }

  @override
  String get statCache => 'cache';

  @override
  String get calculating => 'Calcolo…';

  @override
  String get searchRoute => 'Trova percorso';

  @override
  String get language => 'Lingua';

  @override
  String get languageSystem => 'Automatico (sistema)';

  @override
  String get legendShade => 'All\'ombra';

  @override
  String get legendSun => 'Al sole';

  @override
  String routeTimeNow(String time) {
    return 'ora, $time';
  }

  @override
  String get recalculate => 'Ricalcola';

  @override
  String get about => 'Informazioni';

  @override
  String get dataSources => 'Fonti dei dati';

  @override
  String get openSourceLicenses => 'Licenze open source';

  @override
  String get aboutIntro =>
      'Percorsi a piedi che cercano l\'ombra — o il sole — a seconda della stagione.';

  @override
  String get creditMap =>
      'Strade ed edifici: © contributori di OpenStreetMap (ODbL).';

  @override
  String get creditTiles => 'Riquadri della mappa: OpenStreetMap.';

  @override
  String get creditSun => 'Posizione del sole: algoritmo di Jean Meeus.';

  @override
  String get removeAdsButton => 'Rimuovi pubblicità · 1,99 €';

  @override
  String get adsSectionTitle => 'Pubblicità';

  @override
  String get adsAlreadyRemoved => 'Hai già rimosso la pubblicità. Grazie!';

  @override
  String get removeAdsPromptTitle => 'Senza pubblicità?';

  @override
  String get removeAdsPromptBody =>
      'Rimuovila per sempre con un pagamento unico.';

  @override
  String get notNow => 'Non ora';

  @override
  String get adsRemovedMockDone => 'Pubblicità rimossa (simulato).';

  @override
  String get introTitle => 'All\'ombra o al sole?';

  @override
  String get introBody1 =>
      'Indica una partenza e una destinazione: calcola un percorso a piedi che sta il più possibile all\'ombra… o al sole, se è quello che vuoi.';

  @override
  String get introBody2 =>
      'All\'ombra d\'estate, al sole d\'inverno. Sposta la barra da un lato o dall\'altro a seconda di cosa preferisci. Strade ed edifici: dati di OpenStreetMap.';

  @override
  String get introButton => 'Ho capito';

  @override
  String get showIntro => 'Rivedi l\'introduzione';

  @override
  String get sunLabel => 'Al sole';

  @override
  String sliderPreferSun(String factor) {
    return 'preferisci sole ×$factor';
  }

  @override
  String get shareApp => 'Condividi questa app';
}
