import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_radii.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:intl/intl.dart';

class HomeActivityRow extends StatelessWidget {
  const HomeActivityRow({
    super.key,
    required this.icon,
    required this.label,
    required this.duration,
    required this.start,
    required this.color,
    this.end,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String duration;
  final DateTime start;
  final DateTime? end;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(HelioRadii.sm),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: HelioSpacing.sm),
      child: Row(
        children: [
          _icon(),
          const SizedBox(width: HelioSpacing.md),
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: HelioTypography.capsLabel.copyWith(fontSize: 11),
            ),
          ),
          _times(),
          const SizedBox(width: HelioSpacing.sm),
          Container(width: 3, height: 36, color: color),
        ],
      ),
    ),
  );

  Widget _icon() => Container(
    width: 52,
    height: 56,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(HelioRadii.sm),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 2),
        Text(
          duration,
          style: HelioTypography.capsLabel.copyWith(fontSize: 9, color: color),
        ),
      ],
    ),
  );

  Widget _times() {
    final formatter = DateFormat.jm();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          formatter.format(start.toLocal()),
          style: HelioTypography.bodyMuted,
        ),
        Text(
          formatter.format((end ?? start).toLocal()),
          style: HelioTypography.bodyMuted,
        ),
      ],
    );
  }
}
