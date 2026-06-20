import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:heliolytics/app.dart';
import 'package:heliolytics/services/ble/auth/auth_key_storage.dart';
import 'package:heliolytics/services/ble/auth/auth_key_store.dart';
import 'package:heliolytics/services/config/api_config_storage.dart';
import 'package:heliolytics/constants/constants.dart';

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
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Color(0xFF070A10),
    ),
  );
  final store = _SecureStore();

  //To get signing key and api url from env vars
  final seedApiConfig = kDebugMode ||
      (defaultApiUrl.isNotEmpty && defaultApiSigningSecret.isNotEmpty);
  if (seedApiConfig) {
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
