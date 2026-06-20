import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:heliolytics/utils/app_logger.dart';

/// Scans for a Helio-compatible strap and returns its MAC address.
class AutoStrapService {
  static const _nameFilters = ['helio', 'amazfit', 'mi band'];
  static const _scanTimeout = Duration(seconds: 15);

  Future<String?> scanAndPair() async {
    try {
      if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
        await FlutterBluePlus.turnOn();
        await FlutterBluePlus.adapterState
            .where((s) => s == BluetoothAdapterState.on)
            .first
            .timeout(const Duration(seconds: 5));
      }

      final found = <String, _Candidate>{};
      final sub = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          final name = r.device.platformName.toLowerCase();
          if (!_matchesName(name)) continue;
          final mac = r.device.remoteId.str;
          final prev = found[mac];
          if (prev == null || r.rssi > prev.rssi) {
            found[mac] = _Candidate(mac: mac, name: r.device.platformName, rssi: r.rssi);
          }
        }
      });

      await FlutterBluePlus.startScan(timeout: _scanTimeout);
      await FlutterBluePlus.isScanning
          .where((s) => !s)
          .first
          .timeout(_scanTimeout + const Duration(seconds: 5));
      await sub.cancel();
      await FlutterBluePlus.stopScan();

      if (found.isEmpty) {
        AppLogger.instance.log('Auto-scan: no matching strap found', tag: 'ble');
        return null;
      }

      final best = found.values.reduce((a, b) => a.rssi > b.rssi ? a : b);
      AppLogger.instance.log('Auto-scan: selected ${best.name} (${best.mac})', tag: 'ble');
      return best.mac;
    } catch (e) {
      AppLogger.instance.log('Auto-scan failed', tag: 'ble', error: e);
      await FlutterBluePlus.stopScan();
      return null;
    }
  }

  bool _matchesName(String name) {
    if (name.isEmpty) return false;
    for (final filter in _nameFilters) {
      if (name.contains(filter)) return true;
    }
    return false;
  }
}

class _Candidate {
  final String mac;
  final String name;
  final int rssi;

  const _Candidate({required this.mac, required this.name, required this.rssi});
}
