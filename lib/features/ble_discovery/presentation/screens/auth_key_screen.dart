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
  final _macCtrl = TextEditingController();
  String? _keyError;
  String? _macError;
  bool _saving = false;

  @override
  void dispose() {
    _keyCtrl.dispose();
    _macCtrl.dispose();
    super.dispose();
  }

  String? _validateMac(String mac) {
    final trimmed = mac.trim().toUpperCase();
    // Accept XX:XX:XX:XX:XX:XX format
    final re = RegExp(r'^([0-9A-F]{2}:){5}[0-9A-F]{2}$');
    if (!re.hasMatch(trimmed)) {
      return 'Enter MAC as XX:XX:XX:XX:XX:XX (from Zepp → Profile → Device → info)';
    }
    return null;
  }

  Future<void> _save() async {
    final keyReason = AuthKeyValidator.validate(_keyCtrl.text);
    final macReason = _validateMac(_macCtrl.text);
    setState(() {
      _keyError = keyReason;
      _macError = macReason;
    });
    if (keyReason != null || macReason != null) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(syncOrchestratorProvider.notifier)
          .saveAuthKeyAndMac(_keyCtrl.text, _macCtrl.text.trim());
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

            // --- Auth Key ---
            const Text(
              'Auth Key',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
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

            const SizedBox(height: 16),

            // --- MAC Address ---
            const Text(
              'Strap MAC Address',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'Find it in: Zepp app → Profile → your device → ⓘ info\n'
              'Or: Android Settings → Bluetooth → strap → Device details',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _macCtrl,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'AA:BB:CC:DD:EE:FF',
                errorText: _macError,
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
                  : const Text('Save & Connect'),
            ),
          ],
        ),
      ),
    );
  }
}
