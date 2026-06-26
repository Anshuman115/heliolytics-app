import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heliolytics/router/app_router.dart';
import 'package:heliolytics/design_system/components/helio_backdrop.dart';
import 'package:heliolytics/design_system/theme/helio_theme.dart';

class HeliolyticsApp extends ConsumerWidget {
  const HeliolyticsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Heliolytics',
      theme: buildHelioTheme(),
      themeMode: ThemeMode.dark,
      routerConfig: router,
      // One ambient gradient behind every route; scaffolds are
      // transparent so it shows through consistently.
      builder: (context, child) =>
          HelioBackdrop(child: child ?? const SizedBox.shrink()),
    );
  }
}
