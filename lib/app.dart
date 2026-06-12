import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heliolytics/core/router/app_router.dart';
import 'package:heliolytics/core/theme/app_theme.dart';

class HeliolyticsApp extends ConsumerWidget {
  const HeliolyticsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Heliolytics',
      theme: buildAppTheme(),
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
