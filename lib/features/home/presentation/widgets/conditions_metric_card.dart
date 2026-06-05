import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
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
        padding: const EdgeInsets.fromLTRB(AppSpacing.xs, 10, AppSpacing.xs, 0),
        child: Column(
          // mainAxisSize.max + Expanded = separa conteúdo do separador
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Conteúdo central — ocupa todo o espaço disponível
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ícone
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: Center(child: icon),
                  ),
                  const SizedBox(height: 6),

                  // Label
                  Text(
                    label.toUpperCase(),
                    style: AppTextStyles.ibmSans(
                      9,
                      color: AppColors.textSecondary,
                      fw: FontWeight.w600,
                      ls: 0.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Valor principal
                  Text(
                    value,
                    style: AppTextStyles.orbitron(15, fw: FontWeight.w700),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Sub-valor ou espaçador (só quando não há bottomWidget)
                  if (subValue != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subValue!,
                      style: AppTextStyles.ibmSans(
                        10,
                        color: subValueColor ?? AppColors.accent,
                        fw: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else if (bottomWidget == null)
                    const SizedBox(height: 15),

                  // Widget extra (ex.: bússola)
                  if (bottomWidget != null) ...[
                    const SizedBox(height: 7),
                    bottomWidget!,
                  ],
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Separador inferior com gradiente — sempre no fundo
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
