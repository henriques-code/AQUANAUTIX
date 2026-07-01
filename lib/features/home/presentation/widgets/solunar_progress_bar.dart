import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Barra de progresso animada para actividade solunar (0–100).
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              weakLabel,
              style: AppTextStyles.ibmSans(
                9,
                color: const Color(0xFFE53935),
                fw: FontWeight.w700,
                ls: 0.3,
              ),
            ),
            Text(
              excellentLabel,
              style: AppTextStyles.ibmSans(
                9,
                color: AppColors.green,
                fw: FontWeight.w700,
                ls: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            const double fishWidth = 52;
            final maxLeft = (constraints.maxWidth - fishWidth).clamp(0.0, constraints.maxWidth);
            final indicatorLeft = maxLeft * fraction;

            return SizedBox(
              height: 28,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 11,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFE53935),
                            AppColors.amber,
                            AppColors.green,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: indicatorLeft,
                    top: 0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int i = 0; i < 3; i++) ...[
                          ColorFiltered(
                            colorFilter: const ColorFilter.mode(
                              AppColors.accent,
                              BlendMode.srcIn,
                            ),
                            child: const Text('🐟', style: TextStyle(fontSize: 14)),
                          )
                              .animate(
                                onPlay: (c) => c.repeat(reverse: true),
                                delay: Duration(milliseconds: i * 220),
                              )
                              .moveY(
                                begin: 2,
                                end: -2,
                                duration: 800.ms,
                                curve: Curves.easeInOut,
                              ),
                          if (i < 2) const SizedBox(width: 1),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
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
