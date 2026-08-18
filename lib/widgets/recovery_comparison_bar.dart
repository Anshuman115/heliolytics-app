import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/utils/formatters.dart';

class RecoveryComparisonBar extends StatelessWidget {
  const RecoveryComparisonBar({
    super.key,
    required this.dayKey,
    this.value,
    this.baseline,
    this.higherIsBetter = true,
  });

  final String dayKey;
  final num? value;
  final num? baseline;
  final bool higherIsBetter;

  @override
  Widget build(BuildContext context) => Container(
    height: 42,
    padding: const EdgeInsets.symmetric(horizontal: HelioSpacing.md),
    decoration: BoxDecoration(
      color: HelioColors.canvasBottom,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        _indicator(),
        const SizedBox(width: HelioSpacing.sm),
        Text(
          '${formatSleepComparisonDay(dayKey)} vs. last 30 days',
          style: HelioTypography.capsLabel.copyWith(
            color: HelioColors.textPrimary,
          ),
        ),
      ],
    ),
  );

  Widget _indicator() {
    if (value == null || baseline == null || value == baseline) {
      return const Icon(Icons.remove, color: HelioColors.textMuted);
    }
    final delta = value! - baseline!;
    final improving = higherIsBetter ? delta > 0 : delta < 0;
    return Icon(
      delta > 0 ? Icons.arrow_drop_up : Icons.arrow_drop_down,
      color: improving ? HelioColors.optimalGreen : HelioColors.recoveryMid,
    );
  }
}
