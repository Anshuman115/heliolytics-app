import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/providers/sync_orchestrator.dart';
import 'package:heliolytics/utils/error_messages.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/components/helio_top_bar.dart';
import 'package:heliolytics/design_system/components/helio_wizard_step_header.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_radii.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';

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

  bool _isHelioDevice(String name) {
    final lower = name.toLowerCase();
    return lower.contains('helio') ||
        lower.contains('amazfit') ||
        lower.contains('mi band');
  }

  Future<void> _startScan() async {
    setState(() {
      _devices.clear();
      _scanning = true;
      _error = null;
    });

    try {
      if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
        await FlutterBluePlus.turnOn();
        await FlutterBluePlus.adapterState
            .where((s) => s == BluetoothAdapterState.on)
            .first
            .timeout(const Duration(seconds: 5));
      }

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

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

      await FlutterBluePlus.isScanning
          .where((s) => !s)
          .first
          .timeout(const Duration(seconds: 20));
    } catch (e) {
      setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _pick(_Device device) async {
    await FlutterBluePlus.stopScan();
    await _sub?.cancel();
    if (!mounted) return;
    await ref.read(syncOrchestratorProvider.notifier).saveMac(device.mac);
    if (mounted) context.push('/setup/connect');
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _devices.values.toList()..sort((a, b) => b.rssi.compareTo(a.rssi));

    return Scaffold(
      appBar: HelioTopBar(
        showBack: true,
        onBack: () => Navigator.of(context).pop(),
        title: 'Select Strap',
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(HelioSpacing.lg),
                child: HelioWizardStepHeader(step: 3, totalSteps: 5, title: 'Find your strap'),
              ),
              if (_scanning) const LinearProgressIndicator(color: HelioColors.sleepBlue),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(HelioSpacing.lg),
                  child: Text(_error!, style: const TextStyle(color: HelioColors.recoveryLow)),
                ),
              if (sorted.isEmpty && !_scanning)
                Expanded(
                  child: Center(
                    child: Text('No devices found. Tap refresh.', style: HelioTypography.bodyMuted),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(HelioSpacing.lg),
                    itemCount: sorted.length,
                    itemBuilder: (_, i) => _tile(sorted[i]),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(HelioSpacing.lg),
                child: Text(
                  'Only Amazfit Helio strap devices are supported here.',
                  textAlign: TextAlign.center,
                  style: HelioTypography.bodyMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tile(_Device d) {
    final isHelio = _isHelioDevice(d.name);
    return Padding(
      padding: const EdgeInsets.only(bottom: HelioSpacing.sm),
      child: HelioSurfaceCard(
        onTap: () => _pick(d),
        padding: const EdgeInsets.all(HelioSpacing.md),
        child: Row(
          children: [
            Icon(Icons.watch, color: isHelio ? HelioColors.sleepBlue : HelioColors.textMuted),
            const SizedBox(width: HelioSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.name,
                    style: HelioTypography.body.copyWith(
                      fontWeight: isHelio ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  Text('${d.mac} · ${d.rssi} dBm', style: HelioTypography.bodyMuted),
                ],
              ),
            ),
            if (isHelio)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: HelioSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: HelioColors.sleepBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(HelioRadii.pill),
                ),
                child: Text('STRAP', style: HelioTypography.capsLabel.copyWith(fontSize: 9)),
              ),
          ],
        ),
      ),
    );
  }
}

class _Device {
  final String mac, name;
  final int rssi;
  const _Device({required this.mac, required this.name, required this.rssi});
}
