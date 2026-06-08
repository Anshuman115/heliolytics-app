/// IST calendar-day key for grouping strap samples (UTC+5:30).
String istDayKey(DateTime utcOrLocal) {
  final ist = utcOrLocal.toUtc().add(const Duration(hours: 5, minutes: 30));
  final m = ist.month.toString().padLeft(2, '0');
  final d = ist.day.toString().padLeft(2, '0');
  return '${ist.year}-$m-$d';
}

DateTime istCutoffDaysAgo(int days) =>
    DateTime.now().toUtc().subtract(Duration(days: days));

bool isOnOrAfterIstDay(DateTime sampleUtc, DateTime cutoffUtc) =>
    sampleUtc.isAfter(cutoffUtc) || sampleUtc.isAtSameMomentAs(cutoffUtc);
