import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/core/ble/ble_devices.dart';
import 'package:heliolytics/core/constants.dart';

final bleConnectorProvider = Provider<BleConnector>(
  (ref) => connectorProvider(),
);

/// Holds the four BLE characteristics used by the Helio Strap:
/// - 0x0016 — chunked write (auth)
/// - 0x0017 — chunked notify (auth responses)
/// - 0x0004 — activity control (data fetch commands)
/// - 0x0005 — activity data (sensor data notifications)
class StrapGattConnection implements GattConnection {
  final BluetoothDevice _device;
  BluetoothCharacteristic? _writeChar;
  BluetoothCharacteristic? _notifyChar;
  BluetoothCharacteristic? _controlChar;
  BluetoothCharacteristic? _dataChar;

  final _incomingAuth = StreamController<Uint8List>.broadcast();
  final _incomingControl = StreamController<Uint8List>.broadcast();
  final _incomingData = StreamController<Uint8List>.broadcast();

  StreamSubscription<List<int>>? _notifySub;
  StreamSubscription<List<int>>? _controlSub;
  StreamSubscription<List<int>>? _dataSub;

  StrapGattConnection(this._device);

  @override
  Future<List<BleCharacteristic>> discoverCharacteristics() async {
    try {
      await _device.requestMtu(247);
    } catch (_) {}

    final services = await _device.discoverServices();
    final out = <BleCharacteristic>[];

    // ignore: avoid_print
    print('[STRAP] discovered ${services.length} services:');
    for (final svc in services) {
      // ignore: avoid_print
      print('[STRAP]   svc: ${svc.uuid.str}');
      for (final c in svc.characteristics) {
        // ignore: avoid_print
        print('[STRAP]     char: ${c.uuid.str} notify=${c.properties.notify} write=${c.properties.write}');
      }
    }

    for (final svc in services) {
      for (final c in svc.characteristics) {
        final uuid = c.uuid.str.toLowerCase();
        out.add(BleCharacteristic(
          uuid: uuid,
          canNotify: c.properties.notify,
          canWriteWithoutResponse: c.properties.writeWithoutResponse,
        ));
        if (uuid == chunkedWriteUUID) {
          _writeChar = c;
        }
        if (uuid == chunkedNotifyUUID) {
          _notifyChar = c;
          await c.setNotifyValue(true);
          _notifySub = c.onValueReceived.listen((v) {
            if (v.isNotEmpty) _incomingAuth.add(Uint8List.fromList(v));
          });
        }
        if (uuid == activityControlUUID) {
          _controlChar = c;
          await c.setNotifyValue(true);
          _controlSub = c.onValueReceived.listen((v) {
            // ignore: avoid_print
            print('[STRAP] control notify on 0x0004: ${v.length} bytes');
            if (v.isNotEmpty) _incomingControl.add(Uint8List.fromList(v));
          });
        }
        if (uuid == activityDataUUID) {
          _dataChar = c;
          await c.setNotifyValue(true);
          _dataSub = c.onValueReceived.listen((v) {
            // ignore: avoid_print
            print('[STRAP] data notify on 0x0005: ${v.length} bytes');
            if (v.isNotEmpty) _incomingData.add(Uint8List.fromList(v));
          });
        }
      }
    }

    // ignore: avoid_print
    print('[STRAP] write=$_writeChar notify=$_notifyChar control=$_controlChar data=$_dataChar');
    if (_writeChar == null || _notifyChar == null) {
      throw StateError(
        'Chunked chars 0016/0017 not found. '
        'Found: ${out.map((c) => c.uuid).join(', ')}',
      );
    }
    if (_controlChar == null || _dataChar == null) {
      throw StateError(
        'Activity chars 0004/0005 not found. '
        'Found: ${out.map((c) => c.uuid).join(', ')}',
      );
    }
    return out;
  }

  /// Re-subscribe to control (0x0004) and data (0x0005) notifications.
  /// Must be called AFTER auth — the handshake resets BLE notification state.
  Future<void> resubscribeNotifications() async {
    // Cancel old subscriptions
    await _controlSub?.cancel();
    await _dataSub?.cancel();

    if (_controlChar != null) {
      await _controlChar!.setNotifyValue(true);
      _controlSub = _controlChar!.onValueReceived.listen((v) {
        // ignore: avoid_print
        print('[STRAP] control notify on 0x0004: ${v.length} bytes');
        if (v.isNotEmpty) _incomingControl.add(Uint8List.fromList(v));
      });
      // ignore: avoid_print
      print('[STRAP] re-subscribed to 0x0004 notifications');
    }
    if (_dataChar != null) {
      await _dataChar!.setNotifyValue(true);
      _dataSub = _dataChar!.onValueReceived.listen((v) {
        // ignore: avoid_print
        print('[STRAP] data notify on 0x0005: ${v.length} bytes');
        if (v.isNotEmpty) _incomingData.add(Uint8List.fromList(v));
      });
      // ignore: avoid_print
      print('[STRAP] re-subscribed to 0x0005 notifications');
    }
  }

  /// Write to the chunked write char (0x0016) — used for auth.
  @override
  Future<void> writeChunked(Uint8List bytes) async {
    await _writeChar!.write(bytes, withoutResponse: true);
  }

  /// Write to the activity control char (0x0004) — used for data fetch commands.
  Future<void> writeControl(List<int> bytes) async {
    await _controlChar!.write(bytes, withoutResponse: true);
  }

  /// Stream of notifications from the chunked notify char (0x0017) — auth responses.
  @override
  Stream<Uint8List> get incoming => _incomingAuth.stream;

  /// Stream of notifications from the activity control char (0x0004).
  Stream<Uint8List> get controlStream => _incomingControl.stream;

  /// Stream of notifications from the activity data char (0x0005).
  Stream<Uint8List> get dataStream => _incomingData.stream;

  @override
  Future<void> dispose() async {
    await _notifySub?.cancel();
    await _controlSub?.cancel();
    await _dataSub?.cancel();
    await _incomingAuth.close();
    await _incomingControl.close();
    await _incomingData.close();
    try {
      await _device.disconnect();
    } catch (_) {}
  }
}

/// Connects to a BLE device and sets up a [StrapGattConnection].
class StrapConnector implements BleConnector {
  @override
  Future<GattConnection> connect(String remoteId) async {
    final device = BluetoothDevice.fromId(remoteId);
    // ignore: avoid_print
    print('[STRAP] connecting to $remoteId');
    await device.connect(
      timeout: const Duration(seconds: 30),
      autoConnect: false,
    );
    // ignore: avoid_print
    print('[STRAP] connected, discovering services...');
    final conn = StrapGattConnection(device);
    await conn.discoverCharacteristics();
    // ignore: avoid_print
    print('[STRAP] services discovered, ready');
    return conn;
  }
}

BleConnector connectorProvider() => StrapConnector();
