import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_metric_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/models/hr_sample.dart';
import 'package:heliolytics/models/metric_catalog.dart';
import 'package:heliolytics/utils/formatters.dart';
import 'package:heliolytics/utils/hr_chart_samples.dart';
import 'package:heliolytics/widgets/metric_stats_row.dart';
import 'package:heliolytics/widgets/minute_series_chart.dart';

class ContinuousHrMetricSection extends StatelessWidget {
  final DayMetric day;
  final List<HeartRateSample> samples;

  const ContinuousHrMetricSection({
    super.key,
    required this.day,
    required this.samples,
  });

  @override
  Widget build(BuildContext context) {
    final stats = MetricStats.fromHeartRate(samples);
    final latest = samples.isEmpty ? null : samples.last;
    final value = latest?.bpm.toString() ?? day.restingHr?.toString() ?? '—';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text(
            value,
            style: HelioTypography.scoreMedium.copyWith(
              fontSize: 48,
              color: HelioMetricColors.restingHr,
            ),
          ),
        ),
        if (latest != null)
          Center(
            child: Text(
              'Latest at ${formatChartTime(latest.sampledAt)}',
              style: HelioTypography.bodyMuted,
            ),
          ),
        const SizedBox(height: HelioSpacing.lg),
        MetricStatsRow(stats: stats, unit: 'bpm'),
        const SizedBox(height: HelioSpacing.md),
        HelioSurfaceCard(
          padding: const EdgeInsets.all(HelioSpacing.sm),
          child: samples.isEmpty
              ? Text(
                  MetricCatalog.byId('continuous_hr')!.detail,
                  style: HelioTypography.bodyMuted,
                )
              : MinuteSeriesChart(
                  samples: heartRateAsChartSamples(samples),
                  color: HelioMetricColors.restingHr,
                  unit: 'bpm',
                  height: 280,
                  maxPoints: 1200,
                  showDots: false,
                ),
        ),
        const SizedBox(height: HelioSpacing.md),
        HelioSurfaceCard(
          padding: const EdgeInsets.all(HelioSpacing.lg),
          child: Text(
            MetricCatalog.byId('continuous_hr')!.detail,
            style: HelioTypography.bodyMuted,
          ),
        ),
      ],
    );
  }
}
