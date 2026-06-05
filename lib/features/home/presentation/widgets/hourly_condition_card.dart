import 'package:flutter/material.dart';

import '../../../../core/l10n/aqx_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/hourly_condition.dart';

/// Chip horário compacto — score Oráculo + destaque na melhor hora.
class HourlyConditionCard extends StatelessWidget {
  const HourlyConditionCard({
    super.key,
    required this.item,
    required this.t,
  });

  final HourlyCondition item;
  final AqxL10n t;

  static Color _scoreColor(int score) {
    if (score >= 80) return AppColors.qualityExcelente;
    if (score >= 65) return AppColors.accent;
    if (score >= 45) return AppColors.amber;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = _scoreColor(item.oracleScore);
    final borderColor = item.isBestHour
        ? AppColors.amber
        : AppColors.accent.withValues(alpha: 0.12);

    return Semantics(
      label: '${item.hour}: score ${item.oracleScore}'
          '${item.isBestHour ? ", melhor hora" : ""}',
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: borderColor,
            width: item.isBestHour ? 1.5 : 0.8,
          ),
          color: item.isBestHour
              ? AppColors.amber.withValues(alpha: 0.06)
              : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.hour,
              style: AppTextStyles.ibmSans(
                10,
                color: AppColors.textSecondary,
                fw: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${item.oracleScore}',
              style: AppTextStyles.orbitron(
                18,
                fw: FontWeight.w700,
                color: scoreColor,
              ),
            ),
            const SizedBox(height: 3),
            // Mini barra de score
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: (item.oracleScore / 100).clamp(0.0, 1.0),
                minHeight: 3,
                backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
              ),
            ),
            if (item.isBestHour) ...[
              const SizedBox(height: 4),
              Text(
                t.es ? 'MEJOR' : 'MELHOR',
                style: AppTextStyles.ibmSans(
                  7,
                  color: AppColors.amber,
                  fw: FontWeight.w700,
                  ls: 0.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
