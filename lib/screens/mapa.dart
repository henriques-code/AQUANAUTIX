import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '_shared.dart';
import 'especies.dart';
import '../core/widgets/aquanautix_pins.dart';
import '../core/widgets/map_legend_widget.dart';
import 'paywall.dart';
import '../core/services/analytics_service.dart';
import '../core/services/app_insights_service.dart';
import '../core/l10n/aqx_l10n.dart';
import '../core/state/fishing_context_store.dart';
import '../core/state/fishing_mode_store.dart';
import '../core/tides/oracle_data_service.dart';
import '../core/catch_photos/catch_photo_model.dart';
import '../core/catch_photos/catch_photo_repository.dart';
import '../core/catch_photos/catch_photos_store.dart';
import '../core/supabase_bootstrap.dart';

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// P4 + P10 — ECRÃ 02 · MAPA + SPOTS + LOJAS
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class MapaModuleScreen extends StatelessWidget {
  const MapaModuleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: kBg,
      body: SafeArea(child: MapaScreen()),
    );
  }
}

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key, this.onSpotOpensOracle});

  /// Chamado após escolher um spot: contexto já actualizado; Home pode mudar tab para Oráculo.
  final VoidCallback? onSpotOpensOracle;

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  /// Amarelo — spots FREE partilhados (comunidade / curados).
  static const _pinCommunity = Color(0xFFFFD600);
  /// Azulão — spots PRO (curadoria).
  static const _pinProBlue = Color(0xFF007BFF);

  static const _prefsKeySavedSpotPhotos = 'map_saved_spot_pins_v1';
  static const _prefsKeySeamarks = 'map_show_seamarks_v1';

  bool _rioMode = false;
  bool _mostrarLojas = false;

  // ── Fotos geolocalizadas de capturas ────────────────────
  late final CatchPhotosStore _catchStore;
  final CatchPhotoRepository _catchPhotoRepo = CatchPhotoRepository();
  List<CatchPhoto> _catchPhotos = [];
  bool _loadingCatchPhotos = false;
  bool _showCatchPhotos = true;
  bool _showSeamarks = true; // overlay marcas náuticas (OpenSeaMap)
  bool _sheetExpanded = false; // sheet spots aberto/fechado (começa fechado)
  final _mapController = MapController();
  final Map<String, Uint8List> _spotReferencePhotos = {};

  // Dados dos spots com coordenadas reais PT/ES
  static const _spots = [
    (name: 'Praia da Comporta', local: 'Setúbal · PRAIA', tier: 'FREE', score: 71, lat: 38.374, lon: -8.776, locked: false, elite: false, region: 'SETUBAL', species: 'DOURADA', photo: 'https://images.unsplash.com/photo-1505118380757-91f5f5632de0?w=80&q=70&auto=format'),
    (name: 'Cabo Espichel N.', local: 'Sesimbra · ROCHA', tier: 'PRO', score: 84, lat: 38.415, lon: -9.217, locked: true, elite: false, region: 'SETUBAL', species: 'ROBALO', photo: 'https://images.unsplash.com/photo-1544979590-04bcee11af7d?w=80&q=70&auto=format'),
    (name: 'Pedra Branca', local: 'Ericeira · ROCHA', tier: 'PRO', score: 68, lat: 38.970, lon: -9.420, locked: false, elite: false, region: 'MAFRA', species: 'ROBALO', photo: 'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=80&q=70&auto=format'),
    (name: 'Elite #7 · Sagres', local: 'Algarve · ROCHA', tier: 'ELITE', score: 92, lat: 37.013, lon: -8.943, locked: true, elite: true, region: 'CASCAIS', species: 'CORVINA', photo: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=80&q=70&auto=format'),
  ];

  static const _baitShops = [
    (name: 'Bait Sesimbra', lat: 38.443, lon: -9.100, mapsQuery: '38.443,-9.100', photoUrl: 'https://images.unsplash.com/photo-1516939884455-1445c8652f83?w=160&q=70&auto=format', isOpen: true),
    (name: 'Iscos Comporta', lat: 38.372, lon: -8.781, mapsQuery: '38.372,-8.781', photoUrl: 'https://images.unsplash.com/photo-1556740749-887f6717d7e4?w=160&q=70&auto=format', isOpen: true),
    (name: 'Ericeira Bait', lat: 38.969, lon: -9.418, mapsQuery: '38.969,-9.418', photoUrl: 'https://images.unsplash.com/photo-1520607162513-77705c0f0d4a?w=160&q=70&auto=format', isOpen: true),
    (name: 'Sagres Tackle', lat: 37.011, lon: -8.948, mapsQuery: '37.011,-8.948', photoUrl: 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=160&q=70&auto=format', isOpen: true),
    (name: 'Vigo Mar Shop', lat: 42.226, lon: -8.734, mapsQuery: '42.226,-8.734', photoUrl: 'https://images.unsplash.com/photo-1505118380757-91f5f5632de0?w=160&q=70&auto=format', isOpen: false),
    (name: 'A Coruña Bait', lat: 43.370, lon: -8.398, mapsQuery: '43.370,-8.398', photoUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=160&q=70&auto=format', isOpen: true),
  ];

  @override
  void initState() {
    super.initState();
    _rioMode = FishingModeStore.instance.isRio.value;
    FishingModeStore.instance.isRio.addListener(_onFishingModeChanged);
    unawaited(_loadSavedSpotPhotosFromPrefs());
    unawaited(_loadSeamarksPrefs());
    _catchStore = CatchPhotosStore();
    _catchStore.addListener(_onCatchStoreChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_loadCatchPhotos());
    });
  }

  Future<void> _loadCatchPhotos() async {
    if (_loadingCatchPhotos) return;
    setState(() => _loadingCatchPhotos = true);
    try {
      double lat = 39.5;
      double lng = -9.0;
      try {
        final c = _mapController.camera.center;
        lat = c.latitude;
        lng = c.longitude;
      } catch (_) {}
      final photos = await _catchPhotoRepo.fetchNearby(lat: lat, lng: lng, radiusKm: 100);
      if (!mounted) return;
      setState(() => _catchPhotos = photos);
    } catch (e) {
      debugPrint('CatchPhotos load error: $e');
    } finally {
      if (mounted) setState(() => _loadingCatchPhotos = false);
    }
  }

  void _onCatchStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    FishingModeStore.instance.isRio.removeListener(_onFishingModeChanged);
    _catchStore.removeListener(_onCatchStoreChanged);
    _catchStore.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadSeamarksPrefs() async {
    final p = await SharedPreferences.getInstance();
    final val = p.getBool(_prefsKeySeamarks);
    if (val != null && mounted) setState(() => _showSeamarks = val);
  }

  Future<void> _loadSavedSpotPhotosFromPrefs() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_prefsKeySavedSpotPhotos);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      for (final e in list) {
        final m = e as Map<String, dynamic>;
        final name = m['name'] as String?;
        final b64 = m['photoBase64'] as String?;
        if (name != null && b64 != null && b64.isNotEmpty) {
          _spotReferencePhotos[name] = base64Decode(b64);
        }
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _saveSpotPhotosToPrefs() async {
    final list = <Map<String, dynamic>>[];
    for (final e in _spotReferencePhotos.entries) {
      for (final s in _spots) {
        if (s.name != e.key) continue;
        list.add({
          'name': e.key,
          'lat': s.lat,
          'lon': s.lon,
          'photoBase64': base64Encode(e.value),
        });
        break;
      }
    }
    final p = await SharedPreferences.getInstance();
    await p.setString(_prefsKeySavedSpotPhotos, jsonEncode(list));
  }

  List<({String name, double lat, double lon, String mapsQuery, String photoUrl, bool isOpen})> _nearbyBaitShops() {
    final distance = const Distance();
    return _baitShops.where((shop) {
      if (!shop.isOpen) return false;
      return _spots.any((spot) {
        final km = distance.as(
          LengthUnit.Kilometer,
          LatLng(shop.lat, shop.lon),
          LatLng(spot.lat, spot.lon),
        );
        return km <= 5.0;
      });
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final t = aqxL10nOf(context);
    final sheetExpandedH = MediaQuery.of(context).size.height * 0.40;
    return Column(
      children: [
        // ── Mapa — expande quando o sheet está fechado ───
        Expanded(
          child: Stack(
            children: [
              // flutter_map com tiles Mapbox raster (sem PlatformView — sem ecrã preto).
              Positioned.fill(
                child: _buildFlutterMap(),
              ),

              // Score área
              Positioned(
                top: 12, left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: kCard.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kCyan.withValues(alpha: 0.5)),
                  ),
                  child: Text('${t.es ? "SCORE ÁREA" : "SCORE ÁREA"}:  84', style: mono(11, c: kCyan)),
                ),
              ),
              Positioned(
                top: 50,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: kCard.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kCyan.withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('N', style: mono(9, c: kCyan)),
                      const Icon(Icons.north_rounded, size: 14, color: kCyan),
                      Text('S', style: mono(9, c: kHint)),
                    ],
                  ),
                ),
              ),

              // Botões zoom + layers + ghost + lojas
              Positioned(
                top: 12, right: 12,
                child: Column(children: [
                  _mapBtn(Icons.add, onTap: _zoomIn),
                  const SizedBox(height: 6),
                  _mapBtn(Icons.remove, onTap: _zoomOut),
                  const SizedBox(height: 12),
                  _mapBtn(Icons.layers_outlined, onTap: _cycleLayers),
                  const SizedBox(height: 6),
                  _mapBtn(Icons.my_location_rounded, onTap: _centerOnIberia),
                  const SizedBox(height: 6),
                  _mapBtn(Icons.lock_outline, color: kAmber, onTap: _ghostOrPaywall),
                ]),
              ),
              Positioned(
                left: 12,
                bottom: 12,
                child: MapLegendWidget(isRiver: _rioMode),
              ),

              // ── FAB câmara — nova captura geolocada ───────
              Positioned(
                right: 12,
                bottom: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Biblioteca de espécies
                    _mapBtn(
                      Icons.auto_stories_outlined,
                      color: kAmber,
                      onTap: () => Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => const EspeciesScreen(),
                          transitionDuration: const Duration(milliseconds: 350),
                          transitionsBuilder: (_, anim, __, child) =>
                              FadeTransition(opacity: anim, child: child),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Toggle visibilidade das fotos
                    _mapBtn(
                      _showCatchPhotos ? Icons.photo_library_rounded : Icons.photo_library_outlined,
                      color: _showCatchPhotos ? kCyan : kHint,
                      onTap: () => setState(() => _showCatchPhotos = !_showCatchPhotos),
                    ),
                    const SizedBox(height: 8),
                    // Botão upload
                    GestureDetector(
                      onTap: _openUploadForm,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: kCyan,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: kCyan.withValues(alpha: 0.45), blurRadius: 14, spreadRadius: 2)],
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.black, size: 26),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Sheet bottom (colapsável) ─────────────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          height: _sheetExpanded ? sheetExpandedH : 62.0,
          decoration: BoxDecoration(
            color: kCard,
            border: Border(top: BorderSide(color: kCyan.withValues(alpha: 0.2))),
          ),
          child: ClipRect(
            child: SingleChildScrollView(
              physics: _sheetExpanded
                  ? const AlwaysScrollableScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // Handle clicável — abre/fecha o sheet
              GestureDetector(
                onTap: () => setState(() => _sheetExpanded = !_sheetExpanded),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: double.infinity,
                  height: 32,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 36, height: 4,
                        decoration: BoxDecoration(
                          color: kHint.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _sheetExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                        size: 16,
                        color: kCyan.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Toggle tabs SPOTS / LOJAS ────────────
              Row(children: [
                _sheetTab(t.es ? 'SPOTS CERCANOS' : 'SPOTS PRÓXIMOS', !_mostrarLojas, () => setState(() => _mostrarLojas = false)),
                const SizedBox(width: 8),
                _sheetTab(t.es ? 'ðŸª TIENDAS' : 'ðŸª LOJAS', _mostrarLojas, () => setState(() => _mostrarLojas = true)),
              ]),
              const SizedBox(height: 10),

              if (!_mostrarLojas) ...[
                _spotRow(
                  'Praia da Comporta',
                  'Setúbal · PRAIA',
                  'FREE',
                  null,
                  '71',
                  bloqueado: false,
                  species: 'DOURADA',
                  photoUrl: 'https://images.unsplash.com/photo-1505118380757-91f5f5632de0?w=80&q=70&auto=format',
                  onTap: () => _setContext('SETUBAL', 'DOURADA', spotName: 'Praia da Comporta'),
                ),
                _spotRow(
                  'Cabo Espichel N.',
                  'Sesimbra · ROCHA',
                  'PRO',
                  'GHOST',
                  '84',
                  bloqueado: true,
                  species: 'ROBALO',
                  photoUrl: 'https://images.unsplash.com/photo-1544979590-04bcee11af7d?w=80&q=70&auto=format',
                  onTap: () => _setContext('SETUBAL', 'ROBALO', spotName: 'Cabo Espichel N.'),
                ),
                _spotRow(
                  'Pedra Branca',
                  'Ericeira · ROCHA',
                  'PRO',
                  null,
                  '68',
                  bloqueado: false,
                  species: 'ROBALO',
                  photoUrl: 'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=80&q=70&auto=format',
                  onTap: () => _setContext('MAFRA', 'ROBALO', spotName: 'Pedra Branca'),
                ),
                _spotRow(
                  'Elite #7 · Sagres',
                  'Algarve · ROCHA',
                  'ELITE',
                  'GHOST',
                  '92',
                  bloqueado: true,
                  elite: true,
                  species: 'CORVINA',
                  photoUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=80&q=70&auto=format',
                  onTap: () => _setContext('CASCAIS', 'CORVINA', spotName: 'Elite #7'),
                ),
                const SizedBox(height: 8),
              ] else ...[
                _lojaRow(
                  'Pesca Atlântica',
                  'Sesimbra',
                  '1.2km',
                  '4.7',
                  'ABERTO · até 19h',
                  photoUrl: 'https://images.unsplash.com/photo-1516939884455-1445c8652f83?w=120&q=70&auto=format',
                  mapsQuery: '38.4445,-9.1028',
                ),
                _lojaRow(
                  'Isco & Cia',
                  'Almada',
                  '2.8km',
                  '4.3',
                  'ABERTO · até 20h',
                  photoUrl: 'https://images.unsplash.com/photo-1556740749-887f6717d7e4?w=120&q=70&auto=format',
                  mapsQuery: '38.6803,-9.1568',
                ),
                _lojaRow(
                  'Náutica Sul',
                  'Seixal',
                  '3.5km',
                  '4.9',
                  'Fecha em 45min',
                  photoUrl: 'https://images.unsplash.com/photo-1520607162513-77705c0f0d4a?w=120&q=70&auto=format',
                  mapsQuery: '38.6427,-9.1037',
                ),
                const SizedBox(height: 8),
              ],
              ValueListenableBuilder<FishingContext>(
                valueListenable: FishingContextStore.instance.value,
                builder: (context, fishingCtx, _) => FutureBuilder<AppInsights>(
                  future: AppInsightsService.instance.load(
                    country: fishingCtx.country,
                    region: fishingCtx.region,
                    species: fishingCtx.species,
                  ),
                  builder: (context, snapshot) {
                    final data = snapshot.data ?? AppInsightsService.fallbackData;
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: kBg.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kAmber.withValues(alpha: 0.22)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.privacy_tip_outlined, size: 16, color: kAmber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data.privacyTitle, style: mono(9, c: kAmber, ls: 0.9)),
                                const SizedBox(height: 2),
                                Text(data.privacyDetail, style: ibm(11, c: Colors.white70)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _zoomIn() {
    HapticFeedback.selectionClick();
    final cam = _mapController.camera;
    _mapController.move(cam.center, (cam.zoom + 1.0).clamp(4.0, 19.0));
  }

  void _zoomOut() {
    HapticFeedback.selectionClick();
    final cam = _mapController.camera;
    _mapController.move(cam.center, (cam.zoom - 1.0).clamp(4.0, 19.0));
  }

  void _cycleLayers() {
    HapticFeedback.selectionClick();
    setState(() => _showSeamarks = !_showSeamarks);
    SharedPreferences.getInstance().then((p) => p.setBool(_prefsKeySeamarks, _showSeamarks));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _showSeamarks ? 'Marcas náuticas: ON' : 'Marcas náuticas: OFF',
          style: ibm(13),
        ),
        backgroundColor: kCard,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _centerOnIberia() {
    HapticFeedback.selectionClick();
    _mapController.move(const LatLng(39.5, -9.0), 6.8);
  }

  Widget _buildFlutterMap() {
    // ArcGIS World Imagery — satélite global gratuito, sem API key, sem ecrã preto.
    // Nota: ArcGIS usa {z}/{y}/{x} (y antes de x), diferente do padrão OSM {z}/{x}/{y}.
    const arcgisSatellite =
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
    // Overlay de estradas/labels transparente sobre satélite (modo COSTA).
    const arcgisRoads =
        'https://server.arcgisonline.com/ArcGIS/rest/services/Reference/World_Transportation/MapServer/tile/{z}/{y}/{x}';

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        backgroundColor: kBg,
        initialCenter: const LatLng(39.5, -9.0),
        initialZoom: 6.5,
        minZoom: 4.0,
        maxZoom: 19.0,
      ),
      children: [
        // Base: satélite (COSTA) ou OSM topográfico (RIO)
        TileLayer(
          urlTemplate: _rioMode
              ? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
              : arcgisSatellite,
          userAgentPackageName: 'com.example.aquanautix',
          maxNativeZoom: 19,
        ),
        // Estradas transparentes sobre satélite
        if (!_rioMode)
          TileLayer(
            urlTemplate: arcgisRoads,
            userAgentPackageName: 'com.example.aquanautix',
            maxNativeZoom: 19,
          ),
        // Marcas náuticas
        if (_showSeamarks)
          Opacity(
            opacity: 0.95,
            child: TileLayer(
              urlTemplate: 'https://tiles.openseamap.org/seamark/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.aquanautix',
              minNativeZoom: 6,
              maxNativeZoom: 18,
            ),
          ),
        MarkerLayer(
          markers: [
            ..._buildCommunitySpotMarkers(),
            ..._buildBaitShopMarkers(),
            ..._buildSavedFishermanMarkers(),
            ..._buildTestPins(),
          ],
        ),
        if (_showCatchPhotos)
          MarkerLayer(
            markers: _buildCatchPhotoMarkers(),
          ),
      ],
    );
  }

  // Listener do FishingModeStore — reconstrói flutter_map com novo tileUrl.
  void _onFishingModeChanged() {
    final isRio = FishingModeStore.instance.isRio.value;
    if (isRio == _rioMode) return;
    setState(() => _rioMode = isRio);
  }

  Future<void> _ghostOrPaywall() async {
    HapticFeedback.mediumImpact();
    await PaywallScreen.open(context, source: 'mapa_ghost_mode');
  }

  /// Comunidade curada: FREE amarelo, PRO azulão, ELITE âmbar.
  List<Marker> _buildCommunitySpotMarkers() {
    return _spots.map((s) {
      final Color pinColor = s.elite
          ? kAmber
          : (s.tier == 'PRO' ? _pinProBlue : _pinCommunity);
      return Marker(
        point: LatLng(s.lat, s.lon),
        width: 40,
        height: 47,
        child: GestureDetector(
          onTap: () {
            if (!s.locked) _setContext(s.region, s.species, spotName: s.name);
            _showSpotDetail(
              ctx: context,
              name: s.name,
              local: s.local,
              score: s.score.toString(),
              tier: s.tier,
              bloqueado: s.locked,
              elite: s.elite,
              photoUrl: s.photo,
              species: s.species,
              onTap: s.locked ? null : widget.onSpotOpensOracle,
            );
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: const Size(40, 47),
                painter: s.elite
                    ? const AqxPinElite()
                    : (s.tier == 'PRO'
                        ? const AqxPinPro()
                        : const AqxPinFree()),
              ),
              if (s.locked)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: kCard,
                      shape: BoxShape.circle,
                      border: Border.all(color: pinColor.withValues(alpha: 0.65)),
                    ),
                    child: Icon(Icons.lock_rounded, size: 9, color: pinColor),
                  ),
                ),
            ],
          ),
        ),
      );
    }).toList();
  }

  /// Vermelho — spot com foto de referência gravada pelo pescador (persistida).
  List<Marker> _buildSavedFishermanMarkers() {
    final out = <Marker>[];
    for (final e in _spotReferencePhotos.entries) {
      final photoBytes = e.value;
      for (final s in _spots) {
        if (s.name != e.key) continue;
        out.add(
          Marker(
            point: LatLng(s.lat, s.lon),
            width: 40,
            height: 47,
            child: GestureDetector(
              onTap: () => _showSavedFishermanPinDetail(name: s.name, photo: photoBytes, lat: s.lat, lon: s.lon),
              child: const CustomPaint(
                size: Size(40, 47),
                painter: AqxPinSaved(),
              ),
            ),
          ),
        );
        break;
      }
    }
    return out;
  }

  void _showSavedFishermanPinDetail({
    required String name,
    required Uint8List photo,
    required double lat,
    required double lon,
  }) {
    final t = aqxL10nOf(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: orb(16, fw: FontWeight.w800)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(photo, width: double.infinity, height: 200, fit: BoxFit.cover),
              ),
              const SizedBox(height: 8),
              Text(
                '${t.es ? "Ubicación" : "Localização"}: ${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}',
                style: mono(10, c: kHint),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Verde — lojas de isco abertas ≤5 km (foto + nome no detalhe).
  List<Marker> _buildBaitShopMarkers() {
    final nearbyShops = _nearbyBaitShops();

    return nearbyShops.map((shop) {
      return Marker(
        point: LatLng(shop.lat, shop.lon),
        width: 40,
        height: 47,
        child: GestureDetector(
          onTap: () => _showBaitShopPinDetail(shop),
          child: const CustomPaint(
            size: Size(40, 47),
            painter: AqxPinBait(),
          ),
        ),
      );
    }).toList();
  }

  // ── Fotos geolocalizadas de capturas (repo + perfis) ─────
  List<Marker> _buildCatchPhotoMarkers() {
    final uid = supabaseClientOrNull?.auth.currentUser?.id;
    return _catchPhotos.map((photo) {
      return Marker(
        point: photo.location,
        width: 56,
        height: 68,
        alignment: Alignment.bottomCenter,
        child: CatchPhotoPin(
          photoUrl: photo.photoUrl,
          avatarUrl: photo.avatarUrl,
          isOwn: photo.userId == uid,
          onTap: () => _showCatchPhotoDetail(photo),
        ),
      );
    }).toList();
  }

  void _showCatchPhotoDetail(CatchPhoto photo) {
    final t = aqxL10nOf(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (_, sc) => Container(
          decoration: const BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: sc,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: kHint.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: kBg,
                    backgroundImage: (photo.avatarUrl != null && photo.avatarUrl!.isNotEmpty)
                        ? NetworkImage(photo.avatarUrl!)
                        : null,
                    child: (photo.avatarUrl == null || photo.avatarUrl!.isEmpty)
                        ? const Icon(Icons.person_rounded, color: kCyan, size: 22)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          photo.username ?? 'Pescador',
                          style: ibm(15, fw: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _formatCatchRelative(photo.createdAt),
                          style: ibm(12, c: kHint),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Foto full-width
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  photo.photoUrl,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 220,
                    color: const Color(0xFF071428),
                    child: const Center(child: Icon(Icons.broken_image_rounded, color: kHint, size: 48)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (photo.species != null) ...[
                Text(photo.species!, style: orb(18, fw: FontWeight.w800)),
                const SizedBox(height: 6),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (photo.weightKg != null)
                    _catchChip('⚖️  ${photo.weightKg!.toStringAsFixed(2)} kg'),
                  if (photo.lureType != null)
                    _catchChip('🪝  ${photo.lureType!}'),
                  if (photo.technique != null)
                    _catchChip('🎣  ${photo.technique!}'),
                  _catchChip(
                    '${photo.privacy == CatchPrivacy.public ? "🌐" : photo.privacy == CatchPrivacy.friends ? "👥" : "🔒"}  '
                    '${photo.privacy == CatchPrivacy.public ? (t.es ? "Público" : "Público") : photo.privacy == CatchPrivacy.friends ? (t.es ? "Amigos" : "Amigos") : (t.es ? "Privado" : "Privado")}',
                  ),
                ],
              ),
              if (photo.notes != null && photo.notes!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(photo.notes!, style: ibm(13, c: kHint)),
              ],
              const SizedBox(height: 10),
              Text(
                '${_formatDate(photo.createdAt)}  ·  ${photo.location.latitude.toStringAsFixed(4)}, ${photo.location.longitude.toStringAsFixed(4)}',
                style: mono(10, c: kHint),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _catchChip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFF071428),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: kCyan.withValues(alpha: 0.3)),
    ),
    child: Text(label, style: ibm(12, c: Colors.white)),
  );

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Hoje';
    if (diff.inDays == 1) return 'Ontem';
    if (diff.inDays < 7) return 'há ${diff.inDays} dias';
    return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
  }

  String _formatCatchRelative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Future<void> _openUploadForm() async {
    final t = aqxL10nOf(context);
    final cam = _mapController.camera;
    final center = cam.center;

    // Mostrar formulário de upload
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _CatchUploadSheet(
        defaultLocation: center,
        store: _catchStore,
        t: t,
      ),
    );
    if (mounted) unawaited(_loadCatchPhotos());
  }

  // ── Marcadores de teste — um por tipo de pin ────────────
  // Removível em produção; serve para validar cada painter no mapa.
  List<Marker> _buildTestPins() {
    const pins = [
      (lat: 38.80, lon: -9.50, label: 'FREE TEST',       kind: 0),
      (lat: 38.75, lon: -9.40, label: 'PRO TEST',        kind: 1),
      (lat: 38.70, lon: -9.30, label: 'ELITE TEST',      kind: 2),
      (lat: 38.65, lon: -9.20, label: 'MEUS SPOTS TEST', kind: 3),
      (lat: 38.60, lon: -9.45, label: 'LOJA ISCO TEST',  kind: 4),
      (lat: 38.55, lon: -9.35, label: 'COMUNIDADE TEST', kind: 5),
    ];

    CustomPainter painterFor(int kind) => switch (kind) {
      1 => const AqxPinPro(),
      2 => const AqxPinElite(),
      3 => const AqxPinSaved(),
      4 => const AqxPinBait(),
      5 => const AqxPinCommunity(),
      _ => const AqxPinFree(),
    };

    return pins.map((p) => Marker(
      point: LatLng(p.lat, p.lon),
      width: 40,
      height: 47,
      child: Tooltip(
        message: p.label,
        child: CustomPaint(size: const Size(40, 47), painter: painterFor(p.kind)),
      ),
    )).toList();
  }

  void _showBaitShopPinDetail(({String name, double lat, double lon, String mapsQuery, String photoUrl, bool isOpen}) shop) {
    final t = aqxL10nOf(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(shop.name, style: orb(16, fw: FontWeight.w800)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: netImg(shop.photoUrl, width: double.infinity, height: 180),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: kCyan, foregroundColor: Colors.black),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${shop.mapsQuery}');
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: Text(t.es ? 'Abrir en mapas' : 'Abrir em mapas', style: ibm(13, fw: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetTab(String label, bool sel, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Text(
          label,
          style: sel
              ? orb(11, c: kCyan, ls: 1.2)
              : mono(10, c: kHint),
        ),
      );

  Widget _mapBtn(IconData icon, {Color color = kHint, VoidCallback? onTap}) {
    final child = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: kCard.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kCyan.withValues(alpha: 0.2)),
      ),
      child: Icon(icon, size: 18, color: color),
    );
    if (onTap == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: child,
      ),
    );
  }

  // P4 — spot detail sheet premium
  void _showSpotDetail({
    required BuildContext ctx,
    required String name,
    required String local,
    required String score,
    required String tier,
    required bool bloqueado,
    required bool elite,
    required String photoUrl,
    String species = 'ROBALO',
    VoidCallback? onTap,
  }) {
    final t = aqxL10nOf(ctx);
    final scoreInt = int.tryParse(score) ?? 0;
    final accentColor = elite ? kAmber : kCyan;
    final bundle = OracleDataService.instance.lastBundle;

    // Condições — usar cache do Oráculo quando disponível
    final condOndas  = bundle?.tideHeightM != null
        ? '${bundle!.tideHeightM!.toStringAsFixed(1)}m'
        : '0.8m';
    final condTemp   = bundle?.tempC != null
        ? '${bundle!.tempC!.round()}°C'
        : '16°C';
    final condMare   = bundle?.tideTrendPt.isNotEmpty == true
        ? bundle!.tideTrendPt
        : (t.es ? 'A subir ↑' : 'A subir ↑');

    // Isco + técnica por espécie
    final iscoMap = <String, (String, String)>{
      'ROBALO':   ('Borracha shad 12cm', 'Spinning 9–12ft'),
      'DOURADA':  ('Minhoca / amêijoa',  'Surf 3.9–4.2m'),
      'CORVINA':  ('Calamar / rapete',   'Bottom 4m'),
      'SARGO':    ('Caranguejo / mexilhão', 'Rock 3–4m'),
      'LINGUADO': ('Minhoca / amêijoa',  'Surf 3.6–4.2m'),
      'POLVO':    ('Jig octopus',        'Spinning 2–3m'),
      'BARBO':    ('Milho / minhoca',    'Fundo rio'),
      'ACHIGÃ':   ('Shad / popper',      'Bait 6–8ft'),
    };
    final isco = iscoMap[species] ?? ('Isco natural', 'Adaptado ao local');

    // Capturas recentes placeholder (Ghost Mode)
    const ghostCaptures = [
      (icon: '🎣', texto: 'Robalo · 1.8 kg · há 3h', zona: 'zona Sesimbra'),
      (icon: 'ðŸŸ', texto: 'Dourada · 2.1 kg · ontem', zona: 'zona Setúbal'),
      (icon: '🦈', texto: 'Sargo · 0.9 kg · há 2 dias', zona: 'zona Ericeira'),
    ];

    const fishActivity = [
      _SpotFish('Robalo', 87, [3,5,7,9,8,7,6,4], kCyan),
      _SpotFish('Dourada', 72, [2,4,6,7,6,5,4,3], kAmber),
      _SpotFish('Sargo', 55, [1,2,3,4,4,3,3,2], kHint),
      _SpotFish('Corvina', 40, [1,1,2,3,3,2,2,1], kGreen),
    ];

    showModalBottomSheet<void>(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(ctx).size.height * 0.82,
        decoration: const BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          // Handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: kHint.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(children: [

                // ── Hero image 220px ──────────────────────────
                Stack(children: [
                  Image.network(
                    photoUrl.replaceAll('w=80', 'w=800').replaceAll('w=160', 'w=800'),
                    width: MediaQuery.of(ctx).size.width,
                    height: 220,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : Container(
                            width: MediaQuery.of(ctx).size.width,
                            height: 220,
                            color: const Color(0xFF0A1F3A),
                          ),
                    errorBuilder: (_, __, ___) => Container(
                      width: MediaQuery.of(ctx).size.width,
                      height: 220,
                      color: const Color(0xFF0A1F3A),
                    ),
                  ),
                  // Overlay escuro para spots bloqueados
                  if (bloqueado)
                    Container(
                      width: MediaQuery.of(ctx).size.width,
                      height: 220,
                      color: Colors.black.withValues(alpha: 0.55),
                    ),
                  // Gradient bottom
                  Container(
                    height: 220,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xF2000814), Color(0x44000814), Colors.transparent],
                        stops: [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                  // Gradient lateral
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [const Color(0x66000814), Colors.transparent],
                      ),
                    ),
                  ),
                  // Badge tier — canto superior direito
                  Positioned(
                    top: 14, right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: accentColor.withValues(alpha: 0.7)),
                      ),
                      child: Text(tier, style: ibm(9, c: accentColor, fw: FontWeight.w700)),
                    ),
                  ),
                  // Lock overlay
                  if (bloqueado)
                    Positioned.fill(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_rounded, color: accentColor, size: 36),
                        const SizedBox(height: 8),
                        Text('Spot ${elite ? "ELITE" : "PRO"}',
                            style: orb(12, c: accentColor, ls: 1, fw: FontWeight.w700)),
                      ],
                    )),
                  // Nome + local + score com anel
                  Positioned(bottom: 12, left: 16, right: 16,
                    child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(name, style: orb(20, fw: FontWeight.w900, ls: 0)),
                        const SizedBox(height: 2),
                        Text('ðŸ“ $local', style: mono(10, c: kHint)),
                      ])),
                      // Score com anel circular
                      SizedBox(
                        width: 64, height: 64,
                        child: CustomPaint(
                          painter: _ScoreRingPainter(scoreInt),
                          child: Center(
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              Text(score,
                                style: orb(20,
                                  c: scoreInt >= 75 ? kGreen : (scoreInt >= 50 ? kAmber : const Color(0xFFFF4444)),
                                  fw: FontWeight.w900, ls: 0)),
                            ]),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ]),

                // ── Condições ─────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Row(children: [
                    _condCard('🌊', condOndas, t.es ? 'MARÉ' : 'MARÉ'),
                    const SizedBox(width: 8),
                    _condCard('💨', '12 km/h', t.es ? 'VIENTO' : 'VENTO'),
                    const SizedBox(width: 8),
                    _condCard('ðŸŒ¡ï¸', condTemp, t.es ? 'AGUA' : 'ÁGUA'),
                    const SizedBox(width: 8),
                    _condCard('🔄', condMare, t.es ? 'CORRIENTE' : 'CORRENTE'),
                  ]),
                ),

                // ── Isco + técnica ────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Stack(children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: kBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: accentColor.withValues(alpha: 0.18)),
                      ),
                      child: bloqueado
                          ? ImageFiltered(
                              imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                              child: _iscoContent(isco, t, accentColor),
                            )
                          : _iscoContent(isco, t, accentColor),
                    ),
                    if (bloqueado)
                      Positioned.fill(child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: accentColor.withValues(alpha: 0.5)),
                          ),
                          child: Text(tier, style: ibm(9, c: accentColor, fw: FontWeight.w700)),
                        ),
                      )),
                  ]),
                ),

                // ── Actividade do peixe ───────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(children: [
                    Expanded(child: Text(t.es ? 'ACTIVIDAD DEL PEZ' : 'ACTIVIDADE DO PEIXE',
                        style: mono(10, ls: 1.2))),
                    Text(t.es ? 'hoy' : 'hoje', style: mono(9, c: kHint)),
                  ]),
                ),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  childAspectRatio: 1.7,
                  children: fishActivity.map((f) => _fishActivityCard(f, bloqueado)).toList(),
                ),

                // ── Capturas da comunidade (Ghost Mode) ───────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text('👻 ${t.es ? "CAPTURAS RECIENTES · ZONA" : "CAPTURAS RECENTES · ZONA"}',
                          style: mono(10, ls: 1.1)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: kAmber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: kAmber.withValues(alpha: 0.3)),
                        ),
                        child: Text('GHOST', style: mono(7, c: kAmber)),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    ...ghostCaptures.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Text(c.icon, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(c.texto, style: ibm(12, fw: FontWeight.w500)),
                          Text(c.zona, style: ibm(10, c: kHint)),
                        ])),
                      ]),
                    )),
                    const SizedBox(height: 4),
                    Text('ðŸ“ ${t.es ? "coordenadas exactas protegidas" : "coordenadas exactas protegidas"}',
                        style: mono(8, c: kHint)),
                  ]),
                ),

                // ── CTA desbloquear ───────────────────────────
                if (bloqueado)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                    child: Column(children: [
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            PaywallScreen.open(ctx,
                                source: 'spot_detail_${elite ? "elite" : "pro"}');
                          },
                          child: Text(
                            '${t.es ? "DESBLOQUEAR CON" : "DESBLOQUEAR COM"} ${elite ? "ELITE" : "PRO"} →',
                            style: orb(10, c: Colors.black, fw: FontWeight.w700, ls: 1)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '✓ ${t.es ? "Acceso a todos los spots" : "Acesso a todos os spots"}  ·  ✓ ${t.es ? "Score en tiempo real" : "Score em tempo real"}  ·  ✓ Isco + técnica',
                        style: mono(8, c: kHint),
                        textAlign: TextAlign.center,
                      ),
                    ]),
                  ),

                // ── Botão Oráculo ─────────────────────────────
                if (!bloqueado)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                    child: Column(children: [
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: kCyan.withValues(alpha: 0.15),
                            foregroundColor: kCyan,
                            side: BorderSide(color: kCyan.withValues(alpha: 0.4)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.radar_rounded, size: 18),
                          label: Text(
                            t.es ? 'VER ORÁCULO DE ESTE SPOT' : 'VER ORÁCULO DESTE SPOT',
                            style: orb(10, c: kCyan, ls: 1)),
                          onPressed: () {
                            Navigator.pop(ctx);
                            onTap?.call();
                          },
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t.es ? 'Score actualizado ahora' : 'Score actualizado agora',
                        style: mono(8, c: kHint),
                      ),
                    ]),
                  ),
                if (!bloqueado)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: _spotReferenceCard(name),
                  ),
                const SizedBox(height: 28),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _iscoContent(
      (String, String) isco, AqxL10n t, Color accentColor) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('🎣 ${t.es ? "ISCO + TÉCNICA" : "ISCO + TÉCNICA"}',
          style: mono(10, ls: 1.2, c: accentColor)),
      const SizedBox(height: 8),
      Row(children: [
        const Icon(Icons.anchor_rounded, size: 14, color: kHint),
        const SizedBox(width: 6),
        Text(isco.$1, style: ibm(13, fw: FontWeight.w600)),
      ]),
      const SizedBox(height: 4),
      Row(children: [
        const Icon(Icons.sports_outlined, size: 14, color: kHint),
        const SizedBox(width: 6),
        Text(isco.$2, style: ibm(12, c: kHint)),
      ]),
    ]);
  }

  Widget _condCard(String icon, String val, String lbl) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kCyan.withValues(alpha: 0.1)),
      ),
      child: Column(children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 2),
        Text(val, style: mono(10, c: Colors.white)),
        Text(lbl, style: mono(7)),
      ]),
    ),
  );

  Widget _fishActivityCard(_SpotFish f, bool locked) {
    final maxV = f.bars.reduce((a, b) => a > b ? a : b).toDouble();
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: f.color.withValues(alpha: 0.15)),
      ),
      child: locked
          ? const Center(child: Icon(Icons.lock_rounded, color: kHint, size: 18))
          : Column(children: [
              Row(children: [
                Expanded(child: Text(f.species, style: ibm(11, fw: FontWeight.w600))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: f.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('${f.actScore}%', style: mono(8, c: f.color)),
                ),
              ]),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: f.bars.map((v) {
                  final h = ((v / maxV) * 22).clamp(2.0, 22.0);
                  final active = v >= maxV * 0.65;
                  return Expanded(child: Container(
                    height: h,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: active ? f.color.withValues(alpha: 0.7) : f.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ));
                }).toList(),
              ),
              const SizedBox(height: 2),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('6h', style: mono(7)),
                Text('12h', style: mono(7)),
                Text('18h', style: mono(7)),
              ]),
            ]),
    );
  }

  Widget _spotRow(
    String name, String local, String tier, String? ghost, String score, {
    required bool bloqueado,
    bool elite = false,
    String species = 'ROBALO',
    String photoUrl = 'https://images.unsplash.com/photo-1505118380757-91f5f5632de0?w=80&q=70&auto=format',
    VoidCallback? onTap,
  }) {
    final t = aqxL10nOf(context);
    final accentColor = elite ? kAmber : kCyan;
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(Icons.location_on, size: 14, color: elite ? kAmber : (tier == 'PRO' ? kGreen : kCyan)),
        const SizedBox(width: 6),
        // Foto do spot
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: bloqueado
              ? ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: netImg(photoUrl, width: 52, height: 52),
                )
              : netImg(photoUrl, width: 52, height: 52),
        ),
        const SizedBox(width: 10),
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: elite ? kAmber : kCyan,
            boxShadow: elite
                ? [BoxShadow(color: kAmber.withValues(alpha: 0.5), blurRadius: 6)]
                : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: bloqueado
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(
                    children: [
                      // Conteúdo desfocado
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(name, style: ibm(13, fw: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Row(children: [
                            Text('$local · ', style: ibm(11, c: kHint)),
                            _tierBadge(tier, accentColor),
                            if (ghost != null) ...[const SizedBox(width: 4), _ghostBadge()],
                          ]),
                        ]),
                      ),
                      // Overlay cadeado
                      Positioned.fill(
                        child: Row(children: [
                          Icon(Icons.lock_rounded, size: 14, color: accentColor),
                          const SizedBox(width: 4),
                          Text('${t.es ? "Desbloquear con" : "Desbloquear com"} ${elite ? "ELITE" : "PRO"}',
                              style: ibm(11, c: accentColor, fw: FontWeight.w600)),
                        ]),
                      ),
                    ],
                  ),
                )
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: ibm(13, fw: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Row(children: [
                    Text('$local · ', style: ibm(11, c: kHint)),
                    _tierBadge(tier, accentColor),
                    if (ghost != null) ...[const SizedBox(width: 4), _ghostBadge()],
                  ]),
                ]),
        ),
        const SizedBox(width: 8),
        bloqueado
            ? Icon(Icons.lock_rounded, size: 18, color: accentColor.withValues(alpha: 0.5))
            : Text(score, style: orb(16, c: elite ? kAmber : kCyan, fw: FontWeight.w900, ls: 0)),
      ]),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showSpotDetail(
        ctx: context,
        name: name,
        local: local,
        score: score,
        tier: tier,
        bloqueado: bloqueado,
        elite: elite,
        species: species,
        photoUrl: photoUrl,
        onTap: onTap,
      ),
      child: row,
    );
  }

  void _setContext(String region, String species, {String? spotName}) {
    FishingContextStore.instance.update(region: region, species: species);
    unawaited(
      AnalyticsService.instance.track(
        AnalyticsEvents.mapToOracle,
        params: {
          'region': region,
          'species': species,
          if (spotName != null) 'spot': spotName,
        },
      ),
    );
    widget.onSpotOpensOracle?.call();
  }

  // P10 — loja de isco
  Widget _lojaRow(
    String nome,
    String local,
    String dist,
    String rating,
    String estado,
    {
    required String photoUrl,
    required String mapsQuery,
  }) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final t = aqxL10nOf(context);
            HapticFeedback.selectionClick();
            final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$mapsQuery');
            final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
            if (opened) return;
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  t.es ? '$nome · $local — detalle en breve' : '$nome · $local — detalhe em breve',
                  style: ibm(13),
                ),
                backgroundColor: kCard,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: netImg(photoUrl, width: 44, height: 44),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: kAmber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kAmber.withValues(alpha: 0.3)),
                  ),
                  child: const Center(child: Text('ðŸª', style: TextStyle(fontSize: 18))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nome, style: ibm(13, fw: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Row(children: [
                        Text('$local · $dist · ⭐$rating', style: ibm(11, c: kHint)),
                      ]),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: kGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: kGreen.withValues(alpha: 0.3)),
                      ),
                      child: Text(estado, style: mono(8, c: kGreen)),
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map_outlined, size: 13, color: kCyan),
                        SizedBox(width: 3),
                        Icon(Icons.call_outlined, size: 13, color: kCyan),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  Widget _tierBadge(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(t, style: mono(9, c: c)),
      );

  Widget _ghostBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: kAmber.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: kAmber.withValues(alpha: 0.4)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.lock_outline, size: 9, color: kAmber),
          const SizedBox(width: 2),
          Text('GHOST', style: mono(8, c: kAmber)),
        ]),
      );

  Future<void> _pickSpotReferencePhoto(String spotName) async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1600);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _spotReferencePhotos[spotName] = bytes);
    await _saveSpotPhotosToPrefs();
  }

  Widget _spotReferenceCard(String spotName) {
    final bytes = _spotReferencePhotos[spotName];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kCyan.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Foto de referência pessoal', style: mono(9, c: kCyan)),
          const SizedBox(height: 8),
          if (bytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(bytes, width: double.infinity, height: 120, fit: BoxFit.cover),
            )
          else
            Container(
              height: 88,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kHint.withValues(alpha: 0.3)),
              ),
              child: Text('Sem foto anexada', style: ibm(11, c: kHint)),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _pickSpotReferencePhoto(spotName),
              icon: const Icon(Icons.add_a_photo_outlined, size: 16),
              label: Text(bytes == null ? 'Anexar foto de referência' : 'Trocar foto de referência', style: ibm(11)),
              style: OutlinedButton.styleFrom(
                foregroundColor: kCyan,
                side: BorderSide(color: kCyan.withValues(alpha: 0.35)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Score ring painter ────────────────────────────────────
class _ScoreRingPainter extends CustomPainter {
  const _ScoreRingPainter(this.score);
  final int score;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = (size.width / 2) - 4;
    final trackPaint = Paint()
      ..color = const Color(0xFF1A2E44)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(Offset(cx, cy), r, trackPaint);
    final color = score >= 75
        ? kGreen
        : (score >= 50 ? kAmber : const Color(0xFFFF4444));
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -math.pi / 2,
      2 * math.pi * (score / 100),
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_ScoreRingPainter old) => old.score != score;
}

// ── Painter batimétrico ──────────────────────────────────
class BatimetriaPainter extends CustomPainter {
  const BatimetriaPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Mar "real" visível em todo o fundo.
    final sea = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF123B68), Color(0xFF0A2240), Color(0xFF051528)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sea);

    // Península Ibérica simplificada (Portugal + Espanha).
    final iberia = Path()
      ..moveTo(size.width * 0.36, size.height * 0.16)
      ..lineTo(size.width * 0.66, size.height * 0.14)
      ..lineTo(size.width * 0.80, size.height * 0.24)
      ..lineTo(size.width * 0.83, size.height * 0.40)
      ..lineTo(size.width * 0.76, size.height * 0.58)
      ..lineTo(size.width * 0.65, size.height * 0.72)
      ..lineTo(size.width * 0.53, size.height * 0.79)
      ..lineTo(size.width * 0.44, size.height * 0.77)
      ..lineTo(size.width * 0.36, size.height * 0.66)
      ..lineTo(size.width * 0.30, size.height * 0.50)
      ..lineTo(size.width * 0.29, size.height * 0.33)
      ..close();

    final landFill = Paint()..color = const Color(0xFF24384D).withValues(alpha: 0.93);
    final landStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF8AADBE).withValues(alpha: 0.45);
    canvas.drawPath(iberia, landFill);
    canvas.drawPath(iberia, landStroke);

    // Portugal destacado.
    final portugal = Path()
      ..moveTo(size.width * 0.35, size.height * 0.20)
      ..lineTo(size.width * 0.41, size.height * 0.21)
      ..lineTo(size.width * 0.42, size.height * 0.72)
      ..lineTo(size.width * 0.36, size.height * 0.67)
      ..lineTo(size.width * 0.33, size.height * 0.52)
      ..lineTo(size.width * 0.33, size.height * 0.34)
      ..close();
    canvas.drawPath(
      portugal,
      Paint()..color = const Color(0xFF00F5FF).withValues(alpha: 0.12),
    );
    canvas.drawPath(
      portugal,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFF00F5FF).withValues(alpha: 0.4),
    );

    // Labels geográficos.
    _label(canvas, size, 0.36, 0.74, 'PORTUGAL', const Color(0xFF00F5FF));
    _label(canvas, size, 0.60, 0.56, 'ESPANHA', const Color(0xFF8AADBE));
    _label(canvas, size, 0.16, 0.62, 'ATLÂNTICO', const Color(0xFF8AADBE));
    _label(canvas, size, 0.86, 0.63, 'MEDITERRÂNEO', const Color(0xFF8AADBE));

    // Spots principais.
    _dot(canvas, size, 0.38, 0.31, const Color(0xFF00F5FF), 'Ericeira');
    _dot(canvas, size, 0.38, 0.47, const Color(0xFF00F5FF), 'Espichel');
    _dot(canvas, size, 0.40, 0.59, const Color(0xFF00F5FF), 'Comporta');
    _dotGold(canvas, size, 0.36, 0.70, 'Elite #7');
  }

  void _dot(Canvas c, Size s, double rx, double ry, Color col, String label) {
    final x = s.width * rx; final y = s.height * ry;
    c.drawCircle(Offset(x, y), 9, Paint()..color = col.withValues(alpha: 0.25));
    c.drawCircle(Offset(x, y), 5, Paint()..color = col);
    final tp = TextPainter(
      text: TextSpan(text: label, style: GoogleFonts.shareTechMono(fontSize: 9, color: col, letterSpacing: 0.4)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(x - tp.width / 2, y + 8));
  }

  void _dotGold(Canvas c, Size s, double rx, double ry, String label) {
    const col = Color(0xFFF3C64D);
    final x = s.width * rx; final y = s.height * ry;
    c.drawCircle(Offset(x, y), 10, Paint()..color = col.withValues(alpha: 0.25));
    c.drawCircle(Offset(x, y), 6, Paint()..color = col);
    final tp = TextPainter(
      text: TextSpan(text: label, style: GoogleFonts.shareTechMono(fontSize: 9, color: col, letterSpacing: 0.4)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(x - tp.width / 2, y + 9));
  }

  void _label(Canvas c, Size s, double rx, double ry, String text, Color col) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.shareTechMono(
          fontSize: 8,
          color: col.withValues(alpha: 0.72),
          letterSpacing: 0.6,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(s.width * rx - tp.width / 2, s.height * ry));
  }

  @override
  bool shouldRepaint(_) => false;
}

class _SpotFish {
  final String species;
  final int actScore;
  final List<int> bars;
  final Color color;
  const _SpotFish(this.species, this.actScore, this.bars, this.color);
}

// ── Formulário de upload de captura geolocada ─────────────
class _CatchUploadSheet extends StatefulWidget {
  final LatLng defaultLocation;
  final CatchPhotosStore store;
  final AqxL10n t;

  const _CatchUploadSheet({
    required this.defaultLocation,
    required this.store,
    required this.t,
  });

  @override
  State<_CatchUploadSheet> createState() => _CatchUploadSheetState();
}

class _CatchUploadSheetState extends State<_CatchUploadSheet> {
  final _picker = ImagePicker();
  XFile? _photo;
  /// GPS actual se disponível; senão usa [defaultLocation] do mapa.
  LatLng? _uploadLocation;
  final _speciesCtrl  = TextEditingController();
  final _weightCtrl   = TextEditingController();
  final _lureCtrl     = TextEditingController();
  final _techniqueCtrl = TextEditingController();
  final _notesCtrl    = TextEditingController();
  CatchPrivacy _privacy = CatchPrivacy.public;

  static const _techniques = [
    'Surfcasting', 'Spinning', 'Jigging', 'Fundo', 'Float', 'Topwater', 'Fly', 'Rocha',
  ];

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStoreChanged);
    unawaited(_resolveUploadLocation());
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _resolveUploadLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (mounted) setState(() => _uploadLocation = widget.defaultLocation);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      if (mounted) {
        setState(() => _uploadLocation = LatLng(pos.latitude, pos.longitude));
      }
    } catch (_) {
      if (mounted) setState(() => _uploadLocation = widget.defaultLocation);
    }
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStoreChanged);
    _speciesCtrl.dispose();
    _weightCtrl.dispose();
    _lureCtrl.dispose();
    _techniqueCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final f = await _picker.pickImage(source: ImageSource.camera, imageQuality: 72);
    if (f != null) setState(() => _photo = f);
  }

  Future<void> _pickFromGallery() async {
    final f = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 72);
    if (f != null) setState(() => _photo = f);
  }

  Future<void> _submit() async {
    if (_photo == null) return;
    final loc = _uploadLocation ?? widget.defaultLocation;
    debugPrint('[CatchUpload] submit photo=${_photo!.path} loc=${loc.latitude},${loc.longitude}');
    var ok = false;
    try {
      ok = await widget.store.upload(
        location: loc,
        photoFile: _photo!,
        species: _speciesCtrl.text.trim().isNotEmpty ? _speciesCtrl.text.trim() : null,
        weightKg: double.tryParse(_weightCtrl.text.replaceAll(',', '.')),
        lureType: _lureCtrl.text.trim().isNotEmpty ? _lureCtrl.text.trim() : null,
        technique: _techniqueCtrl.text.trim().isNotEmpty ? _techniqueCtrl.text.trim() : null,
        notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
        privacy: _privacy,
      );
    } catch (e, st) {
      debugPrint('[CatchUpload] ERRO: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao publicar: $e'),
            backgroundColor: const Color(0xFFD50000),
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    if (ok) {
      debugPrint('[CatchUpload] sucesso');
      Navigator.pop(context);
    } else {
      debugPrint('[CatchUpload] falhou: ${widget.store.error}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.store.error ?? 'Erro ao publicar captura'),
          backgroundColor: const Color(0xFFD50000),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uploading = widget.store.uploading;
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: sc,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                children: [
                  Center(
                    child: Container(
                      width: 36, height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(color: kHint.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  Text(
                    widget.t.es ? 'NUEVA CAPTURA' : 'NOVA CAPTURA',
                    style: orb(16, fw: FontWeight.w800, c: kCyan),
                  ),
                  const SizedBox(height: 14),

                  // Foto
                  GestureDetector(
                    onTap: _pickPhoto,
                    child: Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: const Color(0xFF071428),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kCyan.withValues(alpha: 0.35), width: 1.5),
                      ),
                      child: _photo == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.camera_alt_rounded, color: kCyan, size: 36),
                                const SizedBox(height: 8),
                                Text(widget.t.es ? 'Tirar foto' : 'Tirar foto', style: ibm(13, c: kHint)),
                                const SizedBox(height: 4),
                                TextButton(
                                  onPressed: _pickFromGallery,
                                  child: Text(widget.t.es ? 'ou galeria' : 'ou galeria', style: ibm(12, c: kCyan)),
                                ),
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Image.file(File(_photo!.path), fit: BoxFit.cover, width: double.infinity),
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Espécie
                  _field(_speciesCtrl, widget.t.es ? 'Especie' : 'Espécie', Icons.set_meal_rounded),
                  const SizedBox(height: 10),

                  // Peso
                  _field(_weightCtrl, widget.t.es ? 'Peso (kg)' : 'Peso (kg)', Icons.monitor_weight_outlined, numeric: true),
                  const SizedBox(height: 10),

                  // Isco
                  _field(_lureCtrl, widget.t.es ? 'Cebo / Isco' : 'Isco / Cebo', Icons.pest_control_rounded),
                  const SizedBox(height: 10),

                  // Técnica — dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF071428),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kCyan.withValues(alpha: 0.25)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _techniqueCtrl.text.isNotEmpty ? _techniqueCtrl.text : null,
                        dropdownColor: const Color(0xFF071428),
                        style: ibm(13, c: Colors.white),
                        hint: Text(widget.t.es ? 'Técnica' : 'Técnica', style: ibm(13, c: kHint)),
                        items: _techniques.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (v) { if (v != null) setState(() => _techniqueCtrl.text = v); },
                        icon: const Icon(Icons.expand_more, color: kHint),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Notas
                  _field(_notesCtrl, widget.t.es ? 'Notas' : 'Notas', Icons.notes_rounded, maxLines: 2),
                  const SizedBox(height: 14),

                  // Privacidade
                  Text(widget.t.es ? 'Privacidad' : 'Privacidade', style: ibm(12, c: kHint)),
                  const SizedBox(height: 6),
                  Row(children: [
                    _privacyBtn(CatchPrivacy.public, '🌐', widget.t.es ? 'Público' : 'Público'),
                    const SizedBox(width: 8),
                    _privacyBtn(CatchPrivacy.friends, '👥', widget.t.es ? 'Amigos' : 'Amigos'),
                    const SizedBox(width: 8),
                    _privacyBtn(CatchPrivacy.private, '🔒', widget.t.es ? 'Privado' : 'Privado'),
                  ]),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, MediaQuery.paddingOf(context).bottom + 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _photo != null ? kCyan : kHint.withValues(alpha: 0.3),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: uploading || _photo == null ? null : () => unawaited(_submit()),
                  child: uploading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : Text(widget.t.es ? 'PUBLICAR CAPTURA' : 'PUBLICAR CAPTURA', style: orb(13, fw: FontWeight.w800)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {bool numeric = false, int maxLines = 1}) =>
      TextFormField(
        controller: ctrl,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        style: ibm(13, c: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: ibm(12, c: kHint),
          prefixIcon: Icon(icon, color: kCyan, size: 18),
          filled: true,
          fillColor: const Color(0xFF071428),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: kCyan.withValues(alpha: 0.25)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: kCyan.withValues(alpha: 0.25)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kCyan, width: 1.5),
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        ),
      );

  Widget _privacyBtn(CatchPrivacy p, String emoji, String label) {
    final sel = _privacy == p;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _privacy = p),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: sel ? kCyan.withValues(alpha: 0.15) : const Color(0xFF071428),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: sel ? kCyan : kHint.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 2),
              Text(label, style: ibm(10, c: sel ? kCyan : kHint)),
            ],
          ),
        ),
      ),
    );
  }
}



