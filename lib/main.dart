import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:heliolytics/app.dart';
import 'package:heliolytics/core/ble/auth/auth_key_storage.dart';
import 'package:heliolytics/core/ble/auth/auth_key_store.dart';
import 'package:heliolytics/core/config/api_config_storage.dart';
import 'package:heliolytics/core/utils/logger.dart';
import 'package:heliolytics/core/utils/talker_log.dart';

class _SecureStore implements AuthKeyStore {
  final _s = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  @override
  Future<String?> read(String key) => _s.read(key: key);

  @override
  Future<void> write(String key, String value) => _s.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _s.delete(key: key);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final talker = appTalker();
  FlutterError.onError = (details) {
    talker.handle(
      details.exception,
      details.stack ?? StackTrace.current,
      'flutter_error',
    );
    appLog(details.exceptionAsString(), tag: 'flutter_error');
    if (kDebugMode) FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    talker.handle(error, stack, 'platform_error');
    appLog('$error\n$stack', tag: 'platform_error');
    return true;
  };
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Color(0xFF070A10),
    ),
  );
  final store = _SecureStore();
  if (kDebugMode) {
    await ApiConfigStorage(store).ensureDevDefaults();
  }
  runApp(
    ProviderScope(
      overrides: [
        authKeyStoreProvider.overrideWithValue(store),
      ],
      child: const HeliolyticsApp(),
    ),
  );
}
