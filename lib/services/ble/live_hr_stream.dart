import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/services/ble/encrypted_endpoint.dart';
import 'package:heliolytics/services/ble/live_hr_bpm.dart';

/// Real-time HR via endpoint 0x001d + standard BLE Heart Rate Measurement notify.
class LiveHrStream {
  LiveHrStream({
    required this.comms,
    required this.hrChar,
    required this.log,
  });

  final EncryptedEndpoint comms;
  final BluetoothCharacteristic? hrChar;
  final void Function(String) log;

  final _bpmController = StreamController<int>.broadcast();
  Stream<int> get bpmStream => _bpmController.stream;

  StreamSubscription<List<int>>? _hrSub;
  Timer? _keepalive;
  bool _running = false;

  bool get isRunning => _running;

  void onEndpointPayload(int endpoint, Uint8List payload) {
    if (endpoint != liveHrControlEndpoint) return;
    final hex =
        payload.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    log('← live HR ack (${payload.length}B): $hex');
  }

  Future<void> start() async {
    if (_running) return;
    final char = hrChar;
    if (char == null) {
      log('✗ live HR char not found');
      return;
    }
    log('→ live HR start');
    await comms.send(
      liveHrControlEndpoint,
      Uint8List.fromList(liveHrStartCommand),
    );
    await char.setNotifyValue(true);
    _hrSub = char.onValueReceived.listen(_onHrNotify);
    _keepalive = Timer.periodic(
      const Duration(seconds: liveHrKeepaliveIntervalSec),
      (_) => _sendContinue(),
    );
    _running = true;
    log('✓ live HR streaming');
  }

  Future<void> _sendContinue() async {
    if (!_running) return;
    try {
      await comms.send(
        liveHrControlEndpoint,
        Uint8List.fromList(liveHrContinueCommand),
      );
    } catch (e) {
      log('• live HR keepalive failed: $e');
    }
  }

  void _onHrNotify(List<int> value) {
    final bpm = bpmFromGattNotify(value);
    if (bpm == null) return;
    _bpmController.add(bpm);
  }

  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    _keepalive?.cancel();
    _keepalive = null;
    await _hrSub?.cancel();
    _hrSub = null;
    try {
      await comms.send(
        liveHrControlEndpoint,
        Uint8List.fromList(liveHrStopCommand),
      );
      await hrChar?.setNotifyValue(false);
    } catch (e) {
      log('• live HR stop failed: $e');
    }
    log('• live HR stopped');
  }

  void dispose() {
    unawaited(stop());
    _bpmController.close();
  }
}
