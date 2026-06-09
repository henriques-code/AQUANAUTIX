import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../_shared.dart';
import '../../core/tides/weather_details_snapshot.dart';

enum OracleFishingMetricKind {
  tide,
  wind,
  waves,
  tempWater,
  current,
  pressure,
  caudal,
  nivel,
  visibility,
}

class OracleFishingMetric {
  const OracleFishingMetric({
    required this.label,
    required this.value,
    this.sub = '',
    this.sparkline = const [],
    this.showSparkline = true,
    this.alert = false,
    this.kind,
  });

  final String label;
  final String value;
  final String sub;
  final List<double> sparkline;
  final bool showSparkline;
  final bool alert;
  final OracleFishingMetricKind? kind;
}

/// Grelha 2×3 — métricas críticas para pesca (fold do Oráculo).
class OracleFishingMetricsGrid extends StatelessWidget {
  const OracleFishingMetricsGrid({
    super.key,
    required this.metrics,
    this.onMetricTap,
  });

  final List<OracleFishingMetric> metrics;
  final ValueChanged<OracleFishingMetricKind>? onMetricTap;

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
        childAspectRatio: 0.88,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, i) => _MetricTile(
        metric: metrics[i],
        onTap: metrics[i].kind != null && onMetricTap != null
            ? () {
                HapticFeedback.selectionClick();
                onMetricTap!(metrics[i].kind!);
              }
            : null,
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric, this.onTap});

  final OracleFishingMetric metric;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = metric.alert
        ? kAmber.withValues(alpha: 0.55)
        : kCyan.withValues(alpha: 0.12);

    final child = Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      decoration: BoxDecoration(
        color: metric.alert
            ? kAmber.withValues(alpha: 0.06)
            : kCard,
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
              style: ibm(
                9,
                c: metric.alert
                    ? kAmber.withValues(alpha: 0.95)
                    : kCyan.withValues(alpha: 0.85),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const Spacer(),
          if (metric.showSparkline && metric.sparkline.length >= 2)
            SizedBox(
              height: 22,
              width: double.infinity,
              child: CustomPaint(
                painter: _MiniSparklinePainter(
                  values: metric.sparkline,
                  color: metric.alert ? kAmber : const Color(0xFF5B9BD5),
                ),
              ),
            ),
        ],
      ),
    );

    if (onTap == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: child,
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
    if (values.length < 2) return;

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
  required WeatherDetailsSnapshot? weather,
  required String tempWaterValue,
  required String tempWaterSub,
}) {
  final w = weather;
  final windKmh = w?.windSpeedKmh;
  final windVal =
      windKmh != null ? '${windKmh.round()} km/h' : '—';
  final windSub = WeatherDetailsSnapshot.windCardinalPt(w?.windDirDeg);
  final waveM = w?.waveHeightM;
  final waveVal = waveM != null ? '${waveM.toStringAsFixed(1)} m' : '—';
  final waveSub = w?.wavePeriodS != null
      ? '${w!.wavePeriodS!.round()} s'
      : '';
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
      showSparkline: false,
      kind: OracleFishingMetricKind.tide,
    ),
    OracleFishingMetric(
      label: 'VENTO',
      value: windVal,
      sub: windSub,
      sparkline: w?.windSparkline ?? const [],
      alert: windKmh != null && windKmh >= 25,
      kind: OracleFishingMetricKind.wind,
    ),
    OracleFishingMetric(
      label: 'ONDAS',
      value: waveVal,
      sub: waveSub,
      sparkline: w?.waveSparkline ?? const [],
      alert: waveM != null && waveM >= 2.0,
      kind: OracleFishingMetricKind.waves,
    ),
    OracleFishingMetric(
      label: 'TEMP. ÁGUA',
      value: tempWaterValue,
      sub: tempWaterSub,
      sparkline: w?.tempSparkline ?? const [],
      kind: OracleFishingMetricKind.tempWater,
    ),
    OracleFishingMetric(
      label: 'CORRENTE',
      value: currentVal,
      sub: currentSub,
      sparkline: w?.currentSparkline ?? const [],
      alert: currentKmh != null && currentKmh >= 15,
      kind: OracleFishingMetricKind.current,
    ),
    OracleFishingMetric(
      label: 'PRESSÃO',
      value: presVal,
      sub: w != null
          ? WeatherDetailsSnapshot.pressureTrendLabel(w.pressureSparkline)
          : '',
      sparkline: w?.pressureSparkline ?? const [],
      kind: OracleFishingMetricKind.pressure,
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
  final windKmh = w?.windSpeedKmh;
  final windVal =
      windKmh != null ? '${windKmh.round()} km/h' : '—';

  return [
    OracleFishingMetric(
      label: 'CAUDAL',
      value: caudalValue,
      sub: caudalSub,
      kind: OracleFishingMetricKind.caudal,
    ),
    OracleFishingMetric(
      label: 'NÍVEL',
      value: nivelValue,
      sub: nivelSub,
      kind: OracleFishingMetricKind.nivel,
    ),
    OracleFishingMetric(
      label: 'TEMP. ÁGUA',
      value: tempValue,
      sub: tempSub,
      sparkline: w?.tempSparkline ?? const [],
      kind: OracleFishingMetricKind.tempWater,
    ),
    OracleFishingMetric(
      label: 'VENTO',
      value: windVal,
      sub: WeatherDetailsSnapshot.windCardinalPt(w?.windDirDeg),
      sparkline: w?.windSparkline ?? const [],
      alert: windKmh != null && windKmh >= 25,
      kind: OracleFishingMetricKind.wind,
    ),
    OracleFishingMetric(
      label: 'VISIB.',
      value: visibValue,
      sub: '',
      kind: OracleFishingMetricKind.visibility,
    ),
    OracleFishingMetric(
      label: 'PRESSÃO',
      value: presVal,
      sub: w != null
          ? WeatherDetailsSnapshot.pressureTrendLabel(w.pressureSparkline)
          : '',
      sparkline: w?.pressureSparkline ?? const [],
      kind: OracleFishingMetricKind.pressure,
    ),
  ];
}
