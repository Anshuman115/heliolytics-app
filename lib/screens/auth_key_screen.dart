import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/services/ble/auth/auth_key_validator.dart';
import 'package:heliolytics/providers/auth_key_status_provider.dart';
import 'package:heliolytics/providers/sync_orchestrator.dart';
import 'package:heliolytics/design_system/components/helio_primary_button.dart';
import 'package:heliolytics/design_system/components/helio_text_field.dart';
import 'package:heliolytics/design_system/components/helio_top_bar.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';

class AuthKeyScreen extends ConsumerStatefulWidget {
  final bool settingsMode;

  const AuthKeyScreen({super.key, this.settingsMode = false});

  @override
  ConsumerState<AuthKeyScreen> createState() => _AuthKeyScreenState();
}

class _AuthKeyScreenState extends ConsumerState<AuthKeyScreen> {
  final _keyCtrl = TextEditingController();
  String? _keyError;
  bool _saving = false;
  bool _obscureKey = true;

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
      ref.invalidate(authKeyStatusProvider);
      if (!mounted) return;
      if (widget.settingsMode) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Amazfit auth key saved')));
        context.pop();
        unawaited(
          ref.read(syncOrchestratorProvider.notifier).scheduleAutoConnect(),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _keyError = e.toString();
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HelioTopBar(
        title: widget.settingsMode ? 'Auth Key' : null,
        showBack: widget.settingsMode,
        onBack: widget.settingsMode ? () => context.pop() : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(HelioSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('AMAZFIT AUTH KEY', style: HelioTypography.sectionTitle),
            const SizedBox(height: HelioSpacing.sm),
            Text(
              'Enter the 32-character hexadecimal key associated with your Amazfit device.',
              style: HelioTypography.bodyMuted,
            ),
            const SizedBox(height: HelioSpacing.lg),
            HelioTextField(
              controller: _keyCtrl,
              hint: '32-character hexadecimal key',
              maxLength: 32,
              hexOnly: true,
              obscureText: _obscureKey,
              errorText: _keyError,
              suffix: IconButton(
                tooltip: _obscureKey ? 'Show key' : 'Hide key',
                icon: Icon(
                  _obscureKey
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _obscureKey = !_obscureKey),
              ),
            ),
            const SizedBox(height: HelioSpacing.xl),
            HelioPrimaryButton(
              label: 'Save auth key',
              loading: _saving,
              onPressed: _save,
            ),
            const SizedBox(height: HelioSpacing.lg),
            Text(
              'Stored securely on this device. Saving a new key replaces the previous key.',
              textAlign: TextAlign.center,
              style: HelioTypography.bodyMuted,
            ),
          ],
        ),
      ),
    );
  }
}
