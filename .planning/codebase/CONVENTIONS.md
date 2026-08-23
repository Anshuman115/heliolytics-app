# Coding Conventions

**Analysis Date:** 2026-08-23

## Naming Patterns

**Files:**
- Use `snake_case.dart`, with names describing the single responsibility, for example `lib/providers/live_hr_provider.dart` and `lib/widgets/heart_rate_bpm_hero.dart`.
- Keep code grouped by layer: screens, widgets, providers, services, models, router, utils, constants, and design-system tokens/components.

**Functions:**
- Use lower camel case and descriptive verbs such as `fetchDayBundle`, `migrateSchemaIfNeeded`, and `createApiDio`.
- Keep private implementation helpers prefixed with `_`, for example `_parseHeartRate` in `lib/services/metrics_api_client.dart`.

**Variables:**
- Use lower camel case and domain-specific names such as `windowDays`, `dayKey`, `roundStart`, and `sampledAt`.
- Use `final` by default and `const` for compile-time values. Avoid generic names when a metric-specific name is available.

**Types:**
- Use PascalCase for classes, enums, and typedefs, for example `MetricsApiClient`, `DayBundle`, and `MetricsApiTokenFactory`.
- Riverpod providers use lower camel case with a `Provider` suffix, such as `dayBundleProvider` and `metricsApiClientProvider`.

## Code Style

**Formatting:**
- Dart formatting is the baseline. Multi-line constructors and calls use trailing commas so `dart format` can preserve readable widget trees.
- Prefer `const` constructors and immutable literals. `analysis_options.yaml` enables `prefer_const_constructors`, `prefer_const_literals_to_create_immutables`, and `require_trailing_commas`.

**Linting:**
- `analysis_options.yaml` includes `package:flutter_lints/flutter.yaml`.
- Generated `**/*.g.dart` and `**/*.freezed.dart` files are excluded from analyzer checks.
- `flutter analyze` is the authoritative compile and lint check and must finish with zero errors.

## Import Organization

**Order:**
1. Dart SDK imports such as `dart:typed_data`.
2. Package imports, including Flutter and third-party packages.
3. Project package imports using `package:heliolytics/...`.

**Path Aliases:**
- Use package imports rooted at `package:heliolytics/`; relative imports are not the normal pattern.
- Import dependencies through their layer paths, for example `package:heliolytics/providers/...` and `package:heliolytics/services/...`.

## Error Handling

**Patterns:**
- Services translate malformed responses and HTTP conditions into typed domain errors such as `MetricsApiException` and `MetricsApiFailureType` in `lib/services/metrics_api_client.dart`.
- Providers generally allow failures to propagate through Riverpod async state. Tests in `test/core/provider_error_propagation_test.dart` assert the original error object is preserved.
- Expected best-effort boundaries catch narrowly, log the failure, and continue, as in malformed persisted-log replay in `lib/utils/app_logger.dart`.
- UI should render explicit loading, error, and no-data states. Do not fabricate health values, as covered by `test/widgets/heart_rate_bpm_hero_test.dart`.

## Logging

**Framework:** `AppLogger` backed by `dart:developer` and Talker in `lib/utils/app_logger.dart`.

**Patterns:**
- Do not use `print()`. Use `AppLogger.instance.log(message, tag: ..., error: ...)` or the service/session logger seam.
- Use stable tags that identify the feature, for example `sync`, `live_hr`, and `band_alerts`.
- Redact auth headers and avoid persisting sensitive response bodies. `AppLogger.createApiDio` configures Talker Dio logging and hides `X-Heliolytics-Token`, `Authorization`, and `Cookie`.

## Comments

**When to Comment:**
- Comment protocol, persistence, privacy, and lifecycle reasoning that is not obvious from the code, such as the replay guard and PHI logging behavior in `lib/utils/app_logger.dart`.
- Keep comments aligned with current behavior and avoid third-party attribution in tracked files.

**JSDoc/TSDoc:**
- Dart doc comments are used selectively for public services and non-obvious invariants, for example `AppLogger` and its public `log`/`createApiDio` APIs.

## Function Design

**Size:** Keep functions focused on one operation. Widgets should extract sections into separate widgets rather than growing large `build()` methods.

**Parameters:** Prefer named parameters for optional or semantically important values, and use `required` for mandatory inputs, as in `fetchDayBundle` and `MetricsApiClient` construction.

**Return Values:** Prefer typed `Future<T>`, immutable model values, and typed collections. Preserve nullability for unavailable health data instead of substituting invented values.

## Module Design

**Exports:** Define providers and public classes at module scope. Keep helper classes, stubs, and parsing helpers private unless another layer needs them.

**Barrel Files:** Not detected as the primary pattern. Import concrete files directly, such as `lib/providers/day_bundle_provider.dart`.

## Riverpod and Flutter Patterns

- Put providers and Notifiers in `lib/providers/`; use `AsyncNotifier` or other Riverpod async providers instead of `FutureBuilder`.
- Screens are `ConsumerWidget` or `ConsumerStatefulWidget`; UI reads state with `ref.watch` and performs callback actions with `ref.read`.
- Keep API and BLE calls out of widgets. The normal flow is screens to providers to services to models.
- Keep shared spacing and metric colors in design-system tokens rather than magic numbers in widgets.

---

*Convention analysis: 2026-08-23*
