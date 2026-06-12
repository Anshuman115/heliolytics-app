import 'package:flutter/material.dart';
import 'package:heliolytics/core/theme/app_spacing.dart';
import 'package:heliolytics/core/theme/metric_colors.dart';
import 'package:heliolytics/features/health_data/domain/entities/health_sample.dart';
import 'package:heliolytics/features/health_data/presentation/widgets/minute_series_chart.dart';

class DaySeriesSection extends StatelessWidget {
  final String dayKey;
  final Map<String, List<HealthSample>> byMetric;

  const DaySeriesSection({super.key, required this.dayKey, required this.byMetric});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blocks = [
      _Block('Stress', '0–100 score per minute · lower is calmer', 'stress', MetricColors.stress, ''),
      _Block('Resting HR', 'Each device reading (bpm)', 'rhr', MetricColors.restingHr, 'bpm'),
      _Block('HRV', 'RMSSD readings (ms)', 'hrv', MetricColors.hrv, 'ms'),
      _Block('SpO₂', 'Spot readings (%)', 'spo2', MetricColors.spo2, '%'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final b in blocks) ...[
          _seriesBlock(context, theme, b),
          const SizedBox(height: AppSpacing.lg),
        ],
      ],
    );
  }

  Widget _seriesBlock(BuildContext context, ThemeData theme, _Block b) {
    final samples = (byMetric[b.metric] ?? []).where((s) => s.dayKey == dayKey).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(b.title, style: theme.textTheme.titleMedium),
        Text('${samples.length} readings · ${b.hint}', style: theme.textTheme.bodySmall),
        const SizedBox(height: AppSpacing.sm),
        MinuteSeriesChart(samples: samples, color: b.color, unit: b.unit),
      ],
    );
  }
}

class _Block {
  final String title, hint, metric, unit;
  final Color color;
  const _Block(this.title, this.hint, this.metric, this.color, this.unit);
}
