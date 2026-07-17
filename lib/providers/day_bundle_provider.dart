import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/models/day_bundle.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/providers/cloud_sync_provider.dart';
import 'package:heliolytics/providers/detail_metrics_provider.dart';
import 'package:heliolytics/services/cache/daily_bundle_cache_storage.dart';
import 'package:heliolytics/utils/day_key.dart';

final dayBundleProvider = FutureProvider.family<DayBundle, String>((ref, dayKey) async {
  final cache = ref.watch(dailyBundleCacheStorageProvider);
  final isFinal = isFinalDayKey(dayKey);

  if (isFinal) {
    final cached = await cache.read(dayKey);
    if (cached != null) return cached;
  }

  final configured = await ref.read(apiConfiguredProvider.future);
  if (!configured) {
    return DayBundle(day: DayMetric(dayKey: dayKey, steps: 0));
  }

  final bundle = await ref.read(metricsApiClientProvider).fetchDayBundle(dayKey);
  if (isFinal) await cache.write(dayKey, bundle);
  return bundle;
});
