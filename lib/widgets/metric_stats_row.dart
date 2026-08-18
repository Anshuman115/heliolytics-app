import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_radii.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/models/metric_catalog.dart';

class MetricStatsRow extends StatelessWidget {
  final MetricStats stats;
  final String unit;
  final bool includeAverage;

  const MetricStatsRow({
    super.key,
    required this.stats,
    required this.unit,
    this.includeAverage = true,
  });

  @override
  Widget build(BuildContext context) {
    if (stats.count == 0) {
      return Text(
        'No minute data for this day.',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return Row(
      children: [
        if (includeAverage) ...[
          _chip(context, 'Avg', _fmt(stats.avg)),
          const SizedBox(width: HelioSpacing.sm),
        ],
        _chip(context, 'Min', _fmt(stats.min)),
        const SizedBox(width: HelioSpacing.sm),
        _chip(context, 'Max', _fmt(stats.max)),
        const Spacer(),
        Text(
          '${stats.count} pts',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }

  Widget _chip(BuildContext ctx, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: HelioSpacing.sm,
        vertical: HelioSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Theme.of(ctx).colorScheme.surface,
        borderRadius: BorderRadius.circular(HelioRadii.card),
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
