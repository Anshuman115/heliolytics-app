import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heliolytics/core/ble/sync_orchestrator.dart';

/// Scans for all nearby BLE devices and lets the user pick the Helio Strap.
/// On selection, stores the MAC and proceeds to auth + fetch automatically.
class DeviceScanScreen extends ConsumerStatefulWidget {
  const DeviceScanScreen({super.key});

  @override
  ConsumerState<DeviceScanScreen> createState() => _DeviceScanScreenState();
}

class _DeviceScanScreenState extends ConsumerState<DeviceScanScreen> {
  final Map<String, _Device> _devices = {};
  bool _scanning = false;
  String? _error;
  StreamSubscription<List<ScanResult>>? _sub;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    _sub?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _devices.clear();
      _scanning = true;
      _error = null;
    });

    try {
      if (await FlutterBluePlus.adapterState.first !=
          BluetoothAdapterState.on) {
        await FlutterBluePlus.turnOn();
        await FlutterBluePlus.adapterState
            .where((s) => s == BluetoothAdapterState.on)
            .first
            .timeout(const Duration(seconds: 5));
      }

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
      );

      _sub = FlutterBluePlus.scanResults.listen((results) {
        setState(() {
          for (final r in results) {
            _devices[r.device.remoteId.str] = _Device(
              mac: r.device.remoteId.str,
              name: r.device.platformName.isNotEmpty
                  ? r.device.platformName
                  : '(no name)',
              rssi: r.rssi,
            );
          }
        });
      });

      // Wait for scan to finish
      await FlutterBluePlus.isScanning
          .where((s) => !s)
          .first
          .timeout(const Duration(seconds: 20));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _scanning = false);
    }
  }

  Future<void> _pick(_Device device) async {
    await FlutterBluePlus.stopScan();
    await _sub?.cancel();

    if (!mounted) return;
    await ref
        .read(syncOrchestratorProvider.notifier)
        .saveMacAndConnect(device.mac);

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _devices.values.toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi)); // strongest signal first

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select your Helio Strap'),
        actions: [
          if (_scanning)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _startScan,
            ),
        ],
      ),
      body: Column(
        children: [
          if (_scanning)
            const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          if (sorted.isEmpty && !_scanning)
            const Expanded(
              child: Center(child: Text('No devices found. Tap refresh.')),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: sorted.length,
                itemBuilder: (_, i) {
                  final d = sorted[i];
                  final isHelio = d.name.toLowerCase().contains('helio') ||
                      d.name.toLowerCase().contains('amazfit');
                  return ListTile(
                    leading: Icon(
                      Icons.watch,
                      color: isHelio ? Colors.deepPurple : Colors.grey,
                    ),
                    title: Text(
                      d.name,
                      style: TextStyle(
                        fontWeight:
                            isHelio ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text('${d.mac}   RSSI: ${d.rssi} dBm'),
                    trailing: isHelio
                        ? const Chip(
                            label: Text('Helio?'),
                            backgroundColor: Color(0xFFEDE7F6),
                          )
                        : null,
                    onTap: () => _pick(d),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Tap your Helio Strap from the list above.\n'
              'Look for "Helio" or "Amazfit" in the name, or the strongest signal.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _Device {
  final String mac, name;
  final int rssi;
  const _Device({required this.mac, required this.name, required this.rssi});
}
