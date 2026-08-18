import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/providers/metric_trend_provider.dart';

class ProfileHistorySection extends ConsumerWidget {
  const ProfileHistorySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(metricTrendProvider(30)).valueOrNull;
    if (history == null || history.isEmpty) return const SizedBox.shrink();

    final sleep = _max(history, (day) => day.sleepScore);
    final recovery = _max(history, (day) => day.readiness);
    final strain = _max(history, (day) => day.paiScore);
    final activeDays = history.where(_hasActivity).length;
    final steps = history.fold<int>(0, (sum, day) => sum + day.steps);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HelioSurfaceCard(
          color: HelioColors.surface,
          padding: const EdgeInsets.all(HelioSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('PERSONAL RECORDS', style: HelioTypography.sectionTitle),
              const SizedBox(height: HelioSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _Record(
                      label: 'BEST SLEEP',
                      value: sleep == null ? '—' : '$sleep%',
                      color: HelioColors.sleepBlue,
                    ),
                  ),
                  Expanded(
                    child: _Record(
                      label: 'PEAK RECOVERY',
                      value: recovery == null ? '—' : '$recovery%',
                      color: HelioColors.recoveryHigh,
                    ),
                  ),
                  Expanded(
                    child: _Record(
                      label: 'MAX STRAIN',
                      value: strain == null
                          ? '—'
                          : (strain / 10).toStringAsFixed(1),
                      color: HelioColors.strainBlue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: HelioSpacing.md),
        HelioSurfaceCard(
          padding: const EdgeInsets.symmetric(
            horizontal: HelioSpacing.lg,
            vertical: HelioSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text('ACTIVE DAYS', style: HelioTypography.sectionTitle),
              ),
              Text(
                '$activeDays / ${history.length}',
                style: HelioTypography.body,
              ),
              const SizedBox(width: HelioSpacing.sm),
              const Icon(Icons.chevron_right, color: HelioColors.textMuted),
            ],
          ),
        ),
        const SizedBox(height: HelioSpacing.md),
        HelioSurfaceCard(
          padding: const EdgeInsets.symmetric(
            horizontal: HelioSpacing.lg,
            vertical: HelioSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '30-DAY STEPS',
                  style: HelioTypography.sectionTitle,
                ),
              ),
              Text(_formatSteps(steps), style: HelioTypography.body),
            ],
          ),
        ),
      ],
    );
  }

  int? _max(List<DayMetric> days, int? Function(DayMetric) read) {
    final values = days.map(read).whereType<int>().toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a > b ? a : b);
  }

  bool _hasActivity(DayMetric day) =>
      day.steps > 0 || day.workoutCount > 0 || day.activitySessionCount > 0;

  String _formatSteps(int steps) {
    final value = steps.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < value.length; i++) {
      if (i > 0 && (value.length - i) % 3 == 0) buffer.write(',');
      buffer.write(value[i]);
    }
    return buffer.toString();
  }
}

class _Record extends StatelessWidget {
  const _Record({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: HelioTypography.scoreMedium.copyWith(color: color, fontSize: 24),
      ),
      const SizedBox(height: HelioSpacing.xs),
      Text(label, style: HelioTypography.capsLabel.copyWith(fontSize: 9)),
    ],
  );
}
