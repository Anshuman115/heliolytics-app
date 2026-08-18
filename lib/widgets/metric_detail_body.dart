import 'package:flutter/material.dart';
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
    if (definition.id == 'readiness') {
      return RecoveryMetricSection(day: bundle.day);
    }
    if (definition.id == 'continuous_hr') {
      return ContinuousHrMetricSection(
        day: bundle.day,
        samples: detail.heartRateFor(dayKey),
      );
    }
    if (definition.id == 'temperature') {
      return TemperatureMetricSection(samples: detail.tempFor(dayKey));
    }
    if (definition.id == 'pai') {
      return StrainMetricSection(
        definition: definition,
        day: bundle.day,
        heartRate: detail.heartRateFor(dayKey),
      );
    }
    if (definition.seriesKey case final key?) {
      return MetricSeriesSection(
        definition: definition,
        day: bundle.day,
        samples: detail.seriesFor(dayKey, key),
      );
    }
    return ScalarMetricSection(
      definition: definition,
      bundle: bundle,
      heartRate: detail.heartRateFor(dayKey),
    );
  }
}
