import 'package:flutter_test/flutter_test.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/models/sync_coverage.dart';
import 'package:heliolytics/services/ble/sync_window.dart';

void main() {
  final now = DateTime(2026, 7, 26, 12);

  test('clean backend honors the selected first-sync range', () {
    final coverage = SyncCoverage(
      hasData: false,
      types: {for (final code in fetchTypeCodes) code: null},
    );

    final plan = SyncWindow.plan(
      coverage: coverage,
      userBackfillDays: 14,
      now: now,
    );

    expect(plan.anchorSince, now.subtract(const Duration(days: 14)));
    for (final code in fetchTypeCodes) {
      expect(SyncWindow.sinceForType(plan, code), plan.anchorSince);
    }
    expect(plan.logLines.first, contains('last 14 days'));
  });

  test('clean backend defaults to the full first-sync range', () {
    final plan = SyncWindow.plan(
      coverage: SyncCoverage(
        hasData: false,
        types: {for (final code in fetchTypeCodes) code: null},
      ),
      now: now,
    );

    expect(
      plan.anchorSince,
      now.subtract(const Duration(days: initialSyncBackfillDays)),
    );
  });

  test('existing backend data continues to use per-type coverage', () {
    final through = now.subtract(const Duration(hours: 2));
    final plan = SyncWindow.plan(
      coverage: SyncCoverage(
        hasData: true,
        dataThrough: through,
        types: {'0x01': through},
      ),
      userBackfillDays: 14,
      now: now,
    );

    expect(
      SyncWindow.sinceForType(plan, '0x01'),
      through.subtract(const Duration(minutes: syncCoverageOverlapMinutes)),
    );
  });
}
