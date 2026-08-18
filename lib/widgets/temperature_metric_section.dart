import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/metric_catalog.dart';
import 'package:heliolytics/models/temp_sample.dart';
import 'package:heliolytics/widgets/metric_stats_row.dart';
import 'package:heliolytics/widgets/temperature_chart.dart';

class TemperatureMetricSection extends StatelessWidget {
  final List<TempSample> samples;

  const TemperatureMetricSection({super.key, required this.samples});

  @override
  Widget build(BuildContext context) {
    final stats = MetricStats.fromTemp(samples);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MetricStatsRow(stats: stats, unit: '°C'),
        const SizedBox(height: HelioSpacing.md),
        HelioSurfaceCard(
          padding: const EdgeInsets.all(HelioSpacing.sm),
          child: TemperatureChart(samples: samples, height: 280),
        ),
        const SizedBox(height: HelioSpacing.md),
        HelioSurfaceCard(
          padding: const EdgeInsets.all(HelioSpacing.lg),
          child: Text(
            MetricCatalog.byId('temperature')!.detail,
            style: HelioTypography.bodyMuted,
          ),
        ),
      ],
    );
  }
}
