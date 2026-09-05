import 'package:shared_preferences/shared_preferences.dart';

/// Ritmo de anuncios en "A la sombra": tras **cada** búsqueda de ruta se deja
/// un anuncio "armado", y se muestra cuando el usuario va a hacer la
/// siguiente. Estado persistente (sobrevive a cerrar la app).
///
/// Comprar "quitar anuncios" pone [anunciosEliminados] a `true` para siempre.
/// De momento la "compra" es un mock local; el cobro real (in_app_purchase +
/// producto en las tiendas) se conecta más adelante sin cambiar esta clase.
class SearchGate {
  static const _kArmado = 'search_gate_armado';
  static const _kSinAnuncios = 'search_gate_sin_anuncios';

  /// Tras completar una búsqueda: deja un anuncio pendiente para la próxima.
  Future<void> armarAnuncio() async {
    final sp = await SharedPreferences.getInstance();
    if (sp.getBool(_kSinAnuncios) ?? false) return;
    await sp.setBool(_kArmado, true);
  }

  /// Al empezar otra búsqueda: ¿hay un anuncio armado? Lo consume y lo indica.
  Future<bool> consumirAnuncioArmado() async {
    final sp = await SharedPreferences.getInstance();
    if (sp.getBool(_kSinAnuncios) ?? false) return false;
    final armado = sp.getBool(_kArmado) ?? false;
    if (armado) await sp.setBool(_kArmado, false);
    return armado;
  }

  Future<bool> anunciosEliminados() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kSinAnuncios) ?? false;
  }

  /// TODO: sustituir por una compra real (in_app_purchase) cuando haya
  /// cuentas de App Store Connect / Play Console con el producto creado.
  Future<void> eliminarAnunciosMock() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kSinAnuncios, true);
  }
}
