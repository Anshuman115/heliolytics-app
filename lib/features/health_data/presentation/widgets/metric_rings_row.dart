import 'package:flutter/material.dart';
import 'package:heliolytics/core/theme/app_spacing.dart';
import 'package:heliolytics/core/theme/metric_colors.dart';
import 'package:heliolytics/core/utils/metric_progress.dart';
import 'package:heliolytics/features/health_data/domain/entities/day_metric.dart';
import 'package:heliolytics/features/health_data/presentation/widgets/metric_ring.dart';

class MetricRingsRow extends StatelessWidget {
  final DayMetric day;
  final void Function(String metricId)? onRingTap;

  const MetricRingsRow({super.key, required this.day, this.onRingTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      _RingData('Sleep', '${day.sleepScore ?? '—'}', null, MetricKind.sleep, day.sleepScore, MetricColors.sleep, 'sleep'),
      _RingData('Stress', '${day.stressAvg ?? '—'}', 'latest', MetricKind.stress, day.stressAvg, MetricColors.stress, 'stress'),
      _RingData('HRV', '${day.hrvRmssd ?? '—'}', 'ms', MetricKind.hrv, day.hrvRmssd, MetricColors.hrv, 'hrv'),
      _RingData('PAI', '${day.paiScore ?? '—'}', null, MetricKind.pai, day.paiScore, MetricColors.pai, 'pai'),
      _RingData('RHR', '${day.restingHr ?? '—'}', 'bpm', MetricKind.restingHr, day.restingHr, MetricColors.restingHr, 'rhr'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.lg),
            GestureDetector(
              onTap: onRingTap == null ? null : () => onRingTap!(items[i].metricId),
              child: MetricRing(
                label: items[i].label,
                value: items[i].value,
                unit: items[i].unit,
                progress: metricProgress(items[i].kind, items[i].raw),
                color: items[i].color,
              ),
            ),
          ],
          const SizedBox(width: AppSpacing.md),
        ],
      ),
    );
  }
}

class _RingData {
  final String label, value, metricId;
  final String? unit;
  final MetricKind kind;
  final int? raw;
  final Color color;
  const _RingData(this.label, this.value, this.unit, this.kind, this.raw, this.color, this.metricId);
}
