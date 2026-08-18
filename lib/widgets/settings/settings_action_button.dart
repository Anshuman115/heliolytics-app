import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_radii.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';

/// Compact icon + caps-label button used across the Settings sections.
class SettingsActionButton extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color color;
  final bool loading;
  final VoidCallback? onTap;

  const SettingsActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.loading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: HelioSpacing.md),
        decoration: BoxDecoration(
          color: enabled
              ? color.withValues(alpha: 0.14)
              : HelioColors.surfaceElevated,
          borderRadius: BorderRadius.circular(HelioRadii.card),
        ),
        child: Column(
          children: [
            if (loading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            else if (icon != null)
              Icon(
                icon,
                size: 22,
                color: enabled ? color : HelioColors.textMuted,
              ),
            const SizedBox(height: 6),
            Text(
              label,
              style: HelioTypography.capsLabel.copyWith(
                fontSize: 11,
                letterSpacing: 0,
                fontWeight: FontWeight.w700,
                color: enabled ? color : HelioColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
