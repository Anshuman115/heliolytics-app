import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';

class RecoveryBaselineLabel extends StatelessWidget {
  const RecoveryBaselineLabel({
    super.key,
    required this.value,
    required this.baseline,
    required this.higherIsBetter,
  });

  final double value;
  final double baseline;
  final bool? higherIsBetter;

  @override
  Widget build(BuildContext context) {
    final delta = value - baseline;
    final improving = higherIsBetter == null
        ? null
        : higherIsBetter!
        ? delta >= 0
        : delta <= 0;
    final color = improving == null
        ? HelioColors.recoveryMid
        : improving
        ? HelioColors.optimalGreen
        : HelioColors.recoveryLow;
    final icon = delta == 0
        ? Icons.remove
        : delta > 0
        ? Icons.arrow_upward
        : Icons.arrow_downward;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 2),
        Text(
          baseline.toStringAsFixed(0),
          style: HelioTypography.capsLabel.copyWith(
            fontSize: 9,
            color: HelioColors.textMuted,
          ),
        ),
      ],
    );
  }
}
