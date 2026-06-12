import 'package:flutter/material.dart';

class MetricRing extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final double progress;
  final Color color;

  const MetricRing({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final semantic = unit != null ? '$label $value $unit' : '$label $value';
    return Semantics(
      label: semantic,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress.clamp(0, 1),
                  strokeWidth: 6,
                  backgroundColor: color.withValues(alpha: 0.15),
                  color: color,
                ),
                Center(
                  child: ExcludeSemantics(
                    child: Text(value, style: Theme.of(context).textTheme.titleMedium),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          if (unit != null)
            Text(unit!, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
