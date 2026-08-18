import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/providers/sync_orchestrator.dart';
import 'package:heliolytics/design_system/components/helio_bottom_nav.dart';
import 'package:heliolytics/widgets/app_lifecycle_scope.dart';
import 'package:heliolytics/screens/activity_hub_screen.dart';
import 'package:heliolytics/screens/health_hub_screen.dart';
import 'package:heliolytics/screens/home_screen.dart';
import 'package:heliolytics/screens/settings_hub_screen.dart';
import 'package:heliolytics/providers/helio_nav_provider.dart';

class HelioShell extends ConsumerStatefulWidget {
  const HelioShell({super.key});

  @override
  ConsumerState<HelioShell> createState() => _HelioShellState();
}

class _HelioShellState extends ConsumerState<HelioShell> {
  static const _pages = [
    HomeScreen(),
    HealthHubScreen(),
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

    return AppLifecycleScope(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            SafeArea(
              top: true,
              bottom: false,
              child: IndexedStack(index: tab, children: _pages),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: HelioBottomNav(
                index: tab,
                onChanged: (i) => ref.read(helioNavProvider.notifier).state = i,
                onOrbTap: () => context.push('/profile/view'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
