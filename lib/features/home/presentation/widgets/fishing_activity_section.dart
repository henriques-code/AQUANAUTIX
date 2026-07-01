import 'package:flutter/material.dart';

import '../../../../core/l10n/aqx_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'solunar_progress_bar.dart';

/// Bloco «ATIVIDADE PISCATÓRIA HOJE» separado do hero (mockup).
class FishingActivitySection extends StatelessWidget {
  const FishingActivitySection({
    super.key,
    required this.score,
    required this.t,
    required this.updatedAt,
    this.onRefresh,
  });

  final int score;
  final AqxL10n t;
  final DateTime updatedAt;
  final VoidCallback? onRefresh;

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                t.homeSectionActivity,
                style: AppTextStyles.orbitron(13, fw: FontWeight.w700, ls: 0.3),
              ),
            ),
            Text(
              '${t.homeUpdated} ${_formatTime(updatedAt)}',
              style: AppTextStyles.ibmSans(10, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRefresh,
              child: Icon(
                Icons.refresh_rounded,
                size: 16,
                color: AppColors.accent.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SolunarProgressBar(
          score: score,
          qualityLabel: '',
          showScoreBadge: false,
          weakLabel: t.es ? 'DÉBIL' : 'FRACA',
          excellentLabel: 'EXCELENTE',
        ),
      ],
    );
  }
}
