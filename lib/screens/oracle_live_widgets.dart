import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Glifo de peixe + bolhas — sincronizado com [animation] (ex.: repeat controller).
/// Sem ficheiros Lottie: zero dependência de rede/CDN; upgrade futuro: `lottie` com asset.
class OracleAnimatedFishGlyph extends StatelessWidget {
  const OracleAnimatedFishGlyph({
    super.key,
    required this.animation,
    required this.color,
    this.size = 46,
    /// Desloca o ciclo de nado (0–1) para escolas com vários peixes.
    this.phaseOffset = 0,
  });

  final Animation<double> animation;
  final Color color;
  final double size;
  final double phaseOffset;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final t = (animation.value + phaseOffset) % 1.0;
          return CustomPaint(
            size: Size(size, size),
            painter: _FishSwimPainter(t: t, color: color),
          );
        },
      ),
    );
  }
}

class _FishSwimPainter extends CustomPainter {
  _FishSwimPainter({required this.t, required this.color});

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Oscilação mais contida para não cortar cauda/cabeça em slots estreitos.
    final ox = math.sin(t * math.pi * 2) * 2.0;
    final oy = math.sin(t * math.pi * 4 + 0.4) * 1.6;
    final wobble = math.sin(t * math.pi * 2 + 0.2) * 0.09;

    final bodyPaint = Paint()
      ..color = color.withValues(alpha: 0.98)
      ..style = PaintingStyle.fill;
    final outline = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, size.shortestSide * 0.035)
      ..strokeJoin = StrokeJoin.round;

    canvas.save();
    canvas.translate(size.width * 0.5 + ox, size.height * 0.5 + oy);
    canvas.rotate(wobble);

    final body = Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: size.width * 0.52,
          height: size.height * 0.36,
        ),
      );
    canvas.drawPath(body, bodyPaint);
    canvas.drawPath(body, outline);

    final tailPaint = Paint()
      ..color = color.withValues(alpha: 0.88)
      ..style = PaintingStyle.fill;
    final tailOutline = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.9, size.shortestSide * 0.028)
      ..strokeJoin = StrokeJoin.round;
    final tail = Path()
      ..moveTo(-size.width * 0.22, 0)
      ..lineTo(-size.width * 0.46, -size.height * 0.15)
      ..lineTo(-size.width * 0.42, size.height * 0.15)
      ..close();
    canvas.drawPath(tail, tailPaint);
    canvas.drawPath(tail, tailOutline);

    final eyeR = math.max(2.2, size.shortestSide * 0.055);
    canvas.drawCircle(
      Offset(size.width * 0.13, -size.height * 0.055),
      eyeR,
      Paint()..color = Colors.white.withValues(alpha: 0.96),
    );
    canvas.drawCircle(
      Offset(size.width * 0.135, -size.height * 0.048),
      eyeR * 0.45,
      Paint()..color = color.withValues(alpha: 0.9),
    );

    canvas.restore();

    // Bolhas (coordenadas absolutas)
    for (var i = 0; i < 5; i++) {
      final bt = (t * 1.15 + i * 0.17) % 1.0;
      final bx = size.width * (0.62 + i * 0.055) + math.sin(bt * math.pi * 2 + i) * 2.5;
      final by = size.height * (0.88 - bt * 0.72);
      final a = 0.22 + 0.2 * math.sin(t * math.pi * 2 + i);
      canvas.drawCircle(
        Offset(bx, by),
        1.6 + i * 0.45,
        Paint()
          ..color = color.withValues(alpha: a)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FishSwimPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.color != color;
}
