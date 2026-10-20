import 'package:heliolytics/utils/ist_time.dart';

String dayKeyFor(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Today's IST day key, independent of the phone timezone.
String todayDayKey({DateTime? now}) => dayKeyFor(istToday(now: now));

/// True only for days that are closed on the IST calendar.
bool isFinalDayKey(String dayKey, {DateTime? now}) =>
    dayKey.compareTo(todayDayKey(now: now)) < 0;

/// [dayKey] moved by [days]; UTC arithmetic keeps the month and year exact.
String shiftDayKey(String dayKey, int days) {
  final date = DateTime.parse('${dayKey}T00:00:00Z');
  return dayKeyFor(date.add(Duration(days: days)));
}
