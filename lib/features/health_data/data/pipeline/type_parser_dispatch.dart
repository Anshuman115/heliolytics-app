import 'dart:typed_data';

import 'package:heliolytics/core/ble/parsers/activity.dart';
import 'package:heliolytics/core/ble/parsers/hrv.dart';
import 'package:heliolytics/core/ble/parsers/sleep_session.dart';
import 'package:heliolytics/core/ble/parsers/stress.dart';
import 'package:heliolytics/core/ble/parsers/temperature.dart';
import 'package:heliolytics/features/ble_discovery/domain/models/dump_entry.dart';

/// Routes a type code to the matching core parser; returns sample count.
class TypeParserDispatch {
  int countSamples(DumpEntry entry, Uint8List raw) {
    if (raw.isEmpty) return 0;
    final code = entry.code.toLowerCase();
    final anchors = entry.roundSegments;
    switch (code) {
      case '0x01':
        if (anchors.isNotEmpty) {
          return ActivityParser.parseTimedMulti(raw, anchors).length;
        }
        return ActivityParser.parse(raw).length;
      case '0x13':
        if (anchors.isNotEmpty) {
          return StressParser.parseMulti(raw, anchors).length;
        }
        final rs = entry.roundStart ?? DateTime.now();
        return StressParser.parse(raw, rs).length;
      case '0x2e':
        if (anchors.isNotEmpty) {
          return TemperatureParser.parseMulti(raw, anchors).length;
        }
        final rs = entry.roundStart ?? DateTime.now();
        return TemperatureParser.parse(raw, rs).length;
      case '0x48':
        return SleepSessionParser.parse(raw).length;
      case '0x49':
        return HrvParser.parse(raw).length;
      default:
        return 1;
    }
  }
}
