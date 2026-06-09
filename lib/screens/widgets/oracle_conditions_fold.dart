import 'package:flutter/material.dart';

import '../_shared.dart';
import '../../features/home/domain/entities/hourly_condition.dart';
import 'oracle_fishing_metrics_grid.dart';
import 'oracle_timeline_24h.dart';

/// Card unificado — grelha 6 métricas + timeline 12h.
class OracleConditionsFold extends StatelessWidget {
  const OracleConditionsFold({
    super.key,
    required this.metrics,
    required this.hours,
    required this.tideSparkline,
    required this.timelineTitle,
    this.nowLabel = 'agora',
    this.onMetricTap,
  });

  final List<OracleFishingMetric> metrics;
  final List<HourlyCondition> hours;
  final List<double> tideSparkline;
  final String timelineTitle;
  final String nowLabel;
  final ValueChanged<OracleFishingMetricKind>? onMetricTap;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty && hours.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kCyan.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (metrics.isNotEmpty)
            OracleFishingMetricsGrid(
              metrics: metrics,
              onMetricTap: onMetricTap,
            ),
          if (metrics.isNotEmpty && hours.isNotEmpty) ...[
            const SizedBox(height: 10),
            Divider(
              height: 1,
              color: kCyan.withValues(alpha: 0.12),
            ),
            const SizedBox(height: 10),
          ],
          if (hours.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 4),
              child: OracleTimeline24h(
                hours: hours,
                tideSparkline: tideSparkline,
                title: timelineTitle,
                nowLabel: nowLabel,
              ),
            ),
        ],
      ),
    );
  }
}
