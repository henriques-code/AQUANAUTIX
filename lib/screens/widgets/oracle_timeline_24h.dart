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
    this.nowLabel = 'agora',
  });

  static const _chartHeight = 118.0;
  static const _labelTopPad = 72.0;

  final List<HourlyCondition> hours;
  final List<double> tideSparkline;
  final String title;
  final String nowLabel;

  @override
  Widget build(BuildContext context) {
    if (hours.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: mono(11, c: kCyan, ls: 0.9)),
        const SizedBox(height: 8),
        Row(
          children: [
            _LegendSwatch(color: kCyan, label: 'score', isBar: true),
            const SizedBox(width: 10),
            _LegendSwatch(
              color: kCyan.withValues(alpha: 0.45),
              label: 'maré',
              isBar: false,
            ),
            const SizedBox(width: 10),
            _LegendDot(label: nowLabel),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: _chartHeight,
          width: double.infinity,
          child: CustomPaint(
            painter: _TimelinePainter(
              hours: hours,
              tideSparkline: tideSparkline,
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: _labelTopPad),
              child: Row(
                children: [
                  for (var i = 0; i < hours.length; i++)
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hours[i].isCurrentHour)
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(bottom: 3),
                              decoration: const BoxDecoration(
                                color: kCyan,
                                shape: BoxShape.circle,
                              ),
                            ),
                          Text(
                            hours[i].hour.replaceAll(':00', 'h'),
                            style: mono(
                              9,
                              c: hours[i].isCurrentHour
                                  ? kCyan
                                  : hours[i].isBestHour
                                      ? kAmber
                                      : hours[i].isGoldenWindow
                                          ? kAmber.withValues(alpha: 0.75)
                                          : kHint,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendSwatch extends StatelessWidget {
  const _LegendSwatch({
    required this.color,
    required this.label,
    required this.isBar,
  });

  final Color color;
  final String label;
  final bool isBar;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isBar)
          Container(
            width: 8,
            height: 10,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(2),
            ),
          )
        else
          SizedBox(
            width: 14,
            height: 10,
            child: CustomPaint(
              painter: _LegendLinePainter(color: color),
            ),
          ),
        const SizedBox(width: 4),
        Text(label, style: mono(8, c: kHint)),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: kCyan,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: mono(8, c: kHint)),
      ],
    );
  }
}

class _LegendLinePainter extends CustomPainter {
  _LegendLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _LegendLinePainter old) =>
      old.color != color;
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
    const barTop = 22.0;
    const barMaxH = 44.0;
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
        ..strokeWidth = 2.4
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
      final isGolden = hours[i].isGoldenWindow;
      final color = isBest
          ? kAmber
          : isGolden
              ? Color.lerp(kAmber, kCyan, 0.35)!
              : Color.lerp(kHint, kCyan, score / 100)!;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, barTop + barMaxH - barH, bw, barH),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, Paint()..color = color.withValues(alpha: 0.85));

      if (isBest || isGolden) {
        canvas.drawRRect(
          rect,
          Paint()
            ..color = isBest ? kAmber : kAmber.withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = isBest ? 1.2 : 0.8,
        );
      }

      final tp = TextPainter(
        text: TextSpan(
          text: '$score',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isBest
                ? kAmber
                : isGolden
                    ? kAmber.withValues(alpha: 0.85)
                    : Colors.white70,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x + bw / 2 - tp.width / 2, barTop - 4));
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
