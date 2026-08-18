import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliolytics/models/day_bundle.dart';
import 'package:heliolytics/providers/cloud_sync_provider.dart';
import 'package:heliolytics/providers/day_bundle_provider.dart';
import 'package:heliolytics/providers/detail_metrics_provider.dart';
import 'package:heliolytics/services/ble/auth/auth_key_store.dart';
import 'package:heliolytics/services/cache/daily_bundle_cache_storage.dart';
import 'package:heliolytics/services/config/api_config_storage.dart';
import 'package:heliolytics/services/metrics_api_client.dart';

void main() {
  test('a failed bundle fetch never writes the historical cache', () async {
    final expected = StateError('request failed');
    final cache = _RecordingBundleCache();
    final container = ProviderContainer(
      overrides: [
        apiConfiguredProvider.overrideWith((ref) async => true),
        dailyBundleCacheStorageProvider.overrideWithValue(cache),
        metricsApiClientProvider.overrideWithValue(
          _ThrowingMetricsApiClient(expected),
        ),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(dayBundleProvider('2026-01-01').future),
      throwsA(same(expected)),
    );
    expect(cache.writeCount, 0);
  });
}

class _ThrowingMetricsApiClient extends MetricsApiClient {
  _ThrowingMetricsApiClient(this.error)
    : super(ApiConfigStorage(_EmptyAuthKeyStore()), dio: Dio());

  final Object error;

  @override
  Future<DayBundle> fetchDayBundle(String dayKey) => Future.error(error);
}

class _RecordingBundleCache extends DailyBundleCacheStorage {
  int writeCount = 0;

  @override
  Future<DayBundle?> read(String dayKey) async => null;

  @override
  Future<void> write(String dayKey, DayBundle bundle) async {
    writeCount++;
  }
}

class _EmptyAuthKeyStore implements AuthKeyStore {
  @override
  Future<void> delete(String key) async {}

  @override
  Future<String?> read(String key) async => null;

  @override
  Future<void> write(String key, String value) async {}
}
