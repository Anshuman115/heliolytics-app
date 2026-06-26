import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/components/helio_metric_bar.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';

/// Sleep-performance breakdown: each bar coloured by its quality tier,
/// with a Poor / Sufficient / Optimal legend underneath.
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HelioMetricBar(
          label: 'Hours vs needed',
          percent: hoursPct,
          color: qualityTierColor(hoursPct),
        ),
        const SizedBox(height: HelioSpacing.md),
        HelioMetricBar(
          label: 'Sleep efficiency',
          percent: effPct,
          color: qualityTierColor(effPct),
        ),
        const SizedBox(height: HelioSpacing.lg),
        const _TierLegend(),
      ],
    );
  }
}

class _TierLegend extends StatelessWidget {
  const _TierLegend();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _LegendDot(label: 'Poor', color: HelioColors.recoveryLow),
        SizedBox(width: HelioSpacing.lg),
        _LegendDot(label: 'Sufficient', color: HelioColors.recoveryMid),
        SizedBox(width: HelioSpacing.lg),
        _LegendDot(label: 'Optimal', color: HelioColors.optimalGreen),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: HelioTypography.capsLabel.copyWith(fontSize: 10),
        ),
      ],
    );
  }
}
