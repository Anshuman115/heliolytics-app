import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/core/ble/ble_devices.dart';

final bleScannerProvider = Provider<BleScanner>(
  (ref) => scannerProvider(),
);

/// Real BLE scanner backed by flutter_blue_plus.
class FbpScanner implements BleScanner {
  @override
  Stream<DiscoveredDevice> scan({Duration? timeout}) async* {
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
