import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../config/map_config.dart';
import '../l10n/app_localizations.dart';
import '../models/geo.dart';
import '../models/route_result.dart';
import '../models/shadow_map.dart';
import '../services/ads_service.dart';
import '../services/locale_controller.dart';
import '../services/location_service.dart';
import '../services/osm_walk_service.dart';
import '../services/router_service.dart';
import '../services/search_gate.dart';
import '../services/shadow_service.dart';
import 'about_screen.dart';

class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key, required this.localeController});

  final LocaleController localeController;

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

/// Motivo por el que no hay ruta (se traduce al pintar, no al guardarlo).
enum _Aviso { sinRuta, deNoche, red }

class _RouteScreenState extends State<RouteScreen> {
  final _mapController = MapController();
  final _location = const LocationService();
  final _osm = OsmWalkService();
  final _shadow = const ShadowService();
  final _router = const RouterService();

  LatLng _centroInicial = LocationService.fallback;
  LatLng? _inicio;
  LatLng? _fin;

  /// null = salir ahora.
  DateTime? _horaSalida;
  double _prioridadSombra = 3;

  bool _calculando = false;
  RouteResult? _ruta;
  _Aviso? _aviso;
  bool _datosDesdeCache = false;

  /// Hora real con la que se calculó la ruta que se está mostrando.
  DateTime? _horaCalculada;
  bool _calculadaComoAhora = true;

  /// Valor de [_horaSalida] en el momento de calcular: si cambia, la ruta
  /// mostrada queda obsoleta.
  DateTime? _seleccionAlCalcular;

  bool get _rutaObsoleta {
    if (_ruta == null) return false;
    // Se cambió la hora de salida seleccionada.
    if (_horaSalida != _seleccionAlCalcular) return true;
    // Se calculó "para ahora" pero ha pasado bastante tiempo.
    if (_calculadaComoAhora && _horaCalculada != null) {
      return DateTime.now().difference(_horaCalculada!).inMinutes.abs() >= 15;
    }
    return false;
  }

  /// TODO: provisional — arranca con una ruta de ejemplo para probar sin tocar.
  static const bool _demoAlArrancar = false;

  static const _verde = Color(0xFF2E7D32); // sombra
  static const _sol = Color(0xFFEF8A17); // sol

  Color _colorNivel(ShadeLevel l) =>
      l == ShadeLevel.sombra ? _verde : _sol;

  @override
  void initState() {
    super.initState();
    AdsService.instancia.inicializar();
    _location.ubicacionActual().then((u) {
      if (!mounted) return;
      setState(() => _centroInicial = u.punto);
      _mapController.move(u.punto, 15);
      if (_demoAlArrancar) {
        setState(() {
          _inicio = LatLng(41.3874, 2.1686); // Pl. Catalunya
          _fin = LatLng(41.3809, 2.1734); // Pl. Reial
        });
        _buscar();
      }
    });
  }

  @override
  void dispose() {
    _osm.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onTapMapa(LatLng punto) {
    setState(() {
      _ruta = null;
      _aviso = null;
      if (_inicio == null || (_inicio != null && _fin != null)) {
        _inicio = punto;
        _fin = null;
      } else {
        _fin = punto;
      }
    });
  }

  Future<void> _elegirHora() async {
    final base = _horaSalida ?? DateTime.now();
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
      helpText: AppLocalizations.of(context).departureTimeTitle,
    );
    if (t == null) return;
    final now = DateTime.now();
    var dt = DateTime(now.year, now.month, now.day, t.hour, t.minute);
    if (dt.isBefore(now.subtract(const Duration(minutes: 1)))) {
      dt = dt.add(const Duration(days: 1));
    }
    setState(() => _horaSalida = dt);
  }

  Future<void> _elegirIdioma() async {
    final l10n = AppLocalizations.of(context);
    final actual = widget.localeController.locale?.languageCode ?? '';
    final elegido = await showDialog<OpcionIdioma>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.language),
        children: [
          for (final op in idiomasDisponibles)
            ListTile(
              title:
                  Text(op.locale == null ? l10n.languageSystem : op.nombre),
              trailing: (op.locale?.languageCode ?? '') == actual
                  ? const Icon(Icons.check)
                  : null,
              onTap: () => Navigator.pop(ctx, op),
            ),
        ],
      ),
    );
    if (elegido != null) {
      await widget.localeController.establecer(elegido.locale);
    }
  }

  Future<void> _buscar() async {
    final inicio = _inicio, fin = _fin;
    if (inicio == null || fin == null) return;

    // Si la búsqueda anterior dejó un anuncio armado, se muestra ahora (antes
    // de la nueva) y se ofrece quitar los anuncios.
    if (await SearchGate().consumirAnuncioArmado()) {
      final visto = await AdsService.instancia.mostrarSiListo();
      if (visto && mounted) await _ofrecerQuitarAnuncios();
      if (!mounted) return;
    }

    setState(() {
      _calculando = true;
      _aviso = null;
      _ruta = null;
    });

    final cron = Stopwatch()..start();
    final seleccion = _horaSalida;
    final eraAhora = seleccion == null;
    try {
      final hora = seleccion ?? DateTime.now();
      final centro = LatLng(
        (inicio.latitude + fin.latitude) / 2,
        (inicio.longitude + fin.longitude) / 2,
      );

      RouteResult? calcular(CorredorOsm c, ShadowMap shadow) => _router.calcular(
            graph: c.grafo,
            shadow: shadow,
            inicio: inicio,
            fin: fin,
            prioridadSombra: _prioridadSombra,
          );

      // Pasada 1: banda alrededor de la línea recta.
      var corredor = await _osm.descargarCorredor([inicio, fin]);
      var shadow = _shadow.construir(corredor.edificios, centro, hora);
      var ruta = calcular(corredor, shadow);

      // Pasada 2: si la ruta se sale de la zona con edificios, se vuelve a
      // descargar a lo largo de la ruta real y se recalcula, para que TODO el
      // recorrido tenga sus fachadas (y sus sombras).
      const margenCoberturaM = 200.0;
      final seSale = ruta != null &&
          ruta.polyline.any((p) =>
              Geo.distanciaAPolilinea(p, [inicio, fin]) > margenCoberturaM);
      if (seSale) {
        final corredor2 = await _osm.descargarCorredor(
          ruta.polyline,
          radioCallesM: 150,
          radioEdificiosM: 210,
        );
        final shadow2 = _shadow.construir(corredor2.edificios, centro, hora);
        final ruta2 = calcular(corredor2, shadow2);
        if (ruta2 != null) {
          corredor = corredor2;
          shadow = shadow2;
          ruta = ruta2;
        }
      }

      _datosDesdeCache = corredor.desdeCache;
      debugPrint('[ruta] OSM ${cron.elapsedMilliseconds} ms '
          '(${corredor.desdeCache ? "CACHÉ" : "red"}${seSale ? "+2ª pasada" : ""}) · '
          '${corredor.grafo.nodes.length} nodos, '
          '${corredor.edificios.length} edificios · '
          'plantas zona ${corredor.medianaPlantasZona?.toStringAsFixed(1) ?? "—"}');

      if (!mounted) return;
      setState(() {
        _ruta = ruta;
        _horaCalculada = hora;
        _calculadaComoAhora = eraAhora;
        _seleccionAlCalcular = seleccion;
        _aviso = ruta == null
            ? _Aviso.sinRuta
            : shadow.esDeNoche
                ? _Aviso.deNoche
                : null;
      });
      if (ruta != null) {
        _mapController.fitCamera(
          CameraFit.coordinates(
            coordinates: ruta.polyline,
            padding: const EdgeInsets.all(48),
          ),
        );
      }
      debugPrint('[ruta] total ${cron.elapsedMilliseconds} ms');
      // Deja un anuncio armado para la próxima búsqueda.
      await SearchGate().armarAnuncio();
    } catch (e) {
      debugPrint('[ruta] error: $e');
      if (!mounted) return;
      setState(() => _aviso = _Aviso.red);
    } finally {
      if (mounted) setState(() => _calculando = false);
    }
  }

  Future<void> _ofrecerQuitarAnuncios() async {
    final l10n = AppLocalizations.of(context);
    final quitar = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.removeAdsPromptTitle,
                  style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(l10n.removeAdsPromptBody,
                  style: Theme.of(ctx).textTheme.bodyMedium),
              const SizedBox(height: 18),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(l10n.notNow),
                  ),
                  const Spacer(),
                  FilledButton.tonal(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(l10n.removeAdsButton),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (quitar == true) {
      await SearchGate().eliminarAnunciosMock();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.adsRemovedMockDone)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            tooltip: l10n.language,
            icon: const Icon(Icons.translate),
            onPressed: _elegirIdioma,
          ),
          IconButton(
            tooltip: l10n.about,
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),
          // TODO: provisional para pruebas: fija un inicio/destino de ejemplo.
          IconButton(
            tooltip: l10n.exampleRoute,
            icon: const Icon(Icons.casino_outlined),
            onPressed: _calculando
                ? null
                : () {
                    setState(() {
                      _inicio = LatLng(41.3874, 2.1686); // Pl. Catalunya
                      _fin = LatLng(41.3809, 2.1734); // Pl. Reial
                      _ruta = null;
                      _aviso = null;
                    });
                    _buscar();
                  },
          ),
          if (_inicio != null || _fin != null)
            IconButton(
              tooltip: l10n.clearPoints,
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() {
                _inicio = null;
                _fin = null;
                _ruta = null;
                _aviso = null;
              }),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                _mapa(),
                if (_ruta != null)
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: _leyenda(l10n),
                  ),
                if (_calculando)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x33000000),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
          ),
          _panel(l10n),
        ],
      ),
    );
  }

  Widget _leyenda(AppLocalizations l10n) {
    Widget fila(Color color, String texto) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(texto, style: const TextStyle(fontSize: 12)),
          ],
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          fila(_verde, l10n.legendShade),
          const SizedBox(height: 4),
          fila(_sol, l10n.legendSun),
        ],
      ),
    );
  }

  Widget _mapa() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _centroInicial,
        initialZoom: 15,
        onTap: (_, punto) => _onTapMapa(punto),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom |
              InteractiveFlag.drag |
              InteractiveFlag.doubleTapZoom,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: MapConfig.urlTemplate,
          userAgentPackageName: MapConfig.userAgent,
          retinaMode: RetinaMode.isHighDensity(context),
        ),
        if (_ruta != null)
          PolylineLayer(
            polylines: [
              for (final s in _ruta!.segments)
                Polyline(
                  points: s.points,
                  strokeWidth: 6,
                  color: _colorNivel(s.level),
                ),
            ],
          )
        else if (_inicio != null && _fin != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [_inicio!, _fin!],
                strokeWidth: 2,
                color: Colors.grey,
                pattern: StrokePattern.dashed(segments: const [6, 6]),
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            if (_inicio != null)
              Marker(
                point: _inicio!,
                width: 36,
                height: 36,
                child: const Icon(Icons.trip_origin, color: _verde, size: 30),
              ),
            if (_fin != null)
              Marker(
                point: _fin!,
                width: 36,
                height: 36,
                child: const Icon(Icons.place, color: Colors.red, size: 36),
              ),
          ],
        ),
        RichAttributionWidget(
          attributions: [TextSourceAttribution(MapConfig.atribucion)],
        ),
      ],
    );
  }

  Widget _panel(AppLocalizations l10n) {
    final ruta = _ruta;
    final hayPuntos = _inicio != null && _fin != null;

    return SafeArea(
      top: false,
      child: Material(
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!hayPuntos)
                Text(
                  _inicio == null ? l10n.tapForStart : l10n.tapForEnd,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 20),
                  const SizedBox(width: 8),
                  Text(_horaSalida == null
                      ? l10n.departNow
                      : l10n.departAt(_hhmm(_horaSalida!))),
                  const Spacer(),
                  if (_horaSalida != null)
                    TextButton(
                      onPressed: () => setState(() => _horaSalida = null),
                      child: Text(l10n.now),
                    ),
                  TextButton(
                    onPressed: _elegirHora,
                    child: Text(l10n.changeTime),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(l10n.directLabel),
                  Expanded(
                    child: Slider(
                      value: _prioridadSombra,
                      min: 0,
                      max: 6,
                      divisions: 12,
                      label: _prioridadSombra == 0
                          ? l10n.sliderShortest
                          : l10n.sliderPreferShade(
                              _prioridadSombra.toStringAsFixed(1)),
                      onChanged: (v) => setState(() => _prioridadSombra = v),
                    ),
                  ),
                  Text(l10n.shadeLabel),
                ],
              ),
              if (ruta != null) _resumen(l10n, ruta),
              if (_aviso != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _textoAviso(l10n, _aviso!),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: hayPuntos && !_calculando ? _buscar : null,
                  icon: Icon(_rutaObsoleta
                      ? Icons.refresh
                      : Icons.directions_walk),
                  label: Text(_calculando
                      ? l10n.calculating
                      : _rutaObsoleta
                          ? l10n.recalculate
                          : l10n.searchRoute),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _textoAviso(AppLocalizations l10n, _Aviso a) => switch (a) {
        _Aviso.sinRuta => l10n.noRoute,
        _Aviso.deNoche => l10n.nightShortest,
        _Aviso.red => l10n.networkError,
      };

  Widget _resumen(AppLocalizations l10n, RouteResult r) {
    final km = r.distanceM / 1000;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        children: [
          if (_horaCalculada != null)
            _dato(
              Icons.schedule,
              _calculadaComoAhora
                  ? l10n.routeTimeNow(_hhmm(_horaCalculada!))
                  : _hhmm(_horaCalculada!),
            ),
          _dato(
            Icons.straighten,
            km >= 1
                ? l10n.statKm(_fmt(km, 2))
                : l10n.statM(r.distanceM.round()),
          ),
          _dato(Icons.timer_outlined, l10n.statMinutes(r.walkTime.inMinutes)),
          _dato(Icons.wb_shade, l10n.statShade(r.shadedPercent)),
          if (r.desvioM > 20)
            _dato(Icons.turn_slight_right, l10n.statDetour(r.desvioM.round())),
          if (_datosDesdeCache)
            _dato(Icons.offline_bolt_outlined, l10n.statCache),
        ],
      ),
    );
  }

  Widget _dato(IconData icon, String txt) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 4),
          Text(txt),
        ],
      );

  /// Formatea con coma decimal salvo en inglés.
  String _fmt(double v, int dec) {
    final s = v.toStringAsFixed(dec);
    final code = Localizations.localeOf(context).languageCode;
    return code == 'en' ? s : s.replaceAll('.', ',');
  }

  static String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
