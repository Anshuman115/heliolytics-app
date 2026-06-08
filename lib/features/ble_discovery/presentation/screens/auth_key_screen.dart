import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heliolytics/core/ble/auth/auth_key_validator.dart';
import 'package:heliolytics/core/ble/sync_orchestrator.dart';
import 'package:heliolytics/core/ble/session_state.dart';

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
    final keyReason = AuthKeyValidator.validate(_keyCtrl.text);
    setState(() => _keyError = keyReason);
    if (keyReason != null) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(syncOrchestratorProvider.notifier)
          .saveAuthKey(_keyCtrl.text);
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
      appBar: AppBar(title: const Text('Heliolytics Setup')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Auth Key',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              '32 hex chars — from Zepp account or a compatible companion app',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _keyCtrl,
              maxLength: 32,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6',
                errorText: _keyError,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Key'),
            ),
            const SizedBox(height: 12),
            const Text(
              'After saving, tap Connect on the next screen to scan for your Helio Strap.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
