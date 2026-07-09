import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/species/species_compliance.dart';
import '../../core/species/species_models.dart';
import '../../core/vision/vision_climate_snapshot.dart';
import '../../core/vision/vision_scan_result.dart';
import '../_shared.dart';

/// Asset hero do mockup Vision (pescador + robalo).
const kVisionMockupHeroAsset =
    'assets/marketing/catches/oracle_hero_pescador.jpg';

/// Layout do ecrã Vision — alinhado ao mockup AQUANAUTIX (Jul 2026).
class VisionMockupLayout extends StatelessWidget {
  const VisionMockupLayout({
    super.key,
    required this.scan,
    required this.previewBytes,
    required this.scanState,
    required this.scanLine,
    required this.confidence,
    required this.country,
    required this.onCameraTap,
    required this.onDiscard,
    required this.onSave,
    this.captureLocation = 'Cascais, Portugal',
    this.captureDateLabel,
    this.climate,
    this.climateLoading = false,
  });

  final VisionScanResult? scan;
  final Uint8List? previewBytes;
  final VisionMockupScanState scanState;
  final Animation<double> scanLine;
  final Animation<double> confidence;
  final String country;
  final VoidCallback onCameraTap;
  final VoidCallback onDiscard;
  final VoidCallback onSave;
  final String captureLocation;
  final String? captureDateLabel;
  final VisionClimateSnapshot? climate;
  final bool climateLoading;

  @override
  Widget build(BuildContext context) {
    final species = scan?.matchedSpecies;
    final showResult = scanState == VisionMockupScanState.result && species != null;
    final climateSnap = climate ?? VisionClimateSnapshot.demo;
    final locationLabel = climate?.locationLabel ?? captureLocation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        const _VisionScannerBadge(),
        const SizedBox(height: 10),
        _VisionHero(
          previewBytes: previewBytes,
          scanState: scanState,
          scanLine: scanLine,
          confidence: confidence,
          confidenceValue: scan?.confidence ?? 92,
          onCameraTap: onCameraTap,
        ),
        if (showResult) ...[
          const SizedBox(height: 14),
          _VisionSpeciesHeader(species: species),
          const SizedBox(height: 12),
          _VisionStatsRow(
            scan: scan!,
            species: species,
            country: country,
          ),
          const SizedBox(height: 12),
          _VisionInfoGrid(
            species: species,
            captureLocation: locationLabel,
            captureDateLabel: captureDateLabel ?? _defaultCaptureLabel(),
            climate: climateSnap,
            climateLoading: climateLoading,
          ),
          const SizedBox(height: 12),
          _VisionEquipmentSection(species: species),
          const SizedBox(height: 16),
          _VisionActionButtons(
            onDiscard: onDiscard,
            onSave: onSave,
          ),
        ] else if (scanState == VisionMockupScanState.idle) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'APONTAR PARA O PEIXE',
              style: mono(11, ls: 1.4),
              textAlign: TextAlign.center,
            ),
          ),
        ] else ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'A IDENTIFICAR...',
              style: mono(11, c: kCyan, ls: 1.4),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  static String _defaultCaptureLabel() {
    final now = DateTime.now();
    const months = [
      'JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN',
      'JUL', 'AGO', 'SET', 'OUT', 'NOV', 'DEZ',
    ];
    final d = now.day.toString().padLeft(2, '0');
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    return '$d ${months[now.month - 1]} ${now.year} • $h:$m';
  }
}

enum VisionMockupScanState { idle, scanning, result }

class _VisionScannerBadge extends StatelessWidget {
  const _VisionScannerBadge();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kCyan.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.center_focus_strong_rounded, size: 14, color: kCyan),
            const SizedBox(width: 6),
            Text('VISION SCANNER', style: orb(9, c: kCyan, fw: FontWeight.w700, ls: 1.2)),
          ],
        ),
      ),
    );
  }
}

class _VisionHero extends StatelessWidget {
  const _VisionHero({
    required this.previewBytes,
    required this.scanState,
    required this.scanLine,
    required this.confidence,
    required this.confidenceValue,
    required this.onCameraTap,
  });

  final Uint8List? previewBytes;
  final VisionMockupScanState scanState;
  final Animation<double> scanLine;
  final Animation<double> confidence;
  final int confidenceValue;
  final VoidCallback onCameraTap;

  @override
  Widget build(BuildContext context) {
    const heroHeight = 280.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: heroHeight,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (previewBytes != null)
                Image.memory(previewBytes!, fit: BoxFit.cover)
              else
                Image.asset(kVisionMockupHeroAsset, fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.35),
                    ],
                  ),
                ),
              ),
              Positioned(top: 12, left: 12, child: _corner()),
              Positioned(top: 12, right: 12, child: _corner(flipH: true)),
              Positioned(bottom: 12, left: 12, child: _corner(flipV: true)),
              Positioned(bottom: 12, right: 12, child: _corner(flipH: true, flipV: true)),
              if (scanState == VisionMockupScanState.scanning)
                AnimatedBuilder(
                  animation: scanLine,
                  builder: (_, __) => Positioned(
                    top: 24 + (scanLine.value * (heroHeight - 48)),
                    left: 24,
                    right: 24,
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
                        boxShadow: [
                          BoxShadow(color: kCyan.withValues(alpha: 0.6), blurRadius: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              if (scanState != VisionMockupScanState.idle)
                Positioned(
                  top: 12,
                  right: 12,
                  child: scanState == VisionMockupScanState.scanning
                      ? AnimatedBuilder(
                          animation: confidence,
                          builder: (_, __) => _confidenceBadge(confidence.value.toInt()),
                        )
                      : _confidenceBadge(confidenceValue),
                ),
              Positioned(
                bottom: 12,
                left: 12,
                child: GestureDetector(
                  onTap: scanState == VisionMockupScanState.scanning ? null : onCameraTap,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kBg.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kCyan.withValues(alpha: 0.35)),
                    ),
                    child: Icon(Icons.photo_camera_outlined, size: 18, color: kCyan),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _confidenceBadge(int pct) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: kBg.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kCyan.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('$pct%', style: orb(14, c: kCyan, fw: FontWeight.w900, ls: 0)),
            Text('CONFIANÇA', style: mono(7, c: kCyan)),
          ],
        ),
      );

  Widget _corner({bool flipH = false, bool flipV = false}) => Transform.scale(
        scaleX: flipH ? -1 : 1,
        scaleY: flipV ? -1 : 1,
        child: SizedBox(
          width: 22,
          height: 22,
          child: CustomPaint(painter: _CornerPainter()),
        ),
      );
}

class _VisionSpeciesHeader extends StatelessWidget {
  const _VisionSpeciesHeader({required this.species});

  final SpeciesRecord species;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            species.nomePT.toUpperCase(),
            style: orb(22, fw: FontWeight.w900, ls: 0.5),
          ),
          const SizedBox(height: 2),
          Text(species.cientifico, style: ibm(12, c: kHint, fw: FontWeight.w400)),
        ],
      ),
    );
  }
}

class _VisionStatsRow extends StatelessWidget {
  const _VisionStatsRow({
    required this.scan,
    required this.species,
    required this.country,
  });

  final VisionScanResult scan;
  final SpeciesRecord species;
  final String country;

  @override
  Widget build(BuildContext context) {
    final cc = country.toUpperCase();
    final compliance = SpeciesCompliance.evaluateLength(
      species: species,
      country: cc,
      measuredLengthCm: scan.lengthCm,
      measuredWeightG: scan.weightG,
    );
    final minRule = cc == 'ES' ? species.minES : species.minPT;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kCyan.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _statCell(
                icon: Icons.set_meal_outlined,
                value: scan.weightKg != null
                    ? '${scan.weightKg!.toStringAsFixed(2)} kg'
                    : '—',
                label: 'PESO ESTIMADO',
              ),
            ),
            _divider(),
            Expanded(
              child: _statCell(
                value: scan.lengthCm != null
                    ? '${scan.lengthCm!.toStringAsFixed(1)} cm'
                    : '—',
                label: 'COMPRIMENTO',
              ),
            ),
            _divider(),
            Expanded(
              child: _legalBadge(
                isLegal: compliance.isLegal,
                country: cc,
                minRule: minRule,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 36,
        color: kCyan.withValues(alpha: 0.12),
      );

  Widget _statCell({
    IconData? icon,
    required String value,
    required String label,
  }) =>
      Column(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: kCyan),
            const SizedBox(height: 4),
          ],
          Text(value, style: orb(11, fw: FontWeight.w800, ls: 0)),
          const SizedBox(height: 2),
          Text(label, style: mono(7, c: kHint), textAlign: TextAlign.center),
        ],
      );

  Widget _legalBadge({
    required bool isLegal,
    required String country,
    required String minRule,
  }) =>
      Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: kGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: kGreen.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isLegal ? Icons.check_circle_outline : Icons.cancel_outlined,
                  size: 11,
                  color: kGreen,
                ),
                const SizedBox(width: 3),
                Text(
                  isLegal ? 'LEGAL $country' : 'VERIFICAR',
                  style: mono(7, c: kGreen),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text('Min $minRule', style: mono(7, c: kHint)),
        ],
      );
}

class _VisionInfoGrid extends StatelessWidget {
  const _VisionInfoGrid({
    required this.species,
    required this.captureLocation,
    required this.captureDateLabel,
    required this.climate,
    required this.climateLoading,
  });

  final SpeciesRecord species;
  final String captureLocation;
  final String captureDateLabel;
  final VisionClimateSnapshot climate;
  final bool climateLoading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _infoCard(
                title: 'INFORMAÇÕES',
                child: _informacoesBody(species),
              )),
              const SizedBox(width: 10),
              Expanded(child: _infoCard(
                title: 'CLIMA',
                child: _climaBody(climate, climateLoading),
              )),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _infoCard(
                title: 'DICAS',
                child: _dicasBody(species),
              )),
              const SizedBox(width: 10),
              Expanded(child: _infoCard(
                title: 'REGISTO DE CAPTURA',
                child: _registoBody(captureDateLabel, captureLocation),
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoCard({required String title, required Widget child}) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kCyan.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: mono(8, c: kCyan, ls: 1)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      );

  Widget _informacoesBody(SpeciesRecord s) {
    final habitat = s.habitat == 'RIO' ? 'Rio / Barragem' : 'Costeiro / Estuários';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoLine('Habitat', habitat),
        _infoLine('Profundidade', '1–30 m'),
        _infoLine('Temperatura ideal', '12°C – 22°C'),
        _infoLine('Época', 'Outono – Primavera'),
        const SizedBox(height: 4),
        Row(
          children: [
            Text('Status IUCN: ', style: ibm(9, c: kHint)),
            Text('Pouco preocupante', style: ibm(9, c: kGreen, fw: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _climaBody(VisionClimateSnapshot snap, bool loading) {
    if (loading) {
      return SizedBox(
        height: 52,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: kCyan.withValues(alpha: 0.7),
            ),
          ),
        ),
      );
    }

    final temp = snap.temperatureC?.round() ?? 18;
    final wind = snap.windKmh != null
        ? '${snap.windKmh!.round()} km/h'
        : '—';
    final waves = snap.waveHeightM != null
        ? '${snap.waveHeightM!.toStringAsFixed(1)} m'
        : '—';
    final tide = snap.tideHeightM != null
        ? '${snap.tideHeightM!.toStringAsFixed(1)} m'
        : '—';
    final tideIcon =
        snap.tideRising ? Icons.trending_up : Icons.trending_down;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(_wmoIconData(snap.weatherCode), size: 16, color: kAmber),
            const SizedBox(width: 6),
            Text('$temp°C', style: orb(14, fw: FontWeight.w800, ls: 0)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                snap.conditionText,
                style: ibm(10, c: kHint),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _climaMini(Icons.air, wind),
            _climaMini(Icons.waves, waves),
            _climaMini(tideIcon, tide),
          ],
        ),
        if (snap.usedGps) ...[
          const SizedBox(height: 6),
          Text('GPS ao vivo', style: mono(7, c: kCyan)),
        ],
      ],
    );
  }

  IconData _wmoIconData(int? code) {
    if (code == null || code == 0) return Icons.wb_sunny_outlined;
    if (code <= 2) return Icons.wb_cloudy_outlined;
    if (code == 3) return Icons.cloud_outlined;
    if (code <= 55) return Icons.grain;
    if (code <= 67) return Icons.water_drop_outlined;
    if (code <= 77) return Icons.ac_unit;
    return Icons.thunderstorm_outlined;
  }

  Widget _climaMini(IconData icon, String val) => Column(
        children: [
          Icon(icon, size: 14, color: kCyan),
          const SizedBox(height: 2),
          Text(val, style: mono(8)),
        ],
      );

  Widget _dicasBody(SpeciesRecord s) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, size: 14, color: kAmber),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Espécie muito apreciada na pesca desportiva. '
              'Utiliza linha adequada e devolve o exemplar se não cumprir o mínimo legal. '
              '${s.iscoDisplay.isNotEmpty ? "Isco: ${s.iscoDisplay}." : ""}',
              style: ibm(9, c: kHint, fw: FontWeight.w400),
            ),
          ),
        ],
      );

  Widget _registoBody(String date, String location) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_camera_outlined, size: 12, color: kCyan),
              const SizedBox(width: 4),
              Expanded(child: Text(date, style: mono(8))),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 12, color: kHint),
              const SizedBox(width: 4),
              Expanded(child: Text(location, style: ibm(9, c: kHint))),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              'assets/marketing/catches/robalo.jpg',
              height: 48,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ],
      );

  Widget _infoLine(String key, String val) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: RichText(
          text: TextSpan(
            style: ibm(9, c: kHint),
            children: [
              TextSpan(text: '$key: ', style: ibm(9, c: kHint)),
              TextSpan(text: val, style: ibm(9, c: Colors.white)),
            ],
          ),
        ),
      );
}

class _VisionEquipmentSection extends StatelessWidget {
  const _VisionEquipmentSection({required this.species});

  final SpeciesRecord species;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kCyan.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('EQUIPAMENTO UTILIZADO', style: mono(8, c: kCyan, ls: 1)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _equipItem(Icons.sports, 'Vara', 'AX8 Ocean Pro')),
                Expanded(child: _equipItem(Icons.settings_outlined, 'Carreto', 'AX8 SW 6000')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _equipItem(
                    Icons.linear_scale,
                    'Linha',
                    species.cana.isNotEmpty ? 'Fluorocarbono' : '—',
                  ),
                ),
                Expanded(
                  child: _equipItem(
                    Icons.bubble_chart_outlined,
                    'Amostra',
                    species.isco.isNotEmpty ? species.isco.first : 'Amostra Natural',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _equipItem(IconData icon, String label, String value) => Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: kCyan.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, size: 14, color: kCyan),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: mono(7, c: kHint)),
                Text(value, style: ibm(10, fw: FontWeight.w600)),
              ],
            ),
          ),
        ],
      );
}

class _VisionActionButtons extends StatelessWidget {
  const _VisionActionButtons({
    required this.onDiscard,
    required this.onSave,
  });

  final VoidCallback onDiscard;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: kCyan.withValues(alpha: 0.5)),
                foregroundColor: kCyan,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: onDiscard,
              icon: const Icon(Icons.close_rounded, size: 18),
              label: Text('DESCARTAR', style: orb(9, c: kCyan, fw: FontWeight.w700, ls: 0.8)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: kCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: onSave,
              icon: const Icon(Icons.check_rounded, size: 18, color: Colors.black),
              label: Text('GUARDAR CAPTURA', style: orb(8, c: Colors.black, fw: FontWeight.w800, ls: 0.5)),
            ),
          ),
        ],
      ),
    );
  }
}

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
