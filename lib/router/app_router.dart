import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/models/session_state.dart';
import 'package:heliolytics/providers/sync_orchestrator.dart';
import 'package:heliolytics/screens/auth_key_screen.dart';
import 'package:heliolytics/screens/device_scan_screen.dart';
import 'package:heliolytics/screens/api_settings_screen.dart';
import 'package:heliolytics/screens/activity_detail_screen.dart';
import 'package:heliolytics/screens/health_monitor_screen.dart';
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
      GoRoute(path: '/', builder: (_, __) => const HelioShell()),
      GoRoute(
        path: '/health/:dayKey',
        builder: (_, s) => HealthMonitorScreen(dayKey: s.pathParameters['dayKey']!),
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
