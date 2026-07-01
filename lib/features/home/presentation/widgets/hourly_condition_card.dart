import 'package:flutter/material.dart';

import '../../../../core/l10n/aqx_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/hourly_condition.dart';

/// Card horário do carrossel «Melhor Hora Hoje» (mockup).
class HourlyConditionCard extends StatelessWidget {
  const HourlyConditionCard({
    super.key,
    required this.item,
    required this.t,
    this.width = 88,
  });

  final HourlyCondition item;
  final AqxL10n t;
  final double width;

  static String _qualityLabel(AqxL10n t, int score) {
    if (score >= 32) return 'EXCELENTE';
    if (score >= 31) return t.es ? 'MUY BUENA' : 'MUITO BOA';
    if (score >= 29) return t.es ? 'BUENA' : 'BOA';
    if (score >= 27) return t.es ? 'MODERADA' : 'MODERADA';
    return t.es ? 'DÉBIL' : 'FRACA';
  }

  static Color _qualityColor(int score) {
    if (score >= 32) return AppColors.green;
    if (score >= 31) return AppColors.accent;
    if (score >= 29) return const Color(0xFF8BC34A);
    if (score >= 27) return AppColors.amber;
    return AppColors.textSecondary;
  }

  static int _starCount(int score) {
    if (score >= 32) return 5;
    if (score >= 31) return 5;
    if (score >= 29) return 4;
    if (score >= 27) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final label = _qualityLabel(t, item.displayScore);
    final color = _qualityColor(item.displayScore);
    final stars = _starCount(item.displayScore);

    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.isBestHour
                ? AppColors.accent.withValues(alpha: 0.75)
                : AppColors.accent.withValues(alpha: 0.15),
            width: item.isBestHour ? 1.5 : 1,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (item.isBestHour)
              const Positioned(
                top: -2,
                right: 2,
                child: Text('👑', style: TextStyle(fontSize: 12)),
              ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.hour,
                  style: AppTextStyles.ibmSans(11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.displayScore}',
                  style: AppTextStyles.orbitron(22, fw: FontWeight.w700, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: AppTextStyles.ibmSans(8, fw: FontWeight.w700, color: color, ls: 0.3),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 10,
                      color: AppColors.amber,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
