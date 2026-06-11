import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/core/ble/session_state.dart';
import 'package:heliolytics/core/ble/sync_orchestrator.dart';
import 'package:heliolytics/features/health_data/presentation/providers/live_health_provider.dart';
import 'package:heliolytics/features/health_data/presentation/screens/activities_screen.dart';
import 'package:heliolytics/features/health_data/presentation/screens/health_home_screen.dart';
import 'package:heliolytics/features/health_data/presentation/screens/settings_screen.dart';
import 'package:heliolytics/features/health_data/presentation/screens/sleep_screen.dart';
import 'package:heliolytics/shared/providers/shell_tab_provider.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  static const _pages = [
    HealthHomeScreen(),
    SleepScreen(),
    ActivitiesScreen(),
    SettingsScreen(),
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
    final tab = ref.watch(shellTabProvider);

    ref.listen(syncOrchestratorProvider, (prev, next) {
      final done = prev?.state == SessionState.fetching &&
          next.state == SessionState.idle;
      if (done) ref.invalidate(liveHealthProvider);
    });

    return Scaffold(
      body: IndexedStack(index: tab, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => ref.read(shellTabProvider.notifier).state = i,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.bedtime_outlined), selectedIcon: Icon(Icons.bedtime), label: 'Sleep'),
          NavigationDestination(icon: Icon(Icons.sports_outlined), selectedIcon: Icon(Icons.sports), label: 'Activity'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
