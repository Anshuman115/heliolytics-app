import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/design_system/components/helio_notched_card.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/day_metric.dart';
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
                day.respRateAvg,
                'br/min',
                baseline: _baseline(history, (item) => item.respRateAvg),
              ),
              _row(
                Icons.bedtime_outlined,
                'SLEEP PERFORMANCE',
                day.sleepScore,
                '%',
                baseline: _baseline(history, (item) => item.sleepScore),
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
        RecoveryInsightCard(message: _guidance(day.readiness)),
      ],
    );
  }

  Widget _row(
    IconData icon,
    String label,
    num? value,
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
                value == null
                    ? 'No reading'
                    : unit == '%'
                    ? '$value%'
                    : '$value',
                style: HelioTypography.body.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (value != null && baseline != null)
                RecoveryBaselineLabel(
                  value: value.toDouble(),
                  baseline: baseline,
                  higherIsBetter: higherIsBetter,
                ),
            ],
          ),
        ],
      ),
    );
  }

  double? _baseline(List<DayMetric> days, int? Function(DayMetric) select) {
    final values = days.map(select).whereType<int>().toList();
    if (values.length < 5) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double? _average(List<DayMetric> days, int? Function(DayMetric) select) {
    final values = days.map(select).whereType<int>().toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  String _guidance(int? readiness) {
    if (readiness != null && readiness >= 67) {
      return 'Your overnight recovery is strong. Training load can be higher if your body feels aligned with the score.';
    }
    if (readiness != null && readiness <= 33) {
      return 'Recovery is low today. Favor light movement and leave room for a stronger night of sleep.';
    }
    return 'Recovery compares overnight signals with your own history. Use the trend, not one day, to guide training load.';
  }
}
