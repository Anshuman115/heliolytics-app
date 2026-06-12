/// Reject mis-parsed BLE timestamps (1970, 2093, etc.).
bool isPlausibleUnixSec(int sec) {
  const minSec = 1577836800; // 2020-01-01 UTC
  final maxSec = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000 + 86400;
  return sec >= minSec && sec <= maxSec;
}

bool isPlausibleStrapTime(DateTime ts) {
  final y = ts.toUtc().year;
  return y >= 2020 && y <= 2035;
}

bool isDayKeyInWindow(String dayKey, int windowDays) {
  try {
    final parts = dayKey.split('-');
    if (parts.length != 3) return false;
    final y = int.parse(parts[0]);
    if (y < 2020 || y > 2035) return false;
    final day = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    final cutoff = DateTime.now().subtract(Duration(days: windowDays));
    return !day.isBefore(DateTime(cutoff.year, cutoff.month, cutoff.day));
  } catch (_) {
    return false;
  }
}
