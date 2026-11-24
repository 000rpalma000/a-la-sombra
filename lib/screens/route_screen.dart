import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../config/map_config.dart';
import '../l10n/app_localizations.dart';
import '../models/geo.dart';
import '../models/route_result.dart';
import '../models/shadow_map.dart';
import '../services/locale_controller.dart';
import '../services/location_service.dart';
import '../services/osm_walk_service.dart';
import '../services/router_service.dart';
import '../services/shadow_service.dart';
import '../widgets/intro_sheet.dart';
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

  /// Se completa cuando el mapa se ha dibujado por primera vez. Antes de eso
  /// el [MapController] lanza si se usa (pasaba cuando la ubicación respondía
  /// al instante, p. ej. con el permiso denegado).
  final _mapaListo = Completer<void>();
  final _location = const LocationService();
  final _osm = OsmWalkService();
  final _shadow = const ShadowService();
  final _router = const RouterService();

  LatLng _centroInicial = LocationService.fallback;

  /// Ubicación actual del usuario (null hasta que se obtiene).
  LatLng? _miUbicacion;
  LatLng? _inicio;
  LatLng? _fin;

  /// null = salir ahora.
  DateTime? _horaSalida;

  /// Preferencia de exposición: > 0 busca sombra, < 0 busca sol, 0 = más corta.
  double _prioridad = 4.5;
  static const _prioridadMax = 8.0;

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

  /// Valor de [_prioridad] en el momento de calcular.
  double? _prioridadAlCalcular;

  bool get _rutaObsoleta {
    if (_ruta == null) return false;
    // Se cambió la hora de salida o la preferencia sol/sombra.
    if (_horaSalida != _seleccionAlCalcular) return true;
    if (_prioridad != _prioridadAlCalcular) return true;
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
    _quizaMostrarIntro();
    _location.ubicacionActual().then((u) async {
      await _mapaListo.future;
      if (!mounted) return;
      setState(() {
        _centroInicial = u.punto;
        // Solo se marca "estás aquí" si la posición es real, no el respaldo.
        _miUbicacion = u.esReal ? u.punto : null;
      });
      _mapController.move(u.punto, 15);
      if (u.motivo != null) _avisarSinUbicacion(u.motivo!);
      if (_demoAlArrancar) {
        setState(() {
          _inicio = LatLng(41.3874, 2.1686); // Pl. Catalunya
          _fin = LatLng(41.3809, 2.1734); // Pl. Reial
        });
        _buscar();
      }
    });
  }

  void _quizaMostrarIntro() {
    // La introducción sale en cada apertura.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) mostrarIntro(context);
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

      final prioridad = _prioridad;
      RouteResult? calcular(CorredorOsm c, ShadowMap shadow) => _router.calcular(
            graph: c.grafo,
            shadow: shadow,
            inicio: inicio,
            fin: fin,
            prioridad: prioridad,
          );

      // Pasada 1: banda alrededor de la línea recta. Ancha, para que el
      // enrutador pueda plantearse rodeos buscando sombra.
      var corredor = await _osm.descargarCorredor(
        [inicio, fin],
        radioCallesM: 340,
        radioEdificiosM: 400,
      );
      var shadow = _shadow.construir(corredor.edificios, centro, hora);
      var ruta = calcular(corredor, shadow);

      // Pasada 2: si la ruta se sale de la zona con edificios, se vuelve a
      // descargar a lo largo de la ruta real y se recalcula, para que TODO el
      // recorrido tenga sus fachadas (y sus sombras).
      const margenCoberturaM = 320.0;
      final seSale = ruta != null &&
          ruta.polyline.any((p) =>
              Geo.distanciaAPolilinea(p, [inicio, fin]) > margenCoberturaM);
      if (seSale) {
        // Si esta segunda descarga falla, se queda la ruta de la primera
        // pasada (con alguna fachada de menos en los extremos) en vez de
        // perderlo todo.
        try {
          final corredor2 = await _osm.descargarCorredor(
            ruta.polyline,
            radioCallesM: 220,
            radioEdificiosM: 300,
          );
          final shadow2 = _shadow.construir(corredor2.edificios, centro, hora);
          final ruta2 = calcular(corredor2, shadow2);
          if (ruta2 != null) {
            corredor = corredor2;
            shadow = shadow2;
            ruta = ruta2;
          }
        } catch (e) {
          debugPrint('[ruta] falló la 2ª pasada, me quedo con la 1ª: $e');
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
        _prioridadAlCalcular = prioridad;
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
    } catch (e) {
      debugPrint('[ruta] error: $e');
      if (!mounted) return;
      setState(() => _aviso = _Aviso.red);
    } finally {
      if (mounted) setState(() => _calculando = false);
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
                // Siempre visible: si aún no hay ubicación real, reintenta.
                Positioned(
                  top: 12,
                  right: 12,
                  child: FloatingActionButton.small(
                    heroTag: 'miUbicacion',
                    onPressed: _centrarEnMiUbicacion,
                    child: Icon(_miUbicacion != null
                        ? Icons.my_location
                        : Icons.location_searching),
                  ),
                ),
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

  void _avisarSinUbicacion(MotivoSinUbicacion motivo) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final texto = switch (motivo) {
      MotivoSinUbicacion.servicioApagado => l10n.locationOff,
      MotivoSinUbicacion.sinPermiso => l10n.locationDenied,
      MotivoSinUbicacion.sinSenal => l10n.locationNoSignal,
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        duration: const Duration(seconds: 6),
        action: motivo == MotivoSinUbicacion.sinSenal
            ? SnackBarAction(label: l10n.retry, onPressed: _reintentarUbicacion)
            : SnackBarAction(
                label: l10n.openSettings,
                onPressed: () => _location.abrirAjustes(motivo),
              ),
      ),
    );
  }

  Future<void> _reintentarUbicacion() async {
    final u = await _location.ubicacionActual();
    if (!mounted) return;
    if (!u.esReal) {
      _avisarSinUbicacion(u.motivo!);
      return;
    }
    setState(() => _miUbicacion = u.punto);
    _centrarEnMiUbicacion();
  }

  void _centrarEnMiUbicacion() {
    final u = _miUbicacion;
    if (u == null) {
      _reintentarUbicacion();
      return;
    }
    double z;
    try {
      z = _mapController.camera.zoom;
    } catch (_) {
      z = 15;
    }
    _mapController.move(u, z < 14 ? 15 : z);
  }

  Widget _mapa() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        onMapReady: () {
          if (!_mapaListo.isCompleted) _mapaListo.complete();
        },
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
            if (_miUbicacion != null)
              Marker(
                point: _miUbicacion!,
                width: 24,
                height: 24,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF1A73E8),
                    border: Border.fromBorderSide(
                      BorderSide(color: Colors.white, width: 3.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
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
                  Text(l10n.sunLabel),
                  Expanded(
                    child: Slider(
                      value: _prioridad,
                      min: -_prioridadMax,
                      max: _prioridadMax,
                      divisions: 32,
                      label: _prioridad == 0
                          ? l10n.sliderShortest
                          : _prioridad > 0
                              ? l10n.sliderPreferShade(
                                  _prioridad.toStringAsFixed(1))
                              : l10n.sliderPreferSun(
                                  _prioridad.abs().toStringAsFixed(1)),
                      onChanged: (v) => setState(() => _prioridad = v),
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
