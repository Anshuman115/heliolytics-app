import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/design_system/components/helio_primary_button.dart';
import 'package:heliolytics/design_system/components/helio_top_bar.dart';
import 'package:heliolytics/design_system/components/helio_wizard_step_header.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';

class SetupBluetoothScreen extends StatefulWidget {
  const SetupBluetoothScreen({super.key});

  @override
  State<SetupBluetoothScreen> createState() => _SetupBluetoothScreenState();
}

class _SetupBluetoothScreenState extends State<SetupBluetoothScreen> {
  StreamSubscription<BluetoothAdapterState>? _sub;
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    _sub = FlutterBluePlus.adapterState.listen((s) {
      if (s == BluetoothAdapterState.on && mounted) {
        context.push('/setup/permission');
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _enable() async {
    setState(() => _requesting = true);
    await FlutterBluePlus.turnOn();
    if (mounted) setState(() => _requesting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HelioTopBar(showBack: true, onBack: () => context.pop()),
      body: Padding(
        padding: const EdgeInsets.all(HelioSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const HelioWizardStepHeader(step: 1, totalSteps: 5, title: 'Turn on Bluetooth'),
            const SizedBox(height: HelioSpacing.lg),
            Text(
              'Heliolytics needs Bluetooth on to find and pair your strap.',
              style: HelioTypography.bodyMuted,
            ),
            const Spacer(),
            HelioPrimaryButton(
              label: 'Enable Bluetooth',
              loading: _requesting,
              onPressed: _enable,
            ),
          ],
        ),
      ),
    );
  }
}
