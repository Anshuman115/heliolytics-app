import 'package:flutter/material.dart';
import 'package:heliolytics/core/theme/app_spacing.dart';
import 'package:heliolytics/features/health_data/domain/entities/health_sample.dart';
import 'package:heliolytics/features/health_data/domain/metric_catalog.dart';
import 'package:heliolytics/features/health_data/presentation/widgets/minute_series_chart.dart';

class MetricOverviewCard extends StatefulWidget {
  final MetricDef def;
  final String valueLabel;
  final List<HealthSample> samples;
  final VoidCallback onOpenDetail;

  const MetricOverviewCard({
    super.key,
    required this.def,
    required this.valueLabel,
    required this.samples,
    required this.onOpenDetail,
  });

  @override
  State<MetricOverviewCard> createState() => _MetricOverviewCardState();
}

class _MetricOverviewCardState extends State<MetricOverviewCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = MetricStats.fromSamples(widget.samples);
    final valueText =
        '${widget.valueLabel}${widget.def.unit.isEmpty ? '' : ' ${widget.def.unit}'}';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        children: [
          InkWell(
            onTap: widget.onOpenDetail,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.sm, AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: widget.def.color.withValues(alpha: 0.15),
                    child: Icon(widget.def.icon, color: widget.def.color, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.def.title, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          widget.def.note,
                          maxLines: _expanded ? 4 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          valueText,
                          style: theme.textTheme.titleMedium?.copyWith(color: widget.def.color),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                    onPressed: () => setState(() => _expanded = !_expanded),
                  ),
                ],
              ),
            ),
          ),
          if (widget.samples.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
              child: MinuteSeriesChart(
                samples: widget.samples,
                color: widget.def.color,
                unit: widget.def.unit,
                height: 72,
                maxPoints: 80,
                showDots: false,
              ),
            ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.def.detail, style: theme.textTheme.bodySmall),
                  if (stats.count > 0) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${stats.count} readings · avg ${_fmt(stats.avg)} · min ${_fmt(stats.min)} · max ${_fmt(stats.max)}',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                  TextButton(onPressed: widget.onOpenDetail, child: const Text('Open minute view')),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _fmt(double? v) {
    if (v == null) return '—';
    if (widget.def.unit == '°C') return v.toStringAsFixed(1);
    if (widget.def.unit == '%') return '${v.round()}%';
    return v.round().toString();
  }
}
