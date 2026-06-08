import 'package:flutter/material.dart';

import '../_shared.dart';
import 'aqx_pressable.dart';

/// Card «Decisão do Oráculo» — score, janela, razões, CTAs.
class OracleDecisionCard extends StatelessWidget {
  const OracleDecisionCard({
    super.key,
    required this.score,
    required this.statusLabel,
    required this.windowHours,
    required this.reasons,
    required this.onRegisterCatch,
    required this.onViewMap,
    this.speciesTarget = '',
    this.registerLabel = 'REGISTAR CAPTURA',
    this.mapLabel = 'VER NO MAPA',
    this.title = 'DECISÃO DO ORÁCULO',
    this.windowPrefix = 'Melhor janela:',
  });

  final int score;
  final String statusLabel;
  final String windowHours;
  final List<String> reasons;
  final VoidCallback onRegisterCatch;
  final VoidCallback onViewMap;
  final String speciesTarget;
  final String registerLabel;
  final String mapLabel;
  final String title;
  final String windowPrefix;

  Color _scoreColor(int s) {
    if (s >= 80) return kGreen;
    if (s >= 65) return kCyan;
    if (s >= 45) return const Color(0xFF5CADBE);
    return kHint;
  }

  @override
  Widget build(BuildContext context) {
    final accent = _scoreColor(score);
    final reasonsShown = reasons.where((r) => r.trim().isNotEmpty).take(3).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kCyan.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: kCyan.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: mono(10, c: kCyan, ls: 1.1)),
          if (speciesTarget.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.set_meal_outlined, size: 14, color: kCyan.withValues(alpha: 0.9)),
                const SizedBox(width: 5),
                Text(
                  'Alvo: $speciesTarget',
                  style: ibm(12, c: kCyan, fw: FontWeight.w600),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 82,
                height: 82,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 82,
                      height: 82,
                      child: CircularProgressIndicator(
                        value: score.clamp(0, 100) / 100,
                        strokeWidth: 4,
                        backgroundColor: kCyan.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color.lerp(kAmber, kCyan, score / 100) ?? kCyan,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$score', style: orb(24, fw: FontWeight.w900)),
                        Text(
                          statusLabel.toUpperCase(),
                          style: mono(7, c: accent, ls: 0.4),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      windowPrefix,
                      style: ibm(11, c: kHint),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      windowHours,
                      style: ibm(14, c: kAmber, fw: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    for (final r in reasonsShown)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: 14, color: accent.withValues(alpha: 0.9)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(r, style: ibm(12, c: Colors.white70)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AqxNeonButton(
                  label: registerLabel,
                  icon: Icons.camera_alt_outlined,
                  onTap: onRegisterCatch,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AqxGlassButton(
                  label: mapLabel,
                  icon: Icons.map_outlined,
                  onTap: onViewMap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
