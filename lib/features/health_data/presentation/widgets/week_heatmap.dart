import 'package:flutter/material.dart';
import 'package:heliolytics/core/constants.dart';
import 'package:heliolytics/core/theme/app_spacing.dart';
import 'package:heliolytics/core/theme/metric_colors.dart';
import 'package:heliolytics/features/health_data/domain/entities/day_metric.dart';

/// Dark-style row of recent days colored by recovery (readiness → sleep fallback).
class WeekHeatmap extends StatelessWidget {
  final List<DayMetric> days;
  final String selectedDayKey;
  final ValueChanged<String> onDaySelected;

  const WeekHeatmap({
    super.key,
    required this.days,
    required this.selectedDayKey,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final slice = days.take(homeTrendDays).toList().reversed.toList();
    if (slice.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Last $homeTrendDays days', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                for (final d in slice) ...[
                  Expanded(child: _DayCell(day: d, selected: d.dayKey == selectedDayKey, onTap: () => onDaySelected(d.dayKey))),
                  if (d != slice.last) const SizedBox(width: 6),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _legendDot(_recoveryColor(30), 'Low'),
                const SizedBox(width: AppSpacing.md),
                _legendDot(_recoveryColor(65), 'Mid'),
                const SizedBox(width: AppSpacing.md),
                _legendDot(_recoveryColor(90), 'High'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color c, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final DayMetric day;
  final bool selected;
  final VoidCallback onTap;

  const _DayCell({required this.day, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final score = day.readiness ?? day.sleepScore;
    final color = score != null ? _recoveryColor(score) : Colors.white12;
    final parts = day.dayKey.split('-');
    final dow = parts.length == 3
        ? ['M', 'T', 'W', 'T', 'F', 'S', 'S'][DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2])).weekday - 1]
        : '?';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: color.withValues(alpha: selected ? 1 : 0.55),
            borderRadius: BorderRadius.circular(14),
            border: selected ? Border.all(color: Colors.white, width: 2) : null,
          ),
          child: Column(
            children: [
              Text(dow, style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: Colors.white)),
              const SizedBox(height: 2),
              Text(
                score?.toString() ?? '—',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _recoveryColor(int score) {
  final t = (score / 100).clamp(0.0, 1.0);
  return Color.lerp(MetricColors.stress, MetricColors.hrv, t)!;
}
