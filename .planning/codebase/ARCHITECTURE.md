<!-- refreshed: 2026-08-23 -->
# Architecture

**Analysis Date:** 2026-08-23

## System Overview

```text
Flutter app shell (`lib/main.dart`)
        |
        v
GoRouter routes (`lib/router/app_router.dart`) ---> screens (`lib/screens/`)
        |                                               |
        |                                               v
        |                                      Riverpod providers (`lib/providers/`)
        |                                               |
        +-----------------------------------------------+
                                                        v
                         services (`lib/services/`): BLE, network, storage, cache
                                                        |
                         models (`lib/models/`) <-------+------> Go API / strap
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| App bootstrap | Initializes Flutter, Hive, secure stores, and ProviderScope | `lib/main.dart` |
| Router | Owns routes and auth/onboarding redirects | `lib/router/app_router.dart` |
| Shell | Hosts tab navigation and lifecycle-aware app content | `lib/screens/helio_shell.dart` |
| Screens | Compose full pages and react to provider state | `lib/screens/` |
| Providers | Own Riverpod state, orchestration, and UI-facing async flows | `lib/providers/` |
| Services | Encapsulate BLE, HTTP, persistence, caching, and platform APIs | `lib/services/` |
| Models | Typed domain and transport data structures | `lib/models/` |
| Design system | Shared visual tokens and reusable UI components | `lib/design_system/` |

## Pattern Overview

**Overall:** Layer-first Flutter architecture using Riverpod Notifiers and service/repository boundaries.

**Key Characteristics:**
- Screens depend on providers, providers depend on services and models.
- BLE operations are centralized under `lib/services/ble/`; UI never calls BLE directly.
- HTTP access is behind network clients and repositories such as `lib/services/metrics_api_client.dart` and `lib/services/cloud_sync_repository_impl.dart`.
- Async state uses Riverpod providers and Notifiers rather than `FutureBuilder`.
- Server-side parsing is the boundary: the app fetches raw strap bytes and uploads them, then reads parsed metrics.

## Layers

**Presentation:**
- Purpose: Render routes, tabs, feature screens, and extracted widgets.
- Location: `lib/screens/`, `lib/widgets/`, `lib/design_system/`
- Contains: `ConsumerWidget`/`ConsumerStatefulWidget` pages, feature widgets, theme and tokens.
- Depends on: Providers, models, and design system.
- Used by: Router and shell.

**State and orchestration:**
- Purpose: Expose reactive state and coordinate feature workflows.
- Location: `lib/providers/`
- Contains: `AsyncNotifier`, `Notifier`, `Provider`, and `FutureProvider` definitions.
- Depends on: Services and models.
- Used by: Screens, router, and other providers.

**Services and infrastructure:**
- Purpose: Perform external I/O and platform-specific work.
- Location: `lib/services/`
- Contains: BLE session/sync code, Dio clients, secure/config storage, Hive caches, and repositories.
- Depends on: Flutter plugins, models, and utilities.
- Used by: Providers.

**Domain/transport models:**
- Purpose: Type app state, API payloads, metric data, and BLE session results.
- Location: `lib/models/`
- Contains: Immutable-ish data classes and JSON/transport structures.
- Depends on: Dart primitives and serialization helpers.
- Used by: All non-trivial layers.

## Data Flow

### Primary Request Path

1. `lib/main.dart` bootstraps Hive and secure storage, then mounts `ProviderScope`.
2. `lib/router/app_router.dart` evaluates onboarding and auth state from `lib/providers/onboarding_provider.dart` and `lib/providers/sync_orchestrator.dart`.
3. A screen such as `lib/screens/home_screen.dart` watches day and sync providers.
4. `lib/providers/day_bundle_provider.dart` or `lib/providers/cloud_sync_provider.dart` calls cache/repository services.
5. `lib/services/metrics_api_client.dart` and `lib/services/network/metrics_api_transport.dart` request typed metric data from the API.
6. The provider returns model instances such as `lib/models/day_bundle.dart` to widgets.

### BLE Sync Flow

1. `lib/screens/helio_shell.dart` schedules auto-connect through `syncOrchestratorProvider`.
2. `lib/providers/sync_orchestrator.dart` delegates connection and sync to `lib/services/ble/sync_orchestrator_actions.dart` and `lib/services/ble/sync_orchestrator_run.dart`.
3. `lib/services/ble/band_session.dart` owns the single authenticated `BandLink`.
4. `lib/services/ble/type_sync_engine.dart` and fetch/session helpers retrieve pages and build `lib/models/sync_payload.dart`.
5. `lib/services/cloud_sync_repository_impl.dart` uploads raw sync payloads using signed network requests.

**State Management:** Riverpod owns reactive state. `BandSessionProvider`/`BandSession` provide the shared BLE mutex/session, while Hive and secure storage persist only app/cache/config state according to feature boundaries.

## Key Abstractions

**Band session boundary:**
- Purpose: Serialize one authenticated BLE connection for sync, live HR, and alerts.
- Examples: `lib/services/ble/band_session.dart`, `lib/providers/band_session_provider.dart`, `lib/services/ble/band_session_lock.dart`
- Pattern: Shared session object with connection coalescing and explicit disconnect.

**Repository/client boundary:**
- Purpose: Keep API transport details out of screens and most providers.
- Examples: `lib/services/cloud_sync_repository.dart`, `lib/services/cloud_sync_repository_impl.dart`, `lib/services/metrics_api_client.dart`
- Pattern: Interface plus implementation, injected through Riverpod providers.

**Provider-driven feature state:**
- Purpose: Make async loading, errors, and refreshes observable by widgets.
- Examples: `lib/providers/day_bundle_provider.dart`, `lib/providers/live_hr_provider.dart`, `lib/providers/onboarding_provider.dart`
- Pattern: Riverpod Notifiers and derived providers.

## Entry Points

**Application entry:**
- Location: `lib/main.dart`
- Triggers: Flutter platform launch.
- Responsibilities: Plugin initialization, cache migration, config seeding, secure store setup, and app mount.

**Route entry:**
- Location: `lib/router/app_router.dart`
- Triggers: Navigation and provider state changes.
- Responsibilities: Route registration and onboarding/auth redirects.

**Shell entry:**
- Location: `lib/screens/helio_shell.dart`
- Triggers: Authenticated root route `/`.
- Responsibilities: Tab stack, bottom navigation, lifecycle scope, and auto-connect scheduling.

## Architectural Constraints

- **Threading:** Flutter UI isolate; asynchronous BLE, HTTP, storage, and platform calls use Dart futures/streams.
- **Global state:** Provider singletons include `appRouterProvider`, `syncOrchestratorProvider`, and shared `BandSession` state in `lib/providers/band_session_provider.dart`.
- **Circular imports:** No intentional circular dependency chain detected; feature provider/service boundaries should be preserved.
- **BLE ownership:** One shared BLE link is enforced by `BandSessionProvider` and `lib/services/ble/band_session_lock.dart`.
- **Data ownership:** The phone uploads raw session bytes; health parsing and durable health history belong to the server.

## Anti-Patterns

### UI-owned I/O

**What happens:** A screen directly calls BLE, Dio, or storage APIs.
**Why it's wrong:** It bypasses state boundaries and makes lifecycle and testing fragile.
**Do this instead:** Add a service method and expose it through a provider, following `lib/screens/home_screen.dart` → `lib/providers/day_bundle_provider.dart`.

### Provider build side effects

**What happens:** Network or BLE workflow logic is embedded in a widget `build()` method.
**Why it's wrong:** Rebuilds can repeat side effects and make state transitions implicit.
**Do this instead:** Put async work in a Notifier/provider, as in `lib/providers/sync_orchestrator.dart`.

## Error Handling

**Strategy:** Services catch transport/platform failures, log through `AppLogger`, and return typed outcomes or provider errors; screens render loading/error/empty states.

**Patterns:**
- `lib/services/ble/band_session.dart` disconnects and resolves failed connection attempts safely.
- `lib/providers/sync_orchestrator.dart` emits session snapshots and logs for sync state.
- `lib/widgets/error_view.dart` centralizes user-facing error rendering.

## Cross-Cutting Concerns

**Logging:** `lib/utils/app_logger.dart` and Talker-backed log views.
**Validation:** Typed model parsing, auth-key validation in `lib/services/ble/auth/auth_key_validator.dart`, and service-level response handling.
**Authentication:** Secure strap/API credentials through `lib/services/ble/auth/secure_key_store.dart`; signed API requests through `lib/services/network/heliolytics_token.dart`.

---

*Architecture analysis: 2026-08-23*
