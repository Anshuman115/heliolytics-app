import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_radii.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';

class HomeMyDaySection extends StatelessWidget {
  final VoidCallback? onTap;

  const HomeMyDaySection({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: HelioSpacing.sm),
          child: Text('My Day', style: HelioTypography.body.copyWith(fontSize: 18)),
        ),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: HelioSpacing.lg,
              vertical: HelioSpacing.md,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(HelioRadii.card),
              gradient: LinearGradient(
                colors: [
                  HelioColors.outlookGold.withValues(alpha: 0.35),
                  HelioColors.surface,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              border: Border.all(color: HelioColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: HelioColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'H',
                      style: HelioTypography.body.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: HelioSpacing.md),
                Icon(Icons.wb_sunny_outlined, color: HelioColors.outlookGold, size: 20),
                const SizedBox(width: HelioSpacing.sm),
                Expanded(
                  child: Text(
                    'Your Daily Outlook',
                    style: HelioTypography.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Icon(Icons.chevron_right, color: HelioColors.textMuted, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
