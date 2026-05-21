import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import '_shared.dart';
import 'oracle_live_widgets.dart';
import 'paywall.dart';
import '../core/l10n/aqx_l10n.dart';
import '../core/services/analytics_service.dart';
import '../core/state/app_locale_store.dart';
import '../core/state/fishing_context_store.dart';
import '../core/state/fishing_mode_store.dart';
import '../core/state/home_tab_index.dart';
import '../core/state/subscription_store.dart';
import '../core/tides/oracle_data_service.dart';
import '../core/tides/osm_place_search.dart';

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

const _costa = _ModoData(
  local: 'Sesimbra · SETÚBAL',
  localSubtitle: 'Referência regional · demonstração',
  iconeLocal: 'location',
  statusLabel: 'EXCELENTE',
  statusDesc: 'Maré vazante + lua crescente\n+ vento NW fraco',
  horario: '07:00 -> 09:30',
  score: 84,
  cards: [
    _MetricTile(
      icon: Icons.waves_rounded,
      label: 'MARÉ',
      value: '1.80 m',
      sub: 'A descer ↓',
    ),
    _MetricTile(
      icon: Icons.thermostat_rounded,
      label: 'TEMP. ÁGUA',
      value: '17.0 °C',
      sub: 'Estável →',
    ),
    _MetricTile(
      icon: Icons.air_rounded,
      label: 'VENTO',
      value: '14 km/h',
      sub: 'NW',
    ),
    _MetricTile(
      icon: Icons.speed_rounded,
      label: 'PRESSÃO',
      value: '1010 hPa',
      sub: '↗ Estável',
    ),
    _MetricTile(
      icon: Icons.nightlight_round,
      label: 'LUA',
      value: '72%',
      sub: 'Crescente',
    ),
  ],
  dias: [_Dia('HOJ','84','⚡'), _Dia('SEX','71','↑'), _Dia('SÁB','44','☁'), _Dia('DOM','68','↑'), _Dia('SEG','79','⭐')],
  janelaTexto:
      'amanhã 07:15 — índice 79/100 na referência regional. Activa alertas PRO.',
);

const _rio = _ModoData(
  local: 'Rio Tejo · Abrantes',
  localSubtitle: 'Modo rio · dados de demonstração (SNIRH em roadmap)',
  iconeLocal: 'rio',
  statusLabel: 'BOM',
  statusDesc: 'Caudal estável + temperatura\nideal + visibilidade boa',
  horario: '05:30 -> 08:30',
  fonte: 'SNIRH',
  score: 78,
  cards: [
    _MetricTile(icon: Icons.water_rounded, label: 'CAUDAL', value: '42 m³/s'),
    _MetricTile(icon: Icons.show_chart_rounded, label: 'NÍVEL', value: 'Normal'),
    _MetricTile(
      icon: Icons.thermostat_rounded,
      label: 'TEMP. ÁGUA',
      value: '14.0 °C',
    ),
    _MetricTile(
      icon: Icons.speed_rounded,
      label: 'PRESSÃO',
      value: '1013 hPa',
      sub: '↗ Estável',
    ),
    _MetricTile(icon: Icons.visibility_rounded, label: 'VISIB.', value: 'Boa'),
  ],
  dias: [_Dia('HOJ','78','🏞'), _Dia('SEX','82','⬆'), _Dia('SÁB','65','🌧'), _Dia('DOM','71','↑'), _Dia('SEG','80','⭐')],
  janelaTexto: 'amanhã 05:30 — caudal a descer + solunar alto. Barbo e achigã.',
);

// ══════════════════════════════════════════════════════════
// ECRÃ 01 — ORÁCULO
// ══════════════════════════════════════════════════════════
class OraculoScreen extends StatefulWidget {
  const OraculoScreen({super.key});
  @override
  State<OraculoScreen> createState() => _OraculoScreenState();
}

class _OraculoScreenState extends State<OraculoScreen>
    with TickerProviderStateMixin {
  bool _rioMode = false;
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final AnimationController _fishPulse;
  late final VoidCallback _ctxListener;
  late final VoidCallback _homeTabListener;
  _LoadState _costaLoad = _LoadState.loading;
  OracleBundle? _costaBundle;
  String? _costaError;
  _LoadState _rioLoad = _LoadState.loading;
  RiverOracleBundle? _rioBundle;
  String? _rioError;
  bool _costaGpsError = false;
  bool _rioGpsError = false;
  OsmPlace? _planningPlace;

  @override
  void initState() {
    super.initState();
    final ctx = FishingContextStore.instance.value.value;
    _rioMode = ctx.region == 'ABRANTES' || ctx.species == 'BARBO';
    _ctxListener = () {
      if (!mounted) return;
      final c = FishingContextStore.instance.value.value;
      final wantRio = c.region == 'ABRANTES' || c.species == 'BARBO';
      if (wantRio != _rioMode) setState(() => _rioMode = wantRio);
    };
    FishingContextStore.instance.value.addListener(_ctxListener);
    _homeTabListener = () {
      if (!mounted) return;
      if (HomeTabIndex.notifier.value == HomeTabIndex.oracleTabIndex) _trackNorthStar();
    };
    HomeTabIndex.notifier.addListener(_homeTabListener);
    if (HomeTabIndex.notifier.value == HomeTabIndex.oracleTabIndex) _trackNorthStar();
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
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _ctrl.value = 1.0;
    _fishPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    unawaited(_loadCosta());
    unawaited(_loadRio());
  }

  void _trackNorthStar() {
    unawaited(
      AnalyticsService.instance.track(
        AnalyticsEvents.northStarOracleView,
        params: {
          'score': _rioMode
              ? (_rioBundle?.score ?? _rio.score)
              : (_costaBundle?.score ?? _costa.score),
          'mode': _rioMode ? 'rio' : 'costa',
        },
      ),
    );
  }

  @override
  void dispose() {
    HomeTabIndex.notifier.removeListener(_homeTabListener);
    FishingContextStore.instance.value.removeListener(_ctxListener);
    _fishPulse.dispose();
    _ctrl.dispose();
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
      default:
        if (code.isEmpty) return code;
        return '${code[0]}${code.substring(1).toLowerCase()}';
    }
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
    if (isRio) {
      if (score >= 65) return const ['BARBO', 'ACHIGA'];
      return const ['BARBO', 'ACHIGA'];
    }

    final p = place.toLowerCase();
    // PT — localidades costa
    if (p.contains('sesimbra') || p.contains('setúbal') || p.contains('setubal')) {
      return const ['ROBALO', 'SARGO'];
    }
    if (p.contains('peniche') || p.contains('nazaré') || p.contains('nazare')) {
      return const ['ROBALO', 'CORVINA'];
    }
    if (p.contains('sagres') || p.contains('lagos') || p.contains('faro')) {
      return const ['DOURADA', 'SARGO'];
    }
    if (p.contains('cascais') || p.contains('sintra') || p.contains('ericeira')) {
      return const ['ROBALO', 'SARGO'];
    }
    // ES — localidades costa
    if (p.contains('vigo') || p.contains('pontevedra')) {
      return const ['ROBALO', 'DOURADA'];
    }
    if (p.contains('huelva') || p.contains('cádiz') || p.contains('cadiz')) {
      return const ['DOURADA', 'CORVINA'];
    }
    if (p.contains('coruña') || p.contains('coruna') || p.contains('galicia')) {
      return const ['ROBALO', 'SARGO'];
    }
    if (p.contains('barcelona') || p.contains('tarragona') || p.contains('girona')) {
      return const ['DOURADA', 'SARGO'];
    }
    if (p.contains('alicante') || p.contains('valencia') || p.contains('murcia')) {
      return const ['DOURADA', 'SARGO'];
    }
    if (score >= 75) return const ['ROBALO', 'SARGO'];
    if (score >= 55) return const ['DOURADA', 'ROBALO'];
    return <String>[
      selectedSpecies.toUpperCase(),
      selectedSpecies.toUpperCase() == 'SARGO' ? 'ROBALO' : 'SARGO',
    ];
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header: saudação + localização ─────────────
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${t.greeting(DateTime.now().hour)}${t.fisherSuffix}',
                    style: ibm(17, fw: FontWeight.w600),
                  ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.02),
                  const SizedBox(height: 4),
                  FadeTransition(
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
                ],
              ),
            ),
            GestureDetector(
              onTap: () async {
                HapticFeedback.selectionClick();
                final plan = SubscriptionStore.instance.value.value;
                if (!plan.hasProEntitlement) {
                  await PaywallScreen.open(context, source: 'oraculo_alertas');
                  return;
                }
                if (!mounted) return;
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
          Container(
            height: 34,
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kCyan.withValues(alpha: 0.12)),
            ),
            child: Row(children: [
              _chip(Icons.waves_rounded, t.costa, !_rioMode, () => _toggle(false)),
              _chip(
                Icons.landscape_rounded,
                t.rio,
                _rioMode,
                () => _toggle(true),
                iconSize: 20,
              ),
            ]),
          ).animate().fadeIn(delay: 90.ms, duration: 380.ms).slideY(
                begin: 0.05,
                duration: 380.ms,
                curve: Curves.easeOutCubic,
              ),

          const SizedBox(height: 8),

          // ── Fonte de dados (GPS / planeamento) ─────────
          _planningSourceRow(t),
          const SizedBox(height: 8),

          // ── Score card ─────────────────────────────────
          FadeTransition(
            opacity: _fade,
            child: (!_rioMode && _costaLoad != _LoadState.ok) ||
                    (_rioMode && _rioLoad != _LoadState.ok)
                ? _scoreStatePlaceholder(isRio: _rioMode, t: t)
                : _scoreCardContent(d, t),
          ),

          const SizedBox(height: 8),

          // ── Mini-cards métricas (scroll horizontal) ────
          FadeTransition(
            opacity: _fade,
            child: SizedBox(
              height: 104,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    for (var i = 0; i < d.cards.length; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      _metricTile(d.cards[i], width: 76)
                          .animate(key: ValueKey('${d.score}_${d.cards[i].value}_$i'))
                          .fadeIn(
                            delay: Duration(milliseconds: 140 + i * 55),
                            duration: 400.ms,
                          )
                          .slideY(
                            begin: 0.07,
                            duration: 400.ms,
                            curve: Curves.easeOutCubic,
                          ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Previsão 5 dias ────────────────────────────
          Text(t.forecastHeader, style: mono(12, ls: 1.2)),
          const SizedBox(height: 5),
          FadeTransition(
            opacity: _fade,
            child: Row(
              children: [
                for (var i = 0; i < d.dias.length; i++) ...[
                  if (i > 0) const SizedBox(width: 5),
                  _diaCard(d.dias[i], i == 0)
                      .animate(key: ValueKey('dia_${d.dias[i].d}_$i'))
                      .fadeIn(
                        delay: Duration(milliseconds: 200 + i * 45),
                        duration: 350.ms,
                      ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Janela de Ouro — fiel à referência ────────
          FadeTransition(
            opacity: _fade,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF0D1A0A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kAmber.withValues(alpha: 0.25)),
              ),
              child: IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  // Barra âmbar à esquerda
                  Container(
                    width: 4,
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
                ]),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── P5 — Banner push Janela de Ouro ────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kGreen.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: kGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_active_outlined, color: kGreen, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.pushGoldenPro, style: mono(11, c: kGreen, ls: 0.8)),
                  Text(
                    t.pushDemoBody(
                      _rioMode ? t.riverTagusDemo : _alertPlaceHint(t),
                    ),
                    style: ibm(13, c: Colors.white70),
                  ),
                ]),
              ),
              GestureDetector(
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  final ctx = FishingContextStore.instance.value.value;
                  unawaited(
                    AnalyticsService.instance.track(
                      AnalyticsEvents.missionCompleted,
                      params: {
                        'screen': 'oraculo',
                        'mode': _rioMode ? 'rio' : 'costa',
                        'country': ctx.country,
                        'region': ctx.region,
                        'species': ctx.species,
                        'action': 'golden_window_alert_enabled',
                      },
                    ),
                  );
                  final plan = SubscriptionStore.instance.value.value;
                  if (!plan.hasProEntitlement) {
                    await PaywallScreen.open(context, source: 'oraculo_push_janela_ouro');
                    return;
                  }
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        t.es
                            ? 'Alertas push — EM BREVE en esta versión.'
                            : 'Alertas push — EM BREVE nesta versão.',
                        style: ibm(14),
                      ),
                      backgroundColor: kCard,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: kGreen.withValues(alpha: 0.4)),
                  ),
                  child: Text(t.activate, style: mono(11, c: kGreen)),
                ),
              ),
            ]),
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
                      final active = _activeSpeciesCodes(
                        isRio: _rioMode,
                        place: d.local,
                        score: d.score,
                        selectedSpecies: fishingCtx.species,
                      );
                      final primaryCode = active.first;
                      final primaryPlan =
                          _planForSpecies(primaryCode, isRio: _rioMode, t: t);
                      final activeFishLabel = active
                          .take(2)
                          .map(_speciesUiLabel)
                          .join(' + ');
                      return Column(
                        children: [
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
                                    activeFishLabel,
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
    );
  }

  // ── Oracle data ──────────────────────────────────────────

  String _alertPlaceHint(AqxL10n t) {
    final b = _costaBundle;
    if (b == null) return t.alertZone;
    return b.usedGps ? t.alertYou : b.locationHeadline.split('·').first.trim();
  }

  Widget _planningSourceRow(AqxL10n t) {
    final isP = _planningPlace != null;
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
                : kCyan.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isP ? Icons.map_outlined : Icons.my_location_rounded,
              size: 15,
              color: isP ? kAmber : kCyan,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isP ? _planningPlace!.label : t.positionGpsLive,
                style: ibm(13, c: isP ? kAmber : kCyan),
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
      _costaLoad = _LoadState.loading;
      _costaGpsError = false;
    });
    try {
      final ctx = FishingContextStore.instance.value.value;
      final bundle = await OracleDataService.instance.fetch(
        ctx: ctx,
        planningPlace: _planningPlace,
      );
      if (!mounted) return;
      setState(() {
        _costaBundle = bundle;
        _costaLoad = _LoadState.ok;
        _costaGpsError = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (e is OracleGpsRequiredException) {
        setState(() {
          _costaError = e.message;
          _costaLoad = _LoadState.error;
          _costaGpsError = true;
        });
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

  Future<void> _loadRio() async {
    if (!mounted) return;
    setState(() {
      _rioLoad = _LoadState.loading;
      _rioGpsError = false;
    });
    try {
      final ctx = FishingContextStore.instance.value.value;
      final bundle = await OracleDataService.instance.fetchRiver(
        ctx: ctx,
        planningPlace: _planningPlace,
      );
      if (!mounted) return;
      setState(() {
        _rioBundle = bundle;
        _rioLoad = _LoadState.ok;
        _rioGpsError = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (e is OracleGpsRequiredException) {
        setState(() {
          _rioError = e.message;
          _rioLoad = _LoadState.error;
          _rioGpsError = true;
        });
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
    if (b == null) return _rio;
    final tempStr =
        b.tempC != null ? '${b.tempC!.toStringAsFixed(1)} °C' : '—';
    return _ModoData(
      local: b.locationHeadline,
      localSubtitle: b.locationSubtitle,
      locationFromGps: b.usedGps,
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
    if (b == null) return _costa;
    final tideStr = b.tideHeightM != null
        ? '${b.tideHeightM!.toStringAsFixed(2)} m'
        : '—';
    final tempStr =
        b.tempC != null ? '${b.tempC!.toStringAsFixed(1)} °C' : '—';
    final presStr =
        b.pressureHpa != null ? '${b.pressureHpa!.round()} hPa' : '—';
    return _ModoData(
      local: b.locationHeadline,
      localSubtitle: b.locationSubtitle,
      locationFromGps: b.usedGps,
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
    final loading =
        isRio ? _rioLoad == _LoadState.loading : _costaLoad == _LoadState.loading;
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
    final gpsErr = isRio ? _rioGpsError : _costaGpsError;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
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
        const SizedBox(width: 6),
        if (gpsErr) ...[
          GestureDetector(
            onTap: () => _openPlaceSearch(t),
            child: Text(t.search, style: ibm(13, c: kCyan, fw: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Geolocator.openAppSettings(),
            child: Text(t.settings, style: ibm(13, c: kAmber, fw: FontWeight.w600)),
          ),
        ] else ...[
          GestureDetector(
            onTap: () => unawaited(isRio ? _loadRio() : _loadCosta()),
            child: Text(t.retry, style: ibm(13, c: kCyan, fw: FontWeight.w600)),
          ),
        ],
      ]),
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
    return inner
        .animate(key: ValueKey('card_${d.score}_$_rioMode'))
        .fadeIn(duration: 480.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.06, duration: 480.ms, curve: Curves.easeOutCubic)
        .then(delay: 700.ms)
        .shimmer(
          duration: 2.seconds,
          color: kCyan.withValues(alpha: 0.07),
          angle: 0.5,
        );
  }

  Widget _iscoRow(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          SizedBox(width: 88, child: Text(k, style: ibm(13, c: kHint))),
          Expanded(child: Text(v, style: ibm(13, c: Colors.white, fw: FontWeight.w600))),
        ]),
      );

  // ── Toggle chip ───────────────────────────────────────────
  Widget _chip(
    IconData icon,
    String label,
    bool sel,
    VoidCallback onTap, {
    double iconSize = 18,
  }) =>
      Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: sel ? kCyan.withValues(alpha: 0.10) : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              border: sel ? Border.all(color: kCyan.withValues(alpha: 0.5)) : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: iconSize,
                  color: sel ? kCyan : kHint.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 6),
                Text(label,
                    style: orb(12,
                        c: sel ? kCyan : kHint,
                        fw: sel ? FontWeight.w700 : FontWeight.w400,
                        ls: 1.2)),
              ],
            ),
          ),
        ),
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

  // ── Mini-cards métricas (ícone + rótulo + valor + subtítulo opcional) ──
  Widget _metricTile(_MetricTile m, {double? width}) {
    final card = Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kCyan.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(m.icon, color: kCyan, size: 19),
          const SizedBox(height: 4),
          Text(
            m.label,
            style: mono(8.4, c: kCyan, ls: 0.6),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            m.value,
            style: orb(12, c: Colors.white, fw: FontWeight.w700, ls: 0),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          SizedBox(
            height: 30,
            width: double.infinity,
            child: Align(
              alignment: Alignment.topCenter,
              child: Text(
                m.sub,
                style: ibm(10.5, c: kCyan),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
    return width != null ? card : Expanded(child: card);
  }

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
