import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '_shared.dart';
import 'paywall.dart';
import '../core/config/openai_config.dart';
import '../core/state/subscription_store.dart';
import '../core/species/species_catalog.dart';
import '../core/species/species_compliance.dart';
import '../core/state/fishing_context_store.dart';
import '../core/vision/vision_scan_result.dart';
import '../core/vision/vision_scan_service.dart';
import '../core/l10n/aqx_l10n.dart';

// ══════════════════════════════════════════════════════════
// P2 — ECRÃ 03 · VISION SCANNER (animado + OpenAI Vision)
// ══════════════════════════════════════════════════════════
class VisionScreen extends StatefulWidget {
  const VisionScreen({super.key});
  @override
  State<VisionScreen> createState() => _VisionScreenState();
}

class _VisionScreenState extends State<VisionScreen>
    with TickerProviderStateMixin {
  static const _demoSpeciesId = 'dicentrarchus_labrax';
  static const _kFreeScansKey = 'vision_free_scans_used';
  static const _kMaxFreeScans = 3;

  int _freeScansUsed = 0;
  _ScanState _state = _ScanState.result;
  VisionScanResult? _scan;
  Uint8List? _previewBytes;

  late final AnimationController _scanCtrl;
  late final Animation<double> _scanLine;
  late final AnimationController _confCtrl;
  late final Animation<double> _conf;
  late final AnimationController _resultCtrl;
  late final Animation<double> _resultSlide;

  @override
  void initState() {
    super.initState();

    _scanCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _scanLine = CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut);

    _confCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _conf = Tween<double>(begin: 0, end: 98).animate(
      CurvedAnimation(parent: _confCtrl, curve: Curves.easeOut),
    );

    _resultCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _resultSlide = CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOutCubic);

    _confCtrl.value = 1.0;
    _resultCtrl.value = 1.0;

    _loadFreeUsage();
    SpeciesCatalog.instance.ensureLoaded().then((_) {
      if (!mounted) return;
      final d = SpeciesCatalog.instance.byId(_demoSpeciesId);
      setState(() {
        if (d != null) _scan = VisionScanResult.demo(d);
      });
    });
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    _confCtrl.dispose();
    _resultCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFreeUsage() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => _freeScansUsed = p.getInt(_kFreeScansKey) ?? 0);
  }

  /// Verifica gate de usos gratuitos. Retorna true se o scan pode avançar.
  Future<bool> _checkGateAndConsume() async {
    final isPro =
        SubscriptionStore.instance.value.value.hasProEntitlement;
    if (isPro) return true;

    if (_freeScansUsed < _kMaxFreeScans) {
      final p = await SharedPreferences.getInstance();
      await p.setInt(_kFreeScansKey, _freeScansUsed + 1);
      if (mounted) setState(() => _freeScansUsed++);
      return true;
    }

    if (mounted) {
      await PaywallScreen.open(context, source: 'vision_free_limit');
    }
    return false;
  }

  String _mimeFromPath(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.png')) return 'image/png';
    if (p.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _pickAndScan(ImageSource source) async {
    if (!await _checkGateAndConsume()) return;
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 82,
    );
    if (!mounted) return;
    if (xFile == null) return;

    final bytes = await xFile.readAsBytes();
    final mime = _mimeFromPath(xFile.path);

    HapticFeedback.mediumImpact();
    setState(() {
      _previewBytes = bytes;
      _state = _ScanState.scanning;
    });
    _scanCtrl.reset();
    _confCtrl.reset();
    await _scanCtrl.forward();
    _confCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 400));

    await SpeciesCatalog.instance.ensureLoaded();
    final demo = SpeciesCatalog.instance.byId(_demoSpeciesId);

    VisionScanResult out;
    try {
      if (isOpenAiConfigured) {
        out = await VisionScanService.instance.analyzeImageBytes(
          imageBytes: bytes,
          mimeType: mime,
        );
      } else {
        if (demo == null) throw StateError('Catálogo vazio');
        out = VisionScanResult.withDemoFallback(
          demoSpecies: demo,
          errorMessage: 'OPENAI_API_KEY não definida — resultado de referência.',
        );
      }
    } catch (e) {
      if (demo == null) {
        if (!mounted) return;
        setState(() => _state = _ScanState.idle);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vision: $e')),
        );
        return;
      }
      out = VisionScanResult.withDemoFallback(
        demoSpecies: demo,
        errorMessage: e.toString(),
      );
    }

    if (!mounted) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _scan = out;
      _state = _ScanState.result;
    });
    _resultCtrl
      ..reset()
      ..forward();
  }

  void _reset() {
    _scanCtrl.reset();
    _confCtrl.reset();
    _resultCtrl.reset();
    setState(() {
      _state = _ScanState.idle;
      _scan = null;
      _previewBytes = null;
    });
  }

  Future<void> _saveToLogbook(
    BuildContext ctx,
    VisionScanResult scan,
    String speciesName,
    String isco,
    bool isLegal,
    bool isIllegal,
  ) async {
    const prefsKey = 'logbook_capturas_v1';
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(prefsKey) ?? [];
    final tagColor = isLegal ? 'green' : (isIllegal ? 'amber' : 'cyan');
    final tag = isLegal ? 'LEGAL' : (isIllegal ? 'ILEGAL' : 'VERIFICAR');
    final pesoStr = scan.weightKg != null ? '${scan.weightKg!.toStringAsFixed(1)} kg' : '—';
    final detailsStr = scan.lengthCm != null ? '${scan.lengthCm!.toStringAsFixed(0)} cm' : '—';
    final entry = jsonEncode({
      'emoji': '🐟',
      'nome': speciesName,
      'peso': pesoStr,
      'tag': tag,
      'tagColor': tagColor,
      'details': detailsStr,
      'isco': isco,
      'temFoto': _previewBytes != null,
    });
    existing.insert(0, entry);
    await prefs.setStringList(prefsKey, existing);
    if (!ctx.mounted) return;
    final t = aqxL10nOf(ctx);
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(t.es ? 'Guardado en Diario ✓' : 'Guardado no Logbook ✓', style: ibm(13)),
        backgroundColor: kCard,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = aqxL10nOf(context);
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildViewfinder(),
          if (_state != _ScanState.result)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _outlineBtn(
                          Icons.photo_camera_outlined,
                          t.es ? 'CÁMARA' : 'CÂMARA',
                          () => _pickAndScan(ImageSource.camera),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _outlineBtn(
                          Icons.photo_library_outlined,
                          t.es ? 'GALERÍA' : 'GALERIA',
                          () => _pickAndScan(ImageSource.gallery),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<SubscriptionState>(
                    valueListenable: SubscriptionStore.instance.value,
                    builder: (_, sub, __) {
                      if (sub.hasProEntitlement) return const SizedBox.shrink();
                      final left =
                          (_kMaxFreeScans - _freeScansUsed).clamp(0, _kMaxFreeScans);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          left > 0
                              ? '$left scan${left == 1 ? '' : 's'} gratuito${left == 1 ? '' : 's'} restante${left == 1 ? '' : 's'}'
                              : 'Limite atingido — upgrade para PRO',
                          style: mono(10,
                              c: left > 0 ? kHint : kAmber),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _state == _ScanState.idle ? () => _pickAndScan(ImageSource.camera) : null,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _state == _ScanState.scanning
                            ? kCyan.withValues(alpha: 0.5)
                            : kCyan,
                        boxShadow: [
                          BoxShadow(
                            color: kCyan.withValues(alpha: 0.5),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _state == _ScanState.scanning
                            ? Icons.hourglass_top_rounded
                            : Icons.center_focus_strong_rounded,
                        size: 28,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_state == _ScanState.result)
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(_resultSlide),
              child: FadeTransition(
                opacity: _resultSlide,
                child: _buildResultado(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildViewfinder() {
    final t = aqxL10nOf(context);
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: Stack(
        children: [
          if (_state == _ScanState.result && _previewBytes != null)
            Positioned.fill(
              child: Image.memory(
                _previewBytes!,
                fit: BoxFit.cover,
              ),
            )
          else if (_state == _ScanState.result)
            Positioned.fill(
              child: fishPhotoWidget(
                size: 220,
                captured: true,
                emoji: _scan?.matchedSpecies?.emoji ?? '🐟',
              ),
            )
          else
            Positioned.fill(
              child: Container(color: const Color(0xFF020D1A)),
            ),
          Positioned(top: 16, left: 16, child: _corner()),
          Positioned(top: 16, right: 16, child: _corner(flipH: true)),
          Positioned(bottom: 16, left: 16, child: _corner(flipV: true)),
          Positioned(bottom: 16, right: 16, child: _corner(flipH: true, flipV: true)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_state != _ScanState.result) ...[
                  Icon(
                    Icons.set_meal_rounded,
                    size: 52,
                    color: kCyan.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 10),
                  if (_state == _ScanState.idle)
                    Text(t.es ? 'APUNTA AL PEZ' : 'APONTAR PARA O PEIXE', style: mono(11, ls: 1.4)),
                  if (_state == _ScanState.scanning)
                    Text(t.es ? 'IDENTIFICANDO...' : 'A IDENTIFICAR...', style: mono(11, c: kCyan, ls: 1.4)),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: kGreen.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 13, color: Colors.black),
                        const SizedBox(width: 5),
                        Text(t.es ? 'IDENTIFICADO' : 'IDENTIFICADO', style: orb(10, c: Colors.black, ls: 1.2)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_state == _ScanState.scanning)
            AnimatedBuilder(
              animation: _scanLine,
              builder: (_, __) => Positioned(
                top: 20 + (_scanLine.value * 180),
                left: 20,
                right: 20,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        kCyan.withValues(alpha: 0.8),
                        kCyan,
                        kCyan.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [BoxShadow(color: kCyan.withValues(alpha: 0.6), blurRadius: 8)],
                  ),
                ),
              ),
            ),
          if (_state == _ScanState.scanning)
            Positioned(
              top: 12,
              right: 50,
              child: AnimatedBuilder(
                animation: _conf,
                builder: (_, __) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kBg.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kCyan.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '${_conf.value.toInt()}%',
                    style: orb(12, c: kCyan, fw: FontWeight.w900, ls: 0),
                  ),
                ),
              ),
            ),
          if (_state == _ScanState.result)
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: _reset,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kCyan.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.refresh_rounded, color: kCyan, size: 18),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultado() {
    final t = aqxL10nOf(context);
    return ValueListenableBuilder<FishingContext>(
      valueListenable: FishingContextStore.instance.value,
      builder: (context, fishingCtx, _) {
        final scan = _scan;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('// ÚLTIMO RESULTADO', style: mono(10, ls: 1.2)),
              const SizedBox(height: 10),
              if (scan == null)
                Text(t.es ? 'Cargando base de especies…' : 'A carregar base de espécies…', style: ibm(12, c: kHint))
              else if (scan.matchedSpecies != null)
                _visionResultMatched(context, scan, fishingCtx.country)
              else
                _visionResultUnmatched(context, scan, fishingCtx.country),
            ],
          ),
        );
      },
    );
  }

  Widget _visionResultMatched(
    BuildContext context,
    VisionScanResult scan,
    String countryRaw,
  ) {
    final t = aqxL10nOf(context);
    final species = scan.matchedSpecies!;
    final cc = countryRaw.toUpperCase();
    final compliance = SpeciesCompliance.evaluateLength(
      species: species,
      country: cc,
      measuredLengthCm: scan.lengthCm,
      measuredWeightG: scan.weightG,
    );
    final minRule = cc == 'ES' ? species.minES : species.minPT;
    final verdictIcon = compliance.isLegal
        ? Icons.check_circle_outline
        : compliance.isIllegal
            ? Icons.cancel_outlined
            : Icons.help_outline_rounded;
    final verdictColor = compliance.isLegal
        ? kGreen
        : compliance.isIllegal
            ? Colors.redAccent
            : kAmber;
    final confColor = scan.confidence >= 70 ? kGreen : kAmber;

    // Foto da espécie por nome
    final speciesPhotoMap = <String, String>{
      'robalo': 'https://images.unsplash.com/photo-1544979590-04bcee11af7d?w=400&q=75&auto=format',
      'dourada': 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&q=75&auto=format',
      'pargo': 'https://images.unsplash.com/photo-1499728603263-13726abce5fd?w=400&q=75&auto=format',
      'garoupa': 'https://images.unsplash.com/photo-1518568814500-bf0f8d125f46?w=400&q=75&auto=format',
      'sargo': 'https://images.unsplash.com/photo-1504700610630-ac6aba3536d3?w=400&q=75&auto=format',
    };
    final displayNome = species.nomeFor(es: t.es);
    final photoKey = displayNome.toLowerCase().split(' ').first;
    final speciesPhotoUrl = speciesPhotoMap[photoKey]
        ?? speciesPhotoMap['robalo']!;

    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kCyan.withValues(alpha: 0.15)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foto da espécie com overlay
          Stack(children: [
            _previewBytes != null
                ? Image.memory(_previewBytes!, width: double.infinity, height: 180, fit: BoxFit.cover)
                : netImg(speciesPhotoUrl, width: double.infinity, height: 180),
            Container(
              height: 180,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xF0000814), Colors.transparent],
                ),
              ),
            ),
            Positioned(
              bottom: 12, left: 14, right: 14,
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(displayNome, style: orb(18, fw: FontWeight.w900, ls: 0)),
                  Text(species.cientifico, style: ibm(11, c: kHint)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: confColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: confColor.withValues(alpha: 0.5)),
                    ),
                    child: Column(children: [
                      Text('${scan.confidence}%', style: orb(14, c: confColor, fw: FontWeight.w900, ls: 0)),
                      Text('CONF.', style: mono(7, c: confColor)),
                    ]),
                  ),
                ]),
              ]),
            ),
            // Badge legal
            Positioned(
              top: 12, left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: verdictColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: verdictColor.withValues(alpha: 0.5)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(verdictIcon, size: 12, color: verdictColor),
                  const SizedBox(width: 4),
                  Text(
                    compliance.isLegal ? '✅ Legal $cc' : compliance.isIllegal ? '❌ Ilegal $cc' : '⚠️ Verificar',
                    style: mono(9, c: verdictColor),
                  ),
                ]),
              ),
            ),
          ]),

          Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          if (scan.usedFallbackDemo && !isOpenAiConfigured)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Modo offline · define OPENAI_API_KEY',
                style: mono(9, c: kAmber),
              ),
            ),
          if (scan.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                scan.errorMessage!,
                style: ibm(10, c: kHint),
              ),
            ),
          const SizedBox(height: 12),
          Divider(color: kCyan.withValues(alpha: 0.08), height: 1),
          const SizedBox(height: 10),
          _row(
            t.es ? 'Longitud estimada' : 'Comprimento estimado',
            scan.lengthCm != null ? '${scan.lengthCm!.toStringAsFixed(0)} cm' : '—',
          ),
          _row(
            'Peso estimado',
            scan.weightKg != null ? '~${scan.weightKg!.toStringAsFixed(1)} kg' : '—',
          ),
          _row(
            'Mínimo legal ($cc)',
            '$minRule  ${compliance.isLegal ? '✓' : compliance.isIllegal ? '✗' : '?'}',
            vc: verdictColor,
          ),
          _row(t.es ? 'Cebo ideal' : 'Isco ideal', species.iscoDisplay),
          _row('Técnica', species.tecnicaDisplay),
          if (species.vedaAtiva) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.45)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.es
                          ? 'Especie con veda o restricciones en parte del año — confirma ${species.vedaFor(es: true)}.'
                          : 'Espécie com veda ou restrições em parte do ano — confirma ${species.vedaFor(es: false)}.',
                      style: ibm(11, c: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: verdictColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: verdictColor.withValues(alpha: 0.45)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(verdictIcon, size: 16, color: verdictColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(compliance.message, style: ibm(11, c: verdictColor)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Botões: Guardar + Partilhar
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: kCyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.save_outlined, size: 16),
                label: Text('GUARDAR', style: orb(9, c: Colors.black, fw: FontWeight.w700, ls: 1)),
                onPressed: () => _saveToLogbook(
                  context,
                  scan,
                  displayNome,
                  species.iscoDisplay,
                  compliance.isLegal,
                  compliance.isIllegal,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: kCyan.withValues(alpha: 0.4)),
                  foregroundColor: kCyan,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.ios_share_rounded, size: 16),
                label: Text(t.es ? 'COMPARTIR' : 'PARTILHAR', style: orb(9, c: kCyan, ls: 1)),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t.es ? 'Compartiendo en Comunidad… 👻' : 'A partilhar na Comunidade… 👻', style: ibm(13)), backgroundColor: kCard),
                ),
              ),
            ),
          ]),
        ],
          ),
        ),
        ],
      ),
    );
  }

  Widget _visionResultUnmatched(
    BuildContext context,
    VisionScanResult scan,
    String countryRaw,
  ) {
    final t = aqxL10nOf(context);
    final cc = countryRaw.toUpperCase();
    final confColor = scan.confidence >= 70 ? kGreen : kAmber;
    final raw = scan.rawScientific ?? '—';

    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kCyan.withValues(alpha: 0.15)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: kAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.help_outline_rounded, color: kAmber, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.es ? 'Especie fuera de la base local' : 'Espécie fora da base local', style: ibm(14, fw: FontWeight.w700)),
                    Text(raw, style: ibm(11, c: kHint)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: confColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: confColor.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    Text('${scan.confidence}%', style: orb(12, c: confColor, fw: FontWeight.w900, ls: 0)),
                    Text('conf.', style: mono(8, c: confColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _row(
            t.es ? 'Longitud estimada' : 'Comprimento estimado',
            scan.lengthCm != null ? '${scan.lengthCm!.toStringAsFixed(0)} cm' : '—',
          ),
          _row(
            'Peso estimado',
            scan.weightKg != null ? '~${scan.weightKg!.toStringAsFixed(1)} kg' : '—',
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kAmber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kAmber.withValues(alpha: 0.45)),
            ),
            child: Text(
              t.es
                  ? 'No encontramos coincidencia en el catálogo AQUANAUTIX ($cc). Confirma especie y medidas legales en fuentes oficiales.'
                  : 'Não encontrámos correspondência no catálogo AQUANAUTIX ($cc). Confirma espécie e medidas legais nas fontes oficiais.',
              style: ibm(11, c: kAmber),
            ),
          ),
        ],
      ),
    );
  }

  Widget _corner({bool flipH = false, bool flipV = false}) => Transform.scale(
        scaleX: flipH ? -1 : 1,
        scaleY: flipV ? -1 : 1,
        child: SizedBox(
          width: 20,
          height: 20,
          child: CustomPaint(painter: _CornerPainter()),
        ),
      );

  Widget _outlineBtn(IconData icon, String label, VoidCallback onTap) => GestureDetector(
        onTap: _state == _ScanState.scanning ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kCyan.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: kHint),
              const SizedBox(width: 6),
              Text(label, style: mono(10)),
            ],
          ),
        ),
      );

  Widget _row(String key, String val, {Color? vc}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(child: Text(key, style: ibm(12, c: kHint))),
            Text(val, style: ibm(12, c: vc ?? Colors.white, fw: FontWeight.w600)),
          ],
        ),
      );
}

enum _ScanState { idle, scanning, result }

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = kCyan
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(Offset.zero, Offset(size.width, 0), p);
    canvas.drawLine(Offset.zero, Offset(0, size.height), p);
  }

  @override
  bool shouldRepaint(_) => false;
}
