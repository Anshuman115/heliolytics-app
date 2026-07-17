import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/models/session_state.dart';
import 'package:heliolytics/providers/onboarding_provider.dart';
import 'package:heliolytics/providers/sync_orchestrator.dart';
import 'package:heliolytics/screens/auth_key_screen.dart';
import 'package:heliolytics/screens/device_scan_screen.dart';
import 'package:heliolytics/screens/intro_screen.dart';
import 'package:heliolytics/screens/profile_screen.dart';
import 'package:heliolytics/screens/setup_bluetooth_screen.dart';
import 'package:heliolytics/screens/setup_permission_screen.dart';
import 'package:heliolytics/screens/setup_connect_screen.dart';
import 'package:heliolytics/screens/setup_backfill_days_screen.dart';
import 'package:heliolytics/screens/band_alerts_app_pattern_screen.dart';
import 'package:heliolytics/screens/band_alerts_apps_screen.dart';
import 'package:heliolytics/screens/band_alerts_call_pattern_screen.dart';
import 'package:heliolytics/screens/api_settings_screen.dart';
import 'package:heliolytics/screens/app_logs_screen.dart';
import 'package:heliolytics/screens/band_alerts_settings_screen.dart';
import 'package:heliolytics/screens/diagnostics_screen.dart';
import 'package:heliolytics/screens/about_screen.dart';
import 'package:heliolytics/screens/activity_detail_screen.dart';
import 'package:heliolytics/screens/health_monitor_screen.dart';
import 'package:heliolytics/screens/stress_monitor_screen.dart';
import 'package:heliolytics/screens/metric_detail_screen.dart';
import 'package:heliolytics/screens/helio_shell.dart';

final _rootKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen(syncOrchestratorProvider, (prev, next) {
    final authChanged = prev?.state != next.state &&
        (prev?.state == SessionState.noAuthKey || next.state == SessionState.noAuthKey);
    if (authChanged) refresh.value++;
  });
  ref.listen(onboardingProvider, (prev, next) {
    if (prev?.onboardingComplete != next.onboardingComplete) refresh.value++;
  });

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final onboarding = ref.read(onboardingProvider);
      if (!onboarding.onboardingComplete) {
        if (loc == '/intro' || loc == '/profile') return null;
        return '/intro';
      }
      final snap = ref.read(syncOrchestratorProvider);
      final onAuth = loc == '/auth';
      if (snap.state == SessionState.noAuthKey && !onAuth) return '/auth';
      if (snap.state != SessionState.noAuthKey && onAuth) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (_, __) => const AuthKeyScreen()),
      GoRoute(path: '/intro', builder: (_, __) => const IntroScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/', builder: (_, __) => const HelioShell()),
      GoRoute(
        path: '/health/:dayKey',
        builder: (_, s) => HealthMonitorScreen(dayKey: s.pathParameters['dayKey']!),
      ),
      GoRoute(
        path: '/stress/:dayKey',
        builder: (_, s) => StressMonitorScreen(dayKey: s.pathParameters['dayKey']!),
      ),
      GoRoute(
        path: '/metric/:dayKey/:metricId',
        builder: (_, s) => MetricDetailScreen(
          dayKey: s.pathParameters['dayKey']!,
          metricId: s.pathParameters['metricId']!,
        ),
      ),
      GoRoute(
        path: '/activity/detail',
        builder: (_, s) => ActivityDetailScreen(extra: s.extra),
      ),
      GoRoute(path: '/settings/api', builder: (_, __) => const ApiSettingsScreen()),
      GoRoute(path: '/settings/logs', builder: (_, __) => const AppLogsScreen()),
      GoRoute(
        path: '/settings/band-alerts',
        builder: (_, __) => const BandAlertsSettingsScreen(),
      ),
      GoRoute(path: '/settings/diagnostics', builder: (_, __) => const DiagnosticsScreen()),
      GoRoute(path: '/settings/about', builder: (_, __) => const AboutScreen()),
      GoRoute(
        path: '/settings/band-alerts/apps',
        builder: (_, __) => const BandAlertsAppsScreen(),
      ),
      GoRoute(
        path: '/settings/band-alerts/call-pattern',
        builder: (_, __) => const BandAlertsCallPatternScreen(),
      ),
      GoRoute(
        path: '/settings/band-alerts/pattern',
        builder: (_, s) {
          final extra = s.extra;
          if (extra is BandAlertsAppPatternArgs) {
            return BandAlertsAppPatternScreen(args: extra);
          }
          return const BandAlertsAppsScreen();
        },
      ),
      GoRoute(path: '/setup/bluetooth', builder: (_, __) => const SetupBluetoothScreen()),
      GoRoute(path: '/setup/permission', builder: (_, __) => const SetupPermissionScreen()),
      GoRoute(path: '/setup/scan', builder: (_, __) => const DeviceScanScreen()),
      GoRoute(path: '/setup/connect', builder: (_, __) => const SetupConnectScreen()),
      GoRoute(path: '/setup/backfill-days', builder: (_, __) => const SetupBackfillDaysScreen()),
    ],
  );
});
