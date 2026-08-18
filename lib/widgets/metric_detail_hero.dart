import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/components/helio_score_ring.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/models/metric_catalog.dart';
import 'package:heliolytics/utils/metric_progress.dart';

class MetricDetailHero extends StatelessWidget {
  const MetricDetailHero({
    super.key,
    required this.definition,
    required this.day,
  });

  final MetricDef definition;
  final DayMetric day;

  @override
  Widget build(BuildContext context) {
    final color = definition.id == 'readiness'
        ? recoveryColorFor(day.readiness)
        : definition.color;
    return Padding(
      padding: const EdgeInsets.only(bottom: HelioSpacing.xl),
      child: Center(
        child: HelioScoreRing(
          size: HelioRingSize.heroXl,
          progress: _progress(),
          label: definition.title,
          value: definition.summaryValue(day),
          color: color,
          eyebrow: 'HELIOLYTICS',
          showChevron: false,
        ),
      ),
    );
  }

  double? _progress() => switch (definition.id) {
    'readiness' => metricProgress(MetricKind.readiness, day.readiness),
    'sleep' => metricProgress(MetricKind.sleep, day.sleepScore),
    'pai' => metricProgress(MetricKind.pai, day.paiScore),
    _ => null,
  };
}
