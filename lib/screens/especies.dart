import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '_shared.dart';

// ── Modelo ────────────────────────────────────────────────────────────
class Species {
  final String id;
  final String emoji;
  final String nomePT;
  final String nomeES;
  final String cientifico;
  final String familia;
  final String habitat;       // 'COSTA' | 'RIO'
  final String photoUrl;
  final String photoCredit;
  final String minPT;
  final String minES;
  final String quotaPT;
  final String quotaES;
  final bool vedaAtiva;
  final String vedaPT;
  final String vedaES;
  final List<int> mesesMelhor;
  final String mareMelhor;
  final String luaMelhor;
  final String profundidade;
  final int tempAguaMin;
  final int tempAguaMax;
  final String melhorHora;
  final double pesoMaxKg;
  final int comprimentoMaxCm;
  final double lwA;
  final double lwB;
  final List<String> isco;
  final List<String> tecnica;
  final String cana;
  final String linha;
  final String dificuldade;
  final String dica;
  final List<String> tags;

  const Species({
    required this.id,
    required this.emoji,
    required this.nomePT,
    required this.nomeES,
    required this.cientifico,
    required this.familia,
    required this.habitat,
    required this.photoUrl,
    required this.photoCredit,
    required this.minPT,
    required this.minES,
    required this.quotaPT,
    required this.quotaES,
    required this.vedaAtiva,
    required this.vedaPT,
    required this.vedaES,
    required this.mesesMelhor,
    required this.mareMelhor,
    required this.luaMelhor,
    required this.profundidade,
    required this.tempAguaMin,
    required this.tempAguaMax,
    required this.melhorHora,
    required this.pesoMaxKg,
    required this.comprimentoMaxCm,
    required this.lwA,
    required this.lwB,
    required this.isco,
    required this.tecnica,
    required this.cana,
    required this.linha,
    required this.dificuldade,
    required this.dica,
    required this.tags,
  });

  factory Species.fromJson(Map<String, dynamic> j) => Species(
        id: j['id'] as String,
        emoji: j['emoji'] as String? ?? '🐟',
        nomePT: j['nomePT'] as String? ?? j['nome'] as String? ?? '',
        nomeES: j['nomeES'] as String? ?? '',
        cientifico: j['cientifico'] as String? ?? '',
        familia: j['familia'] as String? ?? '',
        habitat: j['habitat'] as String? ?? 'COSTA',
        photoUrl: j['photoUrl'] as String? ?? '',
        photoCredit: j['photoCredit'] as String? ?? '',
        minPT: j['minPT'] as String? ?? '—',
        minES: j['minES'] as String? ?? '—',
        quotaPT: j['quotaPT'] as String? ?? '—',
        quotaES: j['quotaES'] as String? ?? '—',
        vedaAtiva: j['vedaAtiva'] as bool? ?? false,
        vedaPT: j['vedaPT'] as String? ?? '',
        vedaES: j['vedaES'] as String? ?? '',
        mesesMelhor: List<int>.from(j['mesesMelhor'] as List? ?? []),
        mareMelhor: j['mareMelhor'] as String? ?? 'qualquer',
        luaMelhor: j['luaMelhor'] as String? ?? 'qualquer',
        profundidade: j['profundidade'] as String? ?? '',
        tempAguaMin: j['tempAguaMin'] as int? ?? 0,
        tempAguaMax: j['tempAguaMax'] as int? ?? 30,
        melhorHora: j['melhorHora'] as String? ?? 'qualquer',
        pesoMaxKg: (j['pesoMaxKg'] as num?)?.toDouble() ?? 0,
        comprimentoMaxCm: j['comprimentoMaxCm'] as int? ?? 0,
        lwA: (j['lwA'] as num?)?.toDouble() ?? 0,
        lwB: (j['lwB'] as num?)?.toDouble() ?? 0,
        isco: List<String>.from(j['isco'] as List? ?? []),
        tecnica: List<String>.from(j['tecnica'] as List? ?? []),
        cana: j['cana'] as String? ?? '',
        linha: j['linha'] as String? ?? '',
        dificuldade: j['dificuldade'] as String? ?? 'intermédio',
        dica: j['dica'] as String? ?? '',
        tags: List<String>.from(j['tags'] as List? ?? []),
      );

  Color get dificuldadeColor {
    switch (dificuldade) {
      case 'iniciante': return kGreen;
      case 'avançado':  return const Color(0xFFFF6B6B);
      default:          return kAmber;
    }
  }

  Color get habitatColor => habitat == 'RIO' ? const Color(0xFF4FC3F7) : kCyan;
}

// ── Carregamento assíncrono do JSON ───────────────────────────────────
class SpeciesRepository {
  static List<Species>? _cache;

  static Future<List<Species>> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/species_ibero.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    _cache = (data['species'] as List)
        .map((e) => Species.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cache!;
  }
}

// ── Ecrã principal ────────────────────────────────────────────────────
class EspeciesScreen extends StatefulWidget {
  const EspeciesScreen({super.key});

  @override
  State<EspeciesScreen> createState() => _EspeciesScreenState();
}

class _EspeciesScreenState extends State<EspeciesScreen> {
  List<Species> _all = [];
  List<Species> _filtered = [];
  String _habitatFilter = 'TUDO';
  final _searchCtrl = TextEditingController();
  bool _loading = true;

  static const _filters = ['TUDO', 'COSTA', 'RIO'];

  @override
  void initState() {
    super.initState();
    _loadSpecies();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSpecies() async {
    final list = await SpeciesRepository.load();
    if (!mounted) return;
    setState(() {
      _all = list;
      _filtered = list;
      _loading = false;
    });
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = _all.where((s) {
        final habitatOk = _habitatFilter == 'TUDO' || s.habitat == _habitatFilter;
        final searchOk = q.isEmpty ||
            s.nomePT.toLowerCase().contains(q) ||
            s.nomeES.toLowerCase().contains(q) ||
            s.cientifico.toLowerCase().contains(q) ||
            s.tags.any((t) => t.toLowerCase().contains(q));
        return habitatOk && searchOk;
      }).toList();
    });
  }

  void _setHabitat(String h) {
    setState(() => _habitatFilter = h);
    _applyFilter();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildFilterChips(),
            Expanded(child: _loading ? _buildLoading() : _buildGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Row(
          children: [
            if (Navigator.of(context).canPop())
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: kCyan, size: 20),
              ),
            if (Navigator.of(context).canPop()) const SizedBox(width: 10),
            Text('BIBLIOTECA', style: orb(18, c: kCyan, ls: 2)),
            const SizedBox(width: 8),
            Text('DE ESPÉCIES', style: orb(18, c: Colors.white, ls: 2)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: kCyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kCyan.withValues(alpha: 0.3)),
              ),
              child: Text('${_filtered.length}', style: mono(13, c: kCyan)),
            ),
          ],
        ),
      );

  Widget _buildSearchBar() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Container(
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kCyan.withValues(alpha: 0.2)),
          ),
          child: TextField(
            controller: _searchCtrl,
            style: ibm(14, c: Colors.white),
            decoration: InputDecoration(
              hintText: 'Pesquisar espécie, técnica, tag…',
              hintStyle: ibm(14, c: kHint),
              prefixIcon: const Icon(Icons.search_rounded, color: kHint, size: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () { _searchCtrl.clear(); _applyFilter(); },
                      child: const Icon(Icons.clear_rounded, color: kHint, size: 18),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      );

  Widget _buildFilterChips() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Row(
          children: _filters.map((f) {
            final active = _habitatFilter == f;
            Color chipColor;
            switch (f) {
              case 'COSTA': chipColor = kCyan; break;
              case 'RIO':   chipColor = const Color(0xFF4FC3F7); break;
              default:      chipColor = kAmber; break;
            }
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _setHabitat(f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: active ? chipColor.withValues(alpha: 0.18) : kCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active ? chipColor : kHint.withValues(alpha: 0.3),
                      width: active ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    f,
                    style: orb(11, c: active ? chipColor : kHint, ls: 1),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );

  Widget _buildLoading() => const Center(
        child: CircularProgressIndicator(color: kCyan, strokeWidth: 2),
      );

  Widget _buildGrid() {
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, color: kHint, size: 48),
            const SizedBox(height: 12),
            Text('Nenhuma espécie encontrada', style: ibm(14, c: kHint)),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: _filtered.length,
      itemBuilder: (_, i) => _SpeciesCard(
        species: _filtered[i],
        index: i,
        onTap: () => _openDetail(_filtered[i]),
      ),
    );
  }

  void _openDetail(Species s) {
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (_, __, ___) => EspeciesDetailScreen(species: s),
      transitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    ));
  }
}

// ── Card de grelha ─────────────────────────────────────────────────────
class _SpeciesCard extends StatelessWidget {
  final Species species;
  final int index;
  final VoidCallback onTap;
  const _SpeciesCard({required this.species, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: species.habitatColor.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    child: species.photoUrl.isNotEmpty
                        ? Image.network(
                            species.photoUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (_, child, progress) => progress == null
                                ? child
                                : Container(
                                    color: const Color(0xFF0D1F35),
                                    child: const Center(
                                      child: CircularProgressIndicator(color: kCyan, strokeWidth: 1.5),
                                    ),
                                  ),
                            errorBuilder: (_, __, ___) => _photoPlaceholder(),
                          )
                        : _photoPlaceholder(),
                  ),
                  // Habitat badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: species.habitatColor.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        species.habitat,
                        style: orb(8, c: Colors.black, ls: 0.5),
                      ),
                    ),
                  ),
                  // Veda badge
                  if (species.vedaAtiva)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B6B).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('⚠️ VEDA', style: orb(7, c: Colors.white, ls: 0.5)),
                      ),
                    ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(species.nomePT, style: ibm(13, fw: FontWeight.w600, c: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(species.cientifico, style: ibm(10, c: kHint), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _MiniStat(icon: Icons.straighten_rounded, value: species.minPT),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: species.dificuldadeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: species.dificuldadeColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          species.dificuldade[0].toUpperCase(),
                          style: orb(9, c: species.dificuldadeColor, ls: 0),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate(delay: Duration(milliseconds: index * 40)).fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
    );
  }

  Widget _photoPlaceholder() => Container(
        color: const Color(0xFF0D1F35),
        child: Center(
          child: Text(species.emoji, style: const TextStyle(fontSize: 48)),
        ),
      );
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  const _MiniStat({required this.icon, required this.value});
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: kCyan),
          const SizedBox(width: 3),
          Text(value, style: mono(10, c: kCyan)),
        ],
      );
}

// ── Ecrã de detalhe ───────────────────────────────────────────────────
class EspeciesDetailScreen extends StatelessWidget {
  final Species species;
  const EspeciesDetailScreen({super.key, required this.species});

  static const _meses = ['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  if (species.vedaAtiva) ...[_buildVedaBanner(), const SizedBox(height: 14)],
                  _buildMeasuresCard(),
                  const SizedBox(height: 12),
                  _buildCalendarCard(),
                  const SizedBox(height: 12),
                  _buildConditionsCard(),
                  const SizedBox(height: 12),
                  _buildIscoCard(),
                  const SizedBox(height: 12),
                  _buildGearCard(),
                  const SizedBox(height: 12),
                  _buildTipCard(),
                  const SizedBox(height: 12),
                  _buildTagsRow(),
                  const SizedBox(height: 8),
                  Text(species.photoCredit, style: mono(9, c: kHint.withValues(alpha: 0.5))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) => SliverAppBar(
        expandedHeight: 240,
        pinned: true,
        backgroundColor: kBg,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kBg.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: kCyan, size: 18),
          ),
        ),
        flexibleSpace: FlexibleSpaceBar(
          background: Stack(
            fit: StackFit.expand,
            children: [
              species.photoUrl.isNotEmpty
                  ? Image.network(species.photoUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _heroBg())
                  : _heroBg(),
              // Gradiente overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      kBg.withValues(alpha: 0.6),
                      kBg,
                    ],
                    stops: const [0.4, 0.75, 1.0],
                  ),
                ),
              ),
              // Habitat + veda badges
              Positioned(
                top: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: species.habitatColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(species.habitat, style: orb(10, c: Colors.black, ls: 1)),
                    ),
                    if (species.vedaAtiva) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B6B),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('⚠️ VEDA ACTIVA', style: orb(9, c: Colors.white, ls: 0.5)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _heroBg() => Container(
        color: const Color(0xFF0D1F35),
        child: Center(child: Text(species.emoji, style: const TextStyle(fontSize: 96))),
      );

  Widget _buildHeader() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(species.nomePT, style: orb(24, c: Colors.white, ls: 0.5)),
          const SizedBox(height: 2),
          Text(species.nomeES, style: ibm(15, c: kHint)),
          const SizedBox(height: 4),
          Text(species.cientifico, style: ibm(13, fw: FontWeight.w300, c: kHint).copyWith(fontStyle: FontStyle.italic)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.science_outlined, size: 13, color: kAmber),
              const SizedBox(width: 4),
              Text(species.familia, style: mono(12, c: kAmber)),
            ],
          ),
        ],
      );

  Widget _buildVedaBanner() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B6B).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFF6B6B).withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF6B6B), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PT: ${species.vedaPT}', style: ibm(12, c: const Color(0xFFFF9999))),
                  const SizedBox(height: 2),
                  Text('ES: ${species.vedaES}', style: ibm(12, c: const Color(0xFFFF9999))),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildMeasuresCard() => _SectionCard(
        title: 'MEDIDAS LEGAIS',
        icon: Icons.gavel_rounded,
        iconColor: kAmber,
        children: [
          Row(
            children: [
              Expanded(child: _LegalTile(flag: '🇵🇹', label: 'Mínimo PT', value: species.minPT)),
              const SizedBox(width: 8),
              Expanded(child: _LegalTile(flag: '🇪🇸', label: 'Mínimo ES', value: species.minES)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _LegalTile(flag: '🇵🇹', label: 'Quota PT', value: species.quotaPT)),
              const SizedBox(width: 8),
              Expanded(child: _LegalTile(flag: '🇪🇸', label: 'Quota ES', value: species.quotaES)),
            ],
          ),
          const SizedBox(height: 8),
          _DataRow(label: 'Veda PT', value: species.vedaPT),
          const SizedBox(height: 4),
          _DataRow(label: 'Veda ES', value: species.vedaES),
          if (species.pesoMaxKg > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _LegalTile(flag: '⚖️', label: 'Peso máx.', value: '${species.pesoMaxKg} kg')),
                const SizedBox(width: 8),
                Expanded(child: _LegalTile(flag: '📏', label: 'Comp. máx.', value: '${species.comprimentoMaxCm} cm')),
              ],
            ),
          ],
        ],
      );

  Widget _buildCalendarCard() => _SectionCard(
        title: 'CALENDÁRIO',
        icon: Icons.calendar_month_rounded,
        iconColor: kCyan,
        children: [
          Text('Meses de maior actividade', style: ibm(12, c: kHint)),
          const SizedBox(height: 10),
          Row(
            children: List.generate(12, (i) {
              final active = species.mesesMelhor.contains(i + 1);
              return Expanded(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 28,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: active ? kCyan.withValues(alpha: 0.85) : kCard,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: active ? kCyan : kHint.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _meses[i].substring(0, 1),
                          style: orb(8, c: active ? Colors.black : kHint, ls: 0),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      );

  Widget _buildConditionsCard() => _SectionCard(
        title: 'CONDIÇÕES IDEAIS',
        icon: Icons.water_rounded,
        iconColor: const Color(0xFF4FC3F7),
        children: [
          _CondRow(icon: '🌊', label: 'Melhor maré', value: species.mareMelhor),
          _CondRow(icon: '🌙', label: 'Fase lunar', value: species.luaMelhor),
          _CondRow(icon: '🕐', label: 'Melhor hora', value: species.melhorHora),
          _CondRow(icon: '⬇️', label: 'Profundidade', value: species.profundidade),
          _CondRow(
            icon: '🌡️',
            label: 'Temp. água',
            value: '${species.tempAguaMin}–${species.tempAguaMax} °C',
          ),
        ],
      );

  Widget _buildIscoCard() => _SectionCard(
        title: 'ISCO RECOMENDADO',
        icon: Icons.set_meal_rounded,
        iconColor: kAmber,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: species.isco.map((is_) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: kAmber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kAmber.withValues(alpha: 0.35)),
              ),
              child: Text('🪝 $is_', style: ibm(12, c: kAmber)),
            )).toList(),
          ),
          const SizedBox(height: 12),
          Text('TÉCNICAS', style: orb(10, c: kHint, ls: 1.5)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: species.tecnica.map((t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: kCyan.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kCyan.withValues(alpha: 0.25)),
              ),
              child: Text('🎣 $t', style: ibm(12, c: kCyan)),
            )).toList(),
          ),
        ],
      );

  Widget _buildGearCard() => _SectionCard(
        title: 'EQUIPAMENTO',
        icon: Icons.settings_outlined,
        iconColor: kHint,
        children: [
          _DataRow(label: 'Cana', value: species.cana),
          const SizedBox(height: 6),
          _DataRow(label: 'Linha', value: species.linha),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: species.dificuldadeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: species.dificuldadeColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'Dificuldade: ${species.dificuldade}',
                  style: ibm(12, c: species.dificuldadeColor),
                ),
              ),
            ],
          ),
        ],
      );

  Widget _buildTipCard() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kCyan.withValues(alpha: 0.15)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: kCyan.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.tips_and_updates_outlined, color: kCyan, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DICA DO PESCADOR', style: orb(10, c: kCyan, ls: 1.5)),
                  const SizedBox(height: 6),
                  Text(species.dica, style: ibm(13, c: Colors.white.withValues(alpha: 0.85))),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildTagsRow() => Wrap(
        spacing: 6,
        runSpacing: 6,
        children: species.tags.map((t) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: kHint.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kHint.withValues(alpha: 0.2)),
          ),
          child: Text('#$t', style: mono(11, c: kHint)),
        )).toList(),
      );
}

// ── Widgets auxiliares de detalhe ──────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.icon, required this.iconColor, required this.children});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: iconColor.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 16),
                const SizedBox(width: 8),
                Text(title, style: orb(11, c: iconColor, ls: 1.5)),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      );
}

class _LegalTile extends StatelessWidget {
  final String flag, label, value;
  const _LegalTile({required this.flag, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: kBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kHint.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(flag, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text(label, style: mono(10, c: kHint)),
            ]),
            const SizedBox(height: 4),
            Text(value, style: ibm(13, fw: FontWeight.w600, c: Colors.white)),
          ],
        ),
      );
}

class _DataRow extends StatelessWidget {
  final String label, value;
  const _DataRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: mono(12, c: kHint))),
          Expanded(child: Text(value, style: ibm(13, c: Colors.white))),
        ],
      );
}

class _CondRow extends StatelessWidget {
  final String icon, label, value;
  const _CondRow({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            SizedBox(width: 110, child: Text(label, style: mono(12, c: kHint))),
            Expanded(child: Text(value, style: ibm(13, c: Colors.white))),
          ],
        ),
      );
}
