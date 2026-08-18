import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';

/// Sleep-performance breakdown: each bar coloured by its quality tier,
/// with a Poor / Sufficient / Optimal legend underneath.
class SleepPerformanceBars extends StatelessWidget {
  final int? sleepMins;
  final int? sleepEfficiency;
  final int? highSleepStress;
  final int neededMins;

  const SleepPerformanceBars({
    super.key,
    this.sleepMins,
    this.sleepEfficiency,
    this.highSleepStress,
    this.neededMins = 480,
  });

  @override
  Widget build(BuildContext context) {
    final hoursPct = sleepMins != null
        ? ((sleepMins! / neededMins) * 100).round().clamp(0, 100)
        : 0;
    final effPct = sleepEfficiency?.clamp(0, 100) ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _factor(Icons.nights_stay_outlined, 'Hours vs. needed', hoursPct),
        const Divider(height: HelioSpacing.xl, color: HelioColors.border),
        _factor(Icons.bedtime_outlined, 'Sleep efficiency', effPct),
        if (highSleepStress case final stress?) ...[
          const Divider(height: HelioSpacing.xl, color: HelioColors.border),
          _factor(
            Icons.speed_outlined,
            'High sleep stress',
            stress,
            lowerIsBetter: true,
          ),
        ],
        const SizedBox(height: HelioSpacing.lg),
        const _TierLegend(),
      ],
    );
  }

  Widget _factor(
    IconData icon,
    String label,
    int percent, {
    bool lowerIsBetter = false,
  }) => Row(
    children: [
      Icon(icon, size: 23, color: HelioColors.textSecondary),
      const SizedBox(width: HelioSpacing.md),
      Expanded(
        child: Text(label.toUpperCase(), style: HelioTypography.capsLabel),
      ),
      _marks(percent, lowerIsBetter: lowerIsBetter),
      const SizedBox(width: HelioSpacing.md),
      Text(
        '$percent%',
        style: HelioTypography.scoreMedium.copyWith(fontSize: 24),
      ),
    ],
  );

  Widget _marks(int percent, {bool lowerIsBetter = false}) {
    final adjusted = lowerIsBetter ? 100 - percent : percent;
    final color = qualityTierColor(adjusted);
    final active = adjusted >= 67
        ? 2
        : adjusted >= 34
        ? 1
        : 0;
    return Row(
      children: [
        for (var index = 0; index < 3; index++)
          Container(
            width: 24,
            height: 6,
            margin: EdgeInsets.only(left: index == 0 ? 0 : 4),
            decoration: BoxDecoration(
              color: index == active
                  ? color
                  : HelioColors.textMuted.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
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
