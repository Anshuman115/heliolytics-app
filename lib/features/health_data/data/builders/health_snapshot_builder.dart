import 'package:heliolytics/core/ble/parsers/hrv.dart';
import 'package:heliolytics/core/ble/parsers/sleep_session.dart';
import 'package:heliolytics/core/utils/ist_time.dart';
import 'package:heliolytics/features/ble_discovery/data/session_store.dart';
import 'package:heliolytics/features/ble_discovery/domain/models/dump_entry.dart';
import 'package:heliolytics/features/ble_discovery/domain/models/session_catalog.dart';
import 'package:heliolytics/features/health_data/data/builders/health_day_aggregator.dart';
import 'package:heliolytics/features/health_data/domain/entities/live_strap_snapshot.dart';

/// Builds [LiveStrapSnapshot] from the latest app-private sync session only.
class HealthSnapshotBuilder {
  final SessionStore _store;
  static const int windowDays = 30;

  HealthSnapshotBuilder(this._store);

  Future<LiveStrapSnapshot?> buildLatest() async {
    final ids = await _store.listSessions();
    if (ids.isEmpty) return null;
    return build(ids.first);
  }

  Future<LiveStrapSnapshot> build(String sessionId) async {
    final session = await _store.readSessionJson(sessionId);
    final catalog = await _store.readCatalogJson(sessionId);
    final cutoff = istCutoffDaysAgo(windowDays);
    final dayMap = await HealthDayAggregator(_store)
        .build(sessionId, catalog.chunked, cutoff);
    final days = dayMap.values.toList()
      ..sort((a, b) => b.dayKey.compareTo(a.dayKey));

    return LiveStrapSnapshot(
      sessionId: sessionId,
      syncedAt: session.startedAt.toLocal(),
      days: days,
      sleepSessions: await _sleep(sessionId, catalog.chunked, cutoff),
      hrvSamples: await _hrv(sessionId, catalog.chunked, cutoff),
    );
  }

  DumpEntry? _entry(List<DumpEntry> entries, String code) {
    for (final e in entries) {
      if (e.code.toLowerCase() == code) return e;
    }
    return null;
  }

  Future<List<SleepSession>> _sleep(
    String sessionId,
    List<DumpEntry> entries,
    DateTime cutoff,
  ) async {
    if (_entry(entries, '0x48') == null) return [];
    final raw = await _store.readTypeBytes(sessionId, '0x48');
    if (raw == null || raw.isEmpty) return [];
    return SleepSessionParser.parse(raw)
        .where((s) => isOnOrAfterIstDay(s.sessionStart, cutoff))
        .toList();
  }

  Future<List<HrvSample>> _hrv(
    String sessionId,
    List<DumpEntry> entries,
    DateTime cutoff,
  ) async {
    if (_entry(entries, '0x49') == null) return [];
    final raw = await _store.readTypeBytes(sessionId, '0x49');
    if (raw == null || raw.isEmpty) return [];
    return HrvParser.parse(raw)
        .where((s) => isOnOrAfterIstDay(s.timestamp, cutoff))
        .toList();
  }
}
