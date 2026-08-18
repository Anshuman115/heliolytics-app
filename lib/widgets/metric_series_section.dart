import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/models/health_sample.dart';
import 'package:heliolytics/models/metric_catalog.dart';
import 'package:heliolytics/widgets/metric_stats_row.dart';
import 'package:heliolytics/widgets/minute_series_chart.dart';

class MetricSeriesSection extends StatelessWidget {
  final MetricDef definition;
  final DayMetric day;
  final List<HealthSample> samples;

  const MetricSeriesSection({
    super.key,
    required this.definition,
    required this.day,
    required this.samples,
  });

  @override
  Widget build(BuildContext context) {
    final stats = MetricStats.fromSamples(samples);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('AVERAGE', style: HelioTypography.capsLabel),
        const SizedBox(height: HelioSpacing.xs),
        Text(
          _average(stats.avg),
          style: HelioTypography.scoreLarge.copyWith(fontSize: 36),
        ),
        const SizedBox(height: HelioSpacing.lg),
        if (samples.isNotEmpty) ...[
          MetricStatsRow(
            stats: stats,
            unit: definition.unit,
            includeAverage: false,
          ),
          const SizedBox(height: HelioSpacing.md),
          HelioSurfaceCard(
            padding: const EdgeInsets.all(HelioSpacing.sm),
            child: MinuteSeriesChart(
              samples: samples,
              color: definition.color,
              unit: definition.unit,
              height: 220,
              maxPoints: 480,
            ),
          ),
        ] else
          HelioSurfaceCard(
            padding: const EdgeInsets.all(HelioSpacing.lg),
            child: Text(
              'Daily summary available. Minute samples were not recorded for this day.',
              style: HelioTypography.bodyMuted,
            ),
          ),
        const SizedBox(height: HelioSpacing.md),
        HelioSurfaceCard(
          padding: const EdgeInsets.all(HelioSpacing.lg),
          child: Text(definition.detail, style: HelioTypography.bodyMuted),
        ),
      ],
    );
  }

  String _average(double? value) {
    if (value == null) return _dailyValue() ?? '—';
    final formatted = definition.unit == '°C'
        ? value.toStringAsFixed(1)
        : value.round().toString();
    return definition.unit.isEmpty
        ? formatted
        : '$formatted ${definition.unit}';
  }

  String? _dailyValue() {
    final value = definition.summaryValue(day);
    if (value == '—') return null;
    return definition.unit.isEmpty ? value : '$value ${definition.unit}';
  }
}
