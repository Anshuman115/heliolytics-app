import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/core/ble/session_state.dart';
import 'package:heliolytics/core/ble/sync_orchestrator.dart';
import 'package:heliolytics/features/ble_discovery/presentation/screens/auth_key_screen.dart';
import 'package:heliolytics/features/ble_discovery/presentation/screens/device_scan_screen.dart';
import 'package:heliolytics/features/cloud_sync/presentation/screens/api_settings_screen.dart';
import 'package:heliolytics/features/health_data/presentation/screens/activity_detail_screen.dart';
import 'package:heliolytics/features/health_data/presentation/screens/day_detail_screen.dart';
import 'package:heliolytics/features/health_data/presentation/screens/main_shell.dart';
import 'package:heliolytics/features/health_data/presentation/screens/metric_detail_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen(syncOrchestratorProvider, (prev, next) {
    final authChanged = prev?.state != next.state &&
        (prev?.state == SessionState.noAuthKey || next.state == SessionState.noAuthKey);
    if (authChanged) refresh.value++;
  });

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final snap = ref.read(syncOrchestratorProvider);
      final loc = state.matchedLocation;
      final onAuth = loc == '/auth';
      if (snap.state == SessionState.noAuthKey && !onAuth) return '/auth';
      if (snap.state != SessionState.noAuthKey && onAuth) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (_, __) => const AuthKeyScreen()),
      GoRoute(path: '/', builder: (_, __) => const MainShell()),
      GoRoute(
        path: '/day/:dayKey',
        builder: (_, s) => DayDetailScreen(dayKey: s.pathParameters['dayKey']!),
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
      GoRoute(path: '/scan', builder: (_, __) => const DeviceScanScreen()),
    ],
  );
});
