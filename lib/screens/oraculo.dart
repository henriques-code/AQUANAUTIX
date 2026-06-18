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
import '../core/monetization/subscription_gate.dart';
import '../core/fishing/bait_technique_service.dart';
import '../core/species/oracle_rig_recommendation.dart';
import '../core/location/gps_access.dart';
import '../core/state/logbook_tab_index.dart';
import '../core/state/subscription_store.dart';
import '../core/supabase_bootstrap.dart';
import '../core/tides/oracle_hourly_score.dart';
import '../features/home/domain/entities/hourly_condition.dart';
import 'widgets/aqx_pressable.dart';
import 'widgets/oracle_conversion_pack.dart';
import 'widgets/oracle_decisao_fold.dart';
import 'widgets/oracle_hero_decision.dart';
import 'widgets/oracle_mockup_header.dart';
import 'widgets/oracle_conditions_fold.dart';
import 'widgets/oracle_conditions_collapsible.dart';
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
      if (canUseSupabase) {
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
      HomeTabIndex.pendingMapFocus.value = (
        lat: coords.lat,
        lon: coords.lon,
        label: null,
      );
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
    HomeTabIndex.notifier.value = HomeTabIndex.communityTabIndex;
  }

  void _openProUnlockSheet(
    BuildContext context, {
    required AqxL10n t,
    required String speciesLabel,
    required int proScore,
  }) {
    unawaited(
      showOracleProUnlockSheet(
        context,
        distanceLabel: t.es ? 'Spot PRO a 1.2 km' : 'Spot PRO a 1.2 km',
        scoreLine: t.es
            ? 'Score $proScore mañana 07:15'
            : 'Score $proScore amanhã 07:15',
        speciesLabel: speciesLabel,
        source: 'oraculo_pro_drawer',
        es: t.es,
      ),
    );
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

  String _heroWindowLabel(String raw) {
    if (raw.isEmpty || raw == '—') return '—';
    return raw
        .replaceAll('->', '→')
        .replaceAll(RegExp(r'\s*→\s*'), ' → ')
        .trim();
  }

  Widget _buildDecisaoFold(BuildContext context, AqxL10n t, _ModoData d) {
    final hasData = _rioMode ? _hasRioData : _hasCostaData;
    final gpsErr = _rioMode ? _rioGpsError : _costaGpsError;
    final loading = !hasData &&
        !gpsErr &&
        (_rioMode ? _rioLoad : _costaLoad) == _LoadState.loading;
    final err = _rioMode ? _rioError : _costaError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!hasData && !loading && err != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _inlineDataBanner(
              message: err,
              t: t,
              gpsErr: gpsErr,
            ),
          ),
        ValueListenableBuilder<FishingContext>(
          valueListenable: FishingContextStore.instance.value,
          builder: (context, fishingCtx, _) {
            final species = fishingCtx.species;
            final costa = _costaBundle;
            final primaryPlan = OracleRigRecommendation.recommend(
              speciesCode: species,
              isRio: _rioMode,
              tideTrendPt: costa?.tideTrendPt,
              waterTempC: costa?.tempC,
            );
            final zoneCodes = _rioMode
                ? const ['BARBO', 'ACHIGA']
                : const ['ROBALO', 'SARGO', 'DOURADA'];
            final mapCoords = _oracleMapCoords();
            final proScore = ((hasData ? d.score : 84) + 8).clamp(0, 100);
            final windowHours = _heroWindowLabel(d.horario);
            final speciesLabel = _speciesUiLabel(species);
            final decisionText = OracleDecisionCopy.line(
              es: t.es,
              score: hasData ? d.score : 0,
              windowHours: windowHours,
              proScore: proScore,
              loading: loading,
            );
            final proSticky = t.es
                ? 'Spot PRO a 1.2 km · Score $proScore mañana 07:15'
                : 'Spot PRO a 1.2 km · Score $proScore amanhã 07:15';
            final ghostPosts = CommunityDemoPosts.oracleGhostRow();
            final communityProHint = t.es
                ? '${ghostPosts.length} capturas cerca · PRO ve zona 5 km'
                : '${ghostPosts.length} capturas perto · PRO vê zona 5 km';

            void openPro() => _openProUnlockSheet(
                  context,
                  t: t,
                  speciesLabel: speciesLabel,
                  proScore: proScore,
                );

            return OracleDecisaoFold(
              hero: OracleHeroScoreCard(
                heroImageAsset: _rioMode
                    ? oracleHeroAssetForSpecies(species, isRio: true)
                    : kOracleMockupHeroAsset,
                score: hasData ? d.score : 0,
                statusLabel:
                    hasData ? d.statusLabel : (loading ? '…' : '—'),
                windowHours: windowHours,
                windowPrefix: t.es
                    ? 'Mejor ventana hoy:'
                    : 'Melhor janela hoje:',
                mapLat: mapCoords?.lat,
                mapLon: mapCoords?.lon,
                mapIsPlanning: _planningPlace != null,
                mapIsRio: _rioMode,
                onViewMap: _openMapTab,
                pulse: _fishPulse,
                mapLabel: 'VER MAPA',
                loading: loading,
              ),
              decisionText: decisionText,
              decisionLoading: loading,
              proStickySummary: proSticky,
              onProUnlock: openPro,
              speciesCard: OracleSpeciesTargetCard(
                speciesCodes: zoneCodes,
                selectedSpecies: species,
                speciesLabelFor: _speciesUiLabel,
                onSpeciesSelected: (code) {
                  FishingContextStore.instance.update(species: code);
                },
                targetSpecies: speciesLabel,
                bait: primaryPlan.bait,
                rodTechnique:
                    '${primaryPlan.rod} · ${primaryPlan.technique}',
              ),
              ctas: OracleMockupCtas(
                onGoFish: _openMapTab,
                onRegisterCatch: _openLogNovaCaptura,
                goFishLabel: t.es ? 'IR A PESCAR ->' : 'IR PESCAR ->',
                registerLabel:
                    t.es ? 'REGISTRAR CAPTURA' : 'REGISTAR CAPTURA',
                onComparePro: () {
                  if (SubscriptionGate.canAccessProFeatures(
                    SubscriptionStore.instance.value.value,
                  )) {
                    _openPlaceSearch(t);
                  } else {
                    openPro();
                  }
                },
                compareProLabel:
                    t.es ? 'Comparar 3 sitios (PRO)' : 'Comparar 3 sítios (PRO)',
                onAlertPro: () {},
                alertProLabel: t.es
                    ? 'Alertar ventana (PRO) · PRONTO'
                    : 'Alertar janela (PRO) · EM BREVE',
              ),
              communityPosts: ghostPosts,
              es: t.es,
              communityTitle: t.es
                  ? 'GHOST ACTIVIDAD EN LA ZONA'
                  : 'GHOST ATIVIDADE NA ZONA',
              communityProHint: communityProHint,
              onProCommunityHook: openPro,
              onViewCommunity: _openCommunityTab,
              proDistanceLabel: 'Spot PRO a 1.2 km',
              proScoreLine: t.es
                  ? 'Score $proScore mañana 07:15'
                  : 'Score $proScore amanhã 07:15',
              proUnlockLabel:
                  t.es ? 'PRO 3 días gratis →' : 'PRO 3 dias grátis →',
              proSpeciesLabel: speciesLabel,
            );
          },
        ),
      ],
    );
  }

  Widget _buildBaitTechniqueCard(BaitRecommendation rec, AqxL10n t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: cardBox,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ISCO + TÉCNICA', style: mono(10, ls: 1.1)),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: ibm(13, c: Colors.white),
              children: [
                TextSpan(
                  text: t.es ? 'Cebo: ' : 'Isco: ',
                  style: ibm(13, c: kHint),
                ),
                TextSpan(
                  text: rec.bait,
                  style: ibm(13, fw: FontWeight.w700, c: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${t.es ? 'Técnica' : 'Técnica'}: ${rec.technique} · ${rec.rodType}',
            style: ibm(12, fw: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(rec.techniqueDesc, style: ibm(11, c: kHint)),
        ],
      ),
    );
  }

  Widget _inlineDataBanner({
    required String message,
    required AqxL10n t,
    required bool gpsErr,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (gpsErr ? kAmber : Colors.red).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(
            gpsErr ? Icons.location_off_rounded : Icons.wifi_off_rounded,
            color: gpsErr ? kAmber : Colors.red,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: ibm(12, c: Colors.white70))),
          if (gpsErr)
            GestureDetector(
              onTap: () => unawaited(_enableLocation(t)),
              child: Text(
                t.locationBannerAction,
                style: ibm(12, c: kCyan, fw: FontWeight.w700),
              ),
            ),
        ],
      ),
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
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          // ── Mockup: localização + COSTA/RIO ────────────
          OracleMockupHeader(
            placeLabel: d.local,
            coordsLabel: _coordsDisplayLabel().isNotEmpty
                ? _coordsDisplayLabel()
                : d.localSubtitle,
            costaLabel: t.costa,
            rioLabel: t.rio,
            rioMode: _rioMode,
            onCosta: () => _toggle(false),
            onRio: () => _toggle(true),
            isRioIcon: d.iconeLocal == 'rio',
            locationFromGps: d.locationFromGps,
          ),
          const SizedBox(height: 8),

          if (_isGpsBlocked()) ...[
            _locationAccessBanner(t),
            const SizedBox(height: 8),
          ],
          _gpsSearchPill(t),
              ],
            ),
          ),

          // ── Fold Decisão (mockup — sempre visível) ─────
          FadeTransition(
            opacity: _fade,
            child: _buildDecisaoFold(context, t, d),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: FadeTransition(
              opacity: _fade,
              child: ValueListenableBuilder<FishingContext>(
                valueListenable: FishingContextStore.instance.value,
                builder: (context, fishingCtx, _) {
                  final speciesCode = fishingCtx.species.trim();
                  if (speciesCode.isEmpty) return const SizedBox.shrink();
                  final rec = BaitTechniqueService.recommend(
                    targetSpecies: _speciesUiLabel(speciesCode),
                    isRio: _rioMode,
                    month: DateTime.now().month,
                    tideState: _rioMode
                        ? ''
                        : (_costaBundle?.tideTrendPt ?? ''),
                  );
                  return _buildBaitTechniqueCard(rec, t);
                },
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: FadeTransition(
            opacity: _fade,
            child: OracleConditionsCollapsible(
              title: t.es ? 'Condiciones completas' : 'Condições completas',
              subtitle: t.es ? 'Maré · Vento · Ondas' : 'Maré · Vento · Ondas',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OracleConditionsFold(
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
                  const SizedBox(height: 8),
                  KeyedSubtree(
                    key: _weatherSectionKey,
                    child: OracleWeatherDetailsGrid(
                      key: _weatherGridKey,
                      data: _weatherDetails,
                      loading: _weatherDetailsLoading,
                      loadFailed: _weatherDetailsFailed,
                      collapsible: false,
                      initiallyExpanded: true,
                      onRetry: () => unawaited(_loadWeatherDetails(
                        costaBundle: _costaBundle,
                        force: true,
                      )),
                    ),
                  ),
                  if (d.dias.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(t.forecastHeader, style: mono(12, ls: 1.2)),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        for (var i = 0; i < d.dias.length; i++) ...[
                          if (i > 0) const SizedBox(width: 5),
                          _diaCard(d.dias[i], i == 0),
                        ],
                      ],
                    ),
                  ],
                  if (d.janelaTexto.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
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
                                          style: ibm(14, c: kAmber,
                                              fw: FontWeight.w700),
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
                  ],
                  const SizedBox(height: 8),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: kHint.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border:
                              Border.all(color: kHint.withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          t.es ? 'EM BREVE' : 'EM BREVE',
                          style: mono(10, c: kHint, ls: 0.5),
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
            ),
          ),

          const SizedBox(height: 14),
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

  ({double lat, double lon})? _oracleMapCoords() {
    final last = OracleDataService.instance.lastCoords;
    if (last != null) return last;
    final place = _planningPlace;
    if (place != null) return (lat: place.lat, lon: place.lon);
    return null;
  }

  String _coordsDisplayLabel() {
    final c = _oracleMapCoords();
    if (c == null) return '';
    final latDir = c.lat >= 0 ? 'N' : 'S';
    final lonDir = c.lon >= 0 ? 'E' : 'W';
    return '${c.lat.abs().toStringAsFixed(4)}° $latDir, '
        '${c.lon.abs().toStringAsFixed(4)}° $lonDir';
  }

  Widget _gpsSearchPill(AqxL10n t) {
    final isP = _planningPlace != null;
    final gpsBlocked = _isGpsBlocked();
    return OracleGpsSearchPill(
      label: isP
          ? _planningPlace!.label
          : gpsBlocked
              ? t.locationNeededTitle
              : t.positionGpsLive,
      onTap: () => _openPlaceSearch(t),
      leadingIcon: isP
          ? Icons.map_outlined
          : gpsBlocked
              ? Icons.location_off_rounded
              : Icons.search_rounded,
      highlight: isP,
      warning: gpsBlocked && !isP,
      trailing: isP
          ? GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _planningPlace = null);
                unawaited(_loadCosta());
                unawaited(_loadRio());
              },
              child: Icon(Icons.close_rounded, size: 18, color: kHint),
            )
          : gpsBlocked
              ? GestureDetector(
                  onTap: () => unawaited(_enableLocation(t)),
                  child: Text(
                    t.locationBannerAction,
                    style: ibm(12, c: kAmber, fw: FontWeight.w600),
                  ),
                )
              : null,
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
    if (canUseSupabase) {
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

  // ignore: unused_element — legado; mockup fold mostra sempre hero + banner inline
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
