# Technology Stack

**Analysis Date:** 2026-08-23

## Languages

**Primary:**
- Dart 3.8.1 or newer - Flutter application, BLE protocol, API clients, models, providers, and UI in `lib/`

**Secondary:**
- Kotlin/Java 11 - Android activity, notification listener, and foreground service in `android/app/src/main/kotlin/`
- XML - Android manifests, resources, and network security configuration in `android/app/src/main/`

## Runtime

**Environment:**
- Flutter mobile runtime - Android application; iOS project scaffolding is present but the configured native integrations are Android-focused
- Android API 23 minimum; compile and target SDK versions are delegated to Flutter in `android/app/build.gradle.kts`

**Package Manager:**
- Dart Pub / Flutter Pub
- Lockfile: `pubspec.lock` present

## Frameworks

**Core:**
- Flutter - cross-platform mobile UI and application runtime
- Riverpod 2.5.0 and Riverpod Generator 2.4.3 - provider-based state and async orchestration in `lib/providers/`
- GoRouter 14.6.2 - navigation in `lib/router/app_router.dart`

**Testing:**
- `flutter_test` - widget and unit tests in `test/`
- `flutter_lints` 5.0.0 - analysis rules from `analysis_options.yaml`

**Build/Dev:**
- Flutter Gradle plugin with Android Gradle Plugin and Gradle wrapper 8.12 - Android builds
- `build_runner` 2.4.13 - generated Riverpod source
- `flutter_launcher_icons` 0.14.2 - launcher icon generation

## Key Dependencies

**Critical:**
- `flutter_blue_plus` 1.31.0 - BLE scanning, GATT connection, characteristics, notifications, and strap data transfer
- `dio` 5.7.0 - HTTPS API requests and multipart ingest uploads
- `flutter_secure_storage` 9.0.0 - strap auth key, API URL, and API signing secret storage
- `pointycastle` 3.9.0 and `crypto` 3.0.0 - BLE handshake cryptography and HMAC-SHA256 API request signing
- `flutter_riverpod` 2.5.0 - application state and service wiring

**Infrastructure:**
- `hive` 2.2.3 and `hive_flutter` 1.1.0 - per-day parsed response cache
- `shared_preferences` 2.3.0 - small non-sensitive cached values
- `permission_handler` 11.3.1 - Bluetooth, notification, and platform permission checks
- `path_provider` 2.1.0 and `path` 1.9.0 - app-private log and file paths
- `talker` 5.1.19, `talker_dio_logger` 5.1.19, and `talker_flutter` 5.1.16 - structured app and network logging
- `fl_chart` 0.69.0 - health, sleep, activity, and trend charts
- `share_plus` 12.0.0 - sharing diagnostic or log content
- `intl` 0.19.0 - date and number formatting

## Configuration

**Environment:**
- Build-time Dart defines `API_URL`, `API_SIGNING_SECRET`, `STRAP_AUTH_KEY`, and `STRAP_MAC` are read in `lib/constants/constants.dart`
- `build.env.example` documents build inputs; local `build.env` exists and must not be committed or quoted
- Production or store builds can configure the API interactively through `ApiSettingsScreen` and `lib/services/config/api_config_storage.dart`

**Build:**
- `pubspec.yaml` - package, dependency, asset, and launcher configuration
- `analysis_options.yaml` - lint and analyzer configuration
- `android/app/build.gradle.kts` - Android namespace, SDK, NDK 27, release shrinking, and signing
- `android/gradle/wrapper/gradle-wrapper.properties` - Gradle 8.12 distribution

## Platform Requirements

**Development:**
- Flutter SDK with Dart SDK satisfying `^3.8.1`, Android SDK/NDK 27.0.12077973, and a BLE-capable Android device for hardware flows

**Production:**
- Android Play Store APK/AAB deployment; release builds enable R8 shrinking and resource shrinking in `android/app/build.gradle.kts`
- A configured HTTPS Go Heliolytics API and a shared signing secret are required for cloud sync and metrics

---

*Stack analysis: 2026-08-23*
