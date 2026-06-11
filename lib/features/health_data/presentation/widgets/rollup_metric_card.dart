import 'package:flutter/material.dart';
import 'package:heliolytics/core/theme/app_spacing.dart';
import 'package:heliolytics/features/health_data/domain/metric_catalog.dart';

class RollupMetricCard extends StatefulWidget {
  final MetricDef def;
  final String valueLabel;
  final String? subtitle;
  final VoidCallback? onTap;

  const RollupMetricCard({
    super.key,
    required this.def,
    required this.valueLabel,
    this.subtitle,
    this.onTap,
  });

  @override
  State<RollupMetricCard> createState() => _RollupMetricCardState();
}

class _RollupMetricCardState extends State<RollupMetricCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                        if (widget.subtitle != null)
                          Text(widget.subtitle!, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Text(
                    widget.valueLabel,
                    style: theme.textTheme.headlineSmall?.copyWith(color: widget.def.color),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(widget.def.note, style: theme.textTheme.bodySmall),
              TextButton.icon(
                onPressed: () => setState(() => _expanded = !_expanded),
                icon: Icon(_expanded ? Icons.expand_less : Icons.info_outline, size: 18),
                label: Text(_expanded ? 'Hide notes' : 'What is this?'),
              ),
              if (_expanded) Text(widget.def.detail, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
