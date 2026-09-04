import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ca.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ca'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'A la sombra'**
  String get appTitle;

  /// No description provided for @exampleRoute.
  ///
  /// In es, this message translates to:
  /// **'Ruta de ejemplo'**
  String get exampleRoute;

  /// No description provided for @clearPoints.
  ///
  /// In es, this message translates to:
  /// **'Borrar puntos'**
  String get clearPoints;

  /// No description provided for @tapForStart.
  ///
  /// In es, this message translates to:
  /// **'Toca el mapa para marcar el inicio.'**
  String get tapForStart;

  /// No description provided for @tapForEnd.
  ///
  /// In es, this message translates to:
  /// **'Ahora toca el destino.'**
  String get tapForEnd;

  /// No description provided for @departNow.
  ///
  /// In es, this message translates to:
  /// **'Salir ahora'**
  String get departNow;

  /// No description provided for @departAt.
  ///
  /// In es, this message translates to:
  /// **'Salida {time}'**
  String departAt(String time);

  /// No description provided for @changeTime.
  ///
  /// In es, this message translates to:
  /// **'Cambiar hora'**
  String get changeTime;

  /// No description provided for @now.
  ///
  /// In es, this message translates to:
  /// **'Ahora'**
  String get now;

  /// No description provided for @departureTimeTitle.
  ///
  /// In es, this message translates to:
  /// **'Hora de salida'**
  String get departureTimeTitle;

  /// No description provided for @directLabel.
  ///
  /// In es, this message translates to:
  /// **'Directa'**
  String get directLabel;

  /// No description provided for @shadeLabel.
  ///
  /// In es, this message translates to:
  /// **'Sombra'**
  String get shadeLabel;

  /// No description provided for @sliderShortest.
  ///
  /// In es, this message translates to:
  /// **'ruta más corta'**
  String get sliderShortest;

  /// No description provided for @sliderPreferShade.
  ///
  /// In es, this message translates to:
  /// **'prioriza sombra ×{factor}'**
  String sliderPreferShade(String factor);

  /// No description provided for @noRoute.
  ///
  /// In es, this message translates to:
  /// **'No se ha encontrado ninguna ruta peatonal entre esos puntos.'**
  String get noRoute;

  /// No description provided for @nightShortest.
  ///
  /// In es, this message translates to:
  /// **'Es de noche: se muestra la ruta más corta.'**
  String get nightShortest;

  /// No description provided for @networkError.
  ///
  /// In es, this message translates to:
  /// **'No se han podido descargar los datos del mapa. Revisa la conexión e inténtalo de nuevo.'**
  String get networkError;

  /// No description provided for @statKm.
  ///
  /// In es, this message translates to:
  /// **'{value} km'**
  String statKm(String value);

  /// No description provided for @statM.
  ///
  /// In es, this message translates to:
  /// **'{value} m'**
  String statM(int value);

  /// No description provided for @statMinutes.
  ///
  /// In es, this message translates to:
  /// **'{value} min'**
  String statMinutes(int value);

  /// No description provided for @statShade.
  ///
  /// In es, this message translates to:
  /// **'{percent} % en sombra'**
  String statShade(int percent);

  /// No description provided for @statDetour.
  ///
  /// In es, this message translates to:
  /// **'+{meters} m vs directa'**
  String statDetour(int meters);

  /// No description provided for @statCache.
  ///
  /// In es, this message translates to:
  /// **'caché'**
  String get statCache;

  /// No description provided for @calculating.
  ///
  /// In es, this message translates to:
  /// **'Calculando…'**
  String get calculating;

  /// No description provided for @searchRoute.
  ///
  /// In es, this message translates to:
  /// **'Buscar ruta'**
  String get searchRoute;

  /// No description provided for @language.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In es, this message translates to:
  /// **'Automático (sistema)'**
  String get languageSystem;

  /// No description provided for @legendShade.
  ///
  /// In es, this message translates to:
  /// **'En sombra'**
  String get legendShade;

  /// No description provided for @legendSun.
  ///
  /// In es, this message translates to:
  /// **'Al sol'**
  String get legendSun;

  /// No description provided for @routeTimeNow.
  ///
  /// In es, this message translates to:
  /// **'ahora, {time}'**
  String routeTimeNow(String time);

  /// No description provided for @recalculate.
  ///
  /// In es, this message translates to:
  /// **'Recalcular'**
  String get recalculate;

  /// No description provided for @about.
  ///
  /// In es, this message translates to:
  /// **'Acerca de'**
  String get about;

  /// No description provided for @dataSources.
  ///
  /// In es, this message translates to:
  /// **'Fuentes de datos'**
  String get dataSources;

  /// No description provided for @openSourceLicenses.
  ///
  /// In es, this message translates to:
  /// **'Licencias de código abierto'**
  String get openSourceLicenses;

  /// No description provided for @aboutIntro.
  ///
  /// In es, this message translates to:
  /// **'Rutas a pie que buscan ir por la sombra durante las horas de sol.'**
  String get aboutIntro;

  /// No description provided for @creditMap.
  ///
  /// In es, this message translates to:
  /// **'Calles y edificios: © colaboradores de OpenStreetMap (ODbL).'**
  String get creditMap;

  /// No description provided for @creditTiles.
  ///
  /// In es, this message translates to:
  /// **'Teselas del mapa: OpenStreetMap.'**
  String get creditTiles;

  /// No description provided for @creditSun.
  ///
  /// In es, this message translates to:
  /// **'Posición del sol: algoritmo de Jean Meeus.'**
  String get creditSun;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ca', 'en', 'es', 'fr', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ca':
      return AppLocalizationsCa();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
