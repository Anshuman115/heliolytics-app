import 'dart:typed_data';

/// Decoder for the 594-byte ZeppOS sleep-session blob (fetch type 0x48).
class SleepStageSeg {
  final DateTime start;
  final DateTime end;
  final int type;
  const SleepStageSeg(this.start, this.end, this.type);
}

class SleepSession {
  final DateTime sessionStart;
  final int sleepStartMin;
  final int sleepEndMin;
  final int avgHr;
  final int score;
  final List<SleepStageSeg> stages;
  final int remMin;
  final int lightMin;
  final int deepMin;
  final int wakeMin;

  const SleepSession({
    required this.sessionStart,
    required this.sleepStartMin,
    required this.sleepEndMin,
    required this.avgHr,
    required this.score,
    required this.stages,
    required this.remMin,
    required this.lightMin,
    required this.deepMin,
    required this.wakeMin,
  });

  int get totalAsleepMin => remMin + lightMin + deepMin;
}

class SleepSessionParser {
  static const int recordSize = 594;

  static List<SleepSession> parse(Uint8List data) {
    final out = <SleepSession>[];
    var off = 0;
    while (off + recordSize <= data.length) {
      final bd = ByteData.sublistView(data, off, off + recordSize);
      final tsSession = bd.getUint32(0x00, Endian.little);
      final tsMidnight = bd.getUint32(0x04, Endian.little);
      final numStages = bd.getUint8(0x54);
      final base = tsMidnight - 24 * 3600;
      final stages = <SleepStageSeg>[];
      for (var i = 0; i < numStages && 0x56 + 5 * i + 5 <= recordSize; i++) {
        final s = bd.getUint16(0x56 + 5 * i, Endian.little);
        final e = bd.getUint16(0x56 + 5 * i + 2, Endian.little);
        final t = bd.getUint8(0x56 + 5 * i + 4);
        stages.add(SleepStageSeg(
          _epoch(base + s * 60),
          _epoch(base + e * 60),
          t,
        ));
      }
      out.add(SleepSession(
        sessionStart: _epoch(tsSession),
        sleepStartMin: bd.getUint16(0x0a, Endian.little),
        sleepEndMin: bd.getUint16(0x0c, Endian.little),
        avgHr: bd.getUint8(0x15),
        score: bd.getUint8(0x16),
        stages: stages,
        remMin: bd.getUint16(0x24a, Endian.little),
        lightMin: bd.getUint16(0x24c, Endian.little),
        deepMin: bd.getUint16(0x24e, Endian.little),
        wakeMin: bd.getUint16(0x250, Endian.little),
      ));
      off += recordSize;
    }
    return out;
  }

  static DateTime _epoch(int sec) =>
      DateTime.fromMillisecondsSinceEpoch(sec * 1000, isUtc: true);
}
