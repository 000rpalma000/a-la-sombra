import 'package:shared_preferences/shared_preferences.dart';

/// Cuenta cada "búsqueda" (pulsación de "Buscar ruta") de forma persistente,
/// para mostrar un anuncio cada [cadaN] búsquedas — incluso entre sesiones
/// (el contador se guarda en disco, no se reinicia al cerrar la app).
class SearchGate {
  static const cadaN = 3;
  static const _kContador = 'search_gate_contador';
  static const _kSinAnuncios = 'search_gate_sin_anuncios';

  /// Registra una búsqueda y devuelve `true` si toca mostrar un anuncio.
  Future<bool> registrarBusqueda() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kSinAnuncios) ?? false) return false;
    final n = (prefs.getInt(_kContador) ?? 0) + 1;
    await prefs.setInt(_kContador, n);
    return n % cadaN == 0;
  }

  Future<bool> anunciosEliminados() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kSinAnuncios) ?? false;
  }

  /// Compra simulada de "quitar anuncios" (in-app purchase real pendiente de
  /// cuenta de Play Console / App Store Connect).
  Future<void> eliminarAnunciosMock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSinAnuncios, true);
  }
}
