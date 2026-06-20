import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_radii.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';

class HelioVitalTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? status;
  final Color? statusColor;
  final VoidCallback? onTap;

  const HelioVitalTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.status,
    this.statusColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HelioColors.surfaceElevated,
      borderRadius: BorderRadius.circular(HelioRadii.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HelioRadii.card),
        child: Padding(
          padding: const EdgeInsets.all(HelioSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: HelioColors.textSecondary),
                  const Spacer(),
                  if (status != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: HelioSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (statusColor ?? HelioColors.optimalGreen)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(HelioRadii.pill),
                      ),
                      child: Text(
                        status!.toUpperCase(),
                        style: HelioTypography.capsLabel.copyWith(
                          fontSize: 9,
                          color: statusColor ?? HelioColors.optimalGreen,
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(value, style: HelioTypography.scoreMedium.copyWith(fontSize: 20)),
              const SizedBox(height: HelioSpacing.xs),
              Text(label.toUpperCase(), style: HelioTypography.capsLabel),
            ],
          ),
        ),
      ),
    );
  }
}
