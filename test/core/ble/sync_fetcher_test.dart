import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:heliolytics/services/ble/band_link_port.dart';
import 'package:heliolytics/services/ble/sync_fetcher.dart';
import 'package:heliolytics/services/ble/sync_page_anchor.dart';
import 'package:heliolytics/services/ble/sync_session_port.dart';
import 'package:heliolytics/services/ble/sync_window.dart';
import 'package:heliolytics/models/session.dart';
import 'package:heliolytics/models/session_catalog.dart';
import 'package:heliolytics/models/session_mode.dart';
import 'package:heliolytics/models/sync_payload.dart';

class _MockBandLink implements BandLinkPort {
  final Map<int, Uint8List> responses;
  var connectCalls = 0;
  var disconnectCalls = 0;

  _MockBandLink(this.responses);

  @override
  int? get batteryPercent => 90;

  @override
  Future<bool> connectAndAuth({
    required String mac,
    required Uint8List authKey,
  }) async {
    connectCalls++;
    return true;
  }

  @override
  Future<void> disconnect() async => disconnectCalls++;

  @override
  Future<TypeFetchResult> fetchCode(int code, DateTime since) async {
    final raw = responses[code] ?? Uint8List(0);
    return (
      raw: raw,
      expected: raw.isEmpty ? 0 : 1,
      skipped: false,
      roundStart: null,
      roundSegments: <SyncPageAnchor>[],
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
}

class _FakeStore implements SyncSessionPort {
  final Map<String, Session> sessions = {};

  @override
  Future<String> createSession({
    required String? deviceMac,
    required int fetchWindowHours,
    required int listenDurationSec,
    required SessionMode mode,
  }) async {
    const id = 'sess-1';
    sessions[id] = Session(
      sessionId: id,
      startedAt: DateTime.utc(2025, 6, 12),
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
  Future<Session> readSessionJson(String sessionId) async => sessions[sessionId]!;

  @override
  Future<void> writeSessionJson(Session session) async {
    sessions[session.sessionId] = session;
  }

  @override
  Future<void> writeCatalogJson(SessionCatalog catalog) async {}

  @override
  Future<String?> latestSessionId() async =>
      sessions.isEmpty ? null : sessions.keys.first;
}

SyncPayload _basePayload() => SyncPayload(
      session: Session(
        sessionId: 'base',
        startedAt: DateTime.utc(2025, 6, 11),
        deviceMac: 'aa:bb:cc',
        fetchWindowHours: 24,
        listenDurationSec: 0,
        mode: SessionMode.fetchAndListen,
        entries: const [],
        unsolicited: const [],
      ),
      catalog: const SessionCatalog(
        sessionId: 'base',
        chunked: [],
        unsolicited: [],
      ),
      rawByCode: const {},
    );

void main() {
  final plan = SyncWindow.plan(coverageFailed: true, now: DateTime(2025, 6, 12));

  test('run connects and fetches single type payload', () async {
    final client = _MockBandLink({0x49: Uint8List.fromList([1, 2, 3, 4])});
    final fetcher = SyncFetcher(
      log: (_) {},
      store: _FakeStore(),
      linkFactory: (_) => client,
    );

    final outcome = await fetcher.run(
      mac: 'aa:bb:cc',
      authKey: Uint8List.fromList([1]),
      plan: plan,
      singleTypeCode: '0x49',
      mergeBase: _basePayload(),
      disconnectAfter: true,
    );

    expect(outcome, isNotNull);
    expect(client.connectCalls, 1);
    expect(client.disconnectCalls, 1);
    expect(outcome!.payload.rawByCode['0x49']?.length, 4);
    expect(outcome.typeResults.single.status, 'ok');
  });
}
