import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Card de superfície Midnight Deep Sea (substitui padrões glass ad-hoc).
class AquaCard extends StatelessWidget {
  const AquaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 16,
    this.borderAlpha = 0.3,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double borderAlpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.accent.withValues(alpha: borderAlpha)),
      ),
      child: child,
    );
  }
}
