import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/services/ble/auth/auth_key_validator.dart';
import 'package:heliolytics/models/session_state.dart';
import 'package:heliolytics/providers/sync_orchestrator.dart';
import 'package:heliolytics/design_system/components/helio_primary_button.dart';
import 'package:heliolytics/design_system/components/helio_text_field.dart';
import 'package:heliolytics/design_system/components/helio_top_bar.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';

class AuthKeyScreen extends ConsumerStatefulWidget {
  const AuthKeyScreen({super.key});

  @override
  ConsumerState<AuthKeyScreen> createState() => _AuthKeyScreenState();
}

class _AuthKeyScreenState extends ConsumerState<AuthKeyScreen> {
  final _keyCtrl = TextEditingController();
  String? _keyError;
  bool _saving = false;

  @override
  void dispose() {
    _keyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final keyReason = AuthKeyValidator.validate(_keyCtrl.text.trim());
    setState(() => _keyError = keyReason);
    if (keyReason != null) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(syncOrchestratorProvider.notifier)
          .saveAuthKey(_keyCtrl.text.trim());
    } catch (e) {
      setState(() {
        _keyError = e.toString();
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final snap = ref.watch(syncOrchestratorProvider);
    if (snap.state != SessionState.noAuthKey) return const SizedBox.shrink();

    return Scaffold(
      appBar: const HelioTopBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(HelioSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('AUTH KEY', style: HelioTypography.sectionTitle),
            const SizedBox(height: HelioSpacing.sm),
            Text(
              '32 hex chars — from Zepp account or a compatible companion app',
              style: HelioTypography.bodyMuted,
            ),
            const SizedBox(height: HelioSpacing.lg),
            HelioTextField(
              controller: _keyCtrl,
              hint: 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6',
              maxLength: 32,
              errorText: _keyError,
            ),
            const SizedBox(height: HelioSpacing.xl),
            HelioPrimaryButton(label: 'Save key', loading: _saving, onPressed: _save),
            const SizedBox(height: HelioSpacing.lg),
            Text(
              'Strap syncs automatically after pairing.',
              textAlign: TextAlign.center,
              style: HelioTypography.bodyMuted,
            ),
          ],
        ),
      ),
    );
  }
}
