// lib/screens/setup_permission_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/design_system/components/helio_primary_button.dart';
import 'package:heliolytics/design_system/components/helio_secondary_button.dart';
import 'package:heliolytics/design_system/components/helio_top_bar.dart';
import 'package:heliolytics/design_system/components/helio_wizard_step_header.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:permission_handler/permission_handler.dart';

class SetupPermissionScreen extends StatefulWidget {
  const SetupPermissionScreen({super.key});

  @override
  State<SetupPermissionScreen> createState() => _SetupPermissionScreenState();
}

class _SetupPermissionScreenState extends State<SetupPermissionScreen> {
  bool _requesting = false;
  bool _denied = false;

  Future<void> _request() async {
    setState(() {
      _requesting = true;
      _denied = false;
    });
    final results = await [Permission.bluetoothScan, Permission.bluetoothConnect].request();
    final granted = results.values.every((s) => s.isGranted);
    if (!mounted) return;
    if (granted) {
      setState(() => _requesting = false);
      context.push('/setup/scan');
    } else {
      setState(() {
        _requesting = false;
        _denied = true;
      });
    }
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
            const HelioWizardStepHeader(step: 2, totalSteps: 5, title: 'Allow nearby devices'),
            const SizedBox(height: HelioSpacing.lg),
            Text(
              'Heliolytics needs the "Nearby devices" permission to scan for your strap.',
              style: HelioTypography.bodyMuted,
            ),
            if (_denied)
              const _DeniedSection(),
            const Spacer(),
            HelioPrimaryButton(
              label: 'Allow',
              loading: _requesting,
              onPressed: _request,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeniedSection extends StatelessWidget {
  const _DeniedSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: HelioSpacing.lg),
        Text(
          'Permission denied. Enable it in system settings to continue.',
          style: HelioTypography.bodyMuted,
        ),
        const SizedBox(height: HelioSpacing.md),
        const HelioSecondaryButton(label: 'Open Settings', onPressed: openAppSettings),
      ],
    );
  }
}
