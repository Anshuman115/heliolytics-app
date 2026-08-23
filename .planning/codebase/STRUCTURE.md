# Codebase Structure

**Analysis Date:** 2026-08-23

## Directory Layout

```text
Heliolytics_App/
├── lib/
│   ├── constants/       # App literals and configuration defaults
│   ├── design_system/   # Theme, tokens, and shared components
│   ├── models/          # Domain and API data models
│   ├── providers/       # Riverpod state and orchestration
│   ├── router/          # GoRouter configuration
│   ├── screens/         # Full feature pages and app shell
│   ├── services/        # BLE, network, cache, config, and repositories
│   ├── utils/           # Logging, formatting, and helpers
│   ├── widgets/         # Screen and feature UI chunks
│   └── main.dart        # Flutter entry point
├── test/                # Public unit/widget/integration tests
├── android/             # Android host project and Gradle configuration
├── docs/                # Published and local project documentation
└── tool/                # Local build/install/run helpers
```

## Directory Purposes

**`lib/screens/`:**
- Purpose: Full pages and navigation destinations.
- Contains: Onboarding, home, health, activity, settings, diagnostics, and detail screens.
- Key files: `lib/screens/helio_shell.dart`, `lib/screens/home_screen.dart`, `lib/screens/health_monitor_screen.dart`

**`lib/widgets/`:**
- Purpose: Screen-specific and feature-specific UI chunks.
- Contains: Health, activity, stress, sleep, profile, settings, and home widgets.
- Key files: `lib/widgets/home_primary_rings.dart`, `lib/widgets/health/health_metric_grid.dart`, `lib/widgets/activity/activity_overview_body.dart`

**`lib/providers/`:**
- Purpose: Riverpod providers and feature state machines.
- Contains: Sync, BLE session, onboarding, API data, navigation, alerts, and refresh coordination.
- Key files: `lib/providers/sync_orchestrator.dart`, `lib/providers/band_session_provider.dart`, `lib/providers/day_bundle_provider.dart`

**`lib/services/`:**
- Purpose: I/O and platform boundaries.
- Contains: `ble/`, `network/`, `config/`, `cache/`, `band_alerts/`, and repository/client files.
- Key files: `lib/services/ble/band_link.dart`, `lib/services/ble/type_sync_engine.dart`, `lib/services/network/api_dio.dart`, `lib/services/cloud_sync_repository_impl.dart`

**`lib/design_system/`:**
- Purpose: Shared visual language.
- Contains: `components/`, `tokens/`, and `theme/`.
- Key files: `lib/design_system/theme/helio_theme.dart`, `lib/design_system/tokens/helio_spacing.dart`, `lib/design_system/components/helio_bottom_nav.dart`

**`lib/models/`:**
- Purpose: Shared typed values crossing layers.
- Contains: Health metrics, sessions, sync payloads, profiles, alerts, and coverage models.
- Key files: `lib/models/day_bundle.dart`, `lib/models/sync_payload.dart`, `lib/models/session_state.dart`

**`test/`:**
- Purpose: Tracked test suite and test seams.
- Contains: Unit/widget tests and mocks for service/provider boundaries.
- Key files: Search by feature under `test/`; `BandLinkPort` mocks must track `lib/services/ble/band_link_port.dart`.

## Key File Locations

**Entry Points:**
- `lib/main.dart`: Bootstrap and `ProviderScope`.
- `lib/router/app_router.dart`: Route graph and redirects.
- `lib/screens/helio_shell.dart`: Authenticated tab shell.

**Configuration:**
- `pubspec.yaml`: Flutter dependencies and package metadata.
- `analysis_options.yaml`: Dart analyzer rules.
- `lib/constants/constants.dart`: App literals and dart-define defaults.
- `lib/services/config/`: Secure/config persistence implementations.

**Core Logic:**
- `lib/providers/`: Feature state and orchestration.
- `lib/services/ble/`: Strap connection, framing, sync, and live HR.
- `lib/services/network/`: Signed HTTP transport.
- `lib/models/`: Cross-layer contracts.

**Testing:**
- `test/`: Tracked tests and mock implementations.

## Naming Conventions

**Files:**
- Use `snake_case.dart`, with role suffixes such as `_screen.dart`, `_provider.dart`, `_service.dart`, and `_storage.dart`; examples: `lib/screens/home_screen.dart`, `lib/providers/live_hr_provider.dart`.

**Directories:**
- Use lowercase descriptive directories grouped by layer: `lib/services/ble/`, `lib/widgets/health/`, and `lib/design_system/components/`.

## Where to Add New Code

**New Feature:**
- Primary page: `lib/screens/<feature>_screen.dart` or a feature hub under `lib/screens/`.
- State: `lib/providers/<feature>_provider.dart`.
- Service/API work: `lib/services/` under the relevant boundary.
- Models: `lib/models/`.
- Tests: `test/`, co-located by feature convention already present in the suite.

**New Component/Module:**
- Shared reusable UI: `lib/design_system/components/`.
- Feature-specific UI: `lib/widgets/` or its feature subdirectory.
- BLE module: `lib/services/ble/`, with one parser per data type where applicable.

**Utilities:**
- Shared helpers: `lib/utils/`.
- Constants and literals: `lib/constants/constants.dart` or the relevant design token file.

## Special Directories

**`docs/features/`:**
- Purpose: Published feature contracts and behavior documentation.
- Generated: No.
- Committed: Yes.

**`docs/protocol/`, `docs/validation/`, `docs/decisions/`:**
- Purpose: Local-only protocol, validation, and rationale material.
- Generated: Some reports may be generated.
- Committed: No, according to project rules.

**`RawData/`, `helio_dump*/`, `zepp-export/`, `reports/`:**
- Purpose: Local BLE dumps, ground truth, and generated validation artifacts.
- Generated: Yes or locally collected.
- Committed: No, according to project rules.

**`android/`:**
- Purpose: Android host integration, Gradle build, permissions, and platform code.
- Generated: Partly by Flutter tooling.
- Committed: Yes, excluding local build outputs and secrets.

---

*Structure analysis: 2026-08-23*
