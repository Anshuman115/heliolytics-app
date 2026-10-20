import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/providers/activity_history_provider.dart';
import 'package:heliolytics/providers/cloud_sync_provider.dart';
import 'package:heliolytics/providers/day_bundle_provider.dart';
import 'package:heliolytics/providers/detail_metrics_provider.dart';
import 'package:heliolytics/providers/metric_trend_provider.dart';
import 'package:heliolytics/providers/sync_status_provider.dart';
import 'package:heliolytics/services/cache/daily_bundle_cache_storage.dart';

final healthDataRefreshCoordinatorProvider =
    Provider<HealthDataRefreshCoordinator>((ref) {
      return HealthDataRefreshCoordinator(ref);
    });

class HealthDataRefreshCoordinator {
  HealthDataRefreshCoordinator(this._ref);

  final Ref _ref;

  void retryDay(String dayKey, {bool details = false, bool trends = false}) {
    _ref.invalidate(dayBundleProvider(dayKey));
    if (details) _ref.invalidate(detailMetricsProvider(dayKey));
    if (trends) _ref.invalidate(metricTrendProvider);
  }

  Future<void> refreshDay(
    String dayKey, {
    bool details = false,
    bool trends = false,
  }) async {
    await _ref.read(dailyBundleCacheStorageProvider).delete(dayKey);
    final loads = <Future<void>>[
      _ref.refresh(dayBundleProvider(dayKey).future).then((_) {}),
      if (details)
        _ref.refresh(detailMetricsProvider(dayKey).future).then((_) {}),
    ];
    if (trends) _ref.invalidate(metricTrendProvider);
    await Future.wait(loads, eagerError: true);
  }

  Future<void> refreshActivityHistory() async {
    _ref.invalidate(activityHistoryProvider);
    await _ref.read(activityHistoryProvider.future);
  }

  /// Runs after a confirmed upload or profile recomputation.
  Future<void> afterSync() async {
    try {
      await _clearDiskCaches();
    } finally {
      _invalidateAllHealthData();
    }
  }

  Future<void> replaceApiConfiguration({
    required Future<void> Function() save,
  }) async {
    await _clearDiskCaches();
    await save();
    _ref.invalidate(apiConfiguredProvider);
    _invalidateAllHealthData();
  }

  Future<void> _clearDiskCaches() async {
    await Future.wait([
      _ref.read(dailyBundleCacheStorageProvider).clear(),
      _clearLegacyScoresCache(),
    ]);
  }

  /// Removes the deleted daily-health-scores blob without touching other prefs.
  Future<void> _clearLegacyScoresCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(legacyDailyHealthScoresCacheKey);
  }

  void _invalidateAllHealthData() {
    _ref.invalidate(dayBundleProvider);
    _ref.invalidate(activityHistoryProvider);
    _ref.invalidate(detailMetricsProvider);
    _ref.invalidate(metricTrendProvider);
    _ref.invalidate(syncStatusProvider);
  }
}
