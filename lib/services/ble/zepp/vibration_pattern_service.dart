import 'dart:typed_data';

import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/services/ble/band_link.dart';

/// Pushes custom vibration patterns on endpoint 0x0018.
class VibrationPatternService {
  final void Function(String) log;
  VibrationPatternService({required this.log});

  Future<bool> pushDefaults(BandLink link) async {
    log('→ vibration patterns');
    final patterns = <(int type, List<int> onOffMs)>[
      (vibrationTypeAppAlerts, [300, 600]),
      (vibrationTypeIncomingCall, [300, 200, 600, 2000]),
    ];
    for (final (type, onOff) in patterns) {
      final payload = _encode(type, onOff);
      final ok = await link.sendEndpointPayload(
        vibrationPatternEndpoint,
        payload,
        encrypt: true,
      );
      if (!ok) return false;
      await Future<void>.delayed(
        const Duration(milliseconds: bandAlertsInitStepDelayMs),
      );
    }
    log('✓ vibration patterns sent');
    return true;
  }

  /// Plays a pattern immediately (Gadgetbridge "try vibration", byte 4 = 1).
  Future<bool> testBuzz(
    BandLink link, {
    required int type,
    required List<int> onOffMs,
  }) async {
    log('→ vibration pattern test type=0x${type.toRadixString(16)}');
    final ok = await link.sendEndpointPayload(
      vibrationPatternEndpoint,
      _encode(type, onOffMs, test: true),
      encrypt: true,
    );
    if (ok) {
      log('✓ pattern test sent');
    } else {
      log('✗ pattern test failed');
    }
    return ok;
  }

  List<int> _encode(int type, List<int> onOffMs, {bool test = false}) {
    final pairs = onOffMs.length ~/ 2;
    final buf = BytesBuilder();
    buf.addByte(vibrationPatternSetCmd);
    buf.addByte(type);
    buf.addByte(0x01); // custom pattern
    buf.addByte(test ? vibrationPatternTestBuzz : 0x00);
    buf.addByte(pairs);
    final bd = ByteData(2);
    for (final ms in onOffMs) {
      bd.setUint16(0, ms, Endian.little);
      buf.add(bd.buffer.asUint8List());
    }
    return buf.toBytes();
  }
}
