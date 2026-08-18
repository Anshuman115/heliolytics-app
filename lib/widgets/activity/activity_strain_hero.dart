import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/components/helio_score_ring.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/utils/formatters.dart';
import 'package:heliolytics/utils/metric_progress.dart';

class ActivityStrainHero extends StatelessWidget {
  const ActivityStrainHero({super.key, required this.day, required this.onTap});

  final DayMetric day;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strain = day.paiScore;
    return Center(
      child: HelioScoreRing(
        size: HelioRingSize.hero,
        progress: metricProgress(MetricKind.pai, strain),
        label: 'Strain',
        value: formatStrainDecimal(strain),
        color: HelioColors.strainBlue,
        eyebrow: 'HELIOLYTICS',
        showChevron: false,
        onTap: onTap,
      ),
    );
  }
}
