import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '_shared.dart';
import 'oracle_live_widgets.dart';
import '../core/l10n/aqx_l10n.dart';
import '../core/services/analytics_service.dart';
import '../core/state/app_locale_store.dart';
import '../core/state/fishing_context_store.dart';
import '../core/state/fishing_mode_store.dart';
import '../core/state/home_tab_index.dart';
import '../core/tides/moon_phase.dart';
import '../core/tides/open_meteo_tides_repository.dart';
import '../core/tides/oracle_data_service.dart';
import '../core/tides/osm_place_search.dart';
import '../core/tides/region_presets.dart';
import '../core/tides/weather_details_snapshot.dart';
import '../core/community/community_demo_posts.dart';
import '../core/community/community_store.dart';
import '../core/location/gps_access.dart';
import '../core/state/logbook_tab_index.dart';
import '../core/supabase_bootstrap.dart';
import '../core/tides/oracle_hourly_score.dart';
import '../features/home/domain/entities/hourly_condition.dart';
import 'widgets/aqx_pressable.dart';
import 'widgets/oracle_community_strip.dart';
import 'widgets/oracle_mini_map.dart';
import 'widgets/oracle_conditions_fold.dart';
import 'widgets/oracle_decision_card.dart';
import 'widgets/oracle_fishing_metrics_grid.dart';
import 'widgets/oracle_weather_details_grid.dart';
import 'widgets/location_access_sheet.dart';

// ── Dados por modo ─────────────────────────────────────────
class _ModoData {
  final String local;
  final String localSubtitle;
  final bool locationFromGps;
  final String iconeLocal;
  final String statusLabel;
  final String statusDesc;
  final String horario;
  final String fonte;           // '' ou 'SNIRH'
  final int score;
  final List<_MetricTile> cards;
  final List<_Dia> dias;
  final String janelaTexto;

  const _ModoData({
    required this.local,
    this.localSubtitle = '',
    this.locationFromGps = false,
    required this.iconeLocal,
    required this.statusLabel,
    required this.statusDesc,
    required this.horario,
    this.fonte = '',
    required this.score,
    required this.cards,
    required this.dias,
    required this.janelaTexto,
  });
}

/// Mini-card métrica — ícone Material + rótulos alinhados ao mockup Oráculo.
class _MetricTile {
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    this.sub = '',
  });
}
class _Dia { final String d, s, i; const _Dia(this.d, this.s, this.i); }

enum _LoadState { loading, ok, error }

class _RigPlan {
  final String bait;
  final String rod;
  final String technique;
  final String distance;
  const _RigPlan({
    required this.bait,
    required this.rod,
    required this.technique,
    required this.distance,
  });
}

// ══════════════════════════════════════════════════════════
// ECRÃ 01 — ORÁCULO
// ══════════════════════════════════════════════════════════
class OraculoScreen extends StatefulWidget {
  const OraculoScreen({super.key});
  @override
  State<OraculoScreen> createState() => _OraculoScreenState();
}

class _OraculoScreenState extends State<OraculoScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  bool _rioMode = false;
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final AnimationController _fishPulse;
  late final VoidCallback _ctxListener;
  late final VoidCallback _homeTabListener;
  late final VoidCallback _placeSearchListener;
  _LoadState _costaLoad = _LoadState.loading;
  OracleBundle? _costaBundle;
  String? _costaError;
  _LoadState _rioLoad = _LoadState.loading;
  RiverOracleBundle? _rioBundle;
  String? _rioError;
  bool _costaGpsError = false;
  bool _rioGpsError = false;
  OsmPlace? _planningPlace;
  WeatherDetailsSnapshot? _weatherDetails;
  bool _weatherDetailsLoading = false;
  bool _weatherDetailsFailed = false;
  List<HourlyCondition> _hourlyTimeline = const [];
  final _meteoRepo = OpenMeteoTidesRepository();
  final _scrollCtrl = ScrollController();
  final _weatherSectionKey = GlobalKey();
  final _weatherGridKey = GlobalKey<OracleWeatherDetailsGridState>();
  bool _gpsRecheckInFlight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final ctx = FishingContextStore.instance.value.value;
    _rioMode = ctx.region == 'ABRANTES' || ctx.species == 'BARBO';
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _ctrl.value = 1.0;
    _fishPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _ctxListener = () {
      if (!mounted) return;
      final c = FishingContextStore.instance.value.value;
      final wantRio = c.region == 'ABRANTES' || c.species == 'BARBO';
      if (wantRio != _rioMode) setState(() => _rioMode = wantRio);
    };
    FishingContextStore.instance.value.addListener(_ctxListener);
    _homeTabListener = () {
      if (!mounted) return;
      if (HomeTabIndex.notifier.value == HomeTabIndex.oracleTabIndex) {
        _trackNorthStar();
        unawaited(_recheckGpsIfNeeded());
      }
    };
    HomeTabIndex.notifier.addListener(_homeTabListener);
    _placeSearchListener = () {
      if (!mounted || !HomeTabIndex.pendingOraclePlaceSearch.value) return;
      HomeTabIndex.pendingOraclePlaceSearch.value = false;
      _openPlaceSearch(
        AqxL10n(AppLocaleStore.instance.locale.languageCode),
      );
    };
    HomeTabIndex.pendingOraclePlaceSearch.addListener(_placeSearchListener);
    if (HomeTabIndex.pendingOraclePlaceSearch.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _placeSearchListener();
      });
    }
    if (HomeTabIndex.notifier.value == HomeTabIndex.oracleTabIndex) {
      _trackNorthStar();
    }
    unawaited(
      AnalyticsService.instance.track(
        AnalyticsEvents.missionStarted,
        params: {
          'screen': 'oraculo',
          'mode': _rioMode ? 'rio' : 'costa',
          'country': ctx.country,
          'region': ctx.region,
          'species': ctx.species,
        },
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_initLocationAndLoad());
      if (isSupabaseConfigured) {
        unawaited(CommunityStore.instance.loadFeed(country: ctx.country));
      }
    });
  }

  /// Planeamento regional quando não há GPS — evita fetch bloqueado.
  OsmPlace? _effectivePlanningPlace(FishingContext ctx) {
    if (_planningPlace != null) return _planningPlace;
    if (GpsAccess.cachedFix != null || GpsAccess.cachedFixStale != null) {
      return null;
    }
    return _regionalPlace(ctx);
  }

  Future<void> _initLocationAndLoad() async {
    if (!mounted) return;
    if (GpsAccess.cachedFix == null &&
        GpsAccess.cachedFixStale == null &&
        _planningPlace == null) {
      unawaited(_warmStartRegional());
    }
    unawaited(_loadCosta());
    unawaited(_loadRio());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_loadWeatherDetails(costaBundle: _costaBundle));
      unawaited(_loadHourlyTimeline());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_recheckGpsIfNeeded());
    }
  }

  /// Re-tenta GPS ao voltar das definições — só se havia erro GPS.
  Future<void> _recheckGpsIfNeeded({bool force = false}) async {
    if (!mounted || _planningPlace != null || _gpsRecheckInFlight) return;
    if (!force && !_costaGpsError && !_rioGpsError) return;

    _gpsRecheckInFlight = true;
    try {
      final status = await GpsAccess.check();
      if (status != GpsAccessStatus.granted || !mounted) return;

      final fix = await GpsAccess.tryGetFixQuick();
      if (fix == null || !mounted) return;

      OracleDataService.instance.invalidateCache();
      if (!mounted) return;
      setState(() {
        _planningPlace = null;
        _costaGpsError = false;
        _rioGpsError = false;
        _costaError = null;
        _rioError = null;
      });
      unawaited(_loadCosta());
      unawaited(_loadRio());
    } finally {
      _gpsRecheckInFlight = false;
    }
  }

  void _trackNorthStar() {
    unawaited(
      AnalyticsService.instance.track(
        AnalyticsEvents.northStarOracleView,
        params: {
          'score': _rioMode
              ? (_rioBundle?.score ?? 0)
              : (_costaBundle?.score ?? 0),
          'mode': _rioMode ? 'rio' : 'costa',
        },
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    HomeTabIndex.notifier.removeListener(_homeTabListener);
    HomeTabIndex.pendingOraclePlaceSearch.removeListener(_placeSearchListener);
    FishingContextStore.instance.value.removeListener(_ctxListener);
    _fishPulse.dispose();
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _toggle(bool rio) {
    if (rio == _rioMode) return;
    HapticFeedback.selectionClick();
    _ctrl.reverse().then((_) {
      setState(() => _rioMode = rio);
      _syncContext();
      _ctrl.forward();
    });
  }

  void _syncContext() {
    FishingModeStore.instance.isRio.value = _rioMode;
    FishingContextStore.instance.update(
      region: _rioMode ? 'ABRANTES' : 'SETUBAL',
      species: _rioMode ? 'BARBO' : 'ROBALO',
    );
  }

  String _speciesUiLabel(String code) {
    switch (code.toUpperCase()) {
      case 'BARBO':
        return 'Barbo';
      case 'ROBALO':
        return 'Robalo';
      case 'SARGO':
        return 'Sargo';
      case 'DOURADA':
        return 'Dourada';
      case 'ACHIGA':
        return 'Achigã';
      default:
        if (code.isEmpty) return code;
        return '${code[0]}${code.substring(1).toLowerCase()}';
    }
  }

  bool get _hasCostaData => _costaBundle != null;

  bool get _hasRioData => _rioBundle != null;

  OsmPlace _regionalPlace(FishingContext ctx) {
    final p = TideMapPreset.forRegion(ctx.region);
    return OsmPlace(
      lat: p.latitude,
      lon: p.longitude,
      label: p.label,
      displayName: p.label,
    );
  }

  List<_MetricTile> _placeholderCostaCards(AqxL10n t) => [
        _MetricTile(icon: Icons.waves_rounded, label: t.metricTide, value: '—'),
        _MetricTile(icon: Icons.thermostat_rounded, label: t.metricWaterTemp, value: '—'),
        _MetricTile(icon: Icons.air_rounded, label: 'VENTO', value: '—'),
        _MetricTile(icon: Icons.speed_rounded, label: t.metricPressure, value: '—'),
        _MetricTile(icon: Icons.nightlight_round, label: t.metricMoon, value: '—'),
      ];

  List<_MetricTile> _placeholderRioCards(AqxL10n t) => [
        _MetricTile(icon: Icons.water_rounded, label: t.metricFlow, value: '—'),
        _MetricTile(icon: Icons.show_chart_rounded, label: t.metricLevel, value: '—'),
        _MetricTile(icon: Icons.thermostat_rounded, label: t.metricWaterTemp, value: '—'),
        _MetricTile(icon: Icons.speed_rounded, label: t.metricPressure, value: '—'),
        _MetricTile(icon: Icons.visibility_rounded, label: t.metricVis, value: '—'),
      ];

  _ModoData _loadingModoData(AqxL10n t, {required bool isRio}) => _ModoData(
        local: t.positionGpsLive,
        localSubtitle: t.locatingSubtitle,
        iconeLocal: isRio ? 'rio' : 'location',
        statusLabel: '…',
        statusDesc: '',
        horario: '—',
        fonte: isRio ? 'Open‑Meteo' : '',
        score: 0,
        cards: isRio ? _placeholderRioCards(t) : _placeholderCostaCards(t),
        dias: const [],
        janelaTexto: '',
      );

  Future<void> _warmStartRegional() async {
    if (!mounted || _planningPlace != null) return;
    await Future.wait([
      if (_costaBundle == null) _loadRegionalFallback(isRio: false),
      if (_rioBundle == null) _loadRegionalFallback(isRio: true),
    ]);
  }

  Future<void> _loadRegionalFallback({required bool isRio}) async {
    if (_planningPlace != null || !mounted) return;
    final ctx = FishingContextStore.instance.value.value;
    final place = _regionalPlace(ctx);
    try {
      if (isRio) {
        final bundle = await OracleDataService.instance.fetchRiver(
          ctx: ctx,
          planningPlace: place,
        );
        if (!mounted) return;
        setState(() {
          _rioBundle = bundle;
          _rioLoad = _LoadState.ok;
        });
      } else {
        final bundle = await OracleDataService.instance.fetch(
          ctx: ctx,
          planningPlace: place,
        );
        if (!mounted) return;
        setState(() {
          _costaBundle = bundle;
          _costaLoad = _LoadState.ok;
        });
        unawaited(_loadWeatherDetails(costaBundle: bundle));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (isRio) {
          _rioLoad = _LoadState.error;
        } else {
          _costaLoad = _LoadState.error;
        }
      });
    }
  }

  List<String> _decisionReasons(_ModoData d, WeatherDetailsSnapshot? w) {
    final reasons = <String>[];
    for (final line in d.statusDesc.split('\n')) {
      for (final chunk in line.split('+')) {
        final s = chunk.trim();
        if (s.isNotEmpty) {
          reasons.add(s[0].toUpperCase() + s.substring(1));
        }
      }
    }
    if (w != null && w.moonPct > 0) {
      final moonLbl = w.moonPhaseLabel.isNotEmpty
          ? w.moonPhaseLabel
          : 'fase ${w.moonPct}%';
      reasons.add('Solunar · $moonLbl');
    }
    if (w?.windSpeedKmh != null &&
        !reasons.any((r) => r.toLowerCase().contains('vento'))) {
      reasons.add(
        'Vento ${w!.windSpeedKmh!.round()} km/h '
        '${WeatherDetailsSnapshot.windCardinalPt(w.windDirDeg)}',
      );
    }
    if (w?.waveHeightM != null && w!.waveHeightM! > 0 && !_rioMode) {
      reasons.add('Ondas ~${w.waveHeightM!.toStringAsFixed(1)} m');
    }
    return reasons.take(3).toList();
  }

  void _openLogNovaCaptura() {
    LogbookTabIndex.pendingTab.value = LogbookTabIndex.minhasTab;
    LogbookTabIndex.pendingAction.value = 'nova_captura';
    HomeTabIndex.notifier.value = HomeTabIndex.logTabIndex;
    unawaited(
      AnalyticsService.instance.track(
        AnalyticsEvents.tabChange,
        params: {'tab': 'LOG', 'source': 'oraculo_registar_captura'},
      ),
    );
  }

  void _openMapTab() {
    final coords = OracleDataService.instance.lastCoords;
    if (coords != null) {
      HomeTabIndex.pendingMapFocus.value = (lat: coords.lat, lon: coords.lon);
    }
    HomeTabIndex.notifier.value = HomeTabIndex.mapTabIndex;
    unawaited(
      AnalyticsService.instance.track(
        AnalyticsEvents.tabChange,
        params: {'tab': 'MAPA', 'source': 'oraculo_ver_mapa'},
      ),
    );
  }

  void _openCommunityTab() {
    LogbookTabIndex.pendingTab.value = LogbookTabIndex.comunidadeTab;
    HomeTabIndex.notifier.value = HomeTabIndex.logTabIndex;
  }

  void _openCommunityShare() {
    LogbookTabIndex.pendingTab.value = LogbookTabIndex.comunidadeTab;
    LogbookTabIndex.pendingAction.value = 'novo_post';
    HomeTabIndex.notifier.value = HomeTabIndex.logTabIndex;
  }

  void _onFishingMetricTap(OracleFishingMetricKind kind) {
    _weatherGridKey.currentState?.expandAccordion();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _weatherSectionKey.currentContext;
      if (ctx != null && mounted) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
          alignment: 0.05,
        );
      }
    });
  }

  List<OracleFishingMetric> _buildFishingMetrics(_ModoData d) {
    final w = _weatherDetails;
    if (_rioMode) {
      final b = _rioBundle;
      return buildRioFishingMetrics(
        caudalValue: b?.caudalValue ??
            (d.cards.isNotEmpty ? d.cards.first.value : '—'),
        caudalSub: b?.caudalSub ?? '',
        nivelValue: b?.nivelValue ?? '—',
        nivelSub: b?.nivelSub ?? '',
        tempValue: b?.tempC != null
            ? '${b!.tempC!.toStringAsFixed(1)} °C'
            : '—',
        tempSub: b?.tempTrendPt ?? '',
        visibValue: b?.visibValue ?? '—',
        weather: w,
      );
    }
    final b = _costaBundle;
    return buildCostaFishingMetrics(
      tideValue: b?.tideHeightM != null
          ? '${b!.tideHeightM!.toStringAsFixed(2)} m'
          : (d.cards.isNotEmpty ? d.cards[0].value : '—'),
      tideSub: b?.tideTrendPt ?? '',
      weather: w,
      tempWaterValue: b?.tempC != null
          ? '${b!.tempC!.toStringAsFixed(1)} °C'
          : '—',
      tempWaterSub: b?.tempTrendPt ?? '',
    );
  }

  Widget _rigSpeciesChipRow() {
    return ValueListenableBuilder<FishingContext>(
      valueListenable: FishingContextStore.instance.value,
      builder: (context, ctx, _) {
        final codes = _rioMode
            ? const ['BARBO', 'ACHIGA']
            : const ['ROBALO', 'SARGO', 'DOURADA'];
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final code in codes)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AqxGlassChip(
                    label: _speciesUiLabel(code),
                    selected: ctx.species == code,
                    compact: true,
                    onTap: () {
                      FishingContextStore.instance.update(species: code);
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  _RigPlan _planForSpecies(
    String code, {
    required bool isRio,
    required AqxL10n t,
  }) {
    switch (code.toUpperCase()) {
      case 'SARGO':
        return const _RigPlan(
          bait: 'Minhoca + Mexilhão',
          rod: 'Rock 3.3m · 0.20mm',
          technique: 'Rocha / Float',
          distance: '20–35m junto à pedra',
        );
      case 'DOURADA':
        return const _RigPlan(
          bait: 'Minhoca + Amêijoa',
          rod: 'Surf 4.2m · 0.28mm',
          technique: 'Surfcasting',
          distance: '60–90m fundo limpo',
        );
      case 'CORVINA':
        return const _RigPlan(
          bait: 'Rapala + Isco natural',
          rod: 'Fundo 4m · 0.35mm',
          technique: 'Fundo / Espera',
          distance: 'Canal / rebentação',
        );
      case 'LINGUADO':
        return const _RigPlan(
          bait: 'Minhoca + Amêijoa',
          rod: 'Surf 4m · 0.25mm',
          technique: 'Fundo praia',
          distance: '50–80m em areão',
        );
      case 'RAIA':
        return const _RigPlan(
          bait: 'Sardinha + Arenque',
          rod: 'Surf pesado 4.2m',
          technique: 'Fundo arenoso',
          distance: '80m+',
        );
      case 'ACHIGA':
        return const _RigPlan(
          bait: 'Shad + Jig',
          rod: 'Bait 7ft · 0.20mm',
          technique: 'Spinning / Topwater',
          distance: 'Margem estruturada',
        );
      case 'BARBO':
        return const _RigPlan(
          bait: 'Milho + Minhoca',
          rod: 'Rio 3.6m · 0.22mm',
          technique: 'Fundo rio / Float',
          distance: 'Corrente lenta',
        );
      case 'ROBALO':
      default:
        if (isRio) {
          return const _RigPlan(
            bait: 'Milho + Minhoca',
            rod: 'Rio 3.6m · 0.22mm',
            technique: 'Fundo rio / Float',
            distance: 'Corrente lenta',
          );
        }
        return const _RigPlan(
          bait: 'Shad 10–14cm',
          rod: 'Spinning 9ft · PE 0.8',
          technique: 'Spinning / Jigging',
          distance: '40–60m do rochedo',
        );
    }
  }

  List<String> _activeSpeciesCodes({
    required bool isRio,
    required String place,
    required int score,
    required String selectedSpecies,
  }) {
    final sel = selectedSpecies.toUpperCase();
    List<String> defaults;
    if (isRio) {
      defaults = const ['BARBO', 'ACHIGA'];
    } else {
      final p = place.toLowerCase();
      if (p.contains('sesimbra') || p.contains('setúbal') || p.contains('setubal')) {
        defaults = const ['ROBALO', 'SARGO'];
      } else if (p.contains('peniche') || p.contains('nazaré') || p.contains('nazare')) {
        defaults = const ['ROBALO', 'CORVINA'];
      } else if (p.contains('sagres') || p.contains('lagos') || p.contains('faro')) {
        defaults = const ['DOURADA', 'SARGO'];
      } else if (p.contains('cascais') || p.contains('sintra') || p.contains('ericeira')) {
        defaults = const ['ROBALO', 'SARGO'];
      } else if (p.contains('vigo') || p.contains('pontevedra')) {
        defaults = const ['ROBALO', 'DOURADA'];
      } else if (p.contains('huelva') || p.contains('cádiz') || p.contains('cadiz')) {
        defaults = const ['DOURADA', 'CORVINA'];
      } else if (p.contains('coruña') || p.contains('coruna') || p.contains('galicia')) {
        defaults = const ['ROBALO', 'SARGO'];
      } else if (p.contains('barcelona') || p.contains('tarragona') || p.contains('girona')) {
        defaults = const ['DOURADA', 'SARGO'];
      } else if (p.contains('alicante') || p.contains('valencia') || p.contains('murcia')) {
        defaults = const ['DOURADA', 'SARGO'];
      } else if (score >= 75) {
        defaults = const ['ROBALO', 'SARGO'];
      } else if (score >= 55) {
        defaults = const ['DOURADA', 'ROBALO'];
      } else {
        defaults = [sel, sel == 'SARGO' ? 'ROBALO' : 'SARGO'];
      }
    }
    if (defaults.contains(sel)) {
      return [sel, ...defaults.where((c) => c != sel).take(1)];
    }
    return [sel, defaults.first];
  }

  /// Mesmos limiares que o índice no backend (80 / 65 / 45) — evita «MODERADA» vs «BOM».
  (String, Color) _fishActivityMeta(int score, AqxL10n t) {
    if (score >= 80) return (t.activityVeryHigh, kGreen);
    if (score >= 65) return (t.activityGood, kCyan);
    if (score >= 45) return (t.activityModerate, const Color(0xFF5CADBE));
    return (t.activityLow, kHint);
  }

  /// Cor por peixe: pouca actividade → tons uniformes fortes (sem degradê esq→dir).
  /// Índice alto → sequência «acesa» peixe a peixe, cores bem saturadas.
  Color _fishGlyphColor(int score, int stepIndex, Color accent) {
    final s = score.clamp(0, 100);
    if (s < 45) {
      final pulse = 0.58 + 0.42 * ((s / 44).clamp(0.0, 1.0));
      return Color.alphaBlend(
        accent.withValues(alpha: (0.72 * pulse).clamp(0.5, 0.95)),
        const Color(0xFF0D1820),
      );
    }
    final span = (s / 100.0) * 5.0;
    final raw = (span - stepIndex).clamp(0.0, 1.0);
    final on = Curves.easeOut.transform(raw);
    final boosted = (0.42 + 0.58 * on).clamp(0.42, 1.0);
    return Color.alphaBlend(
      accent.withValues(alpha: boosted),
      const Color(0xFF152B38),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AqxL10n(Localizations.localeOf(context).languageCode);
    final d = _rioMode ? _buildRioData(t) : _buildCostaData(t);
    return Scaffold(
      backgroundColor: kBg,
      body: RefreshIndicator(
      color: kCyan,
      backgroundColor: kCard,
      onRefresh: _refreshPage,
      child: SingleChildScrollView(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header: localização ────────────────────────
          Row(children: [
            Expanded(
              child: FadeTransition(
                opacity: _fade,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: kCyan.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: kCyan.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Icon(
                        d.iconeLocal == 'rio'
                            ? Icons.waves
                            : (d.locationFromGps
                                ? Icons.my_location_rounded
                                : Icons.place_outlined),
                        size: 24,
                        color: kCyan,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.local,
                            style: orb(
                              18,
                              c: kCyan,
                              fw: FontWeight.w800,
                              ls: 0.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (d.localSubtitle.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(
                              d.localSubtitle,
                              style: mono(
                                11.5,
                                c: kHint.withValues(alpha: 0.92),
                                ls: 0.35,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      t.alertsProConfigSoon,
                      style: ibm(14),
                    ),
                    backgroundColor: kCard,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kAmber.withValues(alpha: 0.4)),
                ),
                child: const Icon(Icons.notifications_outlined,
                    size: 21, color: kAmber),
              ),
            ),
          ]),
          const SizedBox(height: 10),

          // ── Toggle COSTA / RIO ─────────────────────────
          AqxGlassSegmentToggle(
            leftIcon: Icons.waves_rounded,
            leftLabel: t.costa,
            rightIcon: Icons.landscape_rounded,
            rightLabel: t.rio,
            rightSelected: _rioMode,
            onLeft: () => _toggle(false),
            onRight: () => _toggle(true),
          ),

          const SizedBox(height: 8),

          // ── Fonte de dados (GPS / planeamento) ─────────
          if (_isGpsBlocked()) ...[
            _locationAccessBanner(t),
            const SizedBox(height: 8),
          ],
          _planningSourceRow(t),
          const SizedBox(height: 8),

          if (_oracleMiniMapCoords() case final coords?) ...[
            OracleMiniMap(
              lat: coords.lat,
              lon: coords.lon,
              isPlanning: _planningPlace != null,
              isRio: _rioMode,
              onViewMap: _openMapTab,
              viewMapLabel: t.es ? 'VER MAPA' : 'VER MAPA',
            ),
            const SizedBox(height: 8),
          ],

          // ── Decisão do Oráculo ─────────────────────────
          FadeTransition(
            opacity: _fade,
            child: (_rioMode ? !_hasRioData : !_hasCostaData)
                ? _scoreStatePlaceholder(isRio: _rioMode, t: t)
                : OracleDecisionCard(
                        score: d.score,
                        statusLabel: d.statusLabel,
                        windowHours: d.horario,
                        reasons: _decisionReasons(d, _weatherDetails),
                        registerLabel:
                            t.es ? 'REGISTRAR CAPTURA' : 'REGISTAR CAPTURA',
                        mapLabel: t.es ? 'VER EN MAPA' : 'VER NO MAPA',
                        title: t.es
                            ? 'DECISIÓN DEL ORÁCULO'
                            : 'DECISÃO DO ORÁCULO',
                        windowPrefix:
                            t.es ? 'Mejor ventana:' : 'Melhor janela:',
                        onRegisterCatch: _openLogNovaCaptura,
                        onViewMap: _openMapTab,
                      ),
          ),

          const SizedBox(height: 8),

          // ── Condições agora + 12h (fold unificado) ─────
          FadeTransition(
            opacity: _fade,
            child: OracleConditionsFold(
              metrics: _buildFishingMetrics(d),
              hours: applyTimelineHighlights(
                _hourlyTimeline,
                now: DateTime.now(),
                goldenWindowHours: d.horario,
              ),
              tideSparkline: _weatherDetails?.tideSparkline ?? const [],
              timelineTitle: t.es
                  ? 'PRÓXIMAS 12H · SCORE + MAREA'
                  : 'PRÓXIMAS 12H · SCORE + MARÉ',
              nowLabel: t.es ? 'ahora' : 'agora',
              onMetricTap: _onFishingMetricTap,
            ),
          ),

          const SizedBox(height: 8),

          // ── Meteorologia completa (accordion) ────────
          FadeTransition(
            opacity: _fade,
            child: KeyedSubtree(
              key: _weatherSectionKey,
              child: OracleWeatherDetailsGrid(
                key: _weatherGridKey,
                data: _weatherDetails,
                loading: _weatherDetailsLoading,
                loadFailed: _weatherDetailsFailed,
                collapsible: true,
                initiallyExpanded: false,
                onRetry: () => unawaited(_loadWeatherDetails(
                  costaBundle: _costaBundle,
                  force: true,
                )),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Previsão 5 dias ────────────────────────────
          if (d.dias.isNotEmpty) ...[
            Text(t.forecastHeader, style: mono(12, ls: 1.2)),
            const SizedBox(height: 5),
            FadeTransition(
              opacity: _fade,
              child: Row(
                children: [
                  for (var i = 0; i < d.dias.length; i++) ...[
                    if (i > 0) const SizedBox(width: 5),
                    _diaCard(d.dias[i], i == 0),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // ── Janela de Ouro — fiel à referência ────────
          if (d.janelaTexto.isNotEmpty) ...[
            FadeTransition(
              opacity: _fade,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1A0A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kAmber.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 4,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: kAmber,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('👑', style: TextStyle(fontSize: 17)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: TextSpan(children: [
                                  TextSpan(
                                    text: t.goldenWindowTitle,
                                    style: ibm(14, c: kAmber, fw: FontWeight.w700),
                                  ),
                                  TextSpan(
                                    text: d.janelaTexto,
                                    style: ibm(14, c: Colors.white70),
                                  ),
                                ]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // ── P5 — Push Janela de Ouro (EM BREVE) ────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kHint.withValues(alpha: 0.25)),
            ),
            child: Row(children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: kHint.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.notifications_active_outlined,
                    color: kHint.withValues(alpha: 0.7), size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.pushGoldenPro,
                        style: mono(11, c: kHint, ls: 0.8)),
                    Text(
                      t.pushDemoBody(
                        _rioMode ? t.riverTagusDemo : _alertPlaceHint(t),
                      ),
                      style: ibm(13, c: Colors.white54),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kHint.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: kHint.withValues(alpha: 0.35)),
                ),
                child: Text(
                  t.es ? 'EM BREVE' : 'EM BREVE',
                  style: mono(10, c: kHint, ls: 0.5),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 8),

          // ── Comunidade Ghost (zona) ────────────────────
          ValueListenableBuilder<CommunityState>(
            valueListenable: CommunityStore.instance.value,
            builder: (context, comm, _) {
              final posts = comm.posts.isNotEmpty
                  ? comm.posts
                  : CommunityDemoPosts.posts();
              return OracleCommunityStrip(
                posts: posts,
                loading: comm.loading && comm.posts.isEmpty,
                es: t.es,
                title: t.es ? 'ACTIVIDAD EN LA ZONA' : 'ACTIVIDADE NA ZONA',
                subtitle: t.es
                    ? 'Descubre lo que captura la comunidad'
                    : 'Descobre o que a comunidade está a capturar',
                viewLabel: t.es ? 'VER COMUNIDAD' : 'VER COMUNIDADE',
                shareLabel: t.es ? 'COMPARTIR' : 'PARTILHAR',
                onViewCommunity: _openCommunityTab,
                onShare: _openCommunityShare,
              );
            },
          ),

          const SizedBox(height: 8),

          // ── P3 — Isco + Cana + Técnica ─────────────────
          FadeTransition(
            opacity: _fade,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kCyan.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('🎣', style: TextStyle(fontSize: 17)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t.rigCardTitle,
                          style: mono(12, ls: 1.2),
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 10, color: kCyan.withValues(alpha: 0.08)),
                  ValueListenableBuilder<FishingContext>(
                    valueListenable: FishingContextStore.instance.value,
                    builder: (context, fishingCtx, _) {
                      final zoneCodes = _activeSpeciesCodes(
                        isRio: _rioMode,
                        place: d.local,
                        score: d.score,
                        selectedSpecies: _rioMode ? 'BARBO' : 'ROBALO',
                      );
                      final zoneFishLabel = zoneCodes
                          .take(2)
                          .map(_speciesUiLabel)
                          .join(' + ');
                      final primaryPlan = _planForSpecies(
                        fishingCtx.species,
                        isRio: _rioMode,
                        t: t,
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            t.rigTargetLabel,
                            style: ibm(12, c: kHint),
                          ),
                          const SizedBox(height: 6),
                          _rigSpeciesChipRow(),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  t.rigActivityNeon,
                                  style: orb(
                                    14,
                                    c: kCyan,
                                    fw: FontWeight.w800,
                                    ls: 1.2,
                                  ).copyWith(
                                    shadows: [
                                      Shadow(
                                        color: kCyan.withValues(alpha: 0.95),
                                        blurRadius: 10,
                                      ),
                                      Shadow(
                                        color: kCyan.withValues(alpha: 0.55),
                                        blurRadius: 22,
                                      ),
                                      Shadow(
                                        color: kCyan.withValues(alpha: 0.35),
                                        blurRadius: 34,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 88,
                                  child: Text(
                                    t.rigMoreActive,
                                    style: ibm(13, c: kHint),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    zoneFishLabel,
                                    style:
                                        ibm(14, c: kCyan, fw: FontWeight.w700),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _iscoRow(t.rigBait, primaryPlan.bait),
                          _iscoRow(t.rigRod, primaryPlan.rod),
                          _iscoRow(t.rigTechnique, primaryPlan.technique),
                          _iscoRow(t.rigDistance, primaryPlan.distance),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
      ),
      ),
    );
  }

  // ── Oracle data ──────────────────────────────────────────

  String _alertPlaceHint(AqxL10n t) {
    final b = _costaBundle;
    if (b == null) return t.alertZone;
    return b.usedGps ? t.alertYou : b.locationHeadline.split('·').first.trim();
  }

  bool _isGpsBlocked() {
    if (_planningPlace != null) return false;
    return _rioMode ? _rioGpsError : _costaGpsError;
  }

  Future<void> _enableLocation(AqxL10n t) async {
    HapticFeedback.selectionClick();
    var status = await GpsAccess.request();
    if (status != GpsAccessStatus.granted) {
      await GpsAccess.openSystemSettings(status);
      return;
    }
    final fix = await GpsAccess.tryGetFix(timeout: const Duration(seconds: 15));
    if (fix == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.gpsFixFailed, style: ibm(14)),
          backgroundColor: kCard,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    OracleDataService.instance.invalidateCache();
    setState(() {
      _planningPlace = null;
      _costaGpsError = false;
      _rioGpsError = false;
      _costaError = null;
      _rioError = null;
      _costaBundle = null;
      _rioBundle = null;
    });
    unawaited(_loadCosta());
    unawaited(_loadRio());
  }

  void _showLocationSheet(AqxL10n t) {
    HapticFeedback.selectionClick();
    unawaited(
      GpsAccess.check().then((status) {
        if (!mounted) return;
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => LocationAccessSheet(
            status: status,
            onEnableGps: () async {
              Navigator.pop(ctx);
              await _enableLocation(t);
            },
            onSearchPlace: () {
              Navigator.pop(ctx);
              _openPlaceSearch(t);
            },
          ),
        );
      }),
    );
  }

  Widget _locationAccessBanner(AqxL10n t) {
    final err = _rioMode ? _rioError : _costaError;
    return GestureDetector(
      onTap: () => _showLocationSheet(t),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1408),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kAmber.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_off_rounded, color: kAmber, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    err ?? t.gpsBlocked,
                    style: ibm(13, c: Colors.white70),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: AqxNeonCompactButton(
                    label: t.enableLocation,
                    onTap: () => unawaited(_enableLocation(t)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AqxGlassButton(
                    label: t.searchPlace,
                    onTap: () => _openPlaceSearch(t),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  ({double lat, double lon})? _oracleMiniMapCoords() {
    final last = OracleDataService.instance.lastCoords;
    if (last != null) return last;
    final place = _planningPlace;
    if (place != null) return (lat: place.lat, lon: place.lon);
    return null;
  }

  Widget _planningSourceRow(AqxL10n t) {
    final isP = _planningPlace != null;
    final gpsBlocked = _isGpsBlocked();
    return GestureDetector(
      onTap: () => _openPlaceSearch(t),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isP
                ? kAmber.withValues(alpha: 0.45)
                : gpsBlocked
                    ? kAmber.withValues(alpha: 0.35)
                    : kCyan.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isP
                  ? Icons.map_outlined
                  : gpsBlocked
                      ? Icons.location_off_rounded
                      : Icons.my_location_rounded,
              size: 15,
              color: isP ? kAmber : (gpsBlocked ? kAmber : kCyan),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isP
                    ? _planningPlace!.label
                    : gpsBlocked
                        ? t.locationNeededTitle
                        : t.positionGpsLive,
                style: ibm(
                  13,
                  c: isP ? kAmber : (gpsBlocked ? kAmber : kCyan),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isP)
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _planningPlace = null);
                  unawaited(_loadCosta());
                  unawaited(_loadRio());
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(Icons.close_rounded, size: 15, color: kHint),
                ),
              )
            else if (gpsBlocked)
              GestureDetector(
                onTap: () => unawaited(_enableLocation(t)),
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    t.locationBannerAction,
                    style: ibm(12, c: kAmber, fw: FontWeight.w600),
                  ),
                ),
              )
            else
              Icon(
                Icons.search_rounded,
                size: 22,
                color: kHint.withValues(alpha: 0.6),
              ),
          ],
        ),
      ),
    );
  }

  void _openPlaceSearch(AqxL10n t) {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlaceSearchSheet(
        t: t,
        onSelectPlace: (place) {
          Navigator.pop(context);
          setState(() => _planningPlace = place);
          unawaited(_loadCosta());
          unawaited(_loadRio());
        },
        onSelectGps: () {
          Navigator.pop(context);
          setState(() => _planningPlace = null);
          unawaited(_loadCosta());
          unawaited(_loadRio());
        },
      ),
    );
  }

  void _showIndexInfo() {
    final t = AqxL10n(Localizations.localeOf(context).languageCode);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(children: [
          const Icon(Icons.auto_graph_rounded, color: kCyan, size: 22),
          const SizedBox(width: 8),
          Text(t.indexWhat, style: orb(15, c: kCyan)),
        ]),
        content: SingleChildScrollView(
          child: Text(
            t.indexHelpBody,
            style: ibm(14, c: Colors.white70),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.understood, style: ibm(15, c: kCyan, fw: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _loadCosta() async {
    if (!mounted) return;
    setState(() {
      if (_costaBundle == null) {
        _costaLoad = _LoadState.loading;
        _costaGpsError = false;
      }
    });
    try {
      final ctx = FishingContextStore.instance.value.value;
      final bundle = await OracleDataService.instance.fetch(
        ctx: ctx,
        planningPlace: _effectivePlanningPlace(ctx),
      );
      if (!mounted) return;
      setState(() {
        _costaBundle = bundle;
        _costaLoad = _LoadState.ok;
        _costaGpsError = false;
      });
      unawaited(_loadWeatherDetails(costaBundle: bundle));
    } catch (e) {
      if (!mounted) return;
      if (e is OracleGpsRequiredException) {
        setState(() {
          _costaError = e.message;
          _costaGpsError = true;
          _costaLoad = _LoadState.error;
        });
        await _loadRegionalFallback(isRio: false);
        return;
      }
      setState(() {
        _costaError = _friendlyError(
          AqxL10n(AppLocaleStore.instance.locale.languageCode),
          e.toString(),
        );
        _costaLoad = _LoadState.error;
        _costaGpsError = false;
      });
    }
  }

  Future<void> _refreshPage() async {
    HapticFeedback.lightImpact();
    OracleDataService.instance.invalidateCache();
    setState(() {
      _weatherDetails = null;
      _weatherDetailsFailed = false;
      _hourlyTimeline = const [];
    });
    if (_rioMode) {
      await _loadRio();
    } else {
      await _loadCosta();
    }
    await _loadWeatherDetails(
      costaBundle: _costaBundle,
      force: true,
    );
    await _loadHourlyTimeline();
    if (isSupabaseConfigured) {
      final ctx = FishingContextStore.instance.value.value;
      await CommunityStore.instance.loadFeed(country: ctx.country);
    }
  }

  Future<void> _loadWeatherDetails({
    OracleBundle? costaBundle,
    bool force = false,
  }) async {
    if (!mounted) return;

    var coords = OracleDataService.instance.lastCoords;
    if (coords == null && _planningPlace != null) {
      coords = (lat: _planningPlace!.lat, lon: _planningPlace!.lon);
    }
    if (coords == null) {
      final bundle = costaBundle ?? _costaBundle;
      if (bundle != null && !_rioMode) {
        // Aguarda fetch do Oráculo definir coordenadas
        await Future<void>.delayed(const Duration(milliseconds: 400));
        coords = OracleDataService.instance.lastCoords;
      }
    }
    if (coords == null) {
      if (!mounted) return;
      setState(() {
        _weatherDetailsLoading = false;
        _weatherDetailsFailed = true;
      });
      return;
    }

    if (_weatherDetailsLoading && !force) return;

    setState(() {
      _weatherDetailsLoading = true;
      _weatherDetailsFailed = false;
    });

    final ctx = FishingContextStore.instance.value.value;
    final lang = AppLocaleStore.instance.locale.languageCode;
    final t = AqxL10n(lang);
    final tz = TideMapPreset.timezoneForCountry(ctx.country);
    final now = DateTime.now();
    final moonPhase = moonPhase01(now);
    final moonPct = costaBundle?.moonPct ??
        _costaBundle?.moonPct ??
        (moonFishingFactor(now) * 100).round().clamp(0, 100);
    final moonLabel = costaBundle?.moonPhaseShortPt ??
        _costaBundle?.moonPhaseShortPt ??
        t.moonTileShort(moonPhase);
    final tide = costaBundle ?? _costaBundle;

    try {
      var snap = await _meteoRepo.fetchWeatherDetails(
        latitude: coords.lat,
        longitude: coords.lon,
        timezone: tz,
        tideHeightM: tide?.tideHeightM,
        tideTrendPt: tide?.tideTrendPt ?? '',
        tideRangeM: tide?.tideRangeM,
        moonPct: moonPct,
        moonPhaseLabel: moonLabel,
      );

      if (snap == null) {
        final cur = await _meteoRepo.fetchCurrentConditions(
          latitude: coords.lat,
          longitude: coords.lon,
        );
        snap = WeatherDetailsSnapshot.fallback(
          fetchedAt: now,
          airTempC: cur.tempC ?? tide?.tempC,
          pressureHpa: tide?.pressureHpa,
          windSpeedKmh: cur.windSpeedKmh,
          windDirDeg: cur.windDirDeg,
          waveHeightM: cur.waveHeightM,
          tideHeightM: tide?.tideHeightM,
          tideTrendPt: tide?.tideTrendPt ?? '',
          tideRangeM: tide?.tideRangeM,
          tidePhasePt: WeatherDetailsSnapshot.tidePhaseFromTrend(
            tide?.tideTrendPt ?? '',
            const [],
          ),
          moonPct: moonPct,
          moonPhaseLabel: moonLabel,
        );
      }

      if (!mounted) return;
      setState(() {
        _weatherDetails = snap;
        _weatherDetailsLoading = false;
        _weatherDetailsFailed = false;
      });
      unawaited(_loadHourlyTimeline());
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _weatherDetailsLoading = false;
        _weatherDetailsFailed = true;
      });
    }
  }

  Future<void> _loadHourlyTimeline() async {
    if (!mounted) return;

    var coords = OracleDataService.instance.lastCoords;
    if (coords == null && _planningPlace != null) {
      coords = (lat: _planningPlace!.lat, lon: _planningPlace!.lon);
    }
    if (coords == null) {
      setState(() {
        _hourlyTimeline = fallbackOracleHourlyTimeline(DateTime.now());
      });
      return;
    }

    final ctx = FishingContextStore.instance.value.value;
    final tz = TideMapPreset.timezoneForCountry(ctx.country);

    try {
      final series = await _meteoRepo.fetchForecastWeatherSeries(
        latitude: coords.lat,
        longitude: coords.lon,
        timezone: tz,
      );
      if (!mounted) return;
      setState(() {
        _hourlyTimeline = mapOracleHourlyTimeline(series, DateTime.now());
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hourlyTimeline = fallbackOracleHourlyTimeline(DateTime.now());
      });
    }
  }

  Future<void> _loadRio() async {
    if (!mounted) return;
    setState(() {
      if (_rioBundle == null) {
        _rioLoad = _LoadState.loading;
        _rioGpsError = false;
      }
    });
    try {
      final ctx = FishingContextStore.instance.value.value;
      final bundle = await OracleDataService.instance.fetchRiver(
        ctx: ctx,
        planningPlace: _effectivePlanningPlace(ctx),
      );
      if (!mounted) return;
      setState(() {
        _rioBundle = bundle;
        _rioLoad = _LoadState.ok;
        _rioGpsError = false;
      });
      unawaited(_loadWeatherDetails());
    } catch (e) {
      if (!mounted) return;
      if (e is OracleGpsRequiredException) {
        setState(() {
          _rioError = e.message;
          _rioGpsError = true;
          _rioLoad = _LoadState.error;
        });
        await _loadRegionalFallback(isRio: true);
        return;
      }
      setState(() {
        _rioError = _friendlyError(
          AqxL10n(AppLocaleStore.instance.locale.languageCode),
          e.toString(),
        );
        _rioLoad = _LoadState.error;
        _rioGpsError = false;
      });
    }
  }

  _ModoData _buildRioData(AqxL10n t) {
    final b = _rioBundle;
    if (b == null) {
      if (_rioGpsError) {
        return _ModoData(
          local: t.locationNeededTitle,
          localSubtitle: _rioLoad == _LoadState.loading
              ? t.loadingRegionalData
              : (_rioError ?? t.gpsBlocked),
          iconeLocal: 'rio',
          statusLabel: '—',
          statusDesc: '',
          horario: '—',
          fonte: '',
          score: 0,
          cards: _placeholderRioCards(t),
          dias: const [],
          janelaTexto: '',
        );
      }
      if (_rioLoad == _LoadState.loading) {
        return _loadingModoData(t, isRio: true);
      }
      return _ModoData(
        local: t.errGeneric,
        localSubtitle: _rioError ?? '',
        iconeLocal: 'rio',
        statusLabel: '—',
        statusDesc: '',
        horario: '—',
        fonte: '',
        score: 0,
        cards: _placeholderRioCards(t),
        dias: const [],
        janelaTexto: '',
      );
    }
    final tempStr =
        b.tempC != null ? '${b.tempC!.toStringAsFixed(1)} °C' : '—';
    return _ModoData(
      local: b.locationHeadline,
      localSubtitle: _rioGpsError ? t.regionalWithoutGps : b.locationSubtitle,
      locationFromGps: b.usedGps && !_rioGpsError,
      iconeLocal: 'rio',
      statusLabel: b.statusLabel,
      statusDesc: b.statusDesc,
      horario: b.windowHours,
      fonte: 'Open‑Meteo',
      score: b.score,
      cards: [
        _MetricTile(
          icon: Icons.water_rounded,
          label: t.metricFlow,
          value: b.caudalValue,
          sub: b.caudalSub,
        ),
        _MetricTile(
          icon: Icons.show_chart_rounded,
          label: t.metricLevel,
          value: b.nivelValue,
          sub: b.nivelSub,
        ),
        _MetricTile(
          icon: Icons.thermostat_rounded,
          label: t.metricWaterTemp,
          value: tempStr,
          sub: b.tempTrendPt,
        ),
        _MetricTile(
          icon: Icons.speed_rounded,
          label: t.metricPressure,
          value: '—',
          sub: '',
        ),
        _MetricTile(
          icon: Icons.visibility_rounded,
          label: t.metricVis,
          value: b.visibValue,
          sub: b.visibSub,
        ),
      ],
      dias: b.forecast.map((f) => _Dia(f.dayLabel, '${f.score}', f.icon)).toList(),
      janelaTexto: b.janelaTexto,
    );
  }

  String _friendlyError(AqxL10n t, String e) {
    if (e.contains('SocketException') || e.contains('connection')) {
      return t.errNoNetwork;
    }
    if (e.contains('timeout') || e.contains('TimeoutException')) {
      return t.errTimeout;
    }
    if (e.contains('404') || e.contains('500')) {
      return t.errService;
    }
    return t.errGeneric;
  }

  _ModoData _buildCostaData(AqxL10n t) {
    final b = _costaBundle;
    if (b == null) {
      if (_costaGpsError) {
        return _ModoData(
          local: t.locationNeededTitle,
          localSubtitle: _costaLoad == _LoadState.loading
              ? t.loadingRegionalData
              : (_costaError ?? t.gpsBlocked),
          iconeLocal: 'location',
          statusLabel: '—',
          statusDesc: '',
          horario: '—',
          score: 0,
          cards: _placeholderCostaCards(t),
          dias: const [],
          janelaTexto: '',
        );
      }
      if (_costaLoad == _LoadState.loading) {
        return _loadingModoData(t, isRio: false);
      }
      return _ModoData(
        local: t.errGeneric,
        localSubtitle: _costaError ?? '',
        iconeLocal: 'location',
        statusLabel: '—',
        statusDesc: '',
        horario: '—',
        score: 0,
        cards: _placeholderCostaCards(t),
        dias: const [],
        janelaTexto: '',
      );
    }
    final tideStr = b.tideHeightM != null
        ? '${b.tideHeightM!.toStringAsFixed(2)} m'
        : '—';
    final tempStr =
        b.tempC != null ? '${b.tempC!.toStringAsFixed(1)} °C' : '—';
    final presStr =
        b.pressureHpa != null ? '${b.pressureHpa!.round()} hPa' : '—';
    return _ModoData(
      local: b.locationHeadline,
      localSubtitle: _costaGpsError ? t.regionalWithoutGps : b.locationSubtitle,
      locationFromGps: b.usedGps && !_costaGpsError,
      iconeLocal: 'location',
      statusLabel: b.statusLabel,
      statusDesc: b.statusDesc,
      horario: b.windowHours,
      score: b.score,
      cards: [
        _MetricTile(
          icon: Icons.waves_rounded,
          label: t.metricTide,
          value: tideStr,
          sub: b.tideTrendPt,
        ),
        _MetricTile(
          icon: Icons.thermostat_rounded,
          label: t.metricWaterTemp,
          value: tempStr,
          sub: b.tempTrendPt,
        ),
        _MetricTile(
          icon: Icons.air_rounded,
          label: t.es ? 'VIENTO' : 'VENTO',
          value: '—',
          sub: '—',
        ),
        _MetricTile(
          icon: Icons.speed_rounded,
          label: t.metricPressure,
          value: presStr,
          sub: b.pressureTrendPt,
        ),
        _MetricTile(
          icon: Icons.nightlight_round,
          label: t.metricMoon,
          value: '${b.moonPct}%',
          sub: b.moonPhaseShortPt,
        ),
      ],
      dias: b.forecast.map((f) => _Dia(f.dayLabel, '${f.score}', f.icon)).toList(),
      janelaTexto: b.janelaTexto,
    );
  }

  Widget _scoreStatePlaceholder({required bool isRio, required AqxL10n t}) {
    final gpsErr = isRio ? _rioGpsError : _costaGpsError;
    final loading = (isRio ? _rioLoad : _costaLoad) == _LoadState.loading &&
        !gpsErr;
    if (loading) {
      return Container(
        height: 96,
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kCyan.withValues(alpha: 0.1)),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: kCyan, strokeWidth: 2),
        ),
      );
    }
    final err = isRio ? _rioError : _costaError;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                gpsErr ? Icons.location_off_rounded : Icons.wifi_off_rounded,
                color: gpsErr ? kAmber : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  err ?? t.errGeneric,
                  style: ibm(13, c: Colors.white70),
                ),
              ),
            ],
          ),
          if (gpsErr) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openPlaceSearch(t),
                    child: Text(
                      t.searchPlace,
                      style: ibm(13, c: kCyan, fw: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => unawaited(_enableLocation(t)),
                    child: Text(
                      t.locationBannerAction,
                      style: ibm(13, c: kAmber, fw: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => unawaited(isRio ? _loadRio() : _loadCosta()),
              child: Text(
                t.retry,
                style: ibm(13, c: kCyan, fw: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _fishActivityStrip(int score, AqxL10n t) {
    final meta = _fishActivityMeta(score, t);
    final label = meta.$1;
    final Color col = meta.$2;

    return AnimatedBuilder(
      animation: _fishPulse,
      builder: (context, _) {
        final pulse =
            0.62 + 0.38 * math.sin(_fishPulse.value * math.pi * 2);
        final glow = 0.12 + 0.14 * pulse;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: kBg.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              width: 1.2,
              color: Color.lerp(col, kCyan, 0.25)!.withValues(alpha: 0.35 + 0.12 * pulse),
            ),
            boxShadow: [
              BoxShadow(
                color: col.withValues(alpha: glow),
                blurRadius: 14 + 10 * pulse,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.fishActivityTitle,
                      style: ibm(14, fw: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        for (var i = 0; i < 5; i++) ...[
                          if (i > 0) const SizedBox(width: 4),
                          Expanded(
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: OracleAnimatedFishGlyph(
                                  animation: _fishPulse,
                                  color: _fishGlyphColor(score, i, col),
                                  size: 44,
                                  phaseOffset: i * 0.17,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: col.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: col.withValues(alpha: 0.45)),
                ),
                child: Text(
                  label.toUpperCase(),
                  style: mono(11, c: col, ls: 0.6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ignore: unused_element — legado; substituído por OracleDecisionCard (Sprint 1)
  Widget _scoreCardContent(_ModoData d, AqxL10n t) {
    final inner = Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kCyan.withValues(alpha: 0.14)),
          boxShadow: [
            BoxShadow(
              color: kCyan.withValues(alpha: 0.07),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fishActivityStrip(d.score, t),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TweenAnimationBuilder<int>(
                  key: ValueKey<int>(d.score + (_rioMode ? 10000 : 0)),
                  tween: IntTween(begin: 0, end: d.score),
                  duration: const Duration(milliseconds: 1350),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    final v = value.clamp(0, 100);
                    return SizedBox(
                      width: 88,
                      height: 88,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 88,
                            height: 88,
                            child: CircularProgressIndicator(
                              value: v / 100,
                              strokeWidth: 4,
                              backgroundColor: kCyan.withValues(alpha: 0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color.lerp(kAmber, kCyan, v / 100) ?? kCyan,
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$v',
                                style: orb(
                                  26,
                                  c: Colors.white,
                                  fw: FontWeight.w900,
                                  ls: 0,
                                ),
                              ),
                              Text(
                                'ÍNDICE',
                                style: mono(10, c: kCyan, ls: 1.4),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              t.indexCardSubtitle,
                              style: mono(11, c: kHint, ls: 0.85),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _showIndexInfo();
                            },
                            child: Icon(
                              Icons.help_outline_rounded,
                              size: 21,
                              color: kCyan.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            _rioMode ? Icons.landscape_rounded : Icons.bolt_rounded,
                            color: kCyan,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            d.statusLabel,
                            style: orb(
                              19,
                              c: !_rioMode ? kCyan : kAmber,
                              fw: FontWeight.w900,
                              ls: 1.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(d.statusDesc, style: ibm(12, c: kHint)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _melhorJanelaBar(d, t),
            if (d.fonte.isNotEmpty) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: kAmber.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: kAmber.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    d.fonte,
                    style: mono(10, c: kAmber, ls: 1.0),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    return inner;
  }

  Widget _iscoRow(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          SizedBox(width: 88, child: Text(k, style: ibm(13, c: kHint))),
          Expanded(child: Text(v, style: ibm(13, c: Colors.white, fw: FontWeight.w600))),
        ]),
      );

  Widget _melhorJanelaBar(_ModoData d, AqxL10n t) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFF003A2A).withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kGreen.withValues(alpha: 0.55)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded, color: kGreen, size: 21),
            const SizedBox(width: 10),
            Text(
              t.bestWindow,
              style: ibm(13, c: kGreen, fw: FontWeight.w700),
            ),
            const Spacer(),
            Text(
              d.horario,
              style: ibm(13, c: kGreen, fw: FontWeight.w700),
            ),
          ],
        ),
      );

  // ── Dia card ─────────────────────────────────────────────
  Widget _diaCard(_Dia d, bool active) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: active ? kCyan.withValues(alpha: 0.08) : kCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: active ? kCyan : kCyan.withValues(alpha: 0.08)),
          ),
          child: Column(children: [
            Text(d.d,
                style: mono(10, c: active ? kCyan : kHint)),
            const SizedBox(height: 4),
            Text(d.s,
                style: orb(15,
                    c: active ? kCyan : Colors.white,
                    fw: FontWeight.w900,
                    ls: 0)),
            const SizedBox(height: 2),
            Text(d.i, style: const TextStyle(fontSize: 13)),
          ]),
        ),
      );
}

// ── Bottom sheet de pesquisa de local (modo planeamento) ─────

class _PlaceSearchSheet extends StatefulWidget {
  const _PlaceSearchSheet({
    required this.t,
    required this.onSelectPlace,
    required this.onSelectGps,
  });

  final AqxL10n t;
  final ValueChanged<OsmPlace> onSelectPlace;
  final VoidCallback onSelectGps;

  @override
  State<_PlaceSearchSheet> createState() => _PlaceSearchSheetState();
}

class _PlaceSearchSheetState extends State<_PlaceSearchSheet> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  List<OsmPlace> _results = [];
  bool _searching = false;
  String? _queryError;

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    if (v.trim().length < 2) {
      if (_results.isNotEmpty || _searching) {
        setState(() {
          _results = [];
          _searching = false;
        });
      }
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => _doSearch(v.trim()),
    );
  }

  Future<void> _doSearch(String q) async {
    if (!mounted) return;
    setState(() {
      _searching = true;
      _queryError = null;
    });
    try {
      final r = await searchPlaces(
        q,
        acceptLanguage: widget.t.es ? 'es' : 'pt',
      );
      if (!mounted) return;
      setState(() {
        _results = r;
        _searching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _queryError = widget.t.searchFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + mq.viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: kHint.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(widget.t.searchPlace, style: mono(13, c: kCyan, ls: 1.0)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: widget.onSelectGps,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: kCyan.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kCyan.withValues(alpha: 0.35)),
              ),
              child: Row(children: [
                const Icon(Icons.my_location_rounded, size: 16, color: kCyan),
                const SizedBox(width: 8),
                Text(widget.t.useMyGps,
                    style: ibm(13, c: kCyan, fw: FontWeight.w600)),
              ]),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _ctrl,
            autofocus: true,
            style: ibm(14, c: Colors.white),
            onChanged: _onChanged,
            decoration: InputDecoration(
              hintText: widget.t.searchHint,
              hintStyle: ibm(13, c: kHint),
              filled: true,
              fillColor: kBg,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: kCyan.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: kCyan.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: kCyan.withValues(alpha: 0.6)),
              ),
              prefixIcon:
                  const Icon(Icons.search_rounded, size: 18, color: kCyan),
              suffixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 1.5, color: kCyan),
                      ),
                    )
                  : null,
            ),
          ),
          if (_queryError != null) ...[
            const SizedBox(height: 6),
            Text(_queryError!, style: ibm(12, c: Colors.redAccent)),
          ],
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: mq.size.height * 0.32),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _results.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: kCyan.withValues(alpha: 0.08)),
                itemBuilder: (_, i) {
                  final p = _results[i];
                  return InkWell(
                    onTap: () => widget.onSelectPlace(p),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 9),
                      child: Row(
                        children: [
                          const Icon(Icons.place_outlined,
                              size: 15, color: kHint),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(p.label,
                                    style: ibm(13,
                                        c: Colors.white,
                                        fw: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(
                                  p.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: ibm(11, c: kHint),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else if (!_searching && _ctrl.text.trim().length >= 2) ...[
            const SizedBox(height: 12),
            Text(
              widget.t.noResultsFor(_ctrl.text.trim()),
              style: ibm(13, c: kHint),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
