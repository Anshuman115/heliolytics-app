import 'package:intl/intl.dart';

final _stepsFmt = NumberFormat.decimalPattern();
final _dayFmt = DateFormat.MMMEd();
final _timeFmt = DateFormat.MMMEd().add_jm();

String formatSteps(int steps) => '${_stepsFmt.format(steps)} steps';

/// Exact step count with thousands separators (e.g. "3,708") — no "k" rounding.
String formatStepCount(int steps) => _stepsFmt.format(steps);

String formatDayLabel(String dayKey) {
  final parts = dayKey.split('-');
  if (parts.length != 3) return dayKey;
  final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(d.year, d.month, d.day);
  final diff = today.difference(target).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return _dayFmt.format(d);
}

/// Compact label for top-bar date pill — no weekday names.
String formatNavDayLabel(String dayKey) {
  final parts = dayKey.split('-');
  if (parts.length != 3) return dayKey.toUpperCase();
  final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(d.year, d.month, d.day);
  final diff = today.difference(target).inDays;
  if (diff == 0) return 'TODAY';
  if (diff == 1) return 'YESTERDAY';
  return DateFormat('MMM d').format(d).toUpperCase();
}

String formatWorkoutTime(DateTime dt) => _timeFmt.format(dt.toLocal());

final _hmFmt = DateFormat.Hm();

String formatChartTime(DateTime dt) => _hmFmt.format(dt.toLocal());

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

String formatStrainDecimal(int? strain) {
  if (strain == null) return '—';
  return (strain / 10).toStringAsFixed(1);
}

String formatSyncAgo(DateTime? at) {
  if (at == null) return 'Never synced';
  final diff = DateTime.now().difference(at);
  if (diff.inMinutes < 1) return 'Synced just now';
  if (diff.inHours < 1) return 'Synced ${diff.inMinutes}m ago';
  if (diff.inHours < 24) return 'Synced ${diff.inHours}h ago';
  return 'Synced ${diff.inDays}d ago';
}
