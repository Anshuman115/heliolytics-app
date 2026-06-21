import 'package:flutter_test/flutter_test.dart';
import 'package:heliolytics/services/ble/sync_window.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/models/sync_coverage.dart';

void main() {
  final now = DateTime(2025, 6, 12, 12, 0);
  final backfillSince =
      now.subtract(const Duration(days: initialSyncBackfillDays));

  group('SyncWindow.plan', () {
    test('coverage failure backfills all fetch types', () {
      final plan = SyncWindow.plan(coverageFailed: true, now: now);

      expect(plan.anchorSince, backfillSince);
      expect(plan.perTypeSince.keys, containsAll(fetchTypeCodes));
      for (final code in fetchTypeCodes) {
        expect(plan.perTypeSince[code], backfillSince);
      }
      expect(plan.logLines.first, contains('backfill'));
    });

    test('api not configured backfills all types', () {
      final plan = SyncWindow.plan(apiConfigured: false, now: now);

      expect(plan.anchorSince, backfillSince);
      expect(plan.logLines.first, contains('configure Cloud API'));
    });

    test('per-type null uses 10-day backfill for that type', () {
      final plan = SyncWindow.plan(
        coverage: SyncCoverage(
          hasData: true,
          types: {'0x05': null, '0x48': DateTime(2025, 6, 10, 8, 0)},
        ),
        now: now,
      );

      expect(SyncWindow.sinceForType(plan, '0x05'), backfillSince);
      final sleepSince = plan.perTypeSince['0x48']!;
      expect(
        sleepSince,
        DateTime(2025, 6, 10, 8, 0)
            .subtract(const Duration(minutes: syncCoverageOverlapMinutes)),
      );
    });

    test('per-type non-null subtracts overlap minutes', () {
      final through = DateTime(2025, 6, 11, 15, 30);
      final plan = SyncWindow.plan(
        coverage: SyncCoverage(
          hasData: true,
          types: {'0x01': through},
        ),
        now: now,
      );

      expect(
        SyncWindow.sinceForType(plan, '0x01'),
        through.subtract(const Duration(minutes: syncCoverageOverlapMinutes)),
      );
    });

    test('types without entry use anchor backfill', () {
      final plan = SyncWindow.plan(
        coverage: SyncCoverage(
          hasData: true,
          types: {'0x05': null},
        ),
        now: now,
      );

      expect(SyncWindow.sinceForType(plan, '0x48'), backfillSince);
    });

    test('null workout type uses 10-day backfill only for that type', () {
      final plan = SyncWindow.plan(
        coverage: SyncCoverage(
          hasData: true,
          types: {'0x05': null, '0x48': DateTime(2026, 6, 7, 16)},
        ),
        now: DateTime(2026, 6, 12, 12),
      );

      final since = SyncWindow.sinceForType(plan, '0x05');
      final full = DateTime(2026, 6, 12, 12)
          .subtract(const Duration(days: initialSyncBackfillDays));
      expect(since, full);
    });

    test('null sleep nap type uses 10-day backfill only for that type', () {
      final clock = DateTime(2026, 6, 12, 12);
      final plan = SyncWindow.plan(
        coverage: SyncCoverage(
          hasData: true,
          types: {'0x4E': null, '0x05': DateTime(2026, 6, 6, 20)},
        ),
        now: clock,
      );

      final since = SyncWindow.sinceForType(plan, '0x4E');
      final full =
          clock.subtract(const Duration(days: initialSyncBackfillDays));
      expect(since, full);
    });

    test('dataThrough only sets anchor with overlap', () {
      final through = DateTime(2025, 6, 11, 10, 0);
      final plan = SyncWindow.plan(
        coverage: SyncCoverage(dataThrough: through, hasData: true),
        now: now,
      );

      expect(plan.backendDataThrough, through);
      expect(
        plan.anchorSince,
        through.subtract(const Duration(minutes: syncCoverageOverlapMinutes)),
      );
    });

    test('anchorSince is earliest per-type window', () {
      final types = <String, DateTime?>{
        for (final code in fetchTypeCodes) code: DateTime(2026, 6, 8, 10),
      };
      types['0x4E'] = null;

      final plan = SyncWindow.plan(
        coverage: SyncCoverage(hasData: true, types: types),
        now: DateTime(2026, 6, 12, 12),
      );

      final full = DateTime(2026, 6, 12, 12)
          .subtract(const Duration(days: initialSyncBackfillDays));
      expect(plan.anchorSince, full);
    });

    test('log lines list per-type fetch starts', () {
      final plan = SyncWindow.plan(
        coverage: SyncCoverage(
          hasData: true,
          types: {'0x01': DateTime(2025, 6, 11, 9, 0)},
        ),
        now: now,
      );

      expect(plan.logLines.any((l) => l.contains('0x01')), isTrue);
    });
  });
}
