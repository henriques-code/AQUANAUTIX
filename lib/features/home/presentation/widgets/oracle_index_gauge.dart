import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Gauge circular do índice piscatório (mockup Início).
class OracleIndexGauge extends StatelessWidget {
  const OracleIndexGauge({
    super.key,
    required this.score,
    required this.label,
    this.size = 96,
  });

  final int score;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fraction = (score / 100).clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size + 22,
      child: Column(
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _GaugePainter(fraction: fraction),
              child: Center(
                child: Text(
                  '$score',
                  style: AppTextStyles.orbitron(26, fw: FontWeight.w700),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: AppTextStyles.ibmSans(
              8,
              fw: FontWeight.w700,
              ls: 0.4,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.fraction});

  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const startAngle = math.pi * 0.75;
    const sweep = math.pi * 1.5;

    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweep,
      false,
      track,
    );

    final gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweep,
      colors: const [
        Color(0xFFE53935),
        AppColors.amber,
        AppColors.green,
      ],
    );
    final arc = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweep * fraction,
      false,
      arc,
    );

    final dotAngle = startAngle + sweep * fraction;
    final dot = Offset(
      center.dx + radius * math.cos(dotAngle),
      center.dy + radius * math.sin(dotAngle),
    );
    canvas.drawCircle(
      dot,
      5,
      Paint()..color = AppColors.accent,
    );
    canvas.drawCircle(
      dot,
      8,
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) => old.fraction != fraction;
}
