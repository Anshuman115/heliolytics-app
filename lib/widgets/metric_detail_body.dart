import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/day_bundle.dart';
import 'package:heliolytics/models/metric_catalog.dart';
import 'package:heliolytics/providers/detail_metrics_provider.dart';
import 'package:heliolytics/widgets/continuous_hr_metric_section.dart';
import 'package:heliolytics/widgets/metric_series_section.dart';
import 'package:heliolytics/widgets/recovery_metric_section.dart';
import 'package:heliolytics/widgets/scalar_metric_section.dart';
import 'package:heliolytics/widgets/sleep_metric_body.dart';
import 'package:heliolytics/widgets/strain_metric_section.dart';
import 'package:heliolytics/widgets/temperature_metric_section.dart';

class MetricDetailBody extends StatelessWidget {
  final MetricDef definition;
  final DayBundle bundle;
  final DetailMetrics detail;
  final String dayKey;

  const MetricDetailBody({
    super.key,
    required this.definition,
    required this.bundle,
    required this.detail,
    required this.dayKey,
  });

  @override
  Widget build(BuildContext context) {
    if (definition.id == 'sleep') {
      return SleepMetricBody(
        bundle: bundle,
        dayKey: dayKey,
        stressSamples: detail.seriesFor(dayKey, 'stress'),
      );
    }
    final day = bundle.day;
    if (definition.id == 'readiness') {
      if (day == null) return const _NoDayData();
      return RecoveryMetricSection(day: day);
    }
    if (definition.id == 'continuous_hr') {
      return ContinuousHrMetricSection(
        day: day,
        samples: detail.heartRateFor(dayKey),
      );
    }
    if (definition.id == 'temperature') {
      return TemperatureMetricSection(samples: detail.tempFor(dayKey));
    }
    if (definition.id == 'pai') {
      return ScalarMetricSection(definition: definition, bundle: bundle);
    }
    if (definition.id == 'load') {
      if (day == null) return const _NoDayData();
      return StrainMetricSection(
        definition: definition,
        day: day,
        heartRate: detail.heartRateFor(dayKey),
      );
    }
    if (definition.seriesKey case final key?) {
      return MetricSeriesSection(
        definition: definition,
        day: day,
        samples: detail.seriesFor(dayKey, key),
      );
    }
    return ScalarMetricSection(definition: definition, bundle: bundle);
  }
}

class _NoDayData extends StatelessWidget {
  const _NoDayData();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: HelioSpacing.xl),
    child: Text(
      'No metrics were stored for this day.',
      style: HelioTypography.bodyMuted,
    ),
  );
}
