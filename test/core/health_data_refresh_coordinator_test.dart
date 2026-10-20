import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/models/day_bundle.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/providers/activity_history_provider.dart';
import 'package:heliolytics/providers/api_config_form_provider.dart';
import 'package:heliolytics/providers/day_bundle_provider.dart';
import 'package:heliolytics/providers/detail_metrics_provider.dart';
import 'package:heliolytics/providers/health_data_refresh_coordinator.dart';
import 'package:heliolytics/providers/metric_trend_provider.dart';
import 'package:heliolytics/providers/sync_status_provider.dart';
import 'package:heliolytics/services/ble/auth/auth_key_storage.dart';
import 'package:heliolytics/services/ble/auth/auth_key_store.dart';
import 'package:heliolytics/services/cache/daily_bundle_cache_storage.dart';

const _key =
    'phone.000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f';

DayMetric _day(String key) =>
    DayMetric(dayKey: key, updatedAt: DateTime.utc(2026, 8, 2));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      legacyDailyHealthScoresCacheKey: '{"2026-08-01":{}}',
    });
  });

  test('refresh deletes the selected historical cache entry first', () async {
    const dayKey = '2026-08-01';
    final events = <String>[];
    final container = ProviderContainer(
      overrides: [
        dailyBundleCacheStorageProvider.overrideWithValue(
          _RecordingBundleCache(events),
        ),
        dayBundleProvider.overrideWith((ref, key) async {
          events.add('bundle-load:$key');
          return DayBundle(day: _day(key));
        }),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(healthDataRefreshCoordinatorProvider)
        .refreshDay(dayKey);

    expect(events, ['bundle-delete:$dayKey', 'bundle-load:$dayKey']);
  });

  test('config change clears caches before invalidating health data', () async {
    const dayKey = '2026-08-01';
    final events = <String>[];
    final builds = <String, int>{};
    void built(String name) => builds[name] = (builds[name] ?? 0) + 1;
    final store = _MemoryAuthKeyStore({
      'api_base_url': 'https://old.example',
      'api_key_v2': _key,
    }, events);
    final container = ProviderContainer(
      overrides: [
        authKeyStoreProvider.overrideWithValue(store),
        dailyBundleCacheStorageProvider.overrideWithValue(
          _RecordingBundleCache(events),
        ),
        dayBundleProvider.overrideWith((ref, key) async {
          built('bundle');
          return DayBundle(day: _day(key));
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
        .save('https://new.example', _key);

    final firstWrite = events.indexWhere((event) => event.startsWith('write:'));
    expect(firstWrite, isNonNegative);
    expect(events.take(firstWrite).toSet(), {'bundle-clear'});
    expect(store.values['api_base_url'], 'https://new.example');
    expect(store.values['api_key_v2'], _key);

    await _loadHealthData(container, dayKey);
    expect(builds.values, everyElement(2));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(legacyDailyHealthScoresCacheKey), isFalse);
  });

  test('saving an invalid key fails before touching caches', () async {
    final events = <String>[];
    final store = _MemoryAuthKeyStore({
      'api_base_url': 'https://old.example',
      'api_key_v2': _key,
    }, events);
    final container = ProviderContainer(
      overrides: [
        authKeyStoreProvider.overrideWithValue(store),
        dailyBundleCacheStorageProvider.overrideWithValue(
          _RecordingBundleCache(events),
        ),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container
          .read(apiConfigFormProvider.notifier)
          .save('https://new.example', _key.replaceFirst('phone', 'web')),
      throwsA(anything),
    );
    expect(events, isEmpty);
  });
}

Future<void> _loadHealthData(ProviderContainer container, String dayKey) async {
  await Future.wait<dynamic>([
    container.read(dayBundleProvider(dayKey).future),
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

  @override
  Future<void> delete(String dayKey) async =>
      events.add('bundle-delete:$dayKey');
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
