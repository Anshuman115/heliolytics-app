import 'package:flutter/material.dart';
import 'package:heliolytics/utils/formatters.dart';
import 'package:heliolytics/utils/metric_progress.dart';
import 'package:heliolytics/design_system/components/helio_score_ring.dart';
import 'package:heliolytics/design_system/components/helio_wordmark.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/models/day_metric.dart';

/// Overview header: three equal rings — Sleep, Recovery, Strain.
class HomePrimaryRings extends StatelessWidget {
  final DayMetric day;
  final void Function(String metricId) onRingTap;

  const HomePrimaryRings({
    super.key,
    required this.day,
    required this.onRingTap,
  });

  @override
  Widget build(BuildContext context) {
    final strain = day.paiScore;
    final recoveryColor = recoveryColorFor(day.readiness);

    return Padding(
      padding: const EdgeInsets.only(
        top: HelioSpacing.lg,
        bottom: HelioSpacing.lg,
      ),
      child: Column(
        children: [
          const HelioWordmark(),
          const SizedBox(height: HelioSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ring(
                  progress: metricProgress(MetricKind.sleep, day.sleepScore),
                  label: 'Sleep',
                  value: day.sleepScore != null ? '${day.sleepScore}%' : '—',
                  color: HelioColors.sleepBlue,
                  onTap: () => onRingTap('sleep'),
                ),
              ),
              Expanded(
                child: _ring(
                  progress: metricProgress(MetricKind.readiness, day.readiness),
                  label: 'Recovery',
                  value: day.readiness != null ? '${day.readiness}%' : '—',
                  color: recoveryColor,
                  onTap: () => onRingTap('readiness'),
                ),
              ),
              Expanded(
                child: _ring(
                  progress: metricProgress(MetricKind.pai, strain),
                  label: 'Strain',
                  value: formatStrainDecimal(strain),
                  color: HelioColors.strainBlue,
                  onTap: () => onRingTap('pai'),
                ),
              ),
            ],
          ),
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
}
