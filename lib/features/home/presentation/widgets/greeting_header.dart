import 'package:flutter/material.dart';

import '../../../../core/l10n/aqx_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class GreetingHeader extends StatelessWidget {
  const GreetingHeader({
    super.key,
    required this.greetingLine,
    required this.taglinePrefix,
    required this.taglineHighlight,
    required this.taglineSuffix,
    required this.location,
    this.onLocationTap,
  });

  final String greetingLine;
  final String taglinePrefix;
  final String taglineHighlight;
  final String taglineSuffix;
  final String location;
  final VoidCallback? onLocationTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greetingLine,
                style: AppTextStyles.orbitron(20, fw: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              RichText(
                text: TextSpan(
                  style: AppTextStyles.ibmSans(13, color: AppColors.textSecondary),
                  children: [
                    TextSpan(text: taglinePrefix),
                    TextSpan(
                      text: taglineHighlight,
                      style: AppTextStyles.ibmSans(
                        13,
                        color: AppColors.green,
                        fw: FontWeight.w700,
                      ),
                    ),
                    TextSpan(text: taglineSuffix),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _LocationPill(location: location, onTap: onLocationTap),
      ],
    );
  }
}

class _LocationPill extends StatelessWidget {
  const _LocationPill({required this.location, this.onTap});

  final String location;
  final VoidCallback? onTap;

  String get _display {
    return location.replaceAll(' · ', ', ').replaceAll(' | ', ', ');
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_rounded, size: 13, color: AppColors.accent),
              const SizedBox(width: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 110),
                child: Text(
                  _display,
                  style: AppTextStyles.ibmSans(10, fw: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tagline dinâmica conforme score do Oráculo.
(String, String, String) homeTaglineParts(AqxL10n t, int score) {
  if (score >= 65) {
    return (
      t.homeTaglineGoodPrefix,
      t.homeTaglineGoodHighlight,
      t.homeTaglineGoodSuffix,
    );
  }
  if (score >= 45) {
    return (
      t.homeTaglineOkPrefix,
      t.homeTaglineOkHighlight,
      t.homeTaglineOkSuffix,
    );
  }
  return (
    t.homeTaglineWeakPrefix,
    t.homeTaglineWeakHighlight,
    t.homeTaglineWeakSuffix,
  );
}

String indexGaugeLabel(AqxL10n t, int score) {
  if (score >= 80) return t.homeIndexExcellent;
  if (score >= 65) return t.homeIndexGood;
  if (score >= 45) return t.homeIndexModerate;
  return t.homeIndexWeak;
}
