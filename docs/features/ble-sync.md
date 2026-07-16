# Feature — BLE sync

Pulls historical health data off the Helio Strap and uploads it to the Go API.
This is the app's core job. Everything else reads what this produces.

The phone does **not** parse health data and does **not** store it. It fetches raw
session bytes, wraps them with paging anchors, and posts them. The server parses.

## Flow

```
UI (SettingsHub / HomeScreen)
  └─ syncOrchestrator (provider)          providers/sync_orchestrator.dart
       └─ runFullSync(...)                services/ble/sync_orchestrator_run.dart
            ├─ bandSession.tryAcquire(sync)      ← blocked if band alerts is on
            ├─ resolveSyncWindow(ref)            ← asks the server what it already has
            ├─ SyncFetcher → TypeSyncEngine      ← per-type BLE fetch loop
            └─ SyncCommitter.upload(payload)     ← POST /api/v1/ingest
```

## Step 1 — Acquire the band

`BandSessionProvider` is a mutex over the single `BandLink`. Sync, live HR, and band
alerts all contend for it. `tryAcquire(BandSessionOp.sync)` returns a non-null
message if something else holds it, and the run aborts with that message.

Band alerts mode blocks sync outright — the user must toggle it off first.

## Step 2 — Resolve the sync window (server-driven)

`resolveSyncWindow` (`sync_window_resolver.dart`) calls `GET /api/v1/metrics/coverage`
and hands the result to `SyncWindow.plan(...)` (`sync_window.dart`), which decides a
`since` timestamp **per type code**.

This is what makes reinstall safe: the phone keeps no bookmarks. The server is the
only authority on what's already ingested.

Fallbacks, in order:

| Condition | Plan |
|---|---|
| API not configured | Refuse — "configure Cloud API before syncing" |
| Coverage fetch failed / null | Backfill `initialSyncBackfillDays` for every type |
| `coverage.types` non-empty | Per-type `since` from each type's watermark |
| Only `dataThrough` set | Single cutoff for all types |
| `hasData == false` | Full backfill |

`SyncCoverage` (`models/sync_coverage.dart`) parses `dataThrough`, `lastIngestAt`,
`hasData`, and the per-type map.

## Step 3 — Fetch per type

`TypeSyncEngine` (`type_sync_engine.dart`) speaks the Huami activity-fetch protocol
over plaintext GATT — control `0x0004`, data `0x0005`:

```
[0x01, type] + HuamiTime   →  meta reply [0x10, 0x01, status, expected, date]
[0x02]  fetch              →  data on 0x0005 as [counter, payload...]
[0x03, 0x09] ack (keep)    →  next round
```

Each round yields a `roundStart` from the device. The engine records
`(byteOffset, roundStart)` pairs into `roundSegments` — **per page, not one global
anchor**. Server-side parsers depend on these to timestamp rows correctly.

Type codes live in `constants/constants.dart`. The fetched set includes `0x01`
(HR/steps/activity), `0x05`/`0x06` (workouts), `0x48` (sleep blobs), `0x49` (HRV),
`0x46` (continuous HR), `0x2E` (temperature), `0x39` (readiness), and others.
Some codes are deliberately never fetched (`0x07` is a ~20 MB firmware log).

Byte-level detail — the full chunked protocol, per-code record layouts, and the
paging/anchor semantics — lives in protocol notes kept outside this repo.

## Step 4 — Commit

`SyncPayloadBuilder` assembles the raw bytes + anchors into a `SyncPayload`.
`SyncCommitter` (`sync_committer.dart`) uploads it, then refreshes
`liveHealthProvider` and invalidates `detailMetricsProvider` so the UI repaints
from the server's newly-parsed view.

## Key files

| File | Role |
|---|---|
| `providers/sync_orchestrator.dart` | Riverpod `Notifier`, owns `SessionSnapshot` + logs |
| `services/ble/sync_orchestrator_run.dart` | The run loop |
| `services/ble/sync_window.dart` | Pure window-planning logic (unit-tested) |
| `services/ble/type_sync_engine.dart` | Huami fetch state machine |
| `services/ble/sync_fetcher.dart` | Per-type driver over `BandLinkPort` |
| `services/ble/sync_committer.dart` | Upload + cache invalidation |
| `services/ble/sync_page_anchor.dart` | `(byteOffset, roundStart)` pairs |

## Gotchas

- `BandLinkPort` is the seam for tests. If you add a param to `connectAndAuth`,
  the mock in `test/core/ble/sync_fetcher_test.dart` must match or `flutter analyze`
  fails with `invalid_override`.
- Fetch timeout is 30 s per type, `maxRounds` 20. A strap with months of backlog
  can hit the round cap before the timeout.
- `probeOnly` fetches metadata without pulling data — used to discover which codes
  a strap actually holds.
