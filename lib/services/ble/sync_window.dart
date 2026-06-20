import 'package:heliolytics/services/ble/sync_window_plan.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/models/sync_coverage.dart';

class SyncWindow {
  SyncWindow._();

  static SyncWindowPlan plan({
    SyncCoverage? coverage,
    bool coverageFailed = false,
    bool apiConfigured = true,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    if (!apiConfigured) {
      return _backfillAll(clock, 'Fetch: configure Cloud API before syncing');
    }
    if (coverageFailed || coverage == null) {
      return _backfillAll(
        clock,
        'Fetch: coverage unavailable — backfill $initialSyncBackfillDays days',
      );
    }
    if (coverage.types.isNotEmpty) {
      return _fromPerType(coverage, clock);
    }
    if (coverage.dataThrough != null) {
      return _fromDataThrough(coverage.dataThrough!, clock);
    }
    if (!coverage.hasData) {
      return _backfillAll(
        clock,
        'Fetch: backend empty — first sync last $initialSyncBackfillDays days',
      );
    }
    return _backfillAll(
      clock,
      'Fetch: coverage unavailable — backfill $initialSyncBackfillDays days',
    );
  }

  static DateTime sinceForType(SyncWindowPlan plan, String typeCode) {
    return plan.perTypeSince[typeCode] ?? plan.anchorSince;
  }

  static SyncWindowPlan _fromPerType(SyncCoverage cov, DateTime clock) {
    final perType = <String, DateTime>{};
    final logs = <String>[
      'Fetch: per-type backend coverage (${cov.types.length} types)',
    ];
    for (final code in fetchTypeCodes) {
      final since = _sinceForEntry(code, cov.types, clock);
      perType[code] = since;
      logs.add('  $code: fetch from ${since.toIso8601String()}');
    }
    return SyncWindowPlan(
      anchorSince: _earliest(perType.values, clock),
      perTypeSince: perType,
      logLines: logs,
      backendDataThrough: cov.dataThrough,
    );
  }

  static SyncWindowPlan _fromDataThrough(DateTime through, DateTime clock) {
    final since =
        through.subtract(const Duration(minutes: syncCoverageOverlapMinutes));
    final perType = _uniformSince(since);
    return SyncWindowPlan(
      anchorSince: since,
      perTypeSince: perType,
      backendDataThrough: through,
      logLines: [
        'Fetch: backend data through ${through.toIso8601String()} → '
        'strap from ${since.toIso8601String()}',
        ..._perTypeLogLines(perType),
      ],
    );
  }

  static SyncWindowPlan _backfillAll(DateTime clock, String headline) {
    final since =
        clock.subtract(const Duration(days: initialSyncBackfillDays));
    final perType = _uniformSince(since);
    return SyncWindowPlan(
      anchorSince: since,
      perTypeSince: perType,
      logLines: [headline, ..._perTypeLogLines(perType)],
    );
  }

  static DateTime _sinceForEntry(
    String code,
    Map<String, DateTime?> types,
    DateTime clock,
  ) {
    if (!types.containsKey(code)) {
      return clock.subtract(const Duration(days: initialSyncBackfillDays));
    }
    final through = types[code];
    if (through == null) {
      return clock.subtract(const Duration(days: initialSyncBackfillDays));
    }
    return through.subtract(const Duration(minutes: syncCoverageOverlapMinutes));
  }

  static Map<String, DateTime> _uniformSince(DateTime since) {
    return {for (final c in fetchTypeCodes) c: since};
  }

  static List<String> _perTypeLogLines(Map<String, DateTime> perType) {
    return perType.entries
        .map((e) => '  ${e.key}: fetch from ${e.value.toIso8601String()}')
        .toList();
  }

  static DateTime _earliest(Iterable<DateTime> values, DateTime clock) {
    var earliest = clock;
    for (final v in values) {
      if (v.isBefore(earliest)) earliest = v;
    }
    return earliest;
  }
}
