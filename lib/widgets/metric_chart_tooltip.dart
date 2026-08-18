import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:heliolytics/models/health_sample.dart';
import 'package:heliolytics/utils/formatters.dart';

LineTooltipItem metricChartTooltip(
  List<HealthSample> samples,
  double startMinute,
  LineBarSpot touched,
  String unit,
) {
  final sample = samples.reduce((a, b) {
    final ax = a.sampledAt.millisecondsSinceEpoch / 60000 - startMinute;
    final bx = b.sampledAt.millisecondsSinceEpoch / 60000 - startMinute;
    return (ax - touched.x).abs() <= (bx - touched.x).abs() ? a : b;
  });
  final value = switch (unit) {
    '%' => '${sample.value.round()}%',
    'ms' => '${sample.value.round()} ms',
    'bpm' => '${sample.value.round()} bpm',
    _ => sample.value.toStringAsFixed(1),
  };
  return LineTooltipItem(
    '${formatChartTime(sample.sampledAt)}\n$value',
    const TextStyle(color: Colors.white, fontSize: 11),
  );
}
