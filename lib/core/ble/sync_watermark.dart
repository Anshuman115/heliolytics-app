import 'package:heliolytics/core/ble/auth/auth_key_store.dart';

/// Per-metric incremental sync watermarks (lastTs per metric key).
class SyncWatermark {
  final AuthKeyStore _store;
  SyncWatermark(this._store);

  static const _prefix = 'sync_wm_';

  Future<DateTime?> read(String metric) async {
    final raw = await _store.read('$_prefix$metric');
    if (raw == null || raw.isEmpty) return null;
    final ms = int.tryParse(raw);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> write(String metric, DateTime ts) =>
      _store.write('$_prefix$metric', '${ts.millisecondsSinceEpoch}');

  Future<DateTime> sinceFor(String metric, DateTime backfill) async {
    final last = await read(metric);
    if (last == null) return backfill;
    return last.add(const Duration(minutes: 1));
  }
}
