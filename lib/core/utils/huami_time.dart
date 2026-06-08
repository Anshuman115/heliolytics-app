import 'dart:typed_data';

/// Huami 8-byte time encoding used by the activity-fetch start command,
/// and the parser for the device's start-date metadata reply.
/// Bytes: year(u16 LE) month day hour minute second(=0) tz(15-min units).
class HuamiTime {
  static Uint8List fromDateTime(DateTime dt) {
    final local = dt.toLocal();
    final tzUnits = (local.timeZoneOffset.inMinutes ~/ 15) & 0xFF;
    final out = Uint8List(8);
    final bd = ByteData.sublistView(out);
    bd.setUint16(0, local.year, Endian.little);
    out[2] = local.month;
    out[3] = local.day;
    out[4] = local.hour;
    out[5] = local.minute;
    out[6] = 0;
    out[7] = tzUnits;
    return out;
  }

  /// Parse a 4-byte Unix timestamp (seconds since epoch, little-endian)
  /// used in individual data packets (HR, HRV, etc.).
  static DateTime toDateTime(Uint8List bytes) {
    final b = ByteData.sublistView(bytes);
    return DateTime.fromMillisecondsSinceEpoch(
      b.getUint32(0, Endian.little) * 1000,
      isUtc: true,
    );
  }

  /// Parse the control reply to the start command:
  /// [0x10, 0x01, status, expected(u32 LE @3), year(u16 @7), mon, day, hr, min, sec].
  static ({int expected, DateTime start})? parseStartDate(Uint8List d) {
    if (d.length < 14) return null;
    final expected = ByteData.sublistView(d, 3, 7).getUint32(0, Endian.little);
    if (expected == 0) return (expected: 0, start: DateTime.now());
    final year = ByteData.sublistView(d, 7, 9).getUint16(0, Endian.little);
    final start = DateTime(year, d[9], d[10], d[11], d[12], d[13]);
    return (expected: expected, start: start);
  }
}
