import 'dart:typed_data';

import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/models/dump_entry.dart';
import 'package:heliolytics/models/session_mode.dart';
import 'package:heliolytics/models/session_state.dart';
import 'package:heliolytics/models/strap_health_config.dart';
import 'package:heliolytics/models/sync_payload.dart';
import 'package:heliolytics/services/ble/auth/auth_key_storage.dart';
import 'package:heliolytics/services/ble/band_link.dart';
import 'package:heliolytics/services/ble/band_link_port.dart';
import 'package:heliolytics/services/ble/sync_fetch_outcome.dart';
import 'package:heliolytics/services/ble/sync_fetcher_session.dart';
import 'package:heliolytics/services/ble/sync_type_catalog.dart';
import 'package:heliolytics/services/ble/sync_type_fetch.dart';
import 'package:heliolytics/services/ble/sync_window.dart';
import 'package:heliolytics/services/ble/sync_window_plan.dart';
import 'package:heliolytics/services/ble/sync_session_port.dart';

typedef TypeProgressFn = void Function(String code, TypeCodeResult result);
typedef BandLinkFactory = BandLinkPort Function(void Function(String) log);

class SyncFetcher {
  final void Function(String) log;
  final SyncSessionPort store;
  final AuthKeyStorage auth;
  final BandLinkFactory linkFactory;

  SyncFetcher({
    required this.log,
    required this.store,
    required this.auth,
    BandLinkFactory? linkFactory,
  }) : linkFactory = linkFactory ?? ((l) => BandLink(l));

  Future<SyncFetchOutcome?> run({
    required String mac,
    required Uint8List authKey,
    required SyncWindowPlan plan,
    String? singleTypeCode,
    HealthConfigSnapshot? strapConfig,
    BandLinkPort? client,
    bool disconnectAfter = true,
    void Function(String code)? onTypeStart,
    TypeProgressFn? onTypeProgress,
  }) async {
    if (singleTypeCode != null && !isProductionFetchType(singleTypeCode)) {
      log('✗ forbidden production refetch $singleTypeCode');
      return null;
    }
    final owned = client == null;
    final link = client ?? linkFactory(log);
    if (owned) {
      var authed = await link.connectAndAuth(mac: mac, authKey: authKey);
      if (!authed) {
        log('• connect/auth failed — retrying once');
        await Future<void>.delayed(const Duration(seconds: 1));
        authed = await link.connectAndAuth(mac: mac, authKey: authKey);
      }
      if (!authed) return null;
    }
    try {
      return await fetch(
        client: link,
        mac: mac,
        plan: plan,
        singleTypeCode: singleTypeCode,
        strapConfig: strapConfig,
        onTypeStart: onTypeStart,
        onTypeProgress: onTypeProgress,
      );
    } finally {
      if (owned && disconnectAfter) await link.disconnect();
    }
  }

  Future<SyncFetchOutcome?> fetch({
    required BandLinkPort client,
    required String mac,
    required SyncWindowPlan plan,
    String? singleTypeCode,
    HealthConfigSnapshot? strapConfig,
    void Function(String code)? onTypeStart,
    TypeProgressFn? onTypeProgress,
  }) async {
    if (singleTypeCode != null && !isProductionFetchType(singleTypeCode)) {
      log('✗ forbidden production refetch $singleTypeCode');
      return null;
    }
    final codes = singleTypeCode == null
        ? productionFetchTypeCodes
        : <String>[singleTypeCode];

    final requestedHours = DateTime.now().difference(plan.anchorSince).inHours;
    final hours = requestedHours < 1 ? 1 : requestedHours;
    final sessionId = await store.createSession(
      deviceMac: mac,
      fetchWindowHours: hours,
      listenDurationSec: 0,
      mode: SessionMode.fetchAndListen,
    );

    final entries = <DumpEntry>[];
    final rawByCode = <String, Uint8List>{};
    final results = <TypeCodeResult>[];

    for (final codeStr in codes) {
      onTypeStart?.call(codeStr);
      log('Fetching $codeStr (${typeCodeLabels[codeStr] ?? codeStr}) ...');
      try {
        final typeInt = int.parse(
          codeStr.startsWith('0x') ? codeStr.substring(2) : codeStr,
          radix: 16,
        );
        final fetched = await client.fetchCode(
          typeInt,
          SyncWindow.sinceForType(plan, codeStr),
        );
        if (fetched.outcome == TypeFetchOutcome.disconnected) {
          throw const BandLinkDisconnectedException();
        }
        final parsed = SyncTypeFetch.run(
          codeStr: codeStr,
          fetch: fetched,
          log: log,
        );
        results.add(parsed.result);
        onTypeProgress?.call(codeStr, parsed.result);
        entries.add(parsed.entry);
        if (parsed.raw != null) rawByCode[codeStr] = parsed.raw!;
      } on BandLinkDisconnectedException {
        rethrow;
      } catch (e) {
        log('  ✗ $codeStr: ERROR — $e');
        final err = SyncTypeFetch.errorResult(codeStr, e);
        results.add(err);
        onTypeProgress?.call(codeStr, err);
        entries.add(SyncTypeFetch.errorEntry(codeStr, e));
      }
    }

    final catalog = buildCatalog(sessionId, entries, strapConfig: strapConfig);
    final session = await finalizeFetchSession(
      store: store,
      sessionId: sessionId,
      catalog: catalog,
      client: client,
      auth: auth,
    );
    return SyncFetchOutcome(
      payload: SyncPayload(
        session: session,
        catalog: catalog,
        rawByCode: Map.unmodifiable(rawByCode),
      ),
      typeResults: results,
    );
  }
}
