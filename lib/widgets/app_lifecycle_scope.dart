import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/providers/band_session_provider.dart';

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
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        band.onAppPaused();
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
