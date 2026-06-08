import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/core/ble/connection/ble_devices.dart';
import 'package:heliolytics/core/constants.dart';

// ─── BLE Connector ────────────────────────────────────────────────────────
// Connects to the Helio strap and sets up subscriptions for all four
// GATT characteristics the fetch protocol uses:
//   0x0016 — chunked write (auth handshake + post-auth frames)
//   0x0017 — chunked notify (auth responses)
//   0x0004 — activity control (start/ack fetch commands)
//   0x0005 — activity data (raw data packets)

final bleConnectorProvider = Provider<BleConnector>(
  (ref) => connectorProvider(),
);

class StrapGattConnection implements GattConnection {
  final BluetoothDevice _device;
  BluetoothCharacteristic? _writeChar;
  BluetoothCharacteristic? _notifyChar;
  BluetoothCharacteristic? _controlChar;
  BluetoothCharacteristic? _dataChar;

  StreamSubscription<List<int>>? _notifySub;
  StreamSubscription<List<int>>? _controlSub;
  StreamSubscription<List<int>>? _dataSub;

  void Function(Uint8List)? _notifyHandler;

  final _incomingControl = StreamController<Uint8List>.broadcast();
  final _incomingData = StreamController<Uint8List>.broadcast();

  StrapGattConnection(this._device);

  @override
  Future<List<BleCharacteristic>> discoverCharacteristics() async {
    try {
      await _device.requestMtu(247);
    } catch (_) {}

    final services = await _device.discoverServices();
    final out = <BleCharacteristic>[];

    for (final svc in services) {
      for (final c in svc.characteristics) {
        final uuid = c.uuid.str.toLowerCase();
        out.add(BleCharacteristic(
          uuid: uuid,
          canNotify: c.properties.notify,
          canWriteWithoutResponse: c.properties.writeWithoutResponse,
        ));
        if (uuid == chunkedWriteUUID) _writeChar = c;
        if (uuid == chunkedNotifyUUID) {
          _notifyChar = c;
          await c.setNotifyValue(true);
          _notifySub = c.onValueReceived.listen((v) {
            _notifyHandler?.call(Uint8List.fromList(v));
          });
        }
        if (uuid == activityControlUUID) {
          _controlChar = c;
          await c.setNotifyValue(true);
          _controlSub = c.onValueReceived.listen((v) {
            if (v.isNotEmpty) _incomingControl.add(Uint8List.fromList(v));
          });
        }
        if (uuid == activityDataUUID) {
          _dataChar = c;
          await c.setNotifyValue(true);
          _dataSub = c.onValueReceived.listen((v) {
            if (v.isNotEmpty) _incomingData.add(Uint8List.fromList(v));
          });
        }
      }
    }

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

  Future<void> resubscribeNotifications() async {
    await _controlSub?.cancel();
    await _dataSub?.cancel();

    if (_controlChar != null) {
      await _controlChar!.setNotifyValue(true);
      _controlSub = _controlChar!.onValueReceived.listen((v) {
        if (v.isNotEmpty) _incomingControl.add(Uint8List.fromList(v));
      });
    }
    if (_dataChar != null) {
      await _dataChar!.setNotifyValue(true);
      _dataSub = _dataChar!.onValueReceived.listen((v) {
        if (v.isNotEmpty) _incomingData.add(Uint8List.fromList(v));
      });
    }
  }

  void setNotifyHandler(void Function(Uint8List) handler) {
    _notifyHandler = handler;
  }

  @override
  Future<void> writeChunked(Uint8List bytes) async {
    await _writeChar!.write(bytes, withoutResponse: true);
  }

  Future<void> writeNotify(Uint8List bytes) async {
    await _notifyChar!.write(bytes, withoutResponse: true);
  }

  Future<void> writeControl(List<int> bytes) async {
    await _controlChar!.write(bytes, withoutResponse: true);
  }

  Stream<Uint8List> get controlStream => _incomingControl.stream;
  Stream<Uint8List> get dataStream => _incomingData.stream;

  @override
  Stream<Uint8List> get incoming => const Stream.empty();

  @override
  Future<void> dispose() async {
    await _notifySub?.cancel();
    await _controlSub?.cancel();
    await _dataSub?.cancel();
    await _incomingControl.close();
    await _incomingData.close();
    try {
      await _device.disconnect();
    } catch (_) {}
  }
}

class StrapConnector implements BleConnector {
  @override
  Future<GattConnection> connect(String remoteId) async {
    final device = BluetoothDevice.fromId(remoteId);
    await device.connect(
      timeout: const Duration(seconds: 30),
      autoConnect: false,
    );
    final conn = StrapGattConnection(device);
    await conn.discoverCharacteristics();
    return conn;
  }
}

BleConnector connectorProvider() => StrapConnector();
