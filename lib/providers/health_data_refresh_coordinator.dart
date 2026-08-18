import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/providers/activity_history_provider.dart';
import 'package:heliolytics/providers/cloud_sync_provider.dart';
import 'package:heliolytics/providers/daily_health_scores_provider.dart';
import 'package:heliolytics/providers/day_bundle_provider.dart';
import 'package:heliolytics/providers/detail_metrics_provider.dart';
import 'package:heliolytics/providers/metric_trend_provider.dart';
import 'package:heliolytics/providers/sync_status_provider.dart';
import 'package:heliolytics/services/cache/daily_bundle_cache_storage.dart';
import 'package:heliolytics/services/cache/daily_health_scores_cache_storage.dart';

final healthDataRefreshCoordinatorProvider =
    Provider<HealthDataRefreshCoordinator>((ref) {
      return HealthDataRefreshCoordinator(ref);
    });

class HealthDataRefreshCoordinator {
  HealthDataRefreshCoordinator(this._ref);

  final Ref _ref;

  void retryDay(
    String dayKey, {
    bool healthScores = false,
    bool details = false,
    bool trends = false,
  }) {
    _ref.invalidate(dayBundleProvider(dayKey));
    if (healthScores) {
      _ref.invalidate(dailyHealthScoresProvider(dayKey));
    }
    if (details) _ref.invalidate(detailMetricsProvider(dayKey));
    if (trends) _ref.invalidate(metricTrendProvider);
  }

  Future<void> refreshDay(
    String dayKey, {
    bool healthScores = false,
    bool details = false,
    bool trends = false,
  }) async {
    retryDay(
      dayKey,
      healthScores: healthScores,
      details: details,
      trends: trends,
    );
    final loads = <Future<void>>[
      _ref.read(dayBundleProvider(dayKey).future).then((_) {}),
      if (healthScores)
        _ref.read(dailyHealthScoresProvider(dayKey).future).then((_) {}),
      if (details) _ref.read(detailMetricsProvider(dayKey).future).then((_) {}),
    ];
    await Future.wait(loads, eagerError: true);
  }

  Future<void> refreshActivityHistory() async {
    _ref.invalidate(activityHistoryProvider);
    await _ref.read(activityHistoryProvider.future);
  }

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

  Future<void> _clearDiskCaches() => Future.wait([
    _ref.read(dailyBundleCacheStorageProvider).clear(),
    _ref.read(dailyHealthScoresCacheStorageProvider).clear(),
  ]);

  void _invalidateAllHealthData() {
    _ref.invalidate(dayBundleProvider);
    _ref.invalidate(dailyHealthScoresProvider);
    _ref.invalidate(activityHistoryProvider);
    _ref.invalidate(detailMetricsProvider);
    _ref.invalidate(metricTrendProvider);
    _ref.invalidate(syncStatusProvider);
  }
}
