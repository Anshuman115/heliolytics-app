import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';

class HelioWizardStepHeader extends StatelessWidget {
  final int step;
  final int totalSteps;
  final String title;

  const HelioWizardStepHeader({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(totalSteps, (i) {
            final active = i < step;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  right: i == totalSteps - 1 ? 0 : HelioSpacing.xs,
                ),
                height: 3,
                color: active ? HelioColors.sleepBlue : HelioColors.border,
              ),
            );
          }),
        ),
        const SizedBox(height: HelioSpacing.md),
        Text('STEP $step OF $totalSteps', style: HelioTypography.capsLabel),
        const SizedBox(height: HelioSpacing.xs),
        Text(title, style: HelioTypography.sectionTitle),
      ],
    );
  }
}
