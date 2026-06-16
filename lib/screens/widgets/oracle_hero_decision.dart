import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../_shared.dart';

/// Asset hero fixo do mockup (pescador AQUANAUTIX + robalo na mão).
const kOracleMockupHeroAsset =
    'assets/marketing/catches/oracle_hero_pescador.jpg';

/// Hero — foto fullwidth + score pulse + janela + mini-mapa (mockup).
class OracleHeroScoreCard extends StatelessWidget {
  const OracleHeroScoreCard({
    super.key,
    this.heroImageAsset = kOracleMockupHeroAsset,
    required this.score,
    required this.statusLabel,
    required this.windowHours,
    required this.windowPrefix,
    required this.onViewMap,
    required this.pulse,
    this.mapLat,
    this.mapLon,
    this.mapIsPlanning = false,
    this.mapIsRio = false,
    this.mapLabel = 'VER MAPA',
    this.loading = false,
  });

  final String heroImageAsset;
  final int score;
  final String statusLabel;
  final String windowHours;
  final String windowPrefix;
  final VoidCallback onViewMap;
  final Animation<double> pulse;
  final double? mapLat;
  final double? mapLon;
  final bool mapIsPlanning;
  final bool mapIsRio;
  final String mapLabel;
  final bool loading;

  static const _arcgisSatellite =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

  Widget _heroImage() {
    return Image.asset(
      heroImageAsset,
      fit: BoxFit.cover,
      alignment: const Alignment(0, -0.05),
      errorBuilder: (_, __, ___) => Container(
        color: kCard,
        alignment: Alignment.center,
        child: const Icon(Icons.phishing_rounded, color: kHint, size: 48),
      ),
    );
  }

  Widget _mapThumb() {
    final lat = mapLat;
    final lon = mapLon;
    if (lat == null || lon == null) {
      return _mapFallback();
    }

    final center = LatLng(lat, lon);
    return GestureDetector(
      onTap: onViewMap,
      child: SizedBox(
        width: 92,
        height: 68,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: FlutterMap(
                options: MapOptions(
                  backgroundColor: kBg,
                  initialCenter: center,
                  initialZoom: mapIsPlanning ? 11.0 : 12.5,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: mapIsRio
                        ? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
                        : _arcgisSatellite,
                    userAgentPackageName: 'com.example.aquanautix',
                    maxNativeZoom: 19,
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: center,
                        width: 28,
                        height: 28,
                        child: AnimatedBuilder(
                          animation: pulse,
                          builder: (context, _) {
                            final t =
                                0.5 + 0.5 * math.sin(pulse.value * math.pi * 2);
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 22 + 8 * t,
                                  height: 22 + 8 * t,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: kCyan.withValues(alpha: 0.18 * t),
                                  ),
                                ),
                                Icon(
                                  mapIsPlanning
                                      ? Icons.place_rounded
                                      : Icons.my_location_rounded,
                                  color: kCyan,
                                  size: 18,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.78),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(8),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 2),
                alignment: Alignment.center,
                child: Text(mapLabel, style: mono(6.5, c: kCyan, ls: 0.3)),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kCyan.withValues(alpha: 0.45)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mapFallback() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onViewMap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 92,
          height: 68,
          decoration: BoxDecoration(
            color: kBg.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kCyan.withValues(alpha: 0.45)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.map_outlined, size: 20, color: kCyan),
              Text(mapLabel, style: mono(7, c: kCyan, ls: 0.3)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scoreRing() {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final t = 0.5 + 0.5 * math.sin(pulse.value * math.pi * 2);
        final glow = 0.35 + 0.3 * t;
        return SizedBox(
          width: 86,
          height: 86,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: kCyan.withValues(alpha: 0.5 + 0.35 * t),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kCyan.withValues(alpha: glow),
                      blurRadius: 14 + 12 * t,
                      spreadRadius: 1.5,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 74,
                height: 74,
                child: CircularProgressIndicator(
                  value: loading ? null : score.clamp(0, 100) / 100,
                  strokeWidth: 3.2,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(kCyan),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    loading ? '—' : '$score',
                    style: orb(24, c: Colors.white, fw: FontWeight.w900),
                  ),
                  Text(
                    statusLabel.toUpperCase(),
                    style: mono(7, c: kCyan, ls: 0.4),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _heroImage(),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  kBg.withValues(alpha: 0.35),
                  kBg.withValues(alpha: 0.95),
                ],
                stops: const [0.35, 0.72, 1.0],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _scoreRing(),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          windowPrefix,
                          style: orb(13, c: kAmber, fw: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          windowHours,
                          style: orb(20, c: kAmber, fw: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ),
                _mapThumb(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tabs + card espécie — mockup (pills + Alvo/Isco/Cana).
class OracleSpeciesTargetCard extends StatelessWidget {
  const OracleSpeciesTargetCard({
    super.key,
    required this.speciesCodes,
    required this.selectedSpecies,
    required this.speciesLabelFor,
    required this.onSpeciesSelected,
    required this.targetSpecies,
    required this.bait,
    required this.rodTechnique,
  });

  final List<String> speciesCodes;
  final String selectedSpecies;
  final String Function(String code) speciesLabelFor;
  final ValueChanged<String> onSpeciesSelected;
  final String targetSpecies;
  final String bait;
  final String rodTechnique;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < speciesCodes.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                _SpeciesPill(
                  label: speciesLabelFor(speciesCodes[i]),
                  selected: selectedSpecies.toUpperCase() ==
                      speciesCodes[i].toUpperCase(),
                  onTap: () => onSpeciesSelected(speciesCodes[i]),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kCyan.withValues(alpha: 0.2)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -8,
                top: 0,
                bottom: 0,
                width: 120,
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _TopoWavePainter(),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _rigLine(Icons.gps_fixed_rounded, 'Alvo:', targetSpecies),
                  _rigLine(Icons.phishing_rounded, 'Isco:', bait),
                  _rigLine(Icons.sports_rounded, 'Cana:', rodTechnique),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _rigLine(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: kCyan),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: '$label ', style: ibm(12, c: kCyan)),
                  TextSpan(
                    text: value,
                    style: ibm(13, c: Colors.white, fw: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeciesPill extends StatelessWidget {
  const _SpeciesPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected ? kCyan.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(
            color: selected ? kCyan : kHint.withValues(alpha: 0.35),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: ibm(
            13,
            c: selected ? kCyan : kHint,
            fw: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _TopoWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kCyan.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (var w = 0; w < 5; w++) {
      final path = ui.Path();
      final baseY = size.height * (0.15 + w * 0.17);
      path.moveTo(0, baseY);
      for (var x = 0.0; x <= size.width; x += 4) {
        final y = baseY + math.sin((x / size.width) * math.pi * 2 + w) * 6;
        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// CTAs — IR PESCAR (52px) + REGISTAR CAPTURA (44px outline).
class OracleMockupCtas extends StatelessWidget {
  const OracleMockupCtas({
    super.key,
    required this.onGoFish,
    required this.onRegisterCatch,
    this.goFishLabel = 'IR PESCAR ->',
    this.registerLabel = 'REGISTAR CAPTURA',
  });

  final VoidCallback onGoFish;
  final VoidCallback onRegisterCatch;
  final String goFishLabel;
  final String registerLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 52,
          width: double.infinity,
          child: Material(
            color: kCyan,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onGoFish,
              borderRadius: BorderRadius.circular(10),
              child: Center(
                child: Text(
                  goFishLabel,
                  style: ibm(15, c: kBg, fw: FontWeight.w800),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 44,
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onRegisterCatch,
            style: OutlinedButton.styleFrom(
              foregroundColor: kCyan,
              side: BorderSide(color: kCyan.withValues(alpha: 0.9)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.videocam_outlined, size: 18),
            label: Text(
              registerLabel,
              style: ibm(14, c: kCyan, fw: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

/// Hero costa — sempre foto do mockup.
String oracleHeroAssetForSpecies(String code, {required bool isRio}) {
  if (isRio) return 'assets/marketing/spots/sesimbra.jpg';
  return kOracleMockupHeroAsset;
}
