# Testing Patterns

**Analysis Date:** 2026-08-23

## Test Framework

**Runner:**
- `flutter_test` from the Flutter SDK, declared in `pubspec.yaml`.
- No separate Jest, Vitest, Mockito, Mocktail, or integration-test runner was detected.
- Config: `analysis_options.yaml` controls linting; no dedicated test runner config was detected.

**Assertion Library:**
- Flutter Test matchers: `expect`, `isEmpty`, `hasLength`, `findsOneWidget`, `throwsA`, `isA`, `same`, and `.having`.

**Run Commands:**
```bash
flutter test              # Run the test suite
flutter test test/core    # Run the core/provider/service tests
flutter test test/widgets # Run widget tests
flutter analyze           # Authoritative compile and lint check
```

## Test File Organization

**Location:**
- Tests are in the separate public `test/` tree, grouped into `test/core/` and `test/widgets/` rather than co-located with `lib/` files.

**Naming:**
- Use the source responsibility plus `_test.dart`, for example `test/core/metrics_api_client_test.dart` and `test/widgets/heart_rate_bpm_hero_test.dart`.

**Structure:**
```text
test/
├── core/    # Models, services, BLE protocol, cache, providers, API contracts
└── widgets/ # Flutter widget behavior
```

## Test Structure

**Suite Organization:**
```dart
void main() {
  group('MetricsApiClient HTTP reliability', () {
    test('retries a plain-text 401 once with a fresh token', () async {
      final stub = _StubInterceptor(...);
      expect(await client.fetchDays(windowDays: 1), isEmpty);
    });
  });
}
```

**Patterns:**
- Use descriptive behavior-focused test names, including failure and boundary behavior.
- Use `group` for related API or protocol scenarios; simple files can use top-level `test` calls.
- Register cleanup with `addTearDown(container.dispose)` for `ProviderContainer` instances.
- Use `setUp` and `tearDown` for external resources such as temporary Hive directories and boxes in `test/core/daily_bundle_cache_storage_test.dart`.
- Assert both the returned value and side effects such as request count, cache writes, BLE command bytes, and selected timestamps.

## Mocking

**Framework:** No mocking package is configured. Tests use hand-written fakes, stubs, subclass overrides, Dio interceptors, and Riverpod provider overrides.

**Patterns:**
```dart
final container = ProviderContainer(
  overrides: [
    apiConfiguredProvider.overrideWith((ref) async => true),
    metricsApiClientProvider.overrideWithValue(_ThrowingMetricsApiClient(error)),
  ],
);
addTearDown(container.dispose);
```

**What to Mock:**
- Replace network transport with `_StubInterceptor` in `test/core/metrics_api_client_test.dart`.
- Replace service clients and storage with small local subclasses such as `_ThrowingMetricsApiClient`, `_RecordingBundleCache`, and `_EmptyAuthKeyStore`.
- Inject deterministic callbacks for protocol writes and token generation, then assert exact bytes or token rotation.

**What NOT to Mock:**
- Keep pure parsing, model conversion, date calculations, and widget rendering real. Tests such as `test/core/huami_time_test.dart` and `test/widgets/heart_rate_bpm_hero_test.dart` exercise the actual implementation.

## Fixtures and Factories

**Test Data:**
```dart
final since = DateTime(2026, 7, 12, 13, 42);
final writes = <List<int>>[];
final engine = TypeSyncEngine((bytes) async {
  writes.add(List<int>.from(bytes));
});
```

- Fixtures are declared locally in each test file. Helpers such as `_response`, `_bundleStub`, `_startReply`, and `_detailBlock` build focused protocol or HTTP inputs.
- Shared production fixture files were not detected.

**Location:**
- Test-only fakes and builders live at the bottom of the corresponding `test/core/*_test.dart` file and remain private.

## Coverage

**Requirements:** No explicit coverage target or CI coverage gate was detected.

**View Coverage:**
```bash
flutter test --coverage
```

## Test Types

**Unit Tests:**
- Core tests cover time utilities, cache migration, API decoding/error mapping, provider error propagation, sync windows, and BLE type-sync behavior.

**Integration Tests:**
- No dedicated integration-test directory or runner was detected. Provider tests compose real Riverpod containers with overridden service boundaries.

**E2E Tests:**
- Not detected.

## Common Patterns

**Async Testing:**
```dart
await expectLater(
  container.read(dayBundleProvider('2026-01-01').future),
  throwsA(same(expected)),
);
```

**Error Testing:**
- Assert typed error identity and fields with `throwsA(isA<MetricsApiException>().having(...))`.
- Verify retries and non-retry behavior by inspecting stub request counts and paths.
- Verify no-data behavior explicitly, for example `find.text('—')` and `find.text('64')` not found in `test/widgets/heart_rate_bpm_hero_test.dart`.

**Adding Tests:**
- Add core behavior tests under `test/core/` for providers, services, models, cache, and BLE logic.
- Add rendering tests under `test/widgets/` for isolated widgets. Prefer testing truthful loading, empty, error, and success states.
- Run `flutter analyze` and the relevant `flutter test` target after changes. For full-suite URI/path issues, use a temporary path without special characters as required by `AGENTS.md`.

---

*Testing analysis: 2026-08-23*
