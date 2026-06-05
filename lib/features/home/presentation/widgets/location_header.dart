import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Header de localização com ícone GPS animado (pulse), separador | elegante
/// e hora local actualizada em tempo real.
class LocationHeader extends StatefulWidget {
  const LocationHeader({super.key, required this.location});

  final String location;

  @override
  State<LocationHeader> createState() => _LocationHeaderState();
}

class _LocationHeaderState extends State<LocationHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late Timer _clock;
  late String _time;

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  void initState() {
    super.initState();
    _time = _formatTime(DateTime.now());
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _time = _formatTime(DateTime.now()));
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _clock.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Divide "Sesimbra · SETÚBAL" em partes pelo separador · ou |
    String primary = widget.location;
    String? secondary;
    final sepMatch = RegExp(r'[·|]').firstMatch(widget.location);
    if (sepMatch != null) {
      primary = widget.location.substring(0, sepMatch.start).trim();
      secondary = widget.location.substring(sepMatch.end).trim();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Ícone GPS com pulse subtil
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) => Icon(
            Icons.location_on_rounded,
            size: 14,
            color: AppColors.accent.withValues(
              alpha: 0.45 + _pulseCtrl.value * 0.55,
            ),
          ),
        ),
        const SizedBox(width: 5),

        // Texto de localização: "Sesimbra | SETÚBAL"
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  primary,
                  style: AppTextStyles.ibmSans(
                    12,
                    color: AppColors.textPrimary,
                    fw: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (secondary != null && secondary.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  width: 1,
                  height: 11,
                  color: AppColors.accent.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    secondary,
                    style: AppTextStyles.ibmSans(
                      11,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(width: AppSpacing.xs),

        // Hora local em tempo real
        Text(
          _time,
          style: AppTextStyles.orbitron(
            11,
            fw: FontWeight.w400,
            color: AppColors.accent.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
