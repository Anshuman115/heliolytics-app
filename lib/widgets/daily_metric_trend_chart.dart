import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/utils/chart_bounds.dart';

class DailyMetricTrendChart extends StatelessWidget {
  const DailyMetricTrendChart({
    super.key,
    required this.points,
    required this.color,
    required this.unit,
  });

  final List<({DayMetric day, double value})> points;
  final Color color;
  final String unit;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(
        height: 190,
        child: Center(child: Text('No trend data yet.')),
      );
    }
    final bounds = chartYBounds(points.map((point) => point.value));
    final span = (bounds.$2 - bounds.$1).clamp(0.1, double.infinity);
    final spots = [
      for (var index = 0; index < points.length; index++)
        FlSpot(index.toDouble(), points[index].value),
    ];

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: bounds.$1,
          maxY: bounds.$2,
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: span / 4,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: HelioColors.border, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: _titles(),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((spot) {
                final point = points[spot.x.round()];
                return LineTooltipItem(
                  '${point.day.dayKey}\n${_value(point.value)}',
                  const TextStyle(color: HelioColors.textPrimary),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              color: color,
              barWidth: 2.5,
              dotData: FlDotData(show: points.length <= 14),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  FlTitlesData _titles() => FlTitlesData(
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 38,
        getTitlesWidget: (value, _) => Text(
          value.toStringAsFixed(unit == '°C' ? 1 : 0),
          style: const TextStyle(fontSize: 10, color: HelioColors.textMuted),
        ),
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 24,
        interval: (points.length / 6).ceilToDouble().clamp(1, 30),
        getTitlesWidget: (value, _) {
          final index = value.round();
          if (index < 0 || index >= points.length) return const SizedBox();
          return Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              points[index].day.dayKey.substring(8),
              style: const TextStyle(
                fontSize: 10,
                color: HelioColors.textMuted,
              ),
            ),
          );
        },
      ),
    ),
  );

  String _value(double value) {
    final number = unit == '°C' ? value.toStringAsFixed(1) : value.round();
    return unit.isEmpty ? '$number' : '$number $unit';
  }
}
