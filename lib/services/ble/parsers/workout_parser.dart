import 'dart:typed_data';

/// Decoded workout summary — verified Zepp OS protobuf field map (f2/f7/f16/f19).
class WorkoutSummary {
  final DateTime start;
  final int sportType;
  final int durationSec;
  const WorkoutSummary({
    required this.start,
    required this.sportType,
    required this.durationSec,
  });
}

/// Parser for ZeppOS protobuf workout-summary blobs (fetch 0x05).
class WorkoutParser {
  static const _marker = [0x0a, 0x03, 0x32, 0x2e];

  static List<WorkoutSummary> parseStream(Uint8List data) {
    final out = <WorkoutSummary>[];
    final starts = <int>[];
    for (var i = 0; i + 4 <= data.length; i++) {
      if (data[i] == _marker[0] &&
          data[i + 1] == _marker[1] &&
          data[i + 2] == _marker[2] &&
          data[i + 3] == _marker[3]) {
        starts.add(i);
      }
    }
    for (var s = 0; s < starts.length; s++) {
      final end = s + 1 < starts.length ? starts[s + 1] - 2 : data.length;
      final begin = starts[s];
      if (begin >= end) continue;
      final w = _parseOne(Uint8List.sublistView(data, begin, end));
      if (w != null) out.add(w);
    }
    return out;
  }

  static WorkoutSummary? _parseOne(Uint8List blob) {
    final top = _msg(blob);
    final meta = _sub(top, 2);
    final dur = _sub(top, 7);
    final startSec = _int(meta, 1);
    if (startSec == null || startSec < 1000000000) return null;
    return WorkoutSummary(
      start: DateTime.fromMillisecondsSinceEpoch(startSec * 1000),
      sportType: _int(meta, 3) ?? 0,
      durationSec: _int(dur, 1) ?? 0,
    );
  }

  static Map<int, List<(int, Object)>> _msg(Uint8List d) {
    final m = <int, List<(int, Object)>>{};
    var i = 0;
    while (i < d.length) {
      final (tag, ni) = _varint(d, i);
      if (ni <= i) break;
      i = ni;
      final field = tag >> 3;
      final wt = tag & 7;
      switch (wt) {
        case 0:
          final (v, j) = _varint(d, i);
          i = j;
          (m[field] ??= []).add((0, v));
        case 2:
          final (ln, j) = _varint(d, i);
          i = j;
          if (i + ln > d.length) return m;
          (m[field] ??= []).add((2, Uint8List.sublistView(d, i, i + ln)));
          i += ln;
        case 5:
          if (i + 4 > d.length) return m;
          i += 4;
        case 1:
          if (i + 8 > d.length) return m;
          i += 8;
        default:
          return m;
      }
    }
    return m;
  }

  static Map<int, List<(int, Object)>> _sub(
    Map<int, List<(int, Object)>> m,
    int field,
  ) {
    final v = m[field];
    if (v == null) return const {};
    for (final (k, val) in v) {
      if (k == 2 && val is Uint8List) return _msg(val);
    }
    return const {};
  }

  static int? _int(Map<int, List<(int, Object)>> m, int field) {
    final v = m[field];
    if (v == null) return null;
    for (final (k, val) in v) {
      if (k == 0 && val is int) return val;
    }
    return null;
  }

  static (int, int) _varint(Uint8List d, int i) {
    var v = 0;
    var s = 0;
    while (i < d.length) {
      final b = d[i++];
      v |= (b & 0x7f) << s;
      if (b & 0x80 == 0) return (v, i);
      s += 7;
    }
    return (v, i);
  }
}
