import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:heliolytics/core/constants.dart';
import 'package:heliolytics/core/theme/app_spacing.dart';
import 'package:heliolytics/core/theme/metric_colors.dart';
import 'package:heliolytics/core/utils/formatters.dart';
import 'package:heliolytics/features/health_data/domain/entities/day_metric.dart';

class TrendMetric {
  final String label;
  final Color color;
  final double? Function(DayMetric) value;

  const TrendMetric(this.label, this.color, this.value);
}

class WeekTrendPanel extends StatefulWidget {
  final List<DayMetric> days;

  const WeekTrendPanel({super.key, required this.days});

  @override
  State<WeekTrendPanel> createState() => _WeekTrendPanelState();
}

class _WeekTrendPanelState extends State<WeekTrendPanel> {
  int _idx = 0;

  static final _metrics = [
    TrendMetric('Readiness', MetricColors.readiness, (d) => d.readiness?.toDouble()),
    TrendMetric('Sleep', MetricColors.sleep, (d) => d.sleepScore?.toDouble()),
    TrendMetric('HRV', MetricColors.hrv, (d) => d.hrvRmssd?.toDouble()),
    TrendMetric('Stress', MetricColors.stress, (d) => d.stressAvg?.toDouble()),
    TrendMetric('Steps', MetricColors.pai, (d) => d.steps.toDouble()),
  ];

  @override
  Widget build(BuildContext context) {
    final slice = widget.days.take(homeTrendDays).toList().reversed.toList();
    final m = _metrics[_idx];
    final spots = <FlSpot>[];
    for (var i = 0; i < slice.length; i++) {
      final v = m.value(slice[i]);
      if (v != null) spots.add(FlSpot(i.toDouble(), v));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('$homeTrendDays-day trend', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 20),
                  onPressed: () => setState(() => _idx = (_idx - 1 + _metrics.length) % _metrics.length),
                ),
                Text(m.label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: m.color)),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 20),
                  onPressed: () => setState(() => _idx = (_idx + 1) % _metrics.length),
                ),
              ],
            ),
            if (spots.isEmpty)
              Text('No ${m.label.toLowerCase()} data in this window.', style: Theme.of(context).textTheme.bodySmall)
            else
              SizedBox(
                height: 120,
                child: LineChart(_chart(spots, slice, m)),
              ),
          ],
        ),
      ),
    );
  }

  LineChartData _chart(List<FlSpot> spots, List<DayMetric> slice, TrendMetric m) {
    final vals = spots.map((s) => s.y);
    final minY = vals.reduce((a, b) => a < b ? a : b) * 0.9;
    final maxY = vals.reduce((a, b) => a > b ? a : b) * 1.1;
    return LineChartData(
      minY: minY,
      maxY: maxY,
      gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => const FlLine(color: Colors.white10)),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 20,
            getTitlesWidget: (v, _) {
              final i = v.round().clamp(0, slice.length - 1);
              return Text(formatDayLabel(slice[i].dayKey).split(' ').first, style: const TextStyle(fontSize: 9));
            },
          ),
        ),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: m.color,
          barWidth: 3,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(show: true, color: m.color.withValues(alpha: 0.12)),
        ),
      ],
    );
  }
}
