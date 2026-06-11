import 'package:heliolytics/core/ble/auth/auth_key_store.dart';

/// Tracks local fallback when backend coverage is unavailable.
/// Primary fetch window comes from GET /api/v1/metrics/coverage.
class SyncCursor {
  SyncCursor(this._store);

  final AuthKeyStore _store;
  static const _key = 'sync_last_success_utc';

  Future<DateTime?> readLastSuccess() async {
    final raw = await _store.read(_key);
    if (raw == null || raw.isEmpty) return null;
    final ms = int.tryParse(raw);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
  }

  /// Start of the next BLE fetch window (inclusive).
  Future<DateTime> fetchSince({required int initialBackfillDays}) async {
    final last = await readLastSuccess();
    if (last == null) {
      return DateTime.now().subtract(Duration(days: initialBackfillDays));
    }
    return last;
  }

  Future<void> markSuccess(DateTime endedAt) async {
    await _store.write(_key, '${endedAt.toUtc().millisecondsSinceEpoch}');
  }

  Future<void> clear() => _store.delete(_key);
}
