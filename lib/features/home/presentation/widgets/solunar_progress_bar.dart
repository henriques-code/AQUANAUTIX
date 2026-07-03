import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Barra de actividade piscatória — layout mockup Início.
class SolunarProgressBar extends StatelessWidget {
  const SolunarProgressBar({
    super.key,
    required this.score,
    required this.qualityLabel,
    this.weakLabel = 'FRACA',
    this.excellentLabel = 'EXCELENTE',
    this.showScoreBadge = true,
  });

  final int score;
  final String qualityLabel;
  final String weakLabel;
  final String excellentLabel;
  final bool showScoreBadge;

  static const _barHeight = 9.0;
  static const _knobSize = 15.0;
  static const _fishAreaHeight = 22.0;

  static const _barGradient = LinearGradient(
    colors: [
      Color(0xFFFF5722),
      Color(0xFFFFB300),
      Color(0xFF4CAF50),
      Color(0xFF00E5FF),
    ],
    stops: [0.0, 0.35, 0.72, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: (score / 100).clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeOutCubic,
        builder: (context, fraction, _) => _SolunarBarContent(
          fraction: fraction,
          score: score,
          qualityLabel: qualityLabel,
          weakLabel: weakLabel,
          excellentLabel: excellentLabel,
          showScoreBadge: showScoreBadge,
        ),
      ),
    );
  }
}

class _SolunarBarContent extends StatelessWidget {
  const _SolunarBarContent({
    required this.fraction,
    required this.score,
    required this.qualityLabel,
    required this.weakLabel,
    required this.excellentLabel,
    required this.showScoreBadge,
  });

  final double fraction;
  final int score;
  final String qualityLabel;
  final String weakLabel;
  final String excellentLabel;
  final bool showScoreBadge;

  Color get _badgeColor {
    if (score >= 65) return AppColors.accent;
    return AppColors.amber;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final barWidth = constraints.maxWidth;
            final knobCenter = (barWidth * fraction).clamp(
              SolunarProgressBar._knobSize / 2,
              barWidth - SolunarProgressBar._knobSize / 2,
            );
            final fillWidth = knobCenter + SolunarProgressBar._knobSize / 2;
            const fishRowWidth = 54.0;
            final fishLeft = (knobCenter - fishRowWidth / 2)
                .clamp(0.0, barWidth - fishRowWidth);

            return SizedBox(
              height: SolunarProgressBar._fishAreaHeight +
                  SolunarProgressBar._barHeight +
                  2,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Peixes acima do indicador
                  Positioned(
                    left: fishLeft,
                    top: 0,
                    child: _FishCluster(),
                  ),
                  // Barra
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: SolunarProgressBar._barHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Trilho escuro (zona não preenchida)
                        Container(
                          height: SolunarProgressBar._barHeight,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(99),
                            color: const Color(0xFF0D1B2A).withValues(alpha: 0.85),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                        ),
                        // Preenchimento gradiente até ao knob
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: fillWidth.clamp(0.0, barWidth),
                              height: SolunarProgressBar._barHeight,
                              decoration: const BoxDecoration(
                                gradient: SolunarProgressBar._barGradient,
                              ),
                            ),
                          ),
                        ),
                        // Knob ciano com glow
                        Positioned(
                          left: knobCenter - SolunarProgressBar._knobSize / 2,
                          top: (SolunarProgressBar._barHeight -
                                  SolunarProgressBar._knobSize) /
                              2,
                          child: Container(
                            width: SolunarProgressBar._knobSize,
                            height: SolunarProgressBar._knobSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.accent,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withValues(alpha: 0.9),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                                BoxShadow(
                                  color: AppColors.accent.withValues(alpha: 0.45),
                                  blurRadius: 18,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              weakLabel,
              style: AppTextStyles.ibmSans(
                11,
                color: const Color(0xFFFF4C4C),
                fw: FontWeight.w700,
                ls: 0.5,
              ),
            ),
            Text(
              excellentLabel,
              style: AppTextStyles.ibmSans(
                11,
                color: const Color(0xFF00C853),
                fw: FontWeight.w700,
                ls: 0.5,
              ),
            ),
          ],
        ),
        if (showScoreBadge && qualityLabel.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$score', style: AppTextStyles.orbitron(15, fw: FontWeight.w700)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _badgeColor.withValues(alpha: 0.45)),
                ),
                child: Text(
                  qualityLabel,
                  style: AppTextStyles.ibmSans(
                    10,
                    color: _badgeColor,
                    fw: FontWeight.w700,
                    ls: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _FishCluster extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < 3; i++) ...[
          _FishIcon(
            bright: i == 1,
            delayMs: i * 200,
          ),
          if (i < 2) const SizedBox(width: 2),
        ],
      ],
    );
  }
}

class _FishIcon extends StatelessWidget {
  const _FishIcon({required this.bright, required this.delayMs});

  final bool bright;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    final color = bright ? AppColors.accent : const Color(0xFF007BFF);

    Widget fish = Container(
      decoration: bright
          ? BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.75),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            )
          : null,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        child: const Text('🐟', style: TextStyle(fontSize: 16, height: 1)),
      ),
    );

    return fish
        .animate(onPlay: (c) => c.repeat(reverse: true), delay: Duration(milliseconds: delayMs))
        .moveY(begin: 1.5, end: -1.5, duration: 900.ms, curve: Curves.easeInOut);
  }
}
