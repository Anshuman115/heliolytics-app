import 'dart:typed_data';

import 'package:heliolytics/services/ble/auth/auth_key_storage.dart';
import 'package:heliolytics/services/ble/band_link.dart';
import 'package:heliolytics/services/ble/band_link_port.dart';
import 'package:heliolytics/services/ble/sync_fetch_outcome.dart';
import 'package:heliolytics/services/ble/sync_fetcher_session.dart';
import 'package:heliolytics/services/ble/sync_session_port.dart';
import 'package:heliolytics/services/ble/sync_type_fetch.dart';
import 'package:heliolytics/services/ble/sync_window.dart';
import 'package:heliolytics/services/ble/sync_window_plan.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/models/session_state.dart';
import 'package:heliolytics/models/dump_entry.dart';
import 'package:heliolytics/models/session_mode.dart';
import 'package:heliolytics/models/sync_payload.dart';

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
    SyncPayload? mergeBase,
    bool disconnectAfter = true,
    void Function(String code)? onTypeStart,
    TypeProgressFn? onTypeProgress,
  }) async {
    final client = linkFactory(log);
    var authed = await client.connectAndAuth(mac: mac, authKey: authKey);
    if (!authed) {
      log('• connect/auth failed — retrying once');
      await Future<void>.delayed(const Duration(seconds: 1));
      authed = await client.connectAndAuth(mac: mac, authKey: authKey);
    }
    if (!authed) return null;
    try {
      return await fetch(
        client: client,
        mac: mac,
        plan: plan,
        singleTypeCode: singleTypeCode,
        mergeBase: mergeBase,
        onTypeStart: onTypeStart,
        onTypeProgress: onTypeProgress,
      );
    } finally {
      if (disconnectAfter) await client.disconnect();
    }
  }

  Future<SyncFetchOutcome?> fetch({
    required BandLinkPort client,
    required String mac,
    required SyncWindowPlan plan,
    String? singleTypeCode,
    SyncPayload? mergeBase,
    void Function(String code)? onTypeStart,
    TypeProgressFn? onTypeProgress,
  }) async {
    final codes = singleTypeCode != null ? [singleTypeCode] : fetchTypeCodes;
    if (singleTypeCode != null && mergeBase == null) return null;

    String? sessionId;
    if (singleTypeCode == null) {
      final hours = DateTime.now().difference(plan.anchorSince).inHours.clamp(
        1,
        24 * initialSyncBackfillDays,
      );
      sessionId = await store.createSession(
        deviceMac: mac,
        fetchWindowHours: hours,
        listenDurationSec: 0,
        mode: SessionMode.fetchAndListen,
      );
    }

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
        final parsed = SyncTypeFetch.run(codeStr: codeStr, fetch: fetched, log: log);
        results.add(parsed.result);
        onTypeProgress?.call(codeStr, parsed.result);
        entries.add(parsed.entry);
        if (parsed.raw != null) rawByCode[codeStr] = parsed.raw!;
      } catch (e) {
        log('  ✗ $codeStr: ERROR — $e');
        final err = SyncTypeFetch.errorResult(codeStr, e);
        results.add(err);
        onTypeProgress?.call(codeStr, err);
        entries.add(SyncTypeFetch.errorEntry(codeStr, e));
      }
    }

    if (singleTypeCode != null) {
      return _singleOutcome(mergeBase!, singleTypeCode, entries, results, rawByCode);
    }

    final catalog = buildCatalog(sessionId!, entries);
    final session = await finalizeFetchSession(
      store: store,
      sessionId: sessionId,
      catalog: catalog,
      client: client,
      auth: auth,
    );
    return SyncFetchOutcome(
      payload: SyncPayload(session: session, catalog: catalog, rawByCode: rawByCode),
      typeResults: results,
    );
  }

  SyncFetchOutcome _singleOutcome(
    SyncPayload base,
    String code,
    List<DumpEntry> entries,
    List<TypeCodeResult> results,
    Map<String, Uint8List> rawByCode,
  ) {
    if (rawByCode.isEmpty) {
      return SyncFetchOutcome(payload: base, typeResults: results);
    }
    return SyncFetchOutcome(
      payload: SyncPayload(
        session: base.session,
        catalog: buildCatalog(base.session.sessionId, [entries.single]),
        rawByCode: {code: rawByCode[code]!},
      ),
      typeResults: results,
    );
  }
}
