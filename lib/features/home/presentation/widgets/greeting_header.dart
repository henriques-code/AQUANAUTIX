import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class GreetingHeader extends StatelessWidget {
  const GreetingHeader({
    super.key,
    required this.greetingLine,
    required this.tagline,
  });

  final String greetingLine;
  final String tagline;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(greetingLine, style: AppTextStyles.orbitron(22, fw: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(tagline, style: AppTextStyles.ibmSans(14, color: AppColors.textSecondary)),
      ],
    );
  }
}
