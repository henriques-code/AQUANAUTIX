import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Barra de progresso animada para actividade solunar (0–100).
///
/// Gradiente amber (fraco) → cyan (excelente) com indicador com glow.
/// Entrada animada via [TweenAnimationBuilder] em 1.2 s.
/// Envolto em [RepaintBoundary] para isolar a animação.
class SolunarProgressBar extends StatelessWidget {
  const SolunarProgressBar({
    super.key,
    required this.score,
    required this.qualityLabel,
    this.weakLabel = 'FRACA',
    this.excellentLabel = 'EXCELENTE',
  });

  final int score;
  final String qualityLabel;
  final String weakLabel;
  final String excellentLabel;

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
  });

  final double fraction;
  final int score;
  final String qualityLabel;
  final String weakLabel;
  final String excellentLabel;

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
        // Labels extremidades + título central
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  weakLabel,
                  style: AppTextStyles.ibmSans(
                    9,
                    color: AppColors.amber,
                    fw: FontWeight.w700,
                    ls: 0.3,
                  ),
                ),
                // Peixes animados com bob escalonado
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < 3; i++) ...[
                      Text(
                        i == 1 ? '🐠' : '🐟',
                        style: const TextStyle(fontSize: 13),
                      )
                          .animate(
                            onPlay: (c) => c.repeat(reverse: true),
                            delay: Duration(milliseconds: i * 280),
                          )
                          .moveY(
                            begin: 1.5,
                            end: -1.5,
                            duration: 900.ms,
                            curve: Curves.easeInOut,
                          ),
                      if (i < 2) const SizedBox(width: 3),
                    ],
                  ],
                ),
                Text(
                  excellentLabel,
                  style: AppTextStyles.ibmSans(
                    9,
                    color: AppColors.accent,
                    fw: FontWeight.w700,
                    ls: 0.3,
                  ),
                ),
              ],
            ),
        const SizedBox(height: 7),

        // Barra com gradiente + indicador com glow
        LayoutBuilder(
          builder: (context, constraints) {
            const double dotSize = 14.0;
            final double fillWidth =
                (constraints.maxWidth * fraction).clamp(0.0, constraints.maxWidth);

            return SizedBox(
              height: dotSize,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Track (fundo)
                  Positioned(
                    top: (dotSize - 8) / 2,
                    bottom: (dotSize - 8) / 2,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                  ),

                  // Fill gradiente
                  if (fillWidth > 0)
                    Positioned(
                      top: (dotSize - 8) / 2,
                      bottom: (dotSize - 8) / 2,
                      left: 0,
                      width: fillWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: const LinearGradient(
                            colors: [AppColors.amber, AppColors.accent],
                          ),
                        ),
                      ),
                    ),

                  // Indicador circular com glow
                  if (fraction > 0)
                    Positioned(
                      left: (fillWidth - dotSize / 2)
                          .clamp(0.0, constraints.maxWidth - dotSize),
                      top: 0,
                      child: Container(
                        width: dotSize,
                        height: dotSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.65),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 8),

        // Score + badge de qualidade
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '$score',
              style: AppTextStyles.orbitron(18, fw: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _badgeColor.withValues(alpha: 0.45),
                ),
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
    );
  }
}
