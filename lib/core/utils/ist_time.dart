const int istOffsetSec = 5 * 3600 + 30 * 60;

/// IST calendar-day key — matches Python fast_day_key(epoch_sec).
String istDayKeyFromEpoch(int epochSec) {
  final dayNum = (epochSec + istOffsetSec) ~/ 86400;
  final epoch = DateTime.utc(1970, 1, 1).add(Duration(days: dayNum));
  final m = epoch.month.toString().padLeft(2, '0');
  final d = epoch.day.toString().padLeft(2, '0');
  return '${epoch.year}-$m-$d';
}

String istDayKey(DateTime ts) =>
    istDayKeyFromEpoch(ts.toUtc().millisecondsSinceEpoch ~/ 1000);

/// Device/catalog roundStart ISO strings are IST wall clock, not UTC.
DateTime parseRoundStartIst(String raw) {
  final cleaned = raw.split('.').first.replaceAll('Z', '');
  final dt = DateTime.parse(cleaned);
  return DateTime.fromMillisecondsSinceEpoch(
    istWallToEpochSec(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second) *
        1000,
    isUtc: true,
  );
}

int istWallToEpochSec(int y, int mo, int d, int h, int mi, int s) =>
    DateTime.utc(y, mo, d, h, mi, s)
        .subtract(const Duration(hours: 5, minutes: 30))
        .millisecondsSinceEpoch ~/
        1000;

DateTime istCutoffDaysAgo(int days) =>
    DateTime.now().toUtc().subtract(Duration(days: days));

/// IST wall clock for catalog roundStart (device reports IST, not UTC Z).
String formatRoundStartIst(DateTime utc) {
  final istSec = utc.millisecondsSinceEpoch ~/ 1000 + istOffsetSec;
  final dayNum = istSec ~/ 86400;
  final tod = istSec % 86400;
  final base = DateTime.utc(1970, 1, 1).add(Duration(days: dayNum));
  String p2(int n) => n.toString().padLeft(2, '0');
  final h = tod ~/ 3600;
  final m = (tod % 3600) ~/ 60;
  final s = tod % 60;
  return '${base.year}-${p2(base.month)}-${p2(base.day)}T'
      '${p2(h)}:${p2(m)}:${p2(s)}';
}

bool isOnOrAfterIstDay(DateTime sampleUtc, DateTime cutoffUtc) =>
    sampleUtc.isAfter(cutoffUtc) || sampleUtc.isAtSameMomentAs(cutoffUtc);
