// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'A la sombra';

  @override
  String get exampleRoute => 'Itinéraire d\'exemple';

  @override
  String get clearPoints => 'Effacer les points';

  @override
  String get tapForStart => 'Touchez la carte pour définir le départ.';

  @override
  String get tapForEnd => 'Touchez maintenant la destination.';

  @override
  String get departNow => 'Partir maintenant';

  @override
  String departAt(String time) {
    return 'Départ $time';
  }

  @override
  String get changeTime => 'Changer l\'heure';

  @override
  String get now => 'Maintenant';

  @override
  String get departureTimeTitle => 'Heure de départ';

  @override
  String get directLabel => 'Direct';

  @override
  String get shadeLabel => 'Ombre';

  @override
  String get sliderShortest => 'itinéraire le plus court';

  @override
  String sliderPreferShade(String factor) {
    return 'privilégier l\'ombre ×$factor';
  }

  @override
  String get noRoute => 'Aucun itinéraire piéton trouvé entre ces points.';

  @override
  String get nightShortest =>
      'Il fait nuit : itinéraire le plus court affiché.';

  @override
  String get networkError =>
      'Impossible de télécharger les données de la carte. Vérifiez votre connexion et réessayez.';

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
    return '$percent % à l\'ombre';
  }

  @override
  String statDetour(int meters) {
    return '+$meters m vs direct';
  }

  @override
  String get statCache => 'cache';

  @override
  String get calculating => 'Calcul…';

  @override
  String get searchRoute => 'Rechercher l\'itinéraire';

  @override
  String get language => 'Langue';

  @override
  String get languageSystem => 'Automatique (système)';

  @override
  String get legendShade => 'À l\'ombre';

  @override
  String get legendSun => 'Au soleil';

  @override
  String routeTimeNow(String time) {
    return 'maintenant, $time';
  }

  @override
  String get recalculate => 'Recalculer';

  @override
  String get about => 'À propos';

  @override
  String get dataSources => 'Sources de données';

  @override
  String get openSourceLicenses => 'Licences open source';

  @override
  String get aboutIntro =>
      'Itinéraires à pied qui cherchent à rester à l\'ombre pendant la journée.';

  @override
  String get creditMap =>
      'Rues et bâtiments : © contributeurs OpenStreetMap (ODbL).';

  @override
  String get creditTiles => 'Tuiles de la carte : OpenStreetMap.';

  @override
  String get creditSun => 'Position du soleil : algorithme de Jean Meeus.';

  @override
  String get removeAdsButton => 'Supprimer les publicités · 1,99 €';

  @override
  String get adsSectionTitle => 'Publicités';

  @override
  String get adsAlreadyRemoved =>
      'Vous avez déjà supprimé les publicités. Merci !';

  @override
  String get removeAdsPromptTitle => 'Sans publicités ?';

  @override
  String get removeAdsPromptBody =>
      'Supprimez-les définitivement avec un paiement unique.';

  @override
  String get notNow => 'Pas maintenant';

  @override
  String get adsRemovedMockDone => 'Publicités supprimées (simulé).';
}
