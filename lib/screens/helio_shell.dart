import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/models/session_state.dart';
import 'package:heliolytics/providers/sync_orchestrator.dart';
import 'package:heliolytics/design_system/components/helio_bottom_nav.dart';
import 'package:heliolytics/design_system/components/helio_sync_strip.dart';
import 'package:heliolytics/widgets/app_lifecycle_scope.dart';
import 'package:heliolytics/screens/activity_hub_screen.dart';
import 'package:heliolytics/providers/live_health_provider.dart';
import 'package:heliolytics/screens/home_screen.dart';
import 'package:heliolytics/screens/settings_hub_screen.dart';
import 'package:heliolytics/providers/helio_nav_provider.dart';
import 'package:heliolytics/screens/sleep_hub_screen.dart';

class HelioShell extends ConsumerStatefulWidget {
  const HelioShell({super.key});

  @override
  ConsumerState<HelioShell> createState() => _HelioShellState();
}

class _HelioShellState extends ConsumerState<HelioShell> {
  static const _pages = [
    HomeScreen(),
    SleepHubScreen(),
    ActivityHubScreen(),
    SettingsHubScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncOrchestratorProvider.notifier).scheduleAutoConnect();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(helioNavProvider);

    ref.listen(syncOrchestratorProvider, (prev, next) {
      final wasBusy = prev?.state == SessionState.fetching ||
          prev?.state == SessionState.connecting;
      final nowIdle = next.state == SessionState.idle;
      if (wasBusy && nowIdle) {
        ref.read(liveHealthProvider.notifier).reload();
      }
    });

    return AppLifecycleScope(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          top: true,
          bottom: false,
          child: Column(
            children: [
              const HelioSyncStrip(),
              Expanded(child: IndexedStack(index: tab, children: _pages)),
            ],
          ),
        ),
        bottomNavigationBar: HelioBottomNav(
          index: tab,
          onChanged: (i) => ref.read(helioNavProvider.notifier).state = i,
        ),
      ),
    );
  }
}
