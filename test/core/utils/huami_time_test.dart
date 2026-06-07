import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliolytics/core/utils/huami_time.dart';

void main() {
  test('fromDateTime produces 8-byte Huami format', () {
    final b = HuamiTime.fromDateTime(DateTime(2026, 6, 7, 14, 30));
    expect(b.length, 8);
    // Year 2026 = 0x07EA -> LE bytes: EA 07
    expect(b[0], 0xEA);
    expect(b[1], 0x07);
    expect(b[2], 6); // month
    expect(b[3], 7); // day
    expect(b[4], 14); // hour
    expect(b[5], 30); // minute
    expect(b[6], 0); // seconds = 0
  });

  test('parseStartDate extracts expected packet count', () {
    final data = Uint8List.fromList([
      0x10, 0x01, 0x01, // response, cmd=start, status=ok
      0x0A, 0x00, 0x00, 0x00, // expected = 10 packets
      0xEA, 0x07, // year 2026 LE
      6, 7, 14, 30, 0, // month, day, hour, min, sec
    ]);
    final result = HuamiTime.parseStartDate(data);
    expect(result, isNotNull);
    expect(result!.expected, 10);
    expect(result.start, DateTime(2026, 6, 7, 14, 30, 0));
  });

  test('toDateTime decodes 4-byte LE epoch', () {
    final sec = 1780790400; // 2026-06-07 00:00:00 UTC
    final b = ByteData(4)..setUint32(0, sec, Endian.little);
    final dt = HuamiTime.toDateTime(b.buffer.asUint8List());
    expect(dt, DateTime.utc(2026, 6, 7));
  });
}
