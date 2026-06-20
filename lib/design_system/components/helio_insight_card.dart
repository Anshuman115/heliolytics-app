import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';

class HelioInsightCard extends StatelessWidget {
  final String message;
  final IconData icon;

  const HelioInsightCard({
    super.key,
    required this.message,
    this.icon = Icons.lightbulb_outline,
  });

  @override
  Widget build(BuildContext context) {
    return HelioSurfaceCard(
      padding: const EdgeInsets.all(HelioSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: HelioColors.strainBlue),
          const SizedBox(width: HelioSpacing.md),
          Expanded(child: Text(message, style: HelioTypography.bodyMuted)),
        ],
      ),
    );
  }
}
