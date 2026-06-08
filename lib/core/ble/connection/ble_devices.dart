import 'dart:typed_data';

// ─── Shared BLE domain types ───────────────────────────────────────────────
// These are plain data classes and interfaces with no Flutter/BLE dependency.
// All BLE logic (scanner, connector, fetcher) references these types.

class DiscoveredDevice {
  final String remoteId, name;
  final int rssi;
  const DiscoveredDevice({
    required this.remoteId,
    required this.name,
    required this.rssi,
  });
}

class BleCharacteristic {
  final String uuid;
  final bool canNotify, canWriteWithoutResponse;
  const BleCharacteristic({
    required this.uuid,
    required this.canNotify,
    required this.canWriteWithoutResponse,
  });
}

// A live GATT connection to one device.
abstract class GattConnection {
  Future<List<BleCharacteristic>> discoverCharacteristics();
  Future<void> writeChunked(Uint8List bytes);
  Stream<Uint8List> get incoming;
  Future<void> dispose();
}

// Scans for nearby BLE devices.
abstract class BleScanner {
  Stream<DiscoveredDevice> scan({Duration? timeout});
  Future<void> stop();
}

// Connects to a device by remote ID and returns a GattConnection.
abstract class BleConnector {
  Future<GattConnection> connect(String remoteId);
}
