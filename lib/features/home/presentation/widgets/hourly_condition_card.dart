import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/aqua_card.dart';
import '../../domain/entities/hourly_condition.dart';

class HourlyConditionCard extends StatelessWidget {
  const HourlyConditionCard({super.key, required this.item});

  final HourlyCondition item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 75,
      child: AquaCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        borderRadius: 12,
        borderAlpha: 0.45,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item.hour, style: AppTextStyles.ibmSans(12, fw: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(item.weatherIcon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text('${item.temperature.round()}°C', style: AppTextStyles.ibmSans(12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
