# Feature : BLE sync

Pulls historical health data off the Helio Strap and uploads it to the Go API.
This is the app's core job. Everything else reads what this produces.

The phone does not parse historical health blobs. It fetches raw session bytes,
wraps them with paging anchors, and posts them. The server parses. Closed-day
server responses are cached locally; session metadata and diagnostic dumps are
separate local storage. See [home and caching](home-and-rings.md).

## Flow

```
UI (SettingsHub / HomeScreen)
  └─ syncOrchestrator (provider)          providers/sync_orchestrator.dart
       └─ runFullSync(...)                services/ble/sync_orchestrator_run.dart
            ├─ bandSession.tryAcquire(sync)      ← blocked if band alerts is on
            ├─ resolveSyncWindow(ref)            ← asks the server what it already has
            ├─ SyncFetcher → TypeSyncEngine      ← per-type BLE fetch loop
            └─ SyncCommitter.commit(payload)     ← signed POST /api/ingest
```

## Step 1 : Acquire the band

`BandSessionProvider` is a mutex over the single `BandLink`. Sync, live HR, and band
alerts all contend for it. `tryAcquire(BandSessionOp.sync)` returns a non-null
message if something else holds it, and the run aborts with that message.

Band alerts mode blocks sync outright : the user must toggle it off first.

## Step 2 : Resolve the sync window (server-driven)

`resolveSyncWindow` (`sync_window_resolver.dart`) calls `GET /api/metrics/coverage`
and hands the result to `SyncWindow.plan(...)` (`sync_window.dart`), which decides a
`since` timestamp **per type code**.

This is what makes reinstall safe: the phone keeps no bookmarks. The server is the
only authority on what's already ingested.

`SyncCoverage` (`models/sync_coverage.dart`) decodes a strict C3 shape: `hasData`,
`lastIngestAt`, `dataThrough` and `types` with exactly the eleven measured codes
(`0x01 0x05 0x06 0x0D 0x13 0x25 0x2E 0x38 0x46 0x48 0x49`). Any other key set is a
protocol error shown as a coverage error with retry. `lastIngestAt` is the only
confirmed-sync timestamp; `dataThrough` is display-only and never a fetch cursor.

Planning cases (the empty-backend case is checked before per-type coverage):

| Condition | Plan |
|---|---|
| API not configured | Sync action rejects with "configure Cloud API before syncing"; the window planner alone returns a fallback |
| Coverage fetch failed / null | Backfill `initialSyncBackfillDays` for every type |
| `coverage.types` non-empty | Per-type `since` from each type's watermark |
| Only `dataThrough` set | Display-only; it is not used to skip a fetch |
| `hasData == false` | Full backfill : uses the wizard's chosen day count if set (see below), else `initialSyncBackfillDays` |

### Wizard-chosen backfill days

The device-setup wizard's last step (see
[settings-and-device.md](settings-and-device.md)) lets the user pick how
many days back the *first* sync should pull, via `backfillDaysProvider`
(`StateProvider<int?>`). `SyncWindow.plan(..., userBackfillDays:)` only
consumes it on the genuine "backend empty, first sync" path : a coverage
fetch failure isn't a first-sync signal, so that fallback still uses the
fixed `initialSyncBackfillDays` constant. `SyncOrchestrator._run` reads the
provider, passes it through, and resets it to `null` **only if the sync
actually succeeded** : a failed first attempt (Bluetooth hiccup, auth
rejection) leaves the user's chosen value intact for the retry, rather than
silently falling back to the configured default (currently 20 days).

## Step 3 : Fetch per type

`TypeSyncEngine` (`type_sync_engine.dart`) speaks the Huami activity-fetch protocol
over plaintext GATT : control `0x0004`, data `0x0005`:

```
[0x01, type] + HuamiTime   →  meta reply [0x10, 0x01, status, expected, date]
[0x02]  fetch              →  data on 0x0005 as [counter, payload...]
[0x03, 0x09] ack (keep)    →  next round
```

Each round yields a `roundStart` from the device. The engine records
`(byteOffset, roundStart)` pairs into `roundSegments` : **per page, not one global
anchor**. Server-side parsers depend on these to timestamp rows correctly.

`productionFetchTypeCodes` (`services/ble/sync_type_catalog.dart`) lists the
twelve types a normal sync fetches: `0x01 0x05 0x06 0x0D 0x13 0x25 0x26 0x2E 0x38
0x46 0x48 0x49`. The uploader consumes that list read-only and does not keep a
second accepted-type list. `0x39` and `0x3A` are not used and `0x3B` is a
training-load snapshot that is not ingested as activities. Some codes are
deliberately never fetched (`0x07` is a ~20 MB firmware log).

Measured SpO2 comes only from `0x25`. Type `0x26` contains sleep-breathing
placeholders and is uploaded as `raw_only`; it is never treated as an oxygen
measurement. Physical SpO2 verification on hardware is still pending.

Byte-level detail, including the full chunked protocol, per-code record layouts,
and paging and anchor semantics, lives in protocol notes kept outside this repo.

## Step 4 : Commit

The fetch flow assembles the raw bytes + anchors into a `SyncPayload`.
`IngestRequestEncoder` builds exactly one `session` JSON part, one `catalog` JSON
part and each nonempty raw type part, finalizes the multipart body once and freezes
its boundary and Content-Type. The request is signed over those exact bytes, so a
retry reuses the same body with a fresh timestamp and nonce. It enforces the 16 MiB
and 40-part caps locally and rejects a session without an end time, a bad MAC or an
empty file set before sending.

`SyncCommitter.commit` returns a typed `IngestResult` and the orchestrator keeps it
in `SessionSnapshot.lastIngestResult`:

- Per-type `accepted`, `partial` or `raw_only` status with rows, dropped counts,
  trailing bytes, warnings and the accepted watermark.
- A `partial` upload is reported as partial, not as a complete measurement.
- `0x26` raw-only is expected and does not make `complete` false.
- An atomic 422 (malformed framing, session or catalog) leaves coverage unchanged
  and surfaces an actionable failure. A 409 `session_conflict` needs a newly
  fetched immutable session; the app never changes bytes under an old session id.
- A deterministic 4xx is never retried automatically. Network and 5xx retries reuse
  the immutable request.

After a confirmed upload the committer delegates to `HealthDataRefreshCoordinator`,
which clears the stored day bundles and invalidates day bundles, activity history,
detail metrics, metric trends and sync status. Historical entries are also cleared
because a selected first-sync range or delayed upload can change an older day.

## Key files

| File | Role |
|---|---|
| `providers/sync_orchestrator.dart` | Riverpod `Notifier`, owns `SessionSnapshot` + logs |
| `services/ble/sync_orchestrator_run.dart` | The run loop |
| `services/ble/sync_window.dart` | Pure window-planning logic (unit-tested) |
| `services/ble/type_sync_engine.dart` | Huami fetch state machine |
| `services/ble/sync_fetcher.dart` | Per-type driver over `BandLinkPort` |
| `services/network/ingest_request_encoder.dart` | One-shot multipart encoding |
| `services/cloud_sync_repository_impl.dart` | Signed ingest and typed result |
| `services/ble/sync_committer.dart` | Upload result handling |
| `services/ble/sync_page_anchor.dart` | `(byteOffset, roundStart)` pairs |
| `providers/health_data_refresh_coordinator.dart` | Cache clearing and provider invalidation |

## Gotchas

- `BandLinkPort` is the intended seam for BLE tests. On machines where the
  workspace path prevents the Flutter test runner from resolving test URIs,
  run the suite from an isolated path without special characters.
- Fetch timeout and round limits are defined in `lib/constants/constants.dart`
  and the type engine; consult those values before changing a sync budget. A strap with months of backlog
  can hit the round cap before the timeout.
- `probeOnly` fetches metadata without pulling data : used to discover which codes
  a strap actually holds.
- The device-buffer may expire old data. Report missing data; never invent it.

Validation: not run for this revision.
