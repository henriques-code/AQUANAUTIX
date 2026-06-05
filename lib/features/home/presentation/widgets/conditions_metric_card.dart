import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/aqua_card.dart';

/// Card individual de métrica de condições (vento, ondas, maré, lua).
///
/// Suporta [bottomWidget] opcional para widgets adicionais abaixo do valor
/// (ex.: bússola animada no card de vento).
/// O separador inferior mantém-se sempre fixo no fundo via [Expanded].
class ConditionsMetricCard extends StatelessWidget {
  const ConditionsMetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.subValue,
    this.subValueColor,
    this.bottomWidget,
    this.semanticLabel,
  });

  final Widget icon;
  final String label;
  final String value;
  final String? subValue;
  final Color? subValueColor;

  /// Widget extra abaixo do valor (ex.: bússola). Se null, não renderiza.
  final Widget? bottomWidget;

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? '$label: $value',
      child: AquaCard(
        // Padding lateral; bottom = 0 porque o separador cola ao fundo
        padding: const EdgeInsets.fromLTRB(4, 5, 4, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Ícone
            SizedBox(
              width: 16,
              height: 16,
              child: Center(child: icon),
            ),
            const SizedBox(height: 3),

            // Label
            Text(
              label.toUpperCase(),
              style: AppTextStyles.ibmSans(
                7,
                color: AppColors.textSecondary,
                fw: FontWeight.w600,
                ls: 0.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),

            // Valor principal
            Text(
              value,
              style: AppTextStyles.orbitron(12, fw: FontWeight.w700),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // Sub-valor ou espaçador (só quando não há bottomWidget)
            if (subValue != null) ...[
              const SizedBox(height: 1),
              Text(
                subValue!,
                style: AppTextStyles.ibmSans(
                  8,
                  color: subValueColor ?? AppColors.accent,
                  fw: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ] else if (bottomWidget == null)
              const SizedBox(height: 11),

            // Widget extra (ex.: bússola)
            if (bottomWidget != null) ...[
              const SizedBox(height: 4),
              bottomWidget!,
            ],

            const SizedBox(height: 4),

            // Separador inferior com gradiente
            Container(
              height: 0.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.accent.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
