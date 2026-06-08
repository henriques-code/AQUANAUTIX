import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../_shared.dart';
import '../../features/home/domain/entities/hourly_condition.dart';

/// Timeline 12h — score de pesca + curva de maré sobreposta.
class OracleTimeline24h extends StatelessWidget {
  const OracleTimeline24h({
    super.key,
    required this.hours,
    required this.tideSparkline,
    this.title = 'PRÓXIMAS 12H · SCORE + MARÉ',
  });

  final List<HourlyCondition> hours;
  final List<double> tideSparkline;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (hours.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kCyan.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: mono(10, c: kCyan, ls: 0.9)),
          const SizedBox(height: 8),
          SizedBox(
            height: 88,
            width: double.infinity,
            child: CustomPaint(
              painter: _TimelinePainter(
                hours: hours,
                tideSparkline: tideSparkline,
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 52),
                child: Row(
                  children: [
                    for (var i = 0; i < hours.length; i++)
                      Expanded(
                        child: Text(
                          hours[i].hour.replaceAll(':00', 'h'),
                          style: mono(
                            7,
                            c: hours[i].isBestHour ? kAmber : kHint,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelinePainter extends CustomPainter {
  _TimelinePainter({
    required this.hours,
    required this.tideSparkline,
  });

  final List<HourlyCondition> hours;
  final List<double> tideSparkline;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    const barTop = 18.0;
    const barMaxH = 34.0;
    final n = hours.length;
    if (n == 0) return;

    final tide = _resampleTide(n);

    // Maré — linha ciano
    final tidePath = Path();
    for (var i = 0; i < n; i++) {
      final x = (i + 0.5) / n * w;
      final y = barTop + barMaxH - tide[i] * barMaxH * 0.85;
      if (i == 0) {
        tidePath.moveTo(x, y);
      } else {
        tidePath.lineTo(x, y);
      }
    }
    canvas.drawPath(
      tidePath,
      Paint()
        ..color = kCyan.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // Barras score
    final slotW = w / n;
    for (var i = 0; i < n; i++) {
      final score = hours[i].oracleScore.clamp(0, 100);
      final barH = barMaxH * (score / 100);
      final x = i * slotW + slotW * 0.18;
      final bw = slotW * 0.64;
      final isBest = hours[i].isBestHour;
      final color = isBest
          ? kAmber
          : Color.lerp(kHint, kCyan, score / 100)!;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, barTop + barMaxH - barH, bw, barH),
        const Radius.circular(3),
      );
      canvas.drawRRect(rect, Paint()..color = color.withValues(alpha: 0.85));

      if (isBest) {
        canvas.drawRRect(
          rect,
          Paint()
            ..color = kAmber
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      }

      final tp = TextPainter(
        text: TextSpan(
          text: '$score',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: isBest ? kAmber : Colors.white70,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x + bw / 2 - tp.width / 2, barTop - 2));
    }
  }

  List<double> _resampleTide(int n) {
    final raw = tideSparkline.length >= 4
        ? tideSparkline
        : List<double>.generate(12, (i) {
            return 0.5 + 0.4 * math.sin(i / 11 * math.pi * 2);
          });
    final minV = raw.reduce(math.min);
    final maxV = raw.reduce(math.max);
    final span = (maxV - minV).clamp(0.001, double.infinity);
    final out = <double>[];
    for (var i = 0; i < n; i++) {
      final t = i / (n - 1);
      final f = t * (raw.length - 1);
      final i0 = f.floor().clamp(0, raw.length - 1);
      final i1 = (i0 + 1).clamp(0, raw.length - 1);
      final frac = f - i0;
      final v = raw[i0] * (1 - frac) + raw[i1] * frac;
      out.add(((v - minV) / span).clamp(0.05, 0.98));
    }
    return out;
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter old) =>
      old.hours != hours || old.tideSparkline != tideSparkline;
}
