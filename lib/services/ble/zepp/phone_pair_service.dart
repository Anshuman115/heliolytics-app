import 'dart:convert';

import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/services/ble/band_link.dart';

/// Phone pairing on endpoint 0x000b.
class PhonePairService {
  final void Function(String) log;
  PhonePairService({required this.log});

  Future<bool> initialize(BandLink link, {required String bluetoothName}) async {
    log('→ phone pair init');
    await _send(link, [phonePairCapsRequest]);
    await _delay();
    final name = utf8.encode(bluetoothName);
    await _send(link, [phonePairStartCmd, ...name, 0x00]);
    await _delay();
    await _send(link, [phonePairEnabledSetCmd, 0x01, 0x01, 0x01]);
    log('✓ phone pair commands sent');
    return true;
  }

  Future<void> _send(BandLink link, List<int> payload) async {
    final ok = await link.sendEndpointPayload(
      phonePairEndpoint,
      payload,
      encrypt: true,
    );
    if (!ok) throw StateError('phone pair send failed');
  }

  Future<void> _delay() =>
      Future<void>.delayed(const Duration(milliseconds: bandAlertsInitStepDelayMs));
}
