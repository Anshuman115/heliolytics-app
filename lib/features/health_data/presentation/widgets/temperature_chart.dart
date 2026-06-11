import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:heliolytics/core/theme/metric_colors.dart';
import 'package:heliolytics/core/utils/formatters.dart';
import 'package:heliolytics/features/health_data/domain/entities/temp_sample.dart';

class TemperatureChart extends StatelessWidget {
  final List<TempSample> samples;
  final double height;
  const TemperatureChart({super.key, required this.samples, this.height = 220});

  @override
  Widget build(BuildContext context) {
    if (samples.isEmpty) {
      return const Text('No minute temperature data for this day.');
    }
    final sorted = [...samples]..sort((a, b) => a.sampledAt.compareTo(b.sampledAt));
    final points = _downsample(sorted, 240);
    final spots = <FlSpot>[];
    final start = points.first.sampledAt.millisecondsSinceEpoch / 60000.0;
    for (final s in points) {
      final x = s.sampledAt.millisecondsSinceEpoch / 60000.0 - start;
      spots.add(FlSpot(x, s.celsius));
    }
    final minY = points.map((s) => s.celsius).reduce((a, b) => a < b ? a : b) - 0.3;
    final maxY = points.map((s) => s.celsius).reduce((a, b) => a > b ? a : b) + 0.3;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(color: Colors.white10, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (v, _) => Text('${v.toStringAsFixed(1)}°', style: const TextStyle(fontSize: 10)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: spots.length > 1 ? spots.last.x / 4 : 1,
                getTitlesWidget: (v, _) {
                  final idx = spots.indexWhere((s) => (s.x - v).abs() < 0.5);
                  if (idx < 0) return const SizedBox.shrink();
                  return Text(formatChartTime(points[idx].sampledAt), style: const TextStyle(fontSize: 9));
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (t) => t.map((spot) {
                final i = spot.spotIndex.clamp(0, points.length - 1);
                return LineTooltipItem(
                  '${formatChartTime(points[i].sampledAt)}\n${points[i].celsius.toStringAsFixed(2)}°C',
                  const TextStyle(color: Colors.white, fontSize: 11),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: MetricColors.temperature,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: MetricColors.temperature.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<TempSample> _downsample(List<TempSample> in_, int maxPoints) {
    if (in_.length <= maxPoints) return in_;
    final step = in_.length / maxPoints;
    return [for (var i = 0; i < maxPoints; i++) in_[(i * step).floor()]];
  }
}
