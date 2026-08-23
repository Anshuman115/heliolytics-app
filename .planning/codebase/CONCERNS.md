# Codebase Concerns

**Analysis Date:** 2026-08-23

## Tech Debt

**Oversized Flutter modules:**
- Issue: Several files exceed the repository's 150-line rule, concentrating multiple responsibilities.
- Files: `lib/constants/constants.dart`, `lib/services/ble/band_link.dart`, `lib/screens/activity_detail_screen.dart`, `lib/screens/health_hub_screen.dart`, `lib/services/metrics_api_client.dart`
- Impact: BLE lifecycle, parsing, UI state, and configuration changes are harder to review and test safely.
- Fix approach: Split by responsibility when touched, preserving `BandLinkPort` as the test seam and moving endpoint parsing into focused clients.

**Duplicated local async UI state:**
- Issue: Screens still use `FutureBuilder` and local `setState` for data loading while the project rules require Riverpod `AsyncNotifier` state.
- Files: `lib/screens/health_monitor_screen.dart`, `lib/widgets/home_health_scores_section.dart`, `lib/screens/api_settings_screen.dart`
- Impact: Loading, cancellation, and refresh behavior can diverge from provider-owned state.
- Fix approach: Move async work into providers and keep widgets as consumers of provider state.

**Broad exception handling and fire-and-forget work:**
- Issue: Several operations convert raw exceptions to UI strings or deliberately discard futures.
- Files: `lib/providers/strap_dump_provider.dart`, `lib/screens/profile_screen.dart`, `lib/screens/auth_key_screen.dart`, `lib/providers/band_alerts_forwarder.dart`
- Impact: Failures can be invisible, untracked, or reported with implementation details.
- Fix approach: Use typed failures, await user-visible operations, and route background errors through a bounded logger/state channel.

## Known Bugs

**Profile submission result is not surfaced:**
- Symptoms: Profile save starts an unawaited request and immediately clears the saving state.
- Files: `lib/screens/profile_screen.dart`
- Trigger: Submit a valid profile while the API is slow or unavailable.
- Workaround: None detected; confirm server-side persistence separately.

## Security Considerations

**Configurable API endpoint trust boundary:**
- Risk: Users can enter an arbitrary base URL and the app sends the signing token to that host.
- Files: `lib/services/config/api_config_storage.dart`, `lib/services/network/metrics_api_transport.dart`, `lib/screens/api_settings_screen.dart`
- Current mitigation: Android disables cleartext traffic in `android/app/src/main/AndroidManifest.xml`; token is generated per request.
- Recommendations: Require HTTPS at validation time, warn on endpoint changes, and avoid transmitting signing secrets to non-allowlisted hosts.

**Raw strap dump sharing:**
- Risk: The dump feature shares every file in its output directory, potentially exporting sensitive raw health bytes and unbounded diagnostic logs.
- Files: `lib/providers/strap_dump_provider.dart`, `lib/services/ble/strap_dump_service.dart`
- Current mitigation: Dump data is kept in app storage and is not part of the tracked repository.
- Recommendations: Make export explicit per file, show a sensitive-data warning, bound logs, and provide cleanup after sharing.

## Performance Bottlenecks

**Large in-memory metric expansion:**
- Problem: API responses containing offset/value arrays are expanded into one object per sample.
- Files: `lib/services/metrics_api_client.dart`
- Cause: `_parseSeries`, `_parseHeartRate`, and `_parseTemperature` materialize all requested days before consumers render them.
- Improvement path: Keep compact series representations, paginate or request only visible days, and cap default windows for chart screens.

**Unbounded diagnostic collections:**
- Problem: Strap dump and motor-proof logs retain every message for the run.
- Files: `lib/providers/strap_dump_provider.dart`, `lib/providers/motor_proof_provider.dart`
- Cause: Explicit no-trim log lists and 255-code dump runs.
- Improvement path: Apply a byte/count cap and stream logs to disk rather than retaining all strings in widget state.

## Fragile Areas

**Shared BLE link lifecycle:**
- Files: `lib/services/ble/band_link.dart`, `lib/providers/band_session_provider.dart`, `lib/providers/live_hr_provider.dart`, `lib/providers/band_alerts_provider.dart`
- Why fragile: Multiple streams and mutually exclusive modes share one physical connection; missed cancellation or reconnect ordering can strand subscriptions or block sync.
- Safe modification: Preserve `BandSessionProvider` as the mutex, test connect/disconnect/error paths, and dispose every subscription and timer.
- Test coverage: Unit coverage exists for sync and type fetching, but direct lifecycle coverage across alerts, live HR, and sync is limited.

**Protocol framing and cryptographic handshake:**
- Files: `lib/services/ble/gatt_framing.dart`, `lib/services/ble/pairing_curve_b163.dart`, `lib/services/ble/encrypted_endpoint.dart`
- Why fragile: Byte-level changes can break device interoperability without compile-time signals.
- Safe modification: Add golden vectors and malformed-frame tests before changing wire formats.
- Test coverage: `test/core/type_sync_engine_test.dart` and auth tests cover selected paths, not the complete reconnect and corruption matrix.

## Scaling Limits

**Full-window client fetches:**
- Current capacity: Defaults are configured in `lib/constants/constants.dart` and several endpoints fetch multi-day arrays in one request.
- Limit: Memory, decode time, and chart build cost grow with sample count and window size.
- Scaling path: Enforce server/client pagination and cache per day, then load only the selected range.

## Dependencies at Risk

**Platform and BLE package compatibility:**
- Risk: BLE behavior depends on `flutter_blue_plus`, Android permissions, and foreground-service behavior across OS versions.
- Impact: A dependency or Android target change can break pairing, notifications, or background alerts without Dart API failures.
- Migration plan: Pin and review upgrades, maintain physical-device smoke tests, and verify permissions in `android/app/src/main/AndroidManifest.xml`.

## Missing Critical Features

**No detected automated release/device gate:**
- Problem: Repository tests are concentrated in `test/core/` plus one widget test; no comprehensive physical-device BLE, background alert, or APK install smoke suite is detected.
- Blocks: Regression confidence for the highest-risk hardware and lifecycle paths.

## Test Coverage Gaps

**UI and navigation flows:**
- What's not tested: Settings validation, onboarding, day navigation, empty/error states, and chart rendering across screen sizes.
- Files: `lib/screens/`, `lib/widgets/`
- Risk: UI regressions and lifecycle errors can ship despite core tests passing.
- Priority: Medium

**Security and export behavior:**
- What's not tested: HTTPS endpoint validation, token routing, secret clearing, and raw dump sharing/cleanup.
- Files: `lib/services/network/metrics_api_transport.dart`, `lib/services/config/api_config_storage.dart`, `lib/providers/strap_dump_provider.dart`
- Risk: Credential disclosure or accidental health-data export can go unnoticed.
- Priority: High

**BLE lifecycle failures:**
- What's not tested: Disconnect during fetch, duplicate starts, stream cancellation, Android permission denial, and alert/live-HR contention.
- Files: `lib/services/ble/`, `lib/providers/band_session_provider.dart`
- Risk: Stuck sessions, lost telemetry, or battery-draining subscriptions.
- Priority: High

---

*Concerns audit: 2026-08-23*
