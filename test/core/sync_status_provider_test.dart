import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/models/sync_coverage.dart';
import 'package:heliolytics/providers/cloud_sync_provider.dart';
import 'package:heliolytics/providers/detail_metrics_provider.dart';
import 'package:heliolytics/providers/sync_status_provider.dart';
import 'package:heliolytics/services/ble/auth/auth_key_storage.dart';
import 'package:heliolytics/services/ble/auth/auth_key_store.dart';
import 'package:heliolytics/services/config/api_config_storage.dart';
import 'package:heliolytics/services/metrics_api_client.dart';
import 'package:heliolytics/services/session_store.dart';

Map<String, DateTime?> _emptyTypes() => {
  for (final code in SyncCoverage.measuredTypeCodes) code: null,
};

void main() {
  group('confirmed-sync staleness', () {
    test('exactly 72 hours is not yet stale', () {
      final at = DateTime.utc(2026, 10, 1, 12);
      final status = SyncStatus(lastSyncedAt: at);
      expect(
        status.isStaleConfirmedSyncAt(at.add(const Duration(hours: 72))),
        isFalse,
      );
      expect(
        status.isStaleConfirmedSyncAt(
          at.add(const Duration(hours: 72, seconds: 1)),
        ),
        isTrue,
      );
    });

    test('more than 72 hours is stale', () {
      final status = SyncStatus(
        lastSyncedAt: DateTime.now().subtract(
          const Duration(hours: 72, seconds: 5),
        ),
      );
      expect(status.isStaleConfirmedSync, isTrue);
    });

    test('a future timestamp never yields a negative age', () {
      final status = SyncStatus(
        lastSyncedAt: DateTime.now().add(const Duration(hours: 3)),
      );
      expect(status.timeSinceConfirmedSync, Duration.zero);
      expect(status.isStaleConfirmedSync, isFalse);
    });

    test('no confirmed sync is unknown, not stale', () {
      const status = SyncStatus();
      expect(status.timeSinceConfirmedSync, isNull);
      expect(status.isStaleConfirmedSync, isFalse);
      expect(status.needsFirstSync, isFalse);
    });

    test('dataThrough is never treated as the last sync', () {
      final coverage = SyncCoverage(
        hasData: true,
        types: _emptyTypes(),
        lastIngestAt: null,
        dataThrough: DateTime.now().subtract(const Duration(days: 20)),
      );
      final status = SyncStatus(coverage: coverage);
      expect(status.lastSyncedAt, isNull);
      expect(status.isStaleConfirmedSync, isFalse);
    });

    test('an empty server prompts the first sync', () {
      final coverage = SyncCoverage(
        hasData: false,
        types: _emptyTypes(),
        lastIngestAt: null,
        dataThrough: null,
      );
      expect(SyncStatus(coverage: coverage).needsFirstSync, isTrue);
    });
  });

  group('sync status provider', () {
    late Directory directory;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('heliolytics-status-');
    });

    tearDown(() async {
      await directory.delete(recursive: true);
    });

    test(
      'a coverage failure stays visible while battery still loads',
      () async {
        final container = _container(
          directory,
          client: _ThrowingClient(StateError('coverage failed')),
          battery: 63,
        );
        addTearDown(container.dispose);

        final status = await container.read(syncStatusProvider.future);

        expect(status.coverageError, isA<StateError>());
        expect(status.lastSyncedAt, isNull);
        expect(status.batteryPercent, 63);
        expect(status.coverageKnown, isFalse);
      },
    );

    test('a stale confirmed ingest is reported from lastIngestAt', () async {
      final lastIngest = DateTime.now().subtract(const Duration(days: 4));
      final container = _container(
        directory,
        client: _CoverageClient(
          SyncCoverage(
            hasData: true,
            types: _emptyTypes(),
            lastIngestAt: lastIngest,
            dataThrough: DateTime.now().subtract(const Duration(days: 40)),
          ),
        ),
        battery: null,
      );
      addTearDown(container.dispose);

      final status = await container.read(syncStatusProvider.future);

      expect(status.lastSyncedAt, lastIngest);
      expect(status.isStaleConfirmedSync, isTrue);
      expect(status.coverage!.dataThrough, isNotNull);
    });
  });
}

ProviderContainer _container(
  Directory directory, {
  required MetricsApiClient client,
  int? battery,
}) {
  final store = _MemoryStore({
    if (battery != null) strapBatteryStorageKey: '$battery',
  });
  return ProviderContainer(
    overrides: [
      apiConfiguredProvider.overrideWith((ref) async => true),
      metricsApiClientProvider.overrideWithValue(client),
      sessionStoreProvider.overrideWith(
        (ref) async => SessionStore(rootDir: directory),
      ),
      authKeyStoreProvider.overrideWithValue(store),
    ],
  );
}

class _CoverageClient extends MetricsApiClient {
  _CoverageClient(this.coverage)
    : super(ApiConfigStorage(_MemoryStore(const {})), dio: Dio());

  final SyncCoverage coverage;

  @override
  Future<SyncCoverage> fetchCoverage() async => coverage;
}

class _ThrowingClient extends MetricsApiClient {
  _ThrowingClient(this.error)
    : super(ApiConfigStorage(_MemoryStore(const {})), dio: Dio());

  final Object error;

  @override
  Future<SyncCoverage> fetchCoverage() => Future.error(error);
}

class _MemoryStore implements AuthKeyStore {
  _MemoryStore(this.values);

  final Map<String, String> values;

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
