import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _kAmber = Color(0xFFF3C64D);
const _kGreen = Color(0xFF00D26A);
const _kHint = Color(0xFF8AADBE);

/// Anel de score 0–100 — partilhado entre Oráculo, spots e sheets.
class OracleScoreRing extends StatelessWidget {
  const OracleScoreRing({
    super.key,
    required this.score,
    this.size = 52,
    this.strokeWidth = 3.5,
    this.showLabel = true,
  });

  final int score;
  final double size;
  final double strokeWidth;
  final bool showLabel;

  Color get _accent {
    if (score >= 75) return _kGreen;
    if (score >= 50) return _kAmber;
    return const Color(0xFFFF4444);
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _OracleScoreRingPainter(
        score: score.clamp(0, 100),
        strokeWidth: strokeWidth,
        accent: _accent,
      ),
      child: showLabel
          ? SizedBox(
              width: size,
              height: size,
              child: Center(
                child: Text(
                  '$score',
                  style: GoogleFonts.orbitron(
                    fontSize: size * 0.28,
                    fontWeight: FontWeight.w900,
                    color: _accent,
                    height: 1,
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _OracleScoreRingPainter extends CustomPainter {
  const _OracleScoreRingPainter({
    required this.score,
    required this.strokeWidth,
    required this.accent,
  });

  final int score;
  final double strokeWidth;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = _kHint.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    final sweep = 2 * math.pi * (score / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _OracleScoreRingPainter old) =>
      old.score != score || old.accent != accent;
}
