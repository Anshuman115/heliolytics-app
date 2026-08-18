import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';

class HelioProfileBadge extends StatelessWidget {
  final String? label;
  final VoidCallback? onTap;

  const HelioProfileBadge({super.key, this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: HelioColors.surfaceElevated,
        shape: BoxShape.circle,
        border: Border.all(
          color: HelioColors.canvasGlow.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: label == null
          ? const Icon(Icons.person, size: 18, color: HelioColors.textSecondary)
          : Center(
              child: Text(
                label!,
                style: const TextStyle(
                  color: HelioColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
    );
    if (onTap == null) return badge;
    return GestureDetector(onTap: onTap, child: badge);
  }
}
