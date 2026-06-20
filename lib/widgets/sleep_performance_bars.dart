import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/components/helio_metric_bar.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';

class SleepPerformanceBars extends StatelessWidget {
  final int? sleepMins;
  final int? sleepScore;
  final int neededMins;

  const SleepPerformanceBars({
    super.key,
    this.sleepMins,
    this.sleepScore,
    this.neededMins = 480,
  });

  @override
  Widget build(BuildContext context) {
    final hoursPct = sleepMins != null
        ? ((sleepMins! / neededMins) * 100).round().clamp(0, 100)
        : 0;
    final effPct = sleepScore?.clamp(0, 100) ?? 0;

    return Column(
      children: [
        HelioMetricBar(
          label: 'Hours vs needed',
          percent: hoursPct,
          color: HelioColors.sleepBlue,
        ),
        const SizedBox(height: HelioSpacing.md),
        HelioMetricBar(
          label: 'Sleep efficiency',
          percent: effPct,
          color: HelioColors.optimalGreen,
        ),
      ],
    );
  }
}
