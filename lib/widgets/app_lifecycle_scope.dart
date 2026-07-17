import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/providers/band_session_provider.dart';
import 'package:heliolytics/providers/bluetooth_prompt_provider.dart';
import 'package:heliolytics/providers/onboarding_provider.dart';
import 'package:heliolytics/services/ble/auth/auth_key_storage.dart';

/// Forwards app lifecycle to [bandSessionProvider].
class AppLifecycleScope extends ConsumerStatefulWidget {
  final Widget child;

  const AppLifecycleScope({super.key, required this.child});

  @override
  ConsumerState<AppLifecycleScope> createState() => _AppLifecycleScopeState();
}

class _AppLifecycleScopeState extends ConsumerState<AppLifecycleScope>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final band = ref.read(bandSessionProvider.notifier);
    switch (state) {
      case AppLifecycleState.resumed:
        band.onAppResumed();
        _checkBluetooth();
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        band.onAppPaused();
      default:
        break;
    }
  }

  Future<void> _checkBluetooth() async {
    if (!ref.read(onboardingProvider).onboardingComplete) return;
    final auth = AuthKeyStorage(store: ref.read(authKeyStoreProvider));
    if (!await auth.hasMac()) return;
    final state = await FlutterBluePlus.adapterState.first;
    if (state != BluetoothAdapterState.on) {
      ref.read(bluetoothPromptProvider.notifier).state = true;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
