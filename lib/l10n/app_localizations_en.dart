// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'A la sombra';

  @override
  String get exampleRoute => 'Example route';

  @override
  String get clearPoints => 'Clear points';

  @override
  String get tapForStart => 'Tap the map to set the start.';

  @override
  String get tapForEnd => 'Now tap the destination.';

  @override
  String get departNow => 'Leave now';

  @override
  String departAt(String time) {
    return 'Leaving $time';
  }

  @override
  String get changeTime => 'Change time';

  @override
  String get now => 'Now';

  @override
  String get departureTimeTitle => 'Departure time';

  @override
  String get directLabel => 'Direct';

  @override
  String get shadeLabel => 'Shade';

  @override
  String get sliderShortest => 'shortest route';

  @override
  String sliderPreferShade(String factor) {
    return 'prefer shade ×$factor';
  }

  @override
  String get noRoute => 'No walking route found between those points.';

  @override
  String get nightShortest => 'It\'s night: showing the shortest route.';

  @override
  String get networkError =>
      'Couldn\'t download map data. Check your connection and try again.';

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
    return '$percent% in shade';
  }

  @override
  String statDetour(int meters) {
    return '+$meters m vs direct';
  }

  @override
  String get statCache => 'cached';

  @override
  String get calculating => 'Calculating…';

  @override
  String get searchRoute => 'Find route';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'Automatic (system)';

  @override
  String get legendShade => 'In shade';

  @override
  String get legendSun => 'In sun';

  @override
  String routeTimeNow(String time) {
    return 'now, $time';
  }

  @override
  String get recalculate => 'Recalculate';

  @override
  String get about => 'About';

  @override
  String get dataSources => 'Data sources';

  @override
  String get openSourceLicenses => 'Open-source licenses';

  @override
  String get aboutIntro =>
      'Walking routes that try to stay in the shade during daylight.';

  @override
  String get creditMap =>
      'Streets and buildings: © OpenStreetMap contributors (ODbL).';

  @override
  String get creditTiles => 'Map tiles: OpenStreetMap.';

  @override
  String get creditSun => 'Sun position: algorithm by Jean Meeus.';

  @override
  String get removeAdsButton => 'Remove ads · €1.99';

  @override
  String get adsSectionTitle => 'Ads';

  @override
  String get adsAlreadyRemoved => 'You already removed ads. Thank you!';

  @override
  String get removeAdsPromptTitle => 'No ads?';

  @override
  String get removeAdsPromptBody =>
      'Remove them for good with a one-time payment.';

  @override
  String get notNow => 'Not now';

  @override
  String get adsRemovedMockDone => 'Ads removed (mock).';
}
