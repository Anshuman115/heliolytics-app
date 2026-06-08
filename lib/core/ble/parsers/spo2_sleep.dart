import 'dart:typed_data';
import 'package:heliolytics/core/ble/parsers/unknown.dart';

/// SpO2 during sleep (type code 0x26) — format not yet confirmed.
/// Returns raw bytes wrapped in [UnknownSample] until the format is reverse-engineered.
class Spo2SleepParser {
  static List<UnknownSample> parse(Uint8List bytes) =>
      UnknownParser.parse('0x26', bytes);
}
