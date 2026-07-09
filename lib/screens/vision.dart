import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '_shared.dart';
import '../core/config/openai_config.dart';
import '../core/monetization/subscription_gate.dart';
import '../core/state/subscription_store.dart';
import '../core/species/species_catalog.dart';
import '../core/species/species_compliance.dart';
import '../core/state/fishing_context_store.dart';
import '../core/vision/vision_climate_service.dart';
import '../core/vision/vision_climate_snapshot.dart';
import '../core/vision/vision_scan_result.dart';
import '../core/vision/vision_scan_service.dart';
import '../core/l10n/aqx_l10n.dart';
import 'widgets/vision_mockup_ui.dart';

// ══════════════════════════════════════════════════════════
// P2 — ECRÃ 03 · VISION SCANNER (mockup Jul 2026 + OpenAI)
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
  VisionMockupScanState _state = VisionMockupScanState.result;
  VisionScanResult? _scan;
  Uint8List? _previewBytes;
  VisionClimateSnapshot? _climate;
  bool _climateLoading = true;

  late final AnimationController _scanCtrl;
  late final Animation<double> _scanLine;
  late final AnimationController _confCtrl;
  late final Animation<double> _conf;

  @override
  void initState() {
    super.initState();

    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _scanLine = CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut);

    _confCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _conf = Tween<double>(begin: 0, end: 92).animate(
      CurvedAnimation(parent: _confCtrl, curve: Curves.easeOut),
    );
    _confCtrl.value = 1.0;

    _loadFreeUsage();
    _loadClimate();
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
    super.dispose();
  }

  Future<void> _loadClimate() async {
    setState(() => _climateLoading = true);
    try {
      final snap = await VisionClimateService.instance.fetch();
      if (!mounted) return;
      setState(() {
        _climate = snap;
        _climateLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _climateLoading = false);
    }
  }

  Future<void> _loadFreeUsage() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => _freeScansUsed = p.getInt(_kFreeScansKey) ?? 0);
  }

  Future<bool> _checkGateAndConsume() async {
    final isPro = SubscriptionStore.instance.value.value.hasProEntitlement;
    if (isPro) return true;

    if (_freeScansUsed < _kMaxFreeScans) {
      final p = await SharedPreferences.getInstance();
      await p.setInt(_kFreeScansKey, _freeScansUsed + 1);
      if (mounted) setState(() => _freeScansUsed++);
      return true;
    }

    if (mounted) {
      await SubscriptionGate.ensureProAccess(
        context,
        source: 'vision_free_limit',
      );
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
      _state = VisionMockupScanState.scanning;
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
        setState(() => _state = VisionMockupScanState.idle);
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
      _state = VisionMockupScanState.result;
    });
    unawaited(_loadClimate());
  }

  void _reset() {
    _scanCtrl.reset();
    _confCtrl.reset();
    setState(() {
      _state = VisionMockupScanState.idle;
      _previewBytes = null;
    });
  }

  Future<void> _saveToLogbook() async {
    final scan = _scan;
    if (scan?.matchedSpecies == null) return;

    final species = scan!.matchedSpecies!;
    final t = aqxL10nOf(context);
    final cc =
        FishingContextStore.instance.value.value.country.toUpperCase();
    final compliance = SpeciesCompliance.evaluateLength(
      species: species,
      country: cc,
      measuredLengthCm: scan.lengthCm,
      measuredWeightG: scan.weightG,
    );
    final displayNome = species.nomeFor(es: t.es);

    const prefsKey = 'logbook_capturas_v1';
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(prefsKey) ?? [];
    final tagColor = compliance.isLegal
        ? 'green'
        : (compliance.isIllegal ? 'amber' : 'cyan');
    final tag = compliance.isLegal
        ? 'LEGAL'
        : (compliance.isIllegal ? 'ILEGAL' : 'VERIFICAR');
    final pesoStr = scan.weightKg != null
        ? '${scan.weightKg!.toStringAsFixed(1)} kg'
        : '—';
    final detailsStr = scan.lengthCm != null
        ? '${scan.lengthCm!.toStringAsFixed(0)} cm'
        : '—';
    final entry = jsonEncode({
      'emoji': species.emoji,
      'nome': displayNome,
      'peso': pesoStr,
      'tag': tag,
      'tagColor': tagColor,
      'details': detailsStr,
      'isco': species.iscoDisplay,
      'temFoto': _previewBytes != null,
    });
    existing.insert(0, entry);
    await prefs.setStringList(prefsKey, existing);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          t.es ? 'Guardado en Diario ✓' : 'Guardado no Logbook ✓',
          style: ibm(13),
        ),
        backgroundColor: kCard,
      ),
    );
  }

  void _showPickSource() {
    if (_state == VisionMockupScanState.scanning) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: kHint.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _pickBtn(
                      Icons.photo_camera_outlined,
                      'CÂMARA',
                      () {
                        Navigator.pop(ctx);
                        _pickAndScan(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _pickBtn(
                      Icons.photo_library_outlined,
                      'GALERIA',
                      () {
                        Navigator.pop(ctx);
                        _pickAndScan(ImageSource.gallery);
                      },
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
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      left > 0
                          ? '$left scan${left == 1 ? '' : 's'} gratuito${left == 1 ? '' : 's'} restante${left == 1 ? '' : 's'}'
                          : 'Limite atingido — upgrade para PRO',
                      style: mono(10, c: left > 0 ? kHint : kAmber),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pickBtn(IconData icon, String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: kBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kCyan.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: kCyan),
              const SizedBox(width: 6),
              Text(label, style: mono(10, c: kCyan)),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<FishingContext>(
      valueListenable: FishingContextStore.instance.value,
      builder: (context, fishingCtx, _) {
        return SingleChildScrollView(
          child: VisionMockupLayout(
            scan: _scan,
            previewBytes: _previewBytes,
            scanState: _state,
            scanLine: _scanLine,
            confidence: _conf,
            country: fishingCtx.country,
            onCameraTap: _showPickSource,
            onDiscard: _reset,
            onSave: _saveToLogbook,
            climate: _climate,
            climateLoading: _climateLoading,
          ),
        );
      },
    );
  }
}
