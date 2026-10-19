import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliolytics/models/band_session_state.dart';
import 'package:heliolytics/models/dump_status.dart';
import 'package:heliolytics/models/session_state.dart';
import 'package:heliolytics/models/session.dart';
import 'package:heliolytics/models/session_catalog.dart';
import 'package:heliolytics/models/session_mode.dart';
import 'package:heliolytics/models/sync_payload.dart';
import 'package:heliolytics/providers/band_session_provider.dart';
import 'package:heliolytics/services/ble/auth/auth_key_store.dart';
import 'package:heliolytics/services/ble/auth/auth_key_storage.dart';
import 'package:heliolytics/services/ble/sync_fetcher.dart';
import 'package:heliolytics/services/ble/band_link_port.dart';
import 'package:heliolytics/services/ble/sync_session_port.dart';
import 'package:heliolytics/services/ble/sync_page_anchor.dart';
import 'package:heliolytics/services/ble/sync_window_plan.dart';
import 'package:heliolytics/services/ble/sync_orchestrator_refetch.dart';
import 'package:heliolytics/services/ble/sync_session_log.dart';
import 'package:heliolytics/services/ble/sync_type_catalog.dart';
import 'strap_health_config_provider_test.dart'
    show TestBandSession, HealthBandLink, harness;
import 'health_config_service_test.dart' show FakeHealthPort;

/// The container's [Ref], so orchestrator functions run outside a build.
final testRefProvider = Provider<Ref>((ref) => ref);

class MemoryAuthStore implements AuthKeyStore {
  final values = <String, String>{};
  @override
  Future<void> write(String key, String value) async => values[key] = value;
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> delete(String key) async => values.remove(key);
}

class MemorySessions implements SyncSessionPort {
  var count = 0;
  final sessions = <String, Session>{};
  final catalogs = <String, SessionCatalog>{};

  @override
  Future<String> createSession({
    required String? deviceMac,
    required int fetchWindowHours,
    required int listenDurationSec,
    required SessionMode mode,
  }) async {
    final id = 'session-${++count}';
    sessions[id] = Session(
      sessionId: id,
      startedAt: DateTime.utc(2026, 1, count),
      deviceMac: deviceMac,
      fetchWindowHours: fetchWindowHours,
      listenDurationSec: listenDurationSec,
      mode: mode,
      entries: const [],
      unsolicited: const [],
    );
    return id;
  }

  @override
  Future<Session> readSessionJson(String sessionId) async =>
      sessions[sessionId]!;
  @override
  Future<void> writeSessionJson(Session session) async =>
      sessions[session.sessionId] = session;
  @override
  Future<void> writeCatalogJson(SessionCatalog catalog) async =>
      catalogs[catalog.sessionId] = catalog;
  @override
  Future<String?> latestSessionId() async =>
      count == 0 ? null : 'session-$count';
}

class EmptyBand implements BandLinkPort {
  var fetchCalls = 0;
  final requested = <int>[];
  final windows = <DateTime>[];
  final List<int> bytes;
  EmptyBand({this.bytes = const []});
  @override
  Future<bool> connectAndAuth({
    required String mac,
    required Uint8List authKey,
    bool commsOnly = false,
  }) async => true;
  @override
  Future<TypeFetchResult> fetchCode(int code, DateTime since) async {
    fetchCalls++;
    requested.add(code);
    windows.add(since);
    return (
      raw: Uint8List.fromList(bytes),
      expected: 0,
      skipped: false,
      outcome: TypeFetchOutcome.complete,
      roundStart: null,
      roundSegments: const <SyncPageAnchor>[],
    );
  }

  @override
  Future<void> startLiveHeartRate() async {}
  @override
  Future<void> stopLiveHeartRate() async {}
  @override
  Stream<int>? get liveBpmStream => null;
  @override
  bool get isLiveHeartRateActive => false;
  @override
  Future<void> disconnect() async {}
  @override
  int? get batteryPercent => null;
}

/// HEALTH readback: all-day off, low alert 0, version 3.
Uint8List allDayOffFrame() => Uint8List.fromList([
  0x04,
  0x01,
  0x08,
  0x03,
  0x01,
  0x03,
  0x12,
  0x0b,
  0x01,
  0x31,
  0x0b,
  0x00,
  0x32,
  0x10,
  0x00,
  0x04,
  0x00,
  0x50,
  0x55,
  0x5a,
]);

class RefetchLink extends HealthBandLink {
  RefetchLink(
    super.port, {
    this.bytes = const [],
    this.outcome = TypeFetchOutcome.complete,
  });

  final List<int> bytes;
  final TypeFetchOutcome outcome;
  final requested = <int>[];

  @override
  Future<TypeFetchResult> fetchCode(int code, DateTime since) async {
    requested.add(code);
    return (
      raw: Uint8List.fromList(bytes),
      expected: 0,
      skipped: false,
      outcome: outcome,
      roundStart: null,
      roundSegments: const <SyncPageAnchor>[],
    );
  }
}

void main() {
  final plan = SyncWindowPlan(
    anchorSince: DateTime.utc(2026, 1, 1),
    perTypeSince: const {},
    logLines: const [],
  );
  for (final code in productionFetchTypeCodes) {
    test(
      'canonical production refetch $code is accepted by run and fetch with its own cursor',
      () async {
        final store = MemorySessions();
        final client = EmptyBand(bytes: const [2, 0, 1, 2]);
        final cursor = DateTime.utc(2026, 2, 3, 4);
        final typedPlan = SyncWindowPlan(
          anchorSince: plan.anchorSince,
          perTypeSince: {code: cursor},
          logLines: const [],
        );
        final fetcher = SyncFetcher(
          log: (_) {},
          store: store,
          auth: AuthKeyStorage(store: MemoryAuthStore()),
        );
        final first = await fetcher.run(
          mac: 'AA:BB',
          authKey: Uint8List(16),
          client: client,
          plan: typedPlan,
          singleTypeCode: code,
        );
        final second = await fetcher.fetch(
          client: client,
          mac: 'AA:BB',
          plan: typedPlan,
          singleTypeCode: code,
        );
        expect(first, isNotNull);
        expect(second, isNotNull);
        expect(client.requested, [
          int.parse(code.substring(2), radix: 16),
          int.parse(code.substring(2), radix: 16),
        ]);
        expect(client.windows, [cursor, cursor]);
        expect(store.count, 2);
        expect(first!.payload.catalog.chunked.single.code, code);
        expect(second!.payload.catalog.chunked.single.code, code);
        expect(first.payload.rawByCode.keys, [code]);
        expect(second.payload.rawByCode.keys, [code]);
        expect(first.payload.rawByCode[code], [2, 0, 1, 2]);
        expect(first.payload.session.endedAt, isNotNull);
        expect(second.payload.session.endedAt, isNotNull);
      },
    );
  }

  test(
    'full production sync requests every production type code in order',
    () async {
      final client = EmptyBand();
      final fetcher = SyncFetcher(
        log: (_) {},
        store: MemorySessions(),
        auth: AuthKeyStorage(store: MemoryAuthStore()),
      );
      await fetcher.fetch(client: client, mac: 'AA:BB', plan: plan);
      expect(
        client.requested,
        productionFetchTypeCodes.map(
          (code) => int.parse(code.substring(2), radix: 16),
        ),
      );
    },
  );

  for (final code in ['0x39', '0x3A', '0x3B']) {
    test(
      'runRefetch $code rejects before connection, HEALTH commands or session creation',
      () async {
        final port = FakeHealthPort([]);
        final session = TestBandSession(() => HealthBandLink(port));
        final (container, auth, _) = await harness(session);
        final store = MemorySessions();
        final emitted = <SessionSnapshot>[];
        final entry = Provider<Future<void>>(
          (ref) => runRefetch(
            ref: ref,
            auth: auth,
            store: store,
            sessionLog: SyncSessionLog(),
            codeStr: code,
            setPayload: (_) =>
                fail('Forbidden refetch cannot create a payload'),
            emit: emitted.add,
          ),
        );
        await container.read(entry);
        expect(session.connects, 0);
        expect(port.sent, isEmpty);
        expect(store.count, 0);
        expect(emitted.single.state, SessionState.error);
        expect(
          emitted.single.lastErrorMessage,
          contains('Unsupported production refetch type'),
        );
      },
    );
  }

  test('per-type refetch allocates a new immutable session envelope', () async {
    final store = MemorySessions();
    final client = EmptyBand();
    final fetcher = SyncFetcher(
      log: (_) {},
      store: store,
      auth: AuthKeyStorage(store: MemoryAuthStore()),
    );

    final first = await fetcher.fetch(
      client: client,
      mac: 'AA:BB',
      plan: plan,
      singleTypeCode: '0x25',
    );
    final second = await fetcher.fetch(
      client: client,
      mac: 'AA:BB',
      plan: plan,
      singleTypeCode: '0x25',
    );

    expect(
      first!.payload.session.sessionId,
      isNot(second!.payload.session.sessionId),
    );
    expect(
      store.catalogs[first.payload.session.sessionId]!.chunked,
      hasLength(1),
    );
    expect(
      store.catalogs[second.payload.session.sessionId]!.chunked,
      hasLength(1),
    );
  });

  test(
    'refetch after a full capture leaves the original envelope and raw blobs unchanged',
    () async {
      final store = MemorySessions();
      final client = EmptyBand(bytes: const [2, 1, 2, 3]);
      final fetcher = SyncFetcher(
        log: (_) {},
        store: store,
        auth: AuthKeyStorage(store: MemoryAuthStore()),
      );
      final full = (await fetcher.fetch(
        client: client,
        mac: 'AA:BB',
        plan: plan,
      ))!;
      final originalCatalog = full.payload.catalog.toJson();
      final originalEnd = full.payload.session.endedAt;
      final refetch = (await fetcher.fetch(
        client: client,
        mac: 'AA:BB',
        plan: plan,
        singleTypeCode: '0x25',
      ))!;
      expect(
        refetch.payload.session.sessionId,
        isNot(full.payload.session.sessionId),
      );
      expect(
        refetch.payload.catalog.sessionId,
        refetch.payload.session.sessionId,
      );
      expect(refetch.payload.rawByCode.keys, ['0x25']);
      expect(refetch.payload.catalog.chunked.single.code, '0x25');
      expect(refetch.payload.session.endedAt, isNotNull);
      expect(
        store.catalogs[full.payload.session.sessionId]!.toJson(),
        originalCatalog,
      );
      expect(
        store.sessions[full.payload.session.sessionId]!.endedAt,
        originalEnd,
      );
      expect(full.payload.rawByCode.keys, productionFetchTypeCodes);
      for (final bytes in full.payload.rawByCode.values) {
        expect(bytes, [2, 1, 2, 3]);
      }
      expect(
        store.catalogs[refetch.payload.session.sessionId]!.toJson(),
        refetch.payload.catalog.toJson(),
      );
      expect(
        store.count,
        2,
        reason: 'Refetch allocates exactly one new session',
      );
    },
  );

  test(
    'forbidden readiness/resting-HR/training refetch fails before BLE or session creation',
    () async {
      final store = MemorySessions();
      final client = EmptyBand();
      final fetcher = SyncFetcher(
        log: (_) {},
        store: store,
        auth: AuthKeyStorage(store: MemoryAuthStore()),
      );

      for (final code in ['0x39', '0x3A', '0x3B']) {
        expect(
          await fetcher.fetch(
            client: client,
            mac: 'AA:BB',
            plan: plan,
            singleTypeCode: code,
          ),
          isNull,
        );
      }
      expect(store.count, 0);
      expect(client.fetchCalls, 0);
    },
  );

  test(
    'empty per-type refetch is committed, not reported as failure',
    () async {
      final store = MemorySessions();
      final link = RefetchLink(FakeHealthPort([allDayOffFrame()]));
      final session = TestBandSession(() => link);
      final (container, auth, _) = await harness(session);
      final emitted = <SessionSnapshot>[];
      SyncPayload? published;
      final sessionLog = SyncSessionLog();
      await runRefetch(
        ref: container.read(testRefProvider),
        auth: auth,
        store: store,
        sessionLog: sessionLog,
        codeStr: '0x13',
        setPayload: (payload) => published = payload,
        emit: emitted.add,
      );

      expect(link.requested, [0x13]);
      expect(
        store.count,
        1,
        reason: 'An empty refetch commits its own session',
      );
      expect(published, isNotNull);
      expect(published!.rawByCode, isEmpty);
      expect(
        emitted.map((snapshot) => snapshot.state),
        contains(SessionState.connected),
      );
      expect(
        emitted.where((snapshot) => snapshot.error != SessionError.none),
        isEmpty,
        reason: 'An empty success is not a failure',
      );
      expect(
        emitted.where((snapshot) => snapshot.state == SessionState.error),
        isEmpty,
        reason: 'A commit that skips upload must not emit a terminal error',
      );

      final stored = store.sessions.values.single;
      expect(
        stored.endedAt,
        isNotNull,
        reason: 'The refetch session is finalized, not left open',
      );
      final catalog = store.catalogs[stored.sessionId]!;
      expect(catalog.sessionId, stored.sessionId);
      expect(catalog.chunked, hasLength(1));
      expect(catalog.chunked.single.code, '0x13');
      expect(catalog.chunked.single.status, DumpStatus.empty);

      expect(
        sessionLog.logs.where(
          (line) => line.endsWith('cloud upload skipped (API not configured)'),
        ),
        hasLength(1),
        reason: 'commitPayload reached the commit path exactly once',
      );
    },
  );

  test('disconnect during refetch emits bleDisconnected', () async {
    final store = MemorySessions();
    final link = RefetchLink(
      FakeHealthPort([allDayOffFrame()]),
      outcome: TypeFetchOutcome.disconnected,
    );
    final session = TestBandSession(() => link);
    final (container, auth, _) = await harness(session);
    final emitted = <SessionSnapshot>[];
    await runRefetch(
      ref: container.read(testRefProvider),
      auth: auth,
      store: store,
      sessionLog: SyncSessionLog(),
      codeStr: '0x13',
      setPayload: (_) => fail('A disconnect must not publish a payload'),
      emit: emitted.add,
    );

    expect(emitted.last.error, SessionError.bleDisconnected);
    expect(emitted.last.state, SessionState.error);
    expect(emitted.last.lastErrorMessage, 'Strap disconnected during refetch.');
    final band = container.read(bandSessionProvider.notifier);
    expect(
      band.tryAcquire(BandSessionOp.sync),
      isNull,
      reason: 'The sync lane is released after a disconnect',
    );
    band.release(BandSessionOp.sync);
  });
}
