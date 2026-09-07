import 'package:shared_preferences/shared_preferences.dart';

/// Ritmo de anuncios en "A la sombra": la **primera** búsqueda de la sesión no
/// lleva anuncio; a partir de ahí, cada nueva búsqueda muestra un anuncio antes
/// de calcular. El "armado" vive en memoria, así que al reabrir la app se
/// vuelve a empezar sin anuncio en la primera.
///
/// Comprar "quitar anuncios" (persistente) desactiva todo para siempre.
class SearchGate {
  static const _kSinAnuncios = 'search_gate_sin_anuncios';

  /// En memoria, por sesión.
  static bool _armado = false;

  /// Tras completar una búsqueda: deja un anuncio pendiente para la próxima.
  Future<void> armarAnuncio() async {
    if (await anunciosEliminados()) return;
    _armado = true;
  }

  /// Al empezar otra búsqueda: ¿hay un anuncio armado? Lo consume y lo indica.
  Future<bool> consumirAnuncioArmado() async {
    if (await anunciosEliminados()) {
      _armado = false;
      return false;
    }
    if (!_armado) return false;
    _armado = false;
    return true;
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
