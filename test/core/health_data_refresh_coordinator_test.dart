import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliolytics/models/daily_health_scores.dart';
import 'package:heliolytics/models/day_bundle.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/providers/activity_history_provider.dart';
import 'package:heliolytics/providers/api_config_form_provider.dart';
import 'package:heliolytics/providers/daily_health_scores_provider.dart';
import 'package:heliolytics/providers/day_bundle_provider.dart';
import 'package:heliolytics/providers/detail_metrics_provider.dart';
import 'package:heliolytics/providers/metric_trend_provider.dart';
import 'package:heliolytics/providers/sync_status_provider.dart';
import 'package:heliolytics/services/ble/auth/auth_key_storage.dart';
import 'package:heliolytics/services/ble/auth/auth_key_store.dart';
import 'package:heliolytics/services/cache/daily_bundle_cache_storage.dart';
import 'package:heliolytics/services/cache/daily_health_scores_cache_storage.dart';

void main() {
  test('config change clears caches before invalidating health data', () async {
    const dayKey = '2026-08-01';
    final events = <String>[];
    final builds = <String, int>{};
    void built(String name) => builds[name] = (builds[name] ?? 0) + 1;
    final store = _MemoryAuthKeyStore({
      'api_base_url': 'https://old.example',
      'signing_secret': 'old-secret',
    }, events);
    final container = ProviderContainer(
      overrides: [
        authKeyStoreProvider.overrideWithValue(store),
        dailyBundleCacheStorageProvider.overrideWithValue(
          _RecordingBundleCache(events),
        ),
        dailyHealthScoresCacheStorageProvider.overrideWithValue(
          _RecordingScoresCache(events),
        ),
        dayBundleProvider.overrideWith((ref, key) async {
          built('bundle');
          return DayBundle(day: DayMetric(dayKey: key, steps: 0));
        }),
        dailyHealthScoresProvider.overrideWith((ref, key) async {
          built('scores');
          return DailyHealthScores.empty(key);
        }),
        activityHistoryProvider.overrideWith((ref) async {
          built('history');
          return const ActivityHistory();
        }),
        detailMetricsProvider.overrideWith((ref, key) async {
          built('detail');
          return const DetailMetrics();
        }),
        metricTrendProvider.overrideWith((ref, days) async {
          built('trend');
          return const <DayMetric>[];
        }),
        syncStatusProvider.overrideWith((ref) async {
          built('status');
          return const SyncStatus();
        }),
      ],
    );
    addTearDown(container.dispose);

    await container.read(apiConfigFormProvider.future);
    await _loadHealthData(container, dayKey);
    expect(builds.values, everyElement(1));
    events.clear();

    await container
        .read(apiConfigFormProvider.notifier)
        .save('https://new.example', 'new-secret');

    final firstWrite = events.indexWhere((event) => event.startsWith('write:'));
    expect(events.take(firstWrite).toSet(), {'bundle-clear', 'scores-clear'});
    expect(store.values['api_base_url'], 'https://new.example');
    expect(store.values['signing_secret'], 'new-secret');

    await _loadHealthData(container, dayKey);
    expect(builds.values, everyElement(2));
  });
}

Future<void> _loadHealthData(ProviderContainer container, String dayKey) async {
  await Future.wait<dynamic>([
    container.read(dayBundleProvider(dayKey).future),
    container.read(dailyHealthScoresProvider(dayKey).future),
    container.read(activityHistoryProvider.future),
    container.read(detailMetricsProvider(dayKey).future),
    container.read(metricTrendProvider(7).future),
    container.read(syncStatusProvider.future),
  ]);
}

class _RecordingBundleCache extends DailyBundleCacheStorage {
  _RecordingBundleCache(this.events);
  final List<String> events;

  @override
  Future<void> clear() async => events.add('bundle-clear');
}

class _RecordingScoresCache extends DailyHealthScoresCacheStorage {
  _RecordingScoresCache(this.events);
  final List<String> events;

  @override
  Future<void> clear() async => events.add('scores-clear');
}

class _MemoryAuthKeyStore implements AuthKeyStore {
  _MemoryAuthKeyStore(this.values, this.events);
  final Map<String, String> values;
  final List<String> events;

  @override
  Future<void> delete(String key) async {
    events.add('delete:$key');
    values.remove(key);
  }

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    events.add('write:$key');
    values[key] = value;
  }
}
