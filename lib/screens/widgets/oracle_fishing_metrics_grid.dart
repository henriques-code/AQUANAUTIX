import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../_shared.dart';
import '../../core/tides/weather_details_snapshot.dart';

class OracleFishingMetric {
  const OracleFishingMetric({
    required this.label,
    required this.value,
    this.sub = '',
    this.sparkline = const [],
    this.highlight = false,
  });

  final String label;
  final String value;
  final String sub;
  final List<double> sparkline;
  final bool highlight;
}

/// Grelha 2×3 — métricas críticas para pesca (fold do Oráculo).
class OracleFishingMetricsGrid extends StatelessWidget {
  const OracleFishingMetricsGrid({super.key, required this.metrics});

  final List<OracleFishingMetric> metrics;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.92,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, i) => _MetricTile(metric: metrics[i]),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});

  final OracleFishingMetric metric;

  @override
  Widget build(BuildContext context) {
    final borderColor = metric.highlight
        ? kCyan.withValues(alpha: 0.45)
        : kCyan.withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(metric.label, style: mono(8, c: kHint, ls: 0.5)),
          const SizedBox(height: 2),
          Text(
            metric.value,
            style: ibm(13, fw: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (metric.sub.isNotEmpty)
            Text(
              metric.sub,
              style: ibm(9, c: kCyan.withValues(alpha: 0.85)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const Spacer(),
          SizedBox(
            height: 22,
            width: double.infinity,
            child: CustomPaint(
              painter: _MiniSparklinePainter(
                values: metric.sparkline,
                color: metric.highlight ? kCyan : const Color(0xFF5B9BD5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniSparklinePainter extends CustomPainter {
  _MiniSparklinePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) {
      canvas.drawLine(
        Offset(0, size.height * 0.6),
        Offset(size.width, size.height * 0.6),
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..strokeWidth = 1.2,
      );
      return;
    }

    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final span = (maxV - minV).clamp(0.001, double.infinity);

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = i / (values.length - 1) * size.width;
      final norm = (values[i] - minV) / span;
      final y = size.height - norm * size.height * 0.85 - 2;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniSparklinePainter old) =>
      old.values != values || old.color != color;
}

/// Constrói as 6 métricas COSTA a partir do bundle + snapshot meteorológico.
List<OracleFishingMetric> buildCostaFishingMetrics({
  required String tideValue,
  required String tideSub,
  required List<double> tideSparkline,
  required WeatherDetailsSnapshot? weather,
  required String tempWaterValue,
  required String tempWaterSub,
}) {
  final w = weather;
  final windVal = w?.windSpeedKmh != null
      ? '${w!.windSpeedKmh!.round()} km/h'
      : '—';
  final windSub = WeatherDetailsSnapshot.windCardinalPt(w?.windDirDeg);
  final waveVal = w?.waveHeightM != null
      ? '${w!.waveHeightM!.toStringAsFixed(1)} m'
      : '—';
  final presVal =
      w?.pressureHpa != null ? '${w!.pressureHpa!.round()} hPa' : '—';
  final currentKmh = WeatherDetailsSnapshot.currentKmh(w?.oceanCurrentMs);
  final currentVal = currentKmh != null
      ? '${currentKmh.toStringAsFixed(1)} km/h'
      : '—';
  final currentSub =
      WeatherDetailsSnapshot.windCardinalPt(w?.oceanCurrentDirDeg);

  return [
    OracleFishingMetric(
      label: 'MARÉ',
      value: tideValue,
      sub: tideSub,
      sparkline: tideSparkline,
    ),
    OracleFishingMetric(
      label: 'VENTO',
      value: windVal,
      sub: windSub,
      sparkline: w?.tempSparkline ?? const [],
    ),
    OracleFishingMetric(
      label: 'ONDAS',
      value: waveVal,
      sub: '',
      sparkline: w?.tideSparkline ?? const [],
    ),
    OracleFishingMetric(
      label: 'TEMP. ÁGUA',
      value: tempWaterValue,
      sub: tempWaterSub,
      sparkline: w?.tempSparkline ?? const [],
      highlight: true,
    ),
    OracleFishingMetric(
      label: 'CORRENTE',
      value: currentVal,
      sub: currentSub,
      sparkline: w?.currentSparkline ?? const [],
      highlight: true,
    ),
    OracleFishingMetric(
      label: 'PRESSÃO',
      value: presVal,
      sub: w != null
          ? WeatherDetailsSnapshot.pressureTrendLabel(w.pressureSparkline)
          : '',
      sparkline: w?.pressureSparkline ?? const [],
    ),
  ];
}

List<OracleFishingMetric> buildRioFishingMetrics({
  required String caudalValue,
  required String caudalSub,
  required String nivelValue,
  required String nivelSub,
  required String tempValue,
  required String tempSub,
  required String visibValue,
  required WeatherDetailsSnapshot? weather,
}) {
  final w = weather;
  final presVal =
      w?.pressureHpa != null ? '${w!.pressureHpa!.round()} hPa' : '—';
  final windVal = w?.windSpeedKmh != null
      ? '${w!.windSpeedKmh!.round()} km/h'
      : '—';

  return [
    OracleFishingMetric(label: 'CAUDAL', value: caudalValue, sub: caudalSub),
    OracleFishingMetric(label: 'NÍVEL', value: nivelValue, sub: nivelSub),
    OracleFishingMetric(
      label: 'TEMP. ÁGUA',
      value: tempValue,
      sub: tempSub,
      highlight: true,
    ),
    OracleFishingMetric(
      label: 'VENTO',
      value: windVal,
      sub: WeatherDetailsSnapshot.windCardinalPt(w?.windDirDeg),
    ),
    OracleFishingMetric(
      label: 'VISIB.',
      value: visibValue,
      sub: '',
    ),
    OracleFishingMetric(
      label: 'PRESSÃO',
      value: presVal,
      sub: w != null
          ? WeatherDetailsSnapshot.pressureTrendLabel(w.pressureSparkline)
          : '',
      sparkline: w?.pressureSparkline ?? const [],
    ),
  ];
}
