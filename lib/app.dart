import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heliolytics/core/ble/sync_orchestrator.dart';
import 'package:heliolytics/core/ble/session_state.dart';
import 'package:heliolytics/features/ble_discovery/presentation/screens/auth_key_screen.dart';
import 'package:heliolytics/features/health_data/presentation/screens/health_home_screen.dart';

class HeliolyticsApp extends ConsumerWidget {
  const HeliolyticsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Heliolytics',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const _RootRouter(),
    );
  }
}

class _RootRouter extends ConsumerWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(syncOrchestratorProvider);
    if (snap.state == SessionState.noAuthKey) {
      return const AuthKeyScreen();
    }
    return const HealthHomeScreen();
  }
}
