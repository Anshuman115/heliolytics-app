import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';

class HealthBaselineCard extends StatelessWidget {
  const HealthBaselineCard({
    super.key,
    required this.hrv,
    required this.restingHr,
    required this.onTap,
  });
  final int? hrv;
  final int? restingHr;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => HelioSurfaceCard(
    onTap: onTap,
    color: HelioColors.surfaceElevated,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.monitor_heart_outlined,
              color: HelioColors.optimalGreen,
            ),
            const SizedBox(width: HelioSpacing.sm),
            Text('HEALTH MONITOR', style: HelioTypography.sectionTitle),
            const Spacer(),
            const Icon(Icons.chevron_right, color: HelioColors.textMuted),
          ],
        ),
        const SizedBox(height: HelioSpacing.lg),
        Text('Overnight baseline', style: HelioTypography.scoreMedium),
        const SizedBox(height: HelioSpacing.lg),
        Row(
          children: [
            _BaselineValue(label: 'HRV', value: hrv, unit: 'ms'),
            const SizedBox(width: HelioSpacing.xl),
            _BaselineValue(label: 'RESTING HR', value: restingHr, unit: 'bpm'),
          ],
        ),
      ],
    ),
  );
}

class _BaselineValue extends StatelessWidget {
  const _BaselineValue({
    required this.label,
    required this.value,
    required this.unit,
  });
  final String label;
  final int? value;
  final String unit;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value?.toString() ?? '—',
          style: HelioTypography.scoreLarge.copyWith(fontSize: 34),
        ),
        const SizedBox(height: 3),
        Text('$label  $unit', style: HelioTypography.capsLabel),
      ],
    ),
  );
}

class HealthMonitorRow extends StatelessWidget {
  const HealthMonitorRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: HelioSpacing.md),
      child: Row(
        children: [
          Icon(icon, color: color, size: 27),
          const SizedBox(width: HelioSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.toUpperCase(), style: HelioTypography.sectionTitle),
                const SizedBox(height: 3),
                Text(subtitle, style: HelioTypography.body),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: HelioColors.textMuted),
        ],
      ),
    ),
  );
}
