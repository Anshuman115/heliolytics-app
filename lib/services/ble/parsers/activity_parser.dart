import 'dart:typed_data';

import 'package:heliolytics/services/ble/parsers/workout_parser.dart';
import 'package:heliolytics/services/ble/record_stride.dart';

/// Paging anchor extraction for Huami activity-fetch streams.
class ActivityParser {
  static const _detailHeader = [0x01, 0x0c, 0x70, 0x73, 0x6d, 0x68];
  static const _detailTimestampBytes = 6;
  static const _minEpochMillis = 946684800000;
  static const _maxEpochMillis = 4102444800000;

  static DateTime? lastSampleTime(
    int code,
    Uint8List raw,
    DateTime roundStart,
  ) {
    if (raw.isEmpty) return null;
    if (code == 0x05) return _lastWorkoutTime(raw);
    if (code == 0x06) return _lastWorkoutDetailTime(raw);
    if (isRoundRelative(code)) return _lastRoundRelative(code, raw, roundStart);
    return _lastEpochRecord(code, raw);
  }

  static DateTime? _lastRoundRelative(
    int code,
    Uint8List raw,
    DateTime roundStart,
  ) {
    if (code == 0x13) {
      return roundStart.add(Duration(minutes: raw.length - 1));
    }
    final stride = recordStride(code, raw.length);
    final count = raw.length ~/ stride;
    if (count == 0) return null;
    return roundStart.add(Duration(minutes: count - 1));
  }

  static DateTime? _lastEpochRecord(int code, Uint8List raw) {
    switch (code) {
      case 0x25:
        return _lastEpochStride(raw, 65, header: 0x02);
      case 0x26:
        return _lastEpochStride(raw, 30, header: 0x02);
      case 0x38:
        return _lastEpochStride(raw, 8);
      case 0x3A:
      case 0x3D:
      case 0x49:
        return _lastEpochStride(raw, 6);
      case 0x48:
        return _lastEpochStride(raw, 594);
      default:
        return null;
    }
  }

  static DateTime? _lastEpochStride(Uint8List raw, int stride, {int? header}) {
    var start = 0;
    if (header != null && raw.isNotEmpty && raw[0] == header) {
      start = 1;
    } else if (header != null && raw.length % stride == 0) {
      start = 0;
    }
    DateTime? last;
    for (var i = start; i + stride <= raw.length; i += stride) {
      final sec = ByteData.sublistView(
        raw,
        i,
        i + 4,
      ).getUint32(0, Endian.little);
      if (sec >= 1577836800) {
        last = DateTime.fromMillisecondsSinceEpoch(sec * 1000);
      }
    }
    return last;
  }

  static DateTime? _lastWorkoutTime(Uint8List allRaw) {
    final wk = WorkoutParser.parseStream(allRaw);
    if (wk.isEmpty) return null;
    var last = wk.first.start;
    for (final w in wk) {
      if (w.start.isAfter(last)) last = w.start;
    }
    return last;
  }

  static DateTime? _lastWorkoutDetailTime(Uint8List raw) {
    DateTime? last;
    for (
      var offset = 0;
      offset + _detailHeader.length + _detailTimestampBytes <= raw.length;
      offset++
    ) {
      if (!_matches(raw, offset, _detailHeader)) continue;
      var millis = 0;
      final timestampOffset = offset + _detailHeader.length;
      for (var index = 0; index < _detailTimestampBytes; index++) {
        millis |= raw[timestampOffset + index] << (8 * index);
      }
      if (millis < _minEpochMillis || millis > _maxEpochMillis) continue;
      final timestamp = DateTime.fromMillisecondsSinceEpoch(millis);
      if (last == null || timestamp.isAfter(last)) last = timestamp;
    }
    return last;
  }

  static bool _matches(Uint8List raw, int offset, List<int> marker) {
    for (var index = 0; index < marker.length; index++) {
      if (raw[offset + index] != marker[index]) return false;
    }
    return true;
  }
}
