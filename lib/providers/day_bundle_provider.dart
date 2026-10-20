import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/models/day_bundle.dart';
import 'package:heliolytics/providers/cloud_sync_provider.dart';
import 'package:heliolytics/providers/detail_metrics_provider.dart';
import 'package:heliolytics/services/cache/daily_bundle_cache_storage.dart';
import 'package:heliolytics/services/network/metrics_api_transport.dart';
import 'package:heliolytics/utils/day_key.dart';

/// Selected-day bundle: cache for finished days, three C3 requests otherwise.
/// A configured API with no data returns an empty bundle, which is distinct
/// from an unconfigured API and from a failed request.
final dayBundleProvider = FutureProvider.family<DayBundle, String>((
  ref,
  dayKey,
) async {
  final cache = ref.watch(dailyBundleCacheStorageProvider);
  final isFinal = isFinalDayKey(dayKey);

  if (isFinal) {
    final cached = await cache.read(dayKey);
    if (cached != null) return cached;
  }

  final configured = await ref.read(apiConfiguredProvider.future);
  if (!configured) {
    throw const MetricsApiException(
      type: MetricsApiFailureType.notConfigured,
      path: '/api/daily-metrics',
      message: cloudApiRequiredBeforeSyncMessage,
    );
  }

  final bundle = await ref
      .read(metricsApiClientProvider)
      .fetchDayBundle(dayKey);
  if (isFinal) await cache.write(dayKey, bundle);
  return bundle;
});
