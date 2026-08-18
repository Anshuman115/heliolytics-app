import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';

class HealthSignalRow extends StatelessWidget {
  const HealthSignalRow({
    super.key,
    required this.dayKey,
    required this.label,
    required this.value,
    required this.unit,
    required this.metricId,
    this.last = false,
  });
  final String dayKey;
  final String label;
  final num? value;
  final String unit;
  final String metricId;
  final bool last;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => context.push('/metric/$dayKey/$metricId'),
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: HelioSpacing.lg,
        vertical: HelioSpacing.md,
      ),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: HelioColors.border)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: HelioTypography.body)),
          Text(
            '${value ?? '—'} $unit',
            style: HelioTypography.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: HelioSpacing.sm),
          const Icon(
            Icons.chevron_right,
            size: 18,
            color: HelioColors.textMuted,
          ),
        ],
      ),
    ),
  );
}
