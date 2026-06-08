import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/core/ble/ble_devices.dart';

final bleScannerProvider = Provider<BleScanner>(
  (ref) => scannerProvider(),
);

/// Real BLE scanner backed by flutter_blue_plus.
/// Turns Bluetooth on if it is off before scanning.
class FbpScanner implements BleScanner {
  @override
  Stream<DiscoveredDevice> scan({Duration? timeout}) async* {
    // Turn on Bluetooth if it's off (Android only — iOS cannot do this)
    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      await FlutterBluePlus.turnOn();
      // Wait up to 5 seconds for it to turn on
      await FlutterBluePlus.adapterState
          .where((s) => s == BluetoothAdapterState.on)
          .first
          .timeout(const Duration(seconds: 5));
    }

    await FlutterBluePlus.startScan(timeout: timeout);
    await for (final results in FlutterBluePlus.scanResults) {
      for (final r in results) {
        yield DiscoveredDevice(
          remoteId: r.device.remoteId.str,
          name: r.device.platformName,
          rssi: r.rssi,
        );
      }
    }
  }

  @override
  Future<void> stop() => FlutterBluePlus.stopScan();
}

BleScanner scannerProvider() => FbpScanner();
