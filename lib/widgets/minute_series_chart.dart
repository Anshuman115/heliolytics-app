import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:heliolytics/utils/chart_bounds.dart';
import 'package:heliolytics/utils/formatters.dart';
import 'package:heliolytics/models/health_sample.dart';
import 'package:heliolytics/widgets/metric_chart_tooltip.dart';

class MinuteSeriesChart extends StatelessWidget {
  final List<HealthSample> samples;
  final Color color;
  final String unit;
  final int maxPoints;
  final double height;
  final bool showDots;

  const MinuteSeriesChart({
    super.key,
    required this.samples,
    required this.color,
    required this.unit,
    this.maxPoints = 240,
    this.height = 220,
    this.showDots = true,
  });

  @override
  Widget build(BuildContext context) {
    if (samples.isEmpty) {
      return Text(
        'No readings for this day.',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    final sorted = [...samples]
      ..sort((a, b) => a.sampledAt.compareTo(b.sampledAt));
    final points = _downsample(sorted, maxPoints);
    final start = points.first.sampledAt.millisecondsSinceEpoch / 60000.0;
    final spots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      final s = points[i];
      if (i > 0 &&
          s.sampledAt.difference(points[i - 1].sampledAt).inMinutes > 30) {
        spots.add(FlSpot.nullSpot);
      }
      final x = s.sampledAt.millisecondsSinceEpoch / 60000.0 - start;
      spots.add(FlSpot(x, s.value));
    }
    final vals = points.map((s) => s.value);
    final (minY, maxY) = chartYBounds(vals);
    final ySpan = (maxY - minY).clamp(0.1, double.infinity);

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: ySpan / 4,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: Colors.white10, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (v, _) => Text(
                  unit == '%'
                      ? '${v.round()}%'
                      : v.toStringAsFixed(unit == '°C' ? 1 : 0),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: chartXInterval(spots.last.x),
                getTitlesWidget: (v, _) {
                  final idx = points.indexWhere((s) {
                    final x =
                        s.sampledAt.millisecondsSinceEpoch / 60000.0 - start;
                    return (x - v).abs() < 0.5;
                  });
                  if (idx < 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      formatChartTime(points[idx].sampledAt),
                      style: const TextStyle(fontSize: 9),
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touched) => touched
                  .map((spot) => metricChartTooltip(points, start, spot, unit))
                  .toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: color,
              barWidth: 2.5,
              dotData: FlDotData(show: showDots && spots.length < 80),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.35),
                    color.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<HealthSample> _downsample(List<HealthSample> in_, int cap) {
    if (in_.length <= cap) return in_;
    final step = in_.length / cap;
    return [for (var i = 0; i < cap; i++) in_[(i * step).floor()]];
  }
}
