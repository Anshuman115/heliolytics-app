import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/models/metric_catalog.dart';
import 'package:heliolytics/providers/metric_trend_provider.dart';
import 'package:heliolytics/widgets/daily_metric_trend_chart.dart';
import 'package:heliolytics/widgets/metric_trend_controls.dart';

class MetricTrendSection extends ConsumerStatefulWidget {
  const MetricTrendSection({
    super.key,
    required this.definition,
    this.anchorDayKey,
  });

  final MetricDef definition;
  final String? anchorDayKey;
  @override
  ConsumerState<MetricTrendSection> createState() => _MetricTrendSectionState();
}

class _MetricTrendSectionState extends ConsumerState<MetricTrendSection> {
  int days = metricTrendWeekDays;
  int periodOffset = 0;
  @override
  Widget build(BuildContext context) {
    final (from, to) = _periodBounds();
    final asyncDays = ref.watch(
      metricTrendRangeProvider((from: _formatDay(from), to: _formatDay(to))),
    );
    final points =
        asyncDays.valueOrNull
            ?.map((day) => (day: day, value: _value(day)))
            .where((point) => point.value != null)
            .map((point) => (day: point.day, value: point.value!))
            .toList() ??
        const [];
    final average = points.isEmpty
        ? null
        : points.fold<double>(0, (sum, point) => sum + point.value) /
              points.length;

    return HelioSurfaceCard(
      padding: const EdgeInsets.all(HelioSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${widget.definition.title.toUpperCase()} TREND',
                  style: HelioTypography.sectionTitle,
                ),
              ),
              MetricTrendPeriodControl(
                days: days,
                onChanged: (value) => setState(() {
                  days = value;
                  periodOffset = 0;
                }),
              ),
            ],
          ),
          const SizedBox(height: HelioSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _Average(value: average, unit: widget.definition.unit),
              ),
              MetricTrendDateNav(
                label: _periodLabel(from, to),
                onPrevious:
                    days * (periodOffset + 2) <= metricTrendSixMonthsDays
                    ? () => setState(() => periodOffset++)
                    : null,
                onNext: periodOffset > 0
                    ? () => setState(() => periodOffset--)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: HelioSpacing.md),
          DailyMetricTrendChart(
            points: points,
            color: widget.definition.color,
            unit: widget.definition.unit,
          ),
        ],
      ),
    );
  }

  double? _value(DayMetric day) => switch (widget.definition.id) {
    'readiness' => day.readiness?.toDouble(),
    'sleep' => day.sleepScore?.toDouble(),
    'stress' => day.stressAvg?.toDouble(),
    'hrv' => day.hrvRmssd?.toDouble(),
    'rhr' => day.restingHr?.toDouble(),
    'spo2' || 'spo2_sleep' => day.spo2Avg?.toDouble(),
    'resp_rate' => day.respRateAvg?.toDouble(),
    'temperature' => day.tempAvgC,
    'pai' => day.paiScore == null ? null : day.paiScore! / 10,
    'steps' => day.steps.toDouble(),
    'calories' => day.calories?.toDouble(),
    _ => null,
  };

  (DateTime, DateTime) _periodBounds() {
    final anchor = widget.anchorDayKey == null
        ? DateTime.now()
        : DateTime.parse(widget.anchorDayKey!);
    final today = DateTime(anchor.year, anchor.month, anchor.day);
    final to = today.subtract(Duration(days: days * periodOffset));
    return (to.subtract(Duration(days: days - 1)), to);
  }

  String _formatDay(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  String _periodLabel(DateTime from, DateTime to) {
    final start = DateFormat('MMM d').format(from).toUpperCase();
    final end = DateFormat('MMM d, yy').format(to).toUpperCase();
    return '$start - $end';
  }
}

class _Average extends StatelessWidget {
  const _Average({required this.value, required this.unit});
  final double? value;
  final String unit;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('AVERAGE', style: HelioTypography.capsLabel),
      const SizedBox(height: HelioSpacing.xs),
      Text(
        value == null
            ? '—'
            : '${unit == '°C' ? value!.toStringAsFixed(1) : value!.round()}${unit.isEmpty ? '' : ' $unit'}',
        style: HelioTypography.scoreLarge.copyWith(fontSize: 36),
      ),
    ],
  );
}
