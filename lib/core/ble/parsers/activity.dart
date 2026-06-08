import 'dart:typed_data';

import 'package:heliolytics/core/ble/sync_page_anchor.dart';
import 'package:heliolytics/core/ble/record_stride.dart';

/// Activity record from type code 0x01.
/// 4 or 8 bytes per record (8 when payload is 8-aligned), round-relative timestamps.
class ActivitySample {
  final int kind;
  final int intensity;
  final int steps;
  final int heartRate;
  final int b4;
  final int b5;
  final int b6;
  final int b7;

  const ActivitySample({
    required this.kind,
    required this.intensity,
    required this.steps,
    required this.heartRate,
    this.b4 = 0,
    this.b5 = 0,
    this.b6 = 0,
    this.b7 = 0,
  });
}

class ActivityTimedSample {
  final DateTime timestamp;
  final ActivitySample sample;
  const ActivityTimedSample(this.timestamp, this.sample);
}

class ActivityParser {
  static int _stride(Uint8List bytes) => recordStride(0x01, bytes.length);

  static List<ActivitySample> parse(Uint8List bytes) {
    if (bytes.isEmpty) return [];
    final size = _stride(bytes);
    if (bytes.length % size != 0) {
      throw ArgumentError(
        'Activity payload length ${bytes.length} is not a multiple of $size',
      );
    }
    final out = <ActivitySample>[];
    for (var i = 0; i < bytes.length; i += size) {
      out.add(_one(bytes, i, size));
    }
    return out;
  }

  /// Each fetch page has its own [roundStart] anchor in [segments].
  static List<ActivityTimedSample> parseTimedMulti(
    Uint8List bytes,
    List<SyncPageAnchor> segments,
  ) {
    if (segments.isEmpty) return [];
    final out = <ActivityTimedSample>[];
    for (var i = 0; i < segments.length; i++) {
      final start = segments[i].byteOffset;
      final end = i + 1 < segments.length
          ? segments[i + 1].byteOffset
          : bytes.length;
      if (start >= bytes.length) continue;
      out.addAll(parseTimed(
        bytes.sublist(start, end.clamp(0, bytes.length)),
        segments[i].roundStart,
      ));
    }
    return out;
  }

  /// Decode with per-minute timestamps from the device's roundStart reply.
  static List<ActivityTimedSample> parseTimed(
    Uint8List bytes,
    DateTime roundStart,
  ) {
    if (bytes.isEmpty) return [];
    final size = _stride(bytes);
    final out = <ActivityTimedSample>[];
    var ts = roundStart;
    for (var i = 0; i + size <= bytes.length; i += size) {
      out.add(ActivityTimedSample(ts, _one(bytes, i, size)));
      ts = ts.add(const Duration(minutes: 1));
    }
    return out;
  }

  static ActivitySample _one(Uint8List bytes, int i, int size) {
    return ActivitySample(
      kind: bytes[i],
      intensity: bytes[i + 1],
      steps: bytes[i + 2],
      heartRate: bytes[i + 3],
      b4: size > 4 ? bytes[i + 4] : 0,
      b5: size > 5 ? bytes[i + 5] : 0,
      b6: size > 6 ? bytes[i + 6] : 0,
      b7: size > 7 ? bytes[i + 7] : 0,
    );
  }
}
