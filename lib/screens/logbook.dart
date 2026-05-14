import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '_shared.dart';
import 'especies.dart';
import 'paywall.dart';
import '../core/services/app_insights_service.dart';
import '../core/services/analytics_service.dart';
import '../core/state/fishing_context_store.dart';
import '../core/supabase_bootstrap.dart';
import '../core/community/community_post.dart';
import '../core/community/community_store.dart';
import '../core/l10n/aqx_l10n.dart';

// Dados das capturas (demo)
class _Captura {
  final String emoji, nome, peso, tag, details, isco;
  final Color tagColor;
  bool temFoto;

  _Captura({
    required this.emoji, required this.nome, required this.peso,
    required this.tag, required this.details, required this.isco,
    required this.tagColor, this.temFoto = false,
  });
}

// ══════════════════════════════════════════════════════════
// ECRÃ 04 · LOGBOOK
// ══════════════════════════════════════════════════════════
class LogbookScreen extends StatefulWidget {
  const LogbookScreen({super.key});
  @override
  State<LogbookScreen> createState() => _LogbookScreenState();
}

class _LogbookScreenState extends State<LogbookScreen>
    with SingleTickerProviderStateMixin {

  int _tabIndex = 0;
  late final TabController _tabCtrl;

  static const _prefsKey = 'logbook_capturas_v1';

  static final _demoCapturas = [
    _Captura(emoji: '🐟', nome: 'Robalo Europeu 👑', peso: '4.2kg',
        tag: 'RECORDE', tagColor: kAmber,
        details: 'Cabo Espichel · 17 Abr', isco: 'Shad 14cm',
        temFoto: true),
    _Captura(emoji: '🐡', nome: 'Dourada', peso: '1.8kg',
        tag: 'Score 71', tagColor: kCyan,
        details: 'Comporta · 14 Abr', isco: 'Minhoca'),
    _Captura(emoji: '🦈', nome: 'Garoupa', peso: '2.1kg',
        tag: 'Score 84', tagColor: kCyan,
        details: 'Espichel Norte · 10 Abr', isco: 'Jig 30g'),
  ];

  List<_Captura> _capturas = [];
  bool _capturasLoaded = false;

  Future<void> _loadCapturas() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey);
    if (raw == null || raw.isEmpty) {
      if (mounted) setState(() { _capturas = List.from(_demoCapturas); _capturasLoaded = true; });
      return;
    }
    final loaded = raw.map((s) {
      final m = jsonDecode(s) as Map<String, dynamic>;
      return _Captura(
        emoji: m['emoji'] as String? ?? '🎣',
        nome: m['nome'] as String? ?? '',
        peso: m['peso'] as String? ?? '',
        tag: m['tag'] as String? ?? 'NOVO',
        tagColor: m['tagColor'] == 'amber' ? kAmber : (m['tagColor'] == 'green' ? kGreen : kCyan),
        details: m['details'] as String? ?? '',
        isco: m['isco'] as String? ?? '—',
        temFoto: m['temFoto'] as bool? ?? false,
      );
    }).toList();
    if (mounted) setState(() { _capturas = loaded; _capturasLoaded = true; });
  }

  Future<void> _saveCapturas() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = _capturas.map((c) => jsonEncode({
      'emoji': c.emoji,
      'nome': c.nome,
      'peso': c.peso,
      'tag': c.tag,
      'tagColor': c.tagColor == kAmber ? 'amber' : (c.tagColor == kGreen ? 'green' : 'cyan'),
      'details': c.details,
      'isco': c.isco,
      'temFoto': c.temFoto,
    })).toList();
    await prefs.setStringList(_prefsKey, raw);
  }

  @override
  void initState() {
    super.initState();
    final ctx = FishingContextStore.instance.value.value;
    unawaited(
      AnalyticsService.instance.track(
        AnalyticsEvents.missionStarted,
        params: {
          'screen': 'logbook',
          'country': ctx.country,
          'region': ctx.region,
          'species': ctx.species,
        },
      ),
    );
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() => setState(() => _tabIndex = _tabCtrl.index));
    unawaited(_loadCapturas());
    if (isSupabaseConfigured) {
      final ctx = FishingContextStore.instance.value.value;
      unawaited(CommunityStore.instance.loadFeed(country: ctx.country));
    }
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [_minhasList(), _comunidadeList(), _trofeusList()],
          ),
        ),
      ],
    );
  }

  // ── Header + tabs ─────────────────────────────────────
  Widget _buildHeader() {
    final t = aqxL10nOf(context);
    return Container(
        // i18n PT/ES sem alterar layout
        color: kCard,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(children: [
          Row(children: [
            Text(t.es ? 'DIARIO' : 'LOGBOOK', style: orb(20, ls: 2)),
            const Spacer(),
            // Botão Biblioteca de Espécies
            GestureDetector(
              onTap: () => Navigator.push(context, PageRouteBuilder(
                pageBuilder: (_, __, ___) => const EspeciesScreen(),
                transitionDuration: const Duration(milliseconds: 350),
                transitionsBuilder: (_, anim, __, child) =>
                    FadeTransition(opacity: anim, child: child),
              )),
              child: Container(
                width: 32, height: 32,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: kAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kAmber.withValues(alpha: 0.35)),
                ),
                child: const Icon(Icons.auto_stories_outlined, color: kAmber, size: 17),
              ),
            ),
            GestureDetector(
              onTap: _tabIndex == 1 ? _showNovoPostSheet : _showNovaCapturaSheet,
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: kCyan,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: kCyan.withValues(alpha: 0.4), blurRadius: 10)],
                ),
                child: const Icon(Icons.add, color: Colors.black, size: 20),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kCyan.withValues(alpha: 0.12)),
            ),
            child: TabBar(
              controller: _tabCtrl,
              indicator: BoxDecoration(
                color: kCyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kCyan.withValues(alpha: 0.4)),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: kCyan,
              unselectedLabelColor: kHint,
              tabs: [
                Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.person_outline_rounded, size: 13),
                  const SizedBox(width: 4),
                  Text(t.es ? 'MIS CAPTURAS' : 'AS MINHAS', style: mono(9, c: _tabIndex == 0 ? kCyan : kHint)),
                ])),
                Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.people_outline_rounded, size: 13),
                  const SizedBox(width: 4),
                  Text(t.es ? 'COMUNIDAD' : 'COMUNIDADE', style: mono(9, c: _tabIndex == 1 ? kCyan : kHint)),
                ])),
                Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.emoji_events_outlined, size: 13),
                  const SizedBox(width: 4),
                  Text(t.es ? 'TROFEOS' : 'TROFÉUS', style: mono(9, c: _tabIndex == 2 ? kAmber : kHint)),
                ])),
              ],
            ),
          ),
          const SizedBox(height: 2),
        ]),
      );
  }

  /// Banner regulatório: RecFishing / MAPA vs diário premium AQUANAUTIX.
  Widget _recfishingLogbookBanner(BuildContext context) {
    final fishingCtx = FishingContextStore.instance.value.value;
    final isPt = fishingCtx.country.toUpperCase() == 'PT';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kAmber.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gavel_rounded, size: 16, color: kAmber),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isPt ? 'REGISTO LEGAL · PORTUGAL' : 'REGISTRO LEGAL · ESPAÑA',
                  style: mono(10, c: kAmber, ls: 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isPt
                ? 'RecFishing é o canal oficial quando aplicável. O logbook AQUANAUTIX é o teu diário premium (fotos, técnica, streak) — nunca o substitui.'
                : 'En España el trámite oficial depende de tu comunidad (p. ej. PescaREC). El logbook AQUANAUTIX es complemento de experiencia, no sustituto.',
            style: ibm(11, c: Colors.white70),
          ),
        ],
      ),
    );
  }

  // ── AS MINHAS ─────────────────────────────────────────
  Widget _minhasList() {
    final t = aqxL10nOf(context);
    return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _recfishingLogbookBanner(context),
            const SizedBox(height: 14),
            // Recordes
            Text(t.es ? '// RÉCORDS PERSONALES' : '// RECORDES PESSOAIS', style: mono(10, ls: 1.2)),
            const SizedBox(height: 8),
            Row(children: [
              _pbCard('🐟', 'Robalo', '4.2kg', 'Mar 2026', kCyan),
              const SizedBox(width: 8),
              _pbCard('🐡', 'Dourada', '2.8kg', 'Jan 2026', kAmber),
              const SizedBox(width: 8),
              _pbCard('🦈', 'Pargo', '6.1kg', 'Dez 2025', kHint),
            ]),
            const SizedBox(height: 18),

            // Novo bloco: compliance e reporte UE
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kGreen.withValues(alpha: 0.24)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.fact_check_outlined, size: 16, color: kGreen),
                          const SizedBox(width: 6),
                          Text(data.complianceTitle, style: mono(10, c: kGreen, ls: 1.0)),
                        ]),
                        const SizedBox(height: 6),
                        Text(data.complianceDetail, style: ibm(11, c: Colors.white70)),
                        const SizedBox(height: 8),
                        Row(children: [
                          Text(t.es ? 'Listo para exportar' : 'Pronto para exportar', style: ibm(11, c: kHint)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: kGreen.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: kGreen.withValues(alpha: 0.4)),
                            ),
                            child: Text(data.complianceOk ? 'OK' : (t.es ? 'PENDIENTE' : 'PENDENTE'), style: mono(9, c: kGreen)),
                          ),
                        ]),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),

            // Últimas capturas
            Text('// ÚLTIMAS CAPTURAS', style: mono(10, ls: 1.2)),
            const SizedBox(height: 8),

            if (!_capturasLoaded)
              const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(color: kCyan, strokeWidth: 2),
              ))
            else
              ...List.generate(_capturas.length, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _catchCard(_capturas[i], i),
              )),

            const SizedBox(height: 14),

            // Botões exportar / partilhar
            Row(children: [
              Expanded(
                child: _actionBtn(
                  Icons.upload_outlined,
                  'EXPORTAR',
                  () => _trackMissionCompletedFromLogbook(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _actionBtn(Icons.share_outlined, t.es ? 'COMPARTIR' : 'PARTILHAR',
                  () {
                    _trackMissionCompletedFromLogbook(action: 'share_modal_open');
                    _partilharModal(context, _capturas.first);
                  })),
            ]),
          ],
        ),
      );
  }

  // ── Card de captura com foto ──────────────────────────
  Widget _catchCard(_Captura c, int idx) => Container(
        // Mantém apenas texto i18n; sem alterar UI.
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Foto thumbnail (56×56)
                fishPhotoWidget(
                  size: 56,
                  captured: c.temFoto,
                  emoji: c.emoji,
                  onTap: () => setState(() => c.temFoto = !c.temFoto),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.nome, style: ibm(13, fw: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text(c.details, style: ibm(11, c: kHint)),
                      const SizedBox(height: 4),
                      // Afiliado isco
                      Row(children: [
                        const Text('🪝', style: TextStyle(fontSize: 11)),
                        const SizedBox(width: 4),
                        Text(c.isco, style: ibm(11, c: kHint)),
                        Text(' → Decathlon', style: ibm(11, c: kAmber, fw: FontWeight.w600)),
                      ]),
                    ],
                  ),
                ),

                // Peso + tag
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(c.peso, style: orb(14, fw: FontWeight.w900, ls: 0)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: c.tagColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: c.tagColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(c.tag, style: mono(8, c: c.tagColor)),
                  ),
                  const SizedBox(height: 6),
                  // Botão partilhar individual
                  GestureDetector(
                    onTap: () => _partilharModal(context, c),
                    child: Icon(Icons.share_outlined, size: 16,
                        color: kCyan.withValues(alpha: 0.6)),
                  ),
                ]),
              ],
            ),

            // Indicador foto
            if (!c.temFoto) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => setState(() => c.temFoto = true),
                child: Row(children: [
                  Icon(Icons.add_a_photo_outlined, size: 13,
                      color: kHint.withValues(alpha: 0.5)),
                  const SizedBox(width: 5),
                  Text(aqxL10nOf(context).es ? 'Añadir foto de la captura' : 'Adicionar foto da captura',
                      style: ibm(11, c: kHint.withValues(alpha: 0.5))),
                ]),
              ),
            ],
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final navigator = Navigator.of(context);
                final allSpecies = await SpeciesRepository.load();
                final q = c.nome.toLowerCase();
                final match = allSpecies.firstWhere(
                  (s) =>
                      s.nomePT.toLowerCase().contains(q) ||
                      q.contains(s.nomePT.toLowerCase().split(' ').first) ||
                      s.nomeES.toLowerCase().contains(q),
                  orElse: () => allSpecies.first,
                );
                navigator.push(PageRouteBuilder(
                  pageBuilder: (_, __, ___) => EspeciesDetailScreen(species: match),
                  transitionDuration: const Duration(milliseconds: 350),
                  transitionsBuilder: (_, anim, __, child) =>
                      FadeTransition(opacity: anim, child: child),
                ));
              },
              child: Row(children: [
                Icon(Icons.auto_stories_outlined, size: 13,
                    color: kAmber.withValues(alpha: 0.7)),
                const SizedBox(width: 5),
                Text('Ver ficha · ${c.nome}',
                    style: ibm(11, c: kAmber.withValues(alpha: 0.7))),
                const Spacer(),
                Icon(Icons.chevron_right_rounded, size: 14,
                    color: kAmber.withValues(alpha: 0.5)),
              ]),
            ),
          ],
        ),
      );

  // ── Modal de partilha com foto ────────────────────────
  void _partilharModal(BuildContext context, _Captura c) {
    final t = aqxL10nOf(context);
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4,
                decoration: BoxDecoration(
                    color: kHint.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),

            // Preview da partilha
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kCyan.withValues(alpha: 0.15)),
              ),
              child: Column(
                children: [
                  // Foto grande no topo do card
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: SizedBox(
                      width: double.infinity,
                      height: 160,
                      child: c.temFoto
                          ? fishPhotoWidget(size: 400, captured: true, emoji: c.emoji)
                          : Container(
                              color: const Color(0xFF06101E),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.photo_camera_outlined,
                                      size: 36, color: kHint.withValues(alpha: 0.4)),
                                  const SizedBox(height: 6),
                                  Text(t.es ? 'Sin foto' : 'Sem foto', style: ibm(12, c: kHint.withValues(alpha: 0.4))),
                                ],
                              ),
                            ),
                    ),
                  ),

                  // Info da captura
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Text(c.emoji, style: const TextStyle(fontSize: 22)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(c.nome,
                                          style: ibm(14, fw: FontWeight.w700)),
                                      Text('Zona · Sesimbra · ${c.details.split('·').last.trim()}',
                                          style: ibm(11, c: kHint)),
                                    ]),
                              ),
                            ]),
                            const SizedBox(height: 10),
                            Row(children: [
                              _statChip(c.peso, kAmber),
                              const SizedBox(width: 6),
                              _statChip('Score 84', kGreen),
                              const SizedBox(width: 6),
                              _statChip(c.isco, kCyan),
                            ]),
                          ],
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: Text('AQUANAUTIX',
                              style: mono(8, c: kCyan.withValues(alpha: 0.4), ls: 1.5)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (!c.temFoto) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  setState(() => c.temFoto = true);
                },
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.add_a_photo_outlined, size: 14, color: kCyan),
                  const SizedBox(width: 6),
                  Text(t.es ? 'Añadir foto para compartir' : 'Adicionar foto para partilhar',
                      style: ibm(12, c: kCyan, fw: FontWeight.w600)),
                ]),
              ),
            ],

            const SizedBox(height: 10),
            Text(
                t.es
                    ? '👻 Coordenadas exactas protegidas · Ghost Mode activo'
                    : '👻 Coordenadas exactas protegidas · Ghost Mode activo',
                style: mono(9, c: kHint), textAlign: TextAlign.center),
            const SizedBox(height: 14),

            Row(children: [
              Expanded(child: _actionBtn(Icons.save_alt_outlined, 'GUARDAR',
                  () => Navigator.pop(context))),
              const SizedBox(width: 12),
              Expanded(child: _actionBtn(Icons.share_outlined, t.es ? 'COMPARTIR' : 'PARTILHAR',
                  () => Navigator.pop(context))),
            ]),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String v, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: c.withValues(alpha: 0.4)),
        ),
        child: Text(v, style: mono(9, c: c)),
      );

  // ── COMUNIDADE GHOST — Feed com fotos reais ───────────────
  static const _storyPhotos = [
    'https://images.unsplash.com/photo-1544979590-04bcee11af7d?w=100&q=70&auto=format',
    'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=100&q=70&auto=format',
    'https://images.unsplash.com/photo-1499728603263-13726abce5fd?w=100&q=70&auto=format',
    'https://images.unsplash.com/photo-1504700610630-ac6aba3536d3?w=100&q=70&auto=format',
  ];

  final _feedLikes = <int, bool>{};

  static List<CommunityPost> _mockPosts() => [
    CommunityPost(
      id: 'mock-0', userId: 'mock-u0', username: 'Nuno_Sesimbra', tier: 'PRO',
      avatarUrl: 'https://i.pravatar.cc/80?img=11',
      zoneLabel: '📍 ≈2.1km de si',
      photoUrl: 'https://images.unsplash.com/photo-1544979590-04bcee11af7d?w=600&q=75&auto=format',
      species: 'ROBALO', weightKg: 2.8,
      caption: 'Manhã incrível! Score 82 e a maré a subir. Isco: minhoca 🪱',
      oracleScore: 82, isLegal: true, country: 'PT',
      createdAt: DateTime.now().subtract(const Duration(minutes: 23)),
      likesCount: 47,
    ),
    CommunityPost(
      id: 'mock-1', userId: 'mock-u1', username: 'Pedro_Algarve', tier: 'ELITE',
      avatarUrl: 'https://i.pravatar.cc/80?img=32',
      zoneLabel: '🔒 Spot ELITE · ≈8.4km',
      photoUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600&q=75&auto=format',
      species: 'DOURADA', weightKg: 1.4,
      caption: 'Spot secreto do Algarve 🔒',
      oracleScore: 91, isLegal: true, country: 'PT',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      likesCount: 63, locked: true,
    ),
    CommunityPost(
      id: 'mock-2', userId: 'mock-u2', username: 'RuiSurf_PT', tier: 'PRO',
      avatarUrl: 'https://i.pravatar.cc/80?img=22',
      zoneLabel: '👻 Zona de Comporta',
      photoUrl: 'https://images.unsplash.com/photo-1499728603263-13726abce5fd?w=600&q=75&auto=format',
      species: 'PARGO', weightKg: 3.1,
      caption: 'Recorde pessoal de pargo! 🏆 Técnica de fundo.',
      oracleScore: 74, isLegal: true, country: 'PT',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      likesCount: 31,
    ),
    CommunityPost(
      id: 'mock-3', userId: 'mock-u3', username: 'Carlos_V', tier: 'PRO',
      avatarUrl: 'https://i.pravatar.cc/80?img=44',
      zoneLabel: '👻 Zona de Sesimbra',
      photoUrl: 'https://images.unsplash.com/photo-1518568814500-bf0f8d125f46?w=600&q=75&auto=format',
      species: 'CORVINA', weightKg: 2.3,
      caption: 'Corvina boa ao surfcasting! Score 68.',
      oracleScore: 68, isLegal: true, country: 'PT',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      likesCount: 19,
    ),
  ];

  String _timeAgo(DateTime dt) {
    final t = aqxL10nOf(context);
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return t.es ? 'hace ${d.inMinutes} min' : 'há ${d.inMinutes} min';
    if (d.inHours < 24)   return t.es ? 'hace ${d.inHours}h' : 'há ${d.inHours}h';
    if (d.inDays < 7)     return t.es ? 'hace ${d.inDays}d' : 'há ${d.inDays}d';
    return '${dt.day}/${dt.month}';
  }

  Widget _comunidadeList() => ValueListenableBuilder<CommunityState>(
    valueListenable: CommunityStore.instance.value,
    builder: (context, state, _) {
      final t = aqxL10nOf(context);
      final posts = state.posts.isNotEmpty ? state.posts : _mockPosts();
      return ListView(
        padding: EdgeInsets.zero,
        children: [
          // Ghost mode banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: kAmber.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kAmber.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              const Text('👻', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(child: Text(
                t.es
                    ? 'GHOST MODE — coordenadas nunca compartidas. Zona mínima 5km.'
                    : 'GHOST MODE — coordenadas nunca partilhadas. Zona mínima 5km.',
                style: ibm(10, c: kHint),
              )),
            ]),
          ),

          // Stories bar
          SizedBox(
            height: 92,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              scrollDirection: Axis.horizontal,
              itemCount: _storyPhotos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, i) {
                final names = ['Nuno_S', 'Pedro_A', 'RuiSurf', 'Carlos_V'];
                return Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF00F5FF), Color(0xFFF3C64D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Container(
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: kBg),
                      padding: const EdgeInsets.all(2),
                      child: netImg(
                        _storyPhotos[i],
                        width: 48, height: 48,
                        radius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(names[i], style: mono(8)),
                ]);
              },
            ),
          ),

          // Posts
          ...posts.asMap().entries.map((e) => _buildFeedPost(e.key, e.value)),
          if (state.loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(color: kCyan, strokeWidth: 2)),
            ),
          const SizedBox(height: 80),
        ],
      );
    },
  );

  Widget _buildFeedPost(int idx, CommunityPost post) {
    final t = aqxL10nOf(context);
    final isLocked = post.locked;
    final isLive   = isSupabaseConfigured && CommunityStore.instance.value.value.posts.isNotEmpty;
    final liked    = isLive ? post.likedByMe : (_feedLikes[idx] ?? false);
    final likeCount = isLive
        ? post.likesCount
        : post.likesCount + (liked ? 1 : 0);
    final weightLabel = post.weightKg != null
        ? '${post.weightKg!.toStringAsFixed(1)} kg'
        : '—';
    final avatar = post.avatarUrl ??
        'https://i.pravatar.cc/80?u=${post.userId}';
    final legalLabel = post.country == 'ES' ? 'Legal ES' : 'Legal PT';

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      color: kCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(children: [
              ClipOval(child: netImg(avatar, width: 36, height: 36)),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(post.username, style: ibm(12, fw: FontWeight.w600)),
                    const SizedBox(width: 6),
                    _tierBadgeSmall(post.tier),
                  ]),
                  const SizedBox(height: 2),
                  Text(post.zoneLabel, style: mono(9)),
                ],
              )),
              Text(_timeAgo(post.createdAt), style: mono(9)),
            ]),
          ),

          // Foto + overlay de tags
          Stack(children: [
            SizedBox(
              width: double.infinity,
              height: 220,
              child: isLocked
                  ? ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: netImg(post.photoUrl, width: double.infinity, height: 220),
                    )
                  : netImg(post.photoUrl, width: double.infinity, height: 220),
            ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                height: 80,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xFF000814), Colors.transparent],
                  ),
                ),
              ),
            ),
            if (!isLocked)
              Positioned(
                bottom: 10, left: 12,
                child: Wrap(spacing: 6, children: [
                  _photoTag(post.species, kCyan),
                  _photoTag('⚖️ $weightLabel', kAmber),
                  _photoTag(post.isLegal ? '✅ $legalLabel' : (t.es ? '❌ Fuera de veda' : '❌ Fora época'),
                      post.isLegal ? kGreen : Colors.redAccent),
                ]),
              ),
            if (isLocked)
              Positioned.fill(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_rounded, color: kAmber, size: 32),
                    const SizedBox(height: 8),
                    Text('CAPTURA ELITE\nBLOQUEADA',
                        style: orb(12, c: kAmber, ls: 1),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => PaywallScreen.open(context, source: 'logbook_post_locked'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: kAmber,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(t.es ? 'VER CON PRO →' : 'VER COM PRO →',
                            style: orb(9, c: Colors.black, fw: FontWeight.w700, ls: 1)),
                      ),
                    ),
                  ],
                ),
              ),
          ]),

          // Oracle mini card
          if (!isLocked)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: kCyan.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kCyan.withValues(alpha: 0.15)),
                ),
                child: Row(children: [
                  const Icon(Icons.track_changes_rounded, color: kCyan, size: 14),
                  const SizedBox(width: 6),
                  Expanded(child: Text(
                    'Score Oráculo · ${post.zoneLabel.replaceAll('👻 ', '').replaceAll('📍 ', '').replaceAll('🔒 ', '')}',
                    style: mono(9),
                  )),
                  Text('${post.oracleScore}', style: orb(16, c: kCyan, fw: FontWeight.w900, ls: 0)),
                  Text('/100', style: mono(9)),
                ]),
              ),
            ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(children: [
              GestureDetector(
                onTap: () {
                  if (isLive) {
                    unawaited(CommunityStore.instance.toggleLike(post.id));
                  } else {
                    setState(() => _feedLikes[idx] = !liked);
                  }
                },
                child: Row(children: [
                  Icon(liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 18, color: liked ? const Color(0xFFFF3B5C) : kHint),
                  const SizedBox(width: 4),
                  Text('$likeCount', style: ibm(12, c: kHint)),
                ]),
              ),
              const SizedBox(width: 16),
              Row(children: [
                const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: kHint),
                const SizedBox(width: 4),
                Text('0', style: ibm(12, c: kHint)),
              ]),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kCyan.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: kCyan.withValues(alpha: 0.25)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.ios_share_rounded, size: 12, color: kCyan),
                  const SizedBox(width: 4),
                  Text(t.es ? 'COMPARTIR' : 'PARTILHAR', style: mono(8, c: kCyan)),
                ]),
              ),
            ]),
          ),

          // Caption
          if (!isLocked && post.caption != null && post.caption!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              child: RichText(
                text: TextSpan(style: ibm(12), children: [
                  TextSpan(text: '${post.username} ',
                      style: ibm(12, fw: FontWeight.w600, c: kCyan)),
                  TextSpan(text: post.caption),
                ]),
              ),
            ),

          Divider(color: kCyan.withValues(alpha: 0.05), height: 1),
        ],
      ),
    );
  }

  Widget _photoTag(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(label, style: mono(9, c: color)),
      );

  Widget _tierBadgeSmall(String tier) {
    final isPro = tier == 'PRO';
    final c = isPro ? kAmber : const Color(0xFFc084fc);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(tier, style: orb(7, c: c, fw: FontWeight.w700, ls: 1)),
    );
  }

  // ── TROFÉUS + LEADERBOARD ──────────────────────────────
  static const _speciesPhotos = {
    'Robalo': 'https://images.unsplash.com/photo-1544979590-04bcee11af7d?w=200&q=75&auto=format',
    'Dourada': 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=200&q=75&auto=format',
    'Pargo': 'https://images.unsplash.com/photo-1499728603263-13726abce5fd?w=200&q=75&auto=format',
    'Garoupa': 'https://images.unsplash.com/photo-1518568814500-bf0f8d125f46?w=200&q=75&auto=format',
    'Corvina': 'https://images.unsplash.com/photo-1504700610630-ac6aba3536d3?w=200&q=75&auto=format',
    'Sargo': 'https://images.unsplash.com/photo-1505459668311-8dfac7952bf0?w=200&q=75&auto=format',
  };

  Widget _trofeusList() {
    const records = [
      _RecordEntry(species: 'Robalo Europeu', weight: '4.2kg', length: '61cm', date: 'Mar 2026', score: 87, isHero: true),
      _RecordEntry(species: 'Garoupa', weight: '2.1kg', length: '44cm', date: 'Abr 2026', score: 84),
      _RecordEntry(species: 'Pargo', weight: '6.1kg', length: '72cm', date: 'Dez 2025', score: 79),
      _RecordEntry(species: 'Dourada', weight: '2.8kg', length: '48cm', date: 'Jan 2026', score: 71),
      _RecordEntry(species: 'Corvina', weight: '—', length: '—', date: '—', score: 0),
      _RecordEntry(species: 'Sargo', weight: '—', length: '—', date: '—', score: 0),
    ];

    const leaderboard = [
      _LbEntry(rank: 1, user: 'Pedro_Tavira', region: 'Algarve', weight: '3.8kg', avatar: 'https://i.pravatar.cc/80?img=11'),
      _LbEntry(rank: 2, user: 'Nuno_Sesimbra', region: 'Setúbal', weight: '3.2kg', avatar: 'https://i.pravatar.cc/80?img=22'),
      _LbEntry(rank: 3, user: 'RuiSurf_PT', region: 'Lisboa', weight: '2.9kg', avatar: 'https://i.pravatar.cc/80?img=33'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero record
          Text('// MELHOR CAPTURA', style: mono(10, ls: 1.2)),
          const SizedBox(height: 10),
          _buildRecordHero(records.first),
          const SizedBox(height: 18),

          // Species grid
          Text('// RECORDES POR ESPÉCIE', style: mono(10, ls: 1.2)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.3,
            children: records.skip(1).map(_buildSpeciesCard).toList(),
          ),
          const SizedBox(height: 18),

          // Leaderboard Regional
          Row(children: [
            Expanded(child: Text('// RANKING ROBALO · REGIÃO', style: mono(10, ls: 1.2))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: kAmber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: kAmber.withValues(alpha: 0.35)),
              ),
              child: Text('MAIO 2026', style: mono(8, c: kAmber)),
            ),
          ]),
          const SizedBox(height: 10),
          ...leaderboard.map(_buildLbRow),
          const SizedBox(height: 8),
          // Blur + CTA para FREE
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(children: [
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Column(children: [
                  _buildLbRow(const _LbEntry(rank: 4, user: 'JoaoLisbona', region: 'Lisboa',
                      weight: '2.7kg', avatar: 'https://i.pravatar.cc/80?img=44')),
                  _buildLbRow(const _LbEntry(rank: 5, user: 'MarcoFaro', region: 'Faro',
                      weight: '2.5kg', avatar: 'https://i.pravatar.cc/80?img=55')),
                ]),
              ),
              Positioned.fill(child: Container(
                decoration: BoxDecoration(
                  color: kBg.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('ESTÁS EM #12 — SOBE AO TOP 5',
                      style: ibm(12, fw: FontWeight.w600, c: kAmber), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => PaywallScreen.open(context, source: 'logbook_leaderboard'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: kAmber,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text('UPGRADE PRO →',
                          style: orb(9, c: Colors.black, fw: FontWeight.w700, ls: 1)),
                    ),
                  ),
                ]),
              )),
            ]),
          ),
          const SizedBox(height: 10),
          // Posição do utilizador
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kCyan.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kCyan.withValues(alpha: 0.25)),
            ),
            child: Row(children: [
              Text('#12', style: orb(18, c: kCyan, fw: FontWeight.w900, ls: 0)),
              const SizedBox(width: 14),
              ClipOval(child: netImg('https://i.pravatar.cc/80?img=66', width: 36, height: 36)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Tu', style: ibm(13, fw: FontWeight.w600, c: kCyan)),
                Text('1.8kg · 43cm · Lisboa', style: mono(9)),
              ])),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordHero(_RecordEntry r) {
    final photoUrl = _speciesPhotos[r.species.split(' ').first] ??
        'https://images.unsplash.com/photo-1544979590-04bcee11af7d?w=600&q=75&auto=format';
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kAmber.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        netImg(photoUrl, width: double.infinity, height: 160),
        Container(
          height: 160,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color(0xEE000814), Color(0x44000814)],
            ),
          ),
        ),
        Positioned(
          bottom: 14, left: 14, right: 14,
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: kAmber,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('🏆 RECORDE PESSOAL', style: orb(8, c: Colors.black, ls: 1)),
              ),
              const SizedBox(height: 6),
              Text(r.species, style: orb(18, fw: FontWeight.w900, ls: 0)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(r.weight, style: orb(22, c: kCyan, fw: FontWeight.w900, ls: 0)),
              Text(r.length, style: mono(11, c: kHint)),
              Text('Score ${r.score}', style: mono(10, c: kAmber)),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _buildSpeciesCard(_RecordEntry r) {
    final photoUrl = _speciesPhotos[r.species.split(' ').first];
    final hasRecord = r.score > 0;
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hasRecord
            ? kCyan.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.06)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        if (photoUrl != null)
          Positioned.fill(
            child: Opacity(
              opacity: hasRecord ? 0.35 : 0.12,
              child: netImg(photoUrl, width: double.infinity, height: double.infinity),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(r.species, style: ibm(11, fw: FontWeight.w600)),
              hasRecord
                  ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r.weight, style: orb(14, c: kCyan, fw: FontWeight.w900, ls: 0)),
                      Text(r.date, style: mono(8)),
                    ])
                  : Text('sem registo', style: mono(9, c: kHint.withValues(alpha: 0.5))),
            ],
          ),
        ),
        if (!hasRecord)
          Positioned(top: 8, right: 8,
            child: Icon(Icons.lock_outline, size: 14, color: kHint.withValues(alpha: 0.4))),
      ]),
    );
  }

  Widget _buildLbRow(_LbEntry e) {
    final rankColors = {1: kAmber, 2: const Color(0xFFB0B8C8), 3: const Color(0xFFCD7F32)};
    final c = rankColors[e.rank] ?? kHint;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        SizedBox(width: 28,
          child: Text('#${e.rank}', style: orb(14, c: c, fw: FontWeight.w900, ls: 0), textAlign: TextAlign.center)),
        const SizedBox(width: 8),
        ClipOval(child: netImg(e.avatar, width: 36, height: 36)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(e.user, style: ibm(12, fw: FontWeight.w600)),
          Text(e.region, style: mono(9)),
        ])),
        Text(e.weight, style: orb(13, c: kCyan, fw: FontWeight.w900, ls: 0)),
      ]),
    );

  }

  Widget _pbCard(String emoji, String name, String weight, String date, Color accent) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withValues(alpha: 0.2)),
          ),
          child: Column(children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(name, style: ibm(10, c: kHint), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(weight, style: orb(14, c: accent, fw: FontWeight.w900, ls: 0)),
            const SizedBox(height: 2),
            Text(date, style: mono(8)),
          ]),
        ),
      );

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kCyan.withValues(alpha: 0.3)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 16, color: kCyan),
            const SizedBox(width: 6),
            Text(label, style: mono(10, c: kCyan)),
          ]),
        ),
      );

  // Zonas fuzzy PT + ES — nunca coordenadas exactas
  static const _ptZones = [
    '👻 Zona de Sesimbra', '👻 Costa Alentejana', '👻 Zona de Comporta',
    '👻 Cabo Espichel',    '👻 Algarve Central',  '👻 Algarve Barlavento',
    '👻 Algarve Sotavento','👻 Costa de Cascais',  '👻 Zona de Setúbal',
    '👻 Costa da Caparica','👻 Norte de Portugal',  '👻 Douro Litoral',
    '👻 Zona dos Açores',  '👻 Zona da Madeira',
  ];
  static const _esZones = [
    '👻 Costa Brava',   '👻 Costa Daurada',  '👻 Delta del Ebro',
    '👻 Bahía de Cádiz','👻 Costa de la Luz', '👻 Mar Menor',
    '👻 Costa del Sol', '👻 Islas Baleares',  '👻 Galicia Norte',
    '👻 Galicia Sur',   '👻 Asturias',        '👻 País Vasco',
  ];

  void _showNovoPostSheet() {
    final t = aqxL10nOf(context);
    HapticFeedback.mediumImpact();
    final fishCtx   = FishingContextStore.instance.value.value;
    final zones     = fishCtx.country.toUpperCase() == 'ES' ? _esZones : _ptZones;
    final specCtrl  = TextEditingController(text: fishCtx.species);
    final weightCtrl= TextEditingController();
    final captCtrl  = TextEditingController();
    var   selZone   = zones.first;
    XFile? pickedPhoto;
    var   uploading = false;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSS) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: const BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: Container(
                      width: 36, height: 4,
                      decoration: BoxDecoration(
                        color: kHint.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )),
                    const SizedBox(height: 14),
                    Text(t.es ? 'COMPARTIR CAPTURA' : 'PARTILHAR CAPTURA', style: orb(14, c: kCyan, ls: 1.4)),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Text('👻', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(t.es ? 'Coordenadas nunca compartidas · Ghost Mode' : 'Coordenadas nunca partilhadas · Ghost Mode',
                          style: ibm(10, c: kHint)),
                    ]),
                    const SizedBox(height: 14),

                    // Foto picker
                    GestureDetector(
                      onTap: () async {
                        final img = await ImagePicker().pickImage(
                          source: ImageSource.gallery, imageQuality: 75);
                        if (img != null) setSS(() => pickedPhoto = img);
                      },
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: kBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kCyan.withValues(
                              alpha: pickedPhoto != null ? 0.5 : 0.2)),
                        ),
                        child: pickedPhoto != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: Image.file(
                                  File(pickedPhoto!.path),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_outlined,
                                      size: 28, color: kCyan.withValues(alpha: 0.65)),
                                  const SizedBox(height: 8),
                                  Text('SELECCIONAR FOTO',
                                      style: mono(10, c: kCyan, ls: 1.2)),
                                  const SizedBox(height: 3),
                                  Text('JPG · HEIC · PNG',
                                      style: ibm(10, c: kHint.withValues(alpha: 0.5))),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Zona — InputDecorator + DropdownButton (evita deprecated FormField.value)
                    InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Zona (aprox.)',
                        labelStyle: ibm(12, c: kHint),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: kCyan.withValues(alpha: 0.3))),
                        focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: kCyan)),
                        border: OutlineInputBorder(
                            borderSide: BorderSide(color: kCyan.withValues(alpha: 0.3))),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selZone,
                          dropdownColor: kCard,
                          style: ibm(14),
                          icon: const Icon(Icons.arrow_drop_down, color: kCyan),
                          isExpanded: true,
                          items: zones.map((z) => DropdownMenuItem(
                              value: z, child: Text(z, style: ibm(13)))).toList(),
                          onChanged: (v) => setSS(() => selZone = v!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: specCtrl,
                      style: ibm(14),
                      cursorColor: kCyan,
                      decoration: InputDecoration(
                        labelText: t.es ? 'Especie' : 'Espécie',
                        labelStyle: ibm(12, c: kHint),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: kCyan.withValues(alpha: 0.3))),
                        focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: kCyan)),
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: weightCtrl,
                      style: ibm(14),
                      cursorColor: kCyan,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: t.es ? 'Peso en kg (ej: 2.4)' : 'Peso em kg (ex: 2.4)',
                        labelStyle: ibm(12, c: kHint),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: kCyan.withValues(alpha: 0.3))),
                        focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: kCyan)),
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: captCtrl,
                      style: ibm(14),
                      cursorColor: kCyan,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: t.es ? 'Leyenda (opcional)' : 'Legenda (opcional)',
                        labelStyle: ibm(12, c: kHint),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: kCyan.withValues(alpha: 0.3))),
                        focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: kCyan)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: pickedPhoto != null ? kCyan : kCard,
                        foregroundColor: pickedPhoto != null ? Colors.black : kHint,
                        side: pickedPhoto == null
                            ? BorderSide(color: kHint.withValues(alpha: 0.3))
                            : null,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: uploading ? null : () async {
                        if (pickedPhoto == null) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                            content: Text(t.es ? 'Elige una foto.' : 'Escolhe uma foto.', style: ibm(14)),
                            backgroundColor: kCard,
                          ));
                          return;
                        }
                        final sp = specCtrl.text.trim();
                        if (sp.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                            content: Text(t.es ? 'Indica la especie.' : 'Indica a espécie.', style: ibm(14)),
                            backgroundColor: kCard,
                          ));
                          return;
                        }
                        setSS(() => uploading = true);
                        final photoUrl = await CommunityStore.instance.uploadPhoto(pickedPhoto!);
                        if (photoUrl == null) {
                          setSS(() => uploading = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                              content: Text(aqxL10nOf(ctx).es ? 'Error al enviar foto.' : 'Erro ao enviar foto.', style: ibm(14)),
                              backgroundColor: kCard,
                            ));
                          }
                          return;
                        }
                        final wkg = double.tryParse(
                            weightCtrl.text.trim().replaceAll(',', '.'));
                        final fc = FishingContextStore.instance.value.value;
                        await CommunityStore.instance.createPost(
                          zoneLabel: selZone,
                          photoUrl:  photoUrl,
                          species:   sp,
                          weightKg:  wkg,
                          caption:   captCtrl.text.trim().isEmpty
                              ? null : captCtrl.text.trim(),
                          country:   fc.country,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: uploading
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.black, strokeWidth: 2))
                          : Text(t.es ? 'PUBLICAR EN LA COMUNIDAD' : 'PUBLICAR NA COMUNIDADE',
                              style: mono(11).copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      specCtrl.dispose();
      weightCtrl.dispose();
      captCtrl.dispose();
    });
  }

  void _showNovaCapturaSheet() {
    final t = aqxL10nOf(context);
    HapticFeedback.mediumImpact();
    final esp = TextEditingController(
      text: FishingContextStore.instance.value.value.species,
    );
    final peso = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: const BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                const SizedBox(height: 14),
                Text(t.es ? 'NUEVA CAPTURA' : 'NOVA CAPTURA', style: orb(14, c: kCyan, ls: 1.4)),
                const SizedBox(height: 12),
                TextField(
                  controller: esp,
                  style: ibm(14),
                  decoration: InputDecoration(
                    labelText: t.es ? 'Especie' : 'Espécie',
                    labelStyle: ibm(12, c: kHint),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: kCyan.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: kCyan),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: peso,
                  style: ibm(14),
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: t.es ? 'Peso (ej: 2.4kg)' : 'Peso (ex: 2.4kg)',
                    labelStyle: ibm(12, c: kHint),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: kCyan.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: kCyan),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: kCyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    final nome = esp.text.trim();
                    final p = peso.text.trim();
                    if (nome.isEmpty || p.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(t.es ? 'Rellena especie y peso.' : 'Preenche espécie e peso.', style: ibm(14)),
                          backgroundColor: kCard,
                        ),
                      );
                      return;
                    }
                    final nova = _Captura(
                      emoji: '🎣',
                      nome: nome,
                      peso: p,
                      tag: 'NOVO',
                      tagColor: kGreen,
                      details: 'Registo manual · hoje',
                      isco: '—',
                      temFoto: false,
                    );
                    if (mounted) {
                      setState(() => _capturas.insert(0, nova));
                      // Remove demo data se ainda estava presente
                      if (_capturas.any((c) => c.nome == 'Robalo Europeu 👑') &&
                          _capturas.length > _demoCapturas.length) {
                        setState(() => _capturas.removeWhere(
                            (c) => _demoCapturas.any((d) => d.nome == c.nome)));
                      }
                    }
                    await _saveCapturas();
                    if (ctx.mounted) Navigator.pop(ctx);
                    _trackMissionCompletedFromLogbook(action: 'nova_captura_manual');
                  },
                  child: Text(
                    t.es ? 'AÑADIR AL DIARIO' : 'ADICIONAR AO LOGBOOK',
                    style: mono(11).copyWith(fontWeight: FontWeight.w700, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      esp.dispose();
      peso.dispose();
    });
  }

  void _trackMissionCompletedFromLogbook({String action = 'export_or_save'}) {
    final ctx = FishingContextStore.instance.value.value;
    unawaited(
      AnalyticsService.instance.track(
        AnalyticsEvents.missionCompleted,
        params: {
          'screen': 'logbook',
          'country': ctx.country,
          'region': ctx.region,
          'species': ctx.species,
          'action': action,
        },
      ),
    );
  }
}

// ── Modelos de dados locais ─────────────────────────────────
class _RecordEntry {
  final String species, weight, length, date;
  final int score;
  final bool isHero;
  const _RecordEntry({
    required this.species, required this.weight, required this.length,
    required this.date, required this.score, this.isHero = false,
  });
}

class _LbEntry {
  final int rank;
  final String user, region, weight, avatar;
  const _LbEntry({
    required this.rank, required this.user, required this.region,
    required this.weight, required this.avatar,
  });
}

