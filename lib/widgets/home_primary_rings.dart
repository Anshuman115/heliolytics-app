import 'package:flutter/material.dart';
import 'package:heliolytics/utils/formatters.dart';
import 'package:heliolytics/utils/metric_progress.dart';
import 'package:heliolytics/design_system/components/helio_score_ring.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/models/day_metric.dart';

class HomePrimaryRings extends StatelessWidget {
  final DayMetric day;
  final void Function(String metricId) onRingTap;

  const HomePrimaryRings({super.key, required this.day, required this.onRingTap});

  @override
  Widget build(BuildContext context) {
    final strain = day.paiScore ?? _strainFromSteps(day.steps);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: HelioSpacing.md),
      child: Row(
        children: [
          Expanded(child: _ring(
            progress: metricProgress(MetricKind.sleep, day.sleepScore),
            label: 'Sleep',
            value: day.sleepScore != null ? '${day.sleepScore}%' : '—',
            color: HelioColors.sleepBlue,
            onTap: () => onRingTap('sleep'),
          )),
          Expanded(child: _ring(
            progress: metricProgress(MetricKind.readiness, day.readiness),
            label: 'Recovery',
            value: day.readiness != null ? '${day.readiness}%' : '—',
            color: recoveryColorFor(day.readiness),
            onTap: () => onRingTap('readiness'),
          )),
          Expanded(child: _ring(
            progress: metricProgress(MetricKind.pai, strain),
            label: 'Strain',
            value: formatStrainDecimal(strain),
            color: HelioColors.strainBlue,
            onTap: () => onRingTap('pai'),
          )),
        ],
      ),
    );
  }

  Widget _ring({
    required double? progress,
    required String label,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Center(
      child: HelioScoreRing(
        size: HelioRingSize.triple,
        progress: progress,
        label: label,
        value: value,
        color: color,
        onTap: onTap,
      ),
    );
  }

  int? _strainFromSteps(int steps) {
    if (steps <= 0) return null;
    return (steps / 150).clamp(0, 100).round();
  }
}
