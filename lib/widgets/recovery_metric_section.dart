import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/design_system/components/helio_notched_card.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/models/readiness_components.dart';
import 'package:heliolytics/providers/metric_trend_provider.dart';
import 'package:heliolytics/widgets/recovery_comparison_bar.dart';
import 'package:heliolytics/widgets/recovery_baseline_label.dart';
import 'package:heliolytics/widgets/recovery_insight_card.dart';

class RecoveryMetricSection extends ConsumerWidget {
  const RecoveryMetricSection({super.key, required this.day});

  final DayMetric day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history =
        ref.watch(metricComparisonProvider(day.dayKey)).valueOrNull ?? const [];
    final baseline = _average(history, (item) => item.readiness);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HelioNotchedCard(
          padding: const EdgeInsets.symmetric(vertical: HelioSpacing.xs),
          child: Column(
            children: [
              _row(
                Icons.monitor_heart_outlined,
                'HEART RATE VARIABILITY',
                day.hrvRmssd,
                'ms',
                baseline: _baseline(history, (item) => item.hrvRmssd),
                higherIsBetter: true,
              ),
              _row(
                Icons.favorite_border,
                'RESTING HEART RATE',
                day.restingHr,
                'bpm',
                baseline: _baseline(history, (item) => item.restingHr),
                higherIsBetter: false,
              ),
              _row(
                Icons.air,
                'RESPIRATORY RATE',
                day.respRate,
                'br/min',
                baseline: _baseline(history, (item) => item.respRate),
              ),
              _row(
                Icons.bedtime_outlined,
                'SLEEP PERFORMANCE',
                day.sleepScore?.toDouble(),
                '%',
                baseline: _baseline(
                  history,
                  (item) => item.sleepScore?.toDouble(),
                ),
                higherIsBetter: true,
                last: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: HelioSpacing.md),
        RecoveryComparisonBar(
          dayKey: day.dayKey,
          value: day.readiness,
          baseline: baseline,
        ),
        const SizedBox(height: HelioSpacing.xl),
        RecoveryInsightCard(message: _guidance(day.readinessBand)),
        if (day.readinessComponents case final components?) ...[
          const SizedBox(height: HelioSpacing.lg),
          _componentExplain(components),
        ],
      ],
    );
  }

  Widget _componentExplain(ReadinessComponents components) {
    final status = switch (components.status) {
      ReadinessStatus.scored =>
        'Score from version ${components.version} weights over '
            '${components.baselineNights} baseline nights.',
      ReadinessStatus.calibrating =>
        'Calibrating: ${components.baselineNights} of 14 baseline nights.',
      ReadinessStatus.noBaseline =>
        'No usable HRV baseline yet, so no score is shown.',
      ReadinessStatus.noData => 'No overnight HRV data for this day.',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(status, style: HelioTypography.bodyMuted),
        if (components.flags.isNotEmpty) ...[
          const SizedBox(height: HelioSpacing.xs),
          Text(components.flags.join(', '), style: HelioTypography.bodyMuted),
        ],
      ],
    );
  }

  Widget _row(
    IconData icon,
    String label,
    double? value,
    String unit, {
    double? baseline,
    bool? higherIsBetter,
    bool last = false,
  }) {
    return Container(
      padding: const EdgeInsets.only(
        left: HelioSpacing.lg,
        right: HelioSpacing.xxl,
        top: 14,
        bottom: 14,
      ),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: Color(0x14FFFFFF))),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: HelioColors.textSecondary),
          const SizedBox(width: HelioSpacing.md),
          Expanded(
            child: Text(
              label,
              style: HelioTypography.capsLabel.copyWith(
                color: HelioColors.textPrimary,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value == null ? 'No reading' : _format(value, unit),
                style: HelioTypography.body.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (value != null && baseline != null)
                RecoveryBaselineLabel(
                  value: value,
                  baseline: baseline,
                  higherIsBetter: higherIsBetter,
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _format(double value, String unit) {
    final text = value.toStringAsFixed(1);
    return unit == '%' ? '$text%' : '$text $unit';
  }

  double? _baseline(List<DayMetric> days, double? Function(DayMetric) select) {
    final values = days.map(select).whereType<double>().toList();
    if (values.length < 5) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double? _average(List<DayMetric> days, int? Function(DayMetric) select) {
    final values = days.map(select).whereType<int>().toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  String _guidance(ReadinessBand? band) {
    if (band == ReadinessBand.good) {
      return 'Your overnight recovery is strong. Training load can be higher '
          'if your body feels aligned with the score.';
    }
    if (band == ReadinessBand.low) {
      return 'Recovery is low today. Favor light movement and leave room for a '
          'stronger night of sleep.';
    }
    return 'Recovery compares overnight signals with your own history. Use the '
        'trend, not one day, to guide training load.';
  }
}
