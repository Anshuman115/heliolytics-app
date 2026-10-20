import 'package:intl/intl.dart';

import 'package:heliolytics/utils/ist_time.dart';

final _stepsFmt = NumberFormat.decimalPattern();
final _dayFmt = DateFormat.MMMEd();
final _timeFmt = DateFormat.MMMEd().add_jm();

String formatSteps(int steps) => '${_stepsFmt.format(steps)} steps';

/// Exact step count with thousands separators (e.g. "3,708") — no "k" rounding.
String formatStepCount(int steps) => _stepsFmt.format(steps);

int _daysBeforeIstToday(DateTime date, DateTime? now) {
  final today = istToday(now: now);
  return DateTime.utc(
    today.year,
    today.month,
    today.day,
  ).difference(DateTime.utc(date.year, date.month, date.day)).inDays;
}

String formatDayLabel(String dayKey, {DateTime? now}) {
  final parts = dayKey.split('-');
  if (parts.length != 3) return dayKey;
  final d = DateTime.utc(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
  final diff = _daysBeforeIstToday(d, now);
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return _dayFmt.format(d);
}

/// Compact label for top-bar date navigation.
String formatNavDayLabel(String dayKey, {DateTime? now}) {
  final parts = dayKey.split('-');
  if (parts.length != 3) return dayKey.toUpperCase();
  final d = DateTime.utc(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
  final diff = _daysBeforeIstToday(d, now);
  if (diff == 0) return 'TODAY';
  if (diff == 1) return 'YESTERDAY';
  return DateFormat('EEE, MMM d').format(d).toUpperCase();
}

String formatSleepComparisonDay(String dayKey) {
  final parts = dayKey.split('-');
  if (parts.length != 3) return dayKey;
  final date = DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
  return DateFormat('EEE, MMM d').format(date);
}

String formatWorkoutTime(DateTime dt) => _timeFmt.format(istWallClock(dt));

final _hmFmt = DateFormat.Hm();
final _jmFmt = DateFormat.jm();

String formatChartTime(DateTime dt) => _hmFmt.format(istWallClock(dt));

/// Clock time on the IST wall clock, for activity and stress labels.
String formatTimeOfDay(DateTime dt) => _jmFmt.format(istWallClock(dt));

String formatDurationSec(int sec) {
  if (sec >= 3600) {
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    return '${h}h ${m}m';
  }
  return '${sec ~/ 60}m ${sec % 60}s';
}

String formatSleepMins(int? mins) {
  if (mins == null) return '—';
  return '${mins ~/ 60}h ${mins % 60}m';
}

/// Compact h:mm for activity tiles (e.g. 2:18).
String formatSleepDurationShort(int? mins) {
  if (mins == null) return '—';
  final h = mins ~/ 60;
  final m = mins % 60;
  return '$h:${m.toString().padLeft(2, '0')}';
}

/// One decimal for TRIMP training load.
String formatLoad(double? load) {
  if (load == null) return '—';
  return load.toStringAsFixed(1);
}

String formatSyncAgo(DateTime? at) {
  if (at == null) return 'Never synced';
  final diff = DateTime.now().difference(at);
  if (diff.inMinutes < 1) return 'Synced just now';
  if (diff.inHours < 1) return 'Synced ${diff.inMinutes}m ago';
  if (diff.inHours < 24) return 'Synced ${diff.inHours}h ago';
  return 'Synced ${diff.inDays}d ago';
}
