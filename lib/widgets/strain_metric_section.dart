import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/design_system/components/helio_notched_card.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/models/hr_sample.dart';
import 'package:heliolytics/models/metric_catalog.dart';
import 'package:heliolytics/providers/metric_trend_provider.dart';
import 'package:heliolytics/utils/formatters.dart';
import 'package:heliolytics/utils/hr_zones.dart';
import 'package:heliolytics/widgets/recovery_comparison_bar.dart';

class StrainMetricSection extends ConsumerWidget {
  const StrainMetricSection({
    super.key,
    required this.definition,
    required this.day,
    required this.heartRate,
  });

  final MetricDef definition;
  final DayMetric day;
  final List<HeartRateSample> heartRate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zones = computeHrZones(heartRate);
    final lower = _seconds(zones, 1, 3);
    final upper = _seconds(zones, 4, 5);
    final history =
        ref.watch(metricComparisonProvider(day.dayKey)).valueOrNull ?? const [];
    final baseline = _average(history, (item) => item.paiScore);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HelioNotchedCard(
          color: HelioColors.surface.withValues(alpha: 0.78),
          padding: const EdgeInsets.symmetric(vertical: HelioSpacing.sm),
          child: Column(
            children: [
              _row(Icons.favorite_border, 'HEART RATE ZONES 1-3', _time(lower)),
              _divider(),
              _row(Icons.favorite_border, 'HEART RATE ZONES 4-5', _time(upper)),
              _divider(),
              _row(
                Icons.fitness_center_outlined,
                'STRENGTH ACTIVITY TIME',
                '—',
              ),
              _divider(),
              _row(
                Icons.directions_walk_outlined,
                'STEPS',
                day.steps > 0 ? formatStepCount(day.steps) : '—',
              ),
            ],
          ),
        ),
        if (day.paiScore != null) ...[
          const SizedBox(height: HelioSpacing.lg),
          RecoveryComparisonBar(
            dayKey: day.dayKey,
            value: day.paiScore,
            baseline: baseline,
            higherIsBetter: true,
          ),
        ],
        const SizedBox(height: HelioSpacing.lg),
        _insight(),
      ],
    );
  }

  Widget _row(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: HelioSpacing.lg,
      vertical: HelioSpacing.lg,
    ),
    child: Row(
      children: [
        Icon(icon, size: 23, color: HelioColors.textSecondary),
        const SizedBox(width: HelioSpacing.md),
        Expanded(child: Text(label, style: HelioTypography.capsLabel)),
        Text(value, style: HelioTypography.scoreMedium.copyWith(fontSize: 24)),
      ],
    ),
  );

  Widget _divider() => const Divider(height: 1, color: HelioColors.border);

  Widget _insight() => HelioSurfaceCard(
    color: HelioColors.surface,
    padding: const EdgeInsets.all(HelioSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.lightbulb_outline,
              color: HelioColors.textSecondary,
            ),
            const SizedBox(width: HelioSpacing.sm),
            Expanded(
              child: Text(
                'STRAIN INSIGHT',
                style: HelioTypography.sectionTitle,
              ),
            ),
            const Icon(Icons.chevron_right, color: HelioColors.textMuted),
          ],
        ),
        const SizedBox(height: HelioSpacing.md),
        Text(
          day.paiScore == null || day.paiScore == 0
              ? 'Your accumulated cardiovascular load is low so far today.'
              : 'Your strain reflects the recorded cardiovascular load across the day.',
          style: HelioTypography.body.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );

  int _seconds(HrZoneBreakdown zones, int first, int last) => zones.zones
      .where((zone) => zone.index >= first && zone.index <= last)
      .fold(0, (total, zone) => total + zone.seconds);

  String _time(int seconds) {
    final mins = seconds ~/ 60;
    return '${mins ~/ 60}:${(mins % 60).toString().padLeft(2, '0')}';
  }

  double? _average(List<DayMetric> days, int? Function(DayMetric) select) {
    final values = days.map(select).whereType<int>().toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }
}
