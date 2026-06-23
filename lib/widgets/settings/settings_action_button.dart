import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
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
        padding: const EdgeInsets.symmetric(vertical: HelioSpacing.sm),
        decoration: BoxDecoration(
          color: enabled ? color.withValues(alpha: 0.12) : HelioColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? color.withValues(alpha: 0.3) : HelioColors.border,
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            if (loading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            else if (icon != null)
              Icon(icon, size: 18, color: enabled ? color : HelioColors.textMuted),
            const SizedBox(height: 4),
            Text(
              label,
              style: HelioTypography.capsLabel.copyWith(
                fontSize: 9,
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
