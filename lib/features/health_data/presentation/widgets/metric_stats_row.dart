import 'package:flutter/material.dart';
import 'package:heliolytics/core/theme/app_spacing.dart';
import 'package:heliolytics/features/health_data/domain/metric_catalog.dart';

class MetricStatsRow extends StatelessWidget {
  final MetricStats stats;
  final String unit;

  const MetricStatsRow({super.key, required this.stats, required this.unit});

  @override
  Widget build(BuildContext context) {
    if (stats.count == 0) {
      return Text('No minute data for this day.', style: Theme.of(context).textTheme.bodySmall);
    }
    return Row(
      children: [
        _chip(context, 'Avg', _fmt(stats.avg)),
        const SizedBox(width: AppSpacing.sm),
        _chip(context, 'Min', _fmt(stats.min)),
        const SizedBox(width: AppSpacing.sm),
        _chip(context, 'Max', _fmt(stats.max)),
        const Spacer(),
        Text('${stats.count} pts', style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }

  Widget _chip(BuildContext ctx, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: Theme.of(ctx).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(ctx).textTheme.labelSmall),
          Text(value, style: Theme.of(ctx).textTheme.titleSmall),
        ],
      ),
    );
  }

  String _fmt(double? v) {
    if (v == null) return '—';
    if (unit == '°C') return '${v.toStringAsFixed(1)}°C';
    if (unit == '%') return '${v.round()}%';
    if (unit == 'ms') return '${v.round()} ms';
    if (unit == 'bpm' || unit == 'br/min') return '${v.round()}';
    return v.toStringAsFixed(1);
  }
}
