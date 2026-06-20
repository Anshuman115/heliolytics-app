import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_radii.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';

class SleepStageBar extends StatelessWidget {
  final int deep;
  final int rem;
  final int light;

  const SleepStageBar({
    super.key,
    required this.deep,
    required this.rem,
    required this.light,
  });

  @override
  Widget build(BuildContext context) {
    final total = (deep + rem + light).clamp(1, 99999);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(HelioRadii.pill),
          child: SizedBox(
            height: 16,
            child: Row(
              children: [
                _seg(HelioColors.sleepDeep, deep, total),
                _seg(HelioColors.sleepRem, rem, total),
                _seg(HelioColors.sleepLight, light, total),
              ],
            ),
          ),
        ),
        const SizedBox(height: HelioSpacing.sm),
        Row(
          children: [
            _legend('Deep', deep, HelioColors.sleepDeep),
            const SizedBox(width: HelioSpacing.md),
            _legend('REM', rem, HelioColors.sleepRem),
            const SizedBox(width: HelioSpacing.md),
            _legend('Light', light, HelioColors.sleepLight),
          ],
        ),
      ],
    );
  }

  Widget _seg(Color color, int mins, int total) {
    if (mins <= 0) return const SizedBox.shrink();
    return Expanded(
      flex: mins,
      child: Container(color: color),
    );
  }

  Widget _legend(String name, int mins, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$name ${mins}m',
          style: HelioTypography.capsLabel.copyWith(fontSize: 10),
        ),
      ],
    );
  }
}
