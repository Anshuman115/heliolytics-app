import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/providers/cloud_sync_provider.dart';
import 'package:heliolytics/providers/detail_metrics_provider.dart';

final metricTrendProvider = FutureProvider.family<List<DayMetric>, int>((
  ref,
  days,
) async {
  final configured = await ref.read(apiConfiguredProvider.future);
  if (!configured) return const [];
  final result = await ref
      .read(metricsApiClientProvider)
      .fetchDays(windowDays: days);
  result.sort((a, b) => a.dayKey.compareTo(b.dayKey));
  return result.length > days ? result.sublist(result.length - days) : result;
});

final metricTrendRangeProvider =
    FutureProvider.family<List<DayMetric>, ({String from, String to})>((
      ref,
      range,
    ) async {
      final configured = await ref.read(apiConfiguredProvider.future);
      if (!configured) return const [];
      final result = await ref
          .read(metricsApiClientProvider)
          .fetchDaysBetween(from: range.from, to: range.to);
      result.sort((a, b) => a.dayKey.compareTo(b.dayKey));
      return result;
    });

final metricComparisonProvider =
    FutureProvider.family<List<DayMetric>, String>((ref, dayKey) async {
      final anchor = DateTime.parse(dayKey);
      final to = anchor.subtract(const Duration(days: 1));
      final from = to.subtract(const Duration(days: 29));
      String key(DateTime date) =>
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
      return ref.watch(
        metricTrendRangeProvider((from: key(from), to: key(to))).future,
      );
    });
