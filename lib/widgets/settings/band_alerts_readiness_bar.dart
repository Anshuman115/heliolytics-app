import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/band_alerts_readiness.dart';

class BandAlertsReadinessBar extends StatelessWidget {
  final List<BandAlertsReadinessItem> items;
  final VoidCallback? onFixTap;

  const BandAlertsReadinessBar({
    super.key,
    required this.items,
    this.onFixTap,
  });

  @override
  Widget build(BuildContext context) {
    final pending = items.where((i) => !i.granted).length;
    if (pending == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Setup required ($pending)',
          style: HelioTypography.capsLabel.copyWith(
            fontSize: 11,
            color: HelioColors.syncError,
          ),
        ),
        const SizedBox(height: HelioSpacing.sm),
        ...items.map(_row),
        if (onFixTap != null) ...[
          const SizedBox(height: HelioSpacing.sm),
          TextButton(
            onPressed: onFixTap,
            child: const Text('Grant permissions'),
          ),
        ],
      ],
    );
  }

  Widget _row(BandAlertsReadinessItem item) {
    final color = item.granted ? HelioColors.optimalGreen : HelioColors.syncError;
    return Padding(
      padding: const EdgeInsets.only(bottom: HelioSpacing.xs),
      child: Row(
        children: [
          Icon(
            item.granted ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: color,
          ),
          const SizedBox(width: HelioSpacing.sm),
          Expanded(
            child: Text(
              item.label,
              style: HelioTypography.bodyMuted.copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
