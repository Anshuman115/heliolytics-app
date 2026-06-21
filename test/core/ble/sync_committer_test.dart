import 'package:flutter_test/flutter_test.dart';
import 'package:heliolytics/services/ble/sync_committer.dart';
import 'package:heliolytics/models/session.dart';
import 'package:heliolytics/models/session_mode.dart';
import 'package:heliolytics/models/session_catalog.dart';
import 'package:heliolytics/models/sync_payload.dart';
import 'package:heliolytics/services/cloud_sync_repository.dart';

class _MockRepo implements CloudSyncRepository {
  SyncPayload? lastPayload;
  Object? lastError;

  @override
  Future<void> uploadPayload(SyncPayload payload) async {
    if (lastError != null) throw lastError!;
    lastPayload = payload;
  }
}

SyncPayload _samplePayload() {
  final session = Session(
    sessionId: 's1',
    startedAt: DateTime.utc(2025, 6, 12),
    deviceMac: 'aa:bb',
    fetchWindowHours: 24,
    listenDurationSec: 0,
    mode: SessionMode.fetchAndListen,
    entries: const [],
    unsolicited: const [],
  );
  return SyncPayload(
    session: session,
    catalog: SessionCatalog(sessionId: 's1', chunked: const [], unsolicited: const []),
    rawByCode: const {},
  );
}

void main() {
  test('commit uploads payload and refreshes health', () async {
    final repo = _MockRepo();
    var refreshed = false;
    final logs = <String>[];

    final committer = SyncCommitter(
      upload: repo.uploadPayload,
      isConfigured: () async => true,
      onHealthRefresh: () => refreshed = true,
      log: logs.add,
    );

    final payload = _samplePayload();
    await committer.commit(payload);

    expect(repo.lastPayload, payload);
    expect(refreshed, isTrue);
    expect(logs.any((l) => l.contains('upload done')), isTrue);
  });

  test('commit surfaces upload errors', () async {
    final repo = _MockRepo()..lastError = Exception('network');
    final committer = SyncCommitter(
      upload: repo.uploadPayload,
      isConfigured: () async => true,
      onHealthRefresh: () {},
      log: (_) {},
    );

    expect(
      () => committer.commit(_samplePayload()),
      throwsA(isA<Exception>()),
    );
  });

  test('commit skips when API not configured', () async {
    final repo = _MockRepo();
    final committer = SyncCommitter(
      upload: repo.uploadPayload,
      isConfigured: () async => false,
      onHealthRefresh: () {},
      log: (_) {},
    );

    await committer.commit(_samplePayload());
    expect(repo.lastPayload, isNull);
  });
}
