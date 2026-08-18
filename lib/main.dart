import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:heliolytics/router/app_router.dart';
import 'package:heliolytics/design_system/components/helio_backdrop.dart';
import 'package:heliolytics/design_system/theme/helio_theme.dart';
import 'package:heliolytics/providers/bluetooth_prompt_provider.dart';
import 'package:heliolytics/services/ble/auth/auth_key_storage.dart';
import 'package:heliolytics/services/ble/auth/secure_key_store.dart';
import 'package:heliolytics/services/cache/daily_bundle_cache_storage.dart';
import 'package:heliolytics/services/config/api_config_storage.dart';
import 'package:heliolytics/constants/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Color(0xFF070A10),
    ),
  );
  await Hive.initFlutter();
  await Hive.openBox<String>(cachedDaysBoxName);
  try {
    await DailyBundleCacheStorage().migrateSchemaIfNeeded();
  } catch (_) {
    // Reads ignore mismatched cache schemas, so startup can continue safely.
  }

  final store = SecureKeyStore();

  //To get signing key and api url from env vars
  final seedApiConfig =
      kDebugMode ||
      (defaultApiUrl.isNotEmpty && defaultApiSigningSecret.isNotEmpty);
  if (seedApiConfig) {
    await ApiConfigStorage(store).ensureDevDefaults();
  }

  // Seed strap auth key and MAC from dart-define if provided
  if (defaultStrapAuthKey.isNotEmpty) {
    final existing = await store.read(authKeyStorageKey);
    if (existing == null || existing.isEmpty) {
      await store.write(authKeyStorageKey, defaultStrapAuthKey);
    }
  }
  if (defaultStrapMac.isNotEmpty) {
    final existing = await store.read(strapMacStorageKey);
    if (existing == null || existing.isEmpty) {
      await store.write(strapMacStorageKey, defaultStrapMac);
    }
  }

  runApp(
    ProviderScope(
      overrides: [authKeyStoreProvider.overrideWithValue(store)],
      child: const HeliolyticsApp(),
    ),
  );
}

class HeliolyticsApp extends ConsumerWidget {
  const HeliolyticsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    ref.listen<bool>(bluetoothPromptProvider, (prev, next) {
      if (next != true) return;
      final ctx = router.routerDelegate.navigatorKey.currentContext;
      ref.read(bluetoothPromptProvider.notifier).state = false;
      if (ctx == null) return;
      showDialog(
        context: ctx,
        builder: (_) => AlertDialog(
          title: const Text('Bluetooth is off'),
          content: const Text('Turn on Bluetooth to sync with your strap.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
    return MaterialApp.router(
      title: 'Heliolytics',
      debugShowCheckedModeBanner: false,
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
