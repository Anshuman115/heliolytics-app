import 'dart:typed_data';

import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/services/ble/band_link.dart';

typedef MotorProofProgress = void Function(MotorProofStep step);

enum MotorProofStep { connecting, buzzing }

/// Find-device buzz over endpoint 0x001a (encrypted).
class FindDeviceService {
  final void Function(String) log;

  FindDeviceService({required this.log});

  Future<BandLink> openSession({
    required String mac,
    required Uint8List authKey,
    MotorProofProgress? onProgress,
  }) async {
    onProgress?.call(MotorProofStep.connecting);
    final link = BandLink(log);
    var authed = await link.connectAndAuth(
      mac: mac,
      authKey: authKey,
      commsOnly: true,
    );
    if (!authed) {
      log('• retrying connect/auth');
      await Future<void>.delayed(const Duration(seconds: 1));
      authed = await link.connectAndAuth(
        mac: mac,
        authKey: authKey,
        commsOnly: true,
      );
    }
    if (!authed) throw StateError('Connect or auth failed');
    return link;
  }

  Future<void> buzz(
    BandLink link, {
    MotorProofProgress? onProgress,
    bool requestCapabilities = true,
  }) async {
    if (requestCapabilities) {
      await _sendEncrypted(link, findDeviceCapabilitiesRequest);
      await Future<void>.delayed(
        const Duration(milliseconds: motorProofCapabilitiesDelayMs),
      );
    }
    onProgress?.call(MotorProofStep.buzzing);
    await pulseBuzz(
      link,
      durationMs: motorProofBuzzDurationSec * 1000,
    );
    log('✓ motor proof complete');
  }

  Future<void> startBuzz(BandLink link) async {
    log('→ find device start');
    await _sendEncrypted(link, findDeviceStart);
  }

  Future<void> stopBuzz(BandLink link) async {
    log('→ find device stop');
    await _sendEncrypted(link, findDeviceStopFromPhone);
  }

  Future<void> pulseBuzz(
    BandLink link, {
    required int durationMs,
  }) async {
    await startBuzz(link);
    await Future<void>.delayed(Duration(milliseconds: durationMs));
    await stopBuzz(link);
  }

  Future<void> _sendEncrypted(BandLink link, int cmd) async {
    final ok = await link.sendEndpointPayload(
      findDeviceEndpoint,
      [cmd],
      encrypt: true,
    );
    if (!ok) throw StateError('Encrypted send failed (0x${cmd.toRadixString(16)})');
  }
}
