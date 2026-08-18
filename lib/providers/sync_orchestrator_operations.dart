part of 'sync_orchestrator.dart';

Future<void> runOrchestratedSync({
  required Ref ref,
  required AuthKeyStorage auth,
  required SessionStore? store,
  required SyncSessionLog sessionLog,
  required List<TypeCodeResult> results,
  required void Function(SyncPayload?) setPayload,
  required void Function(SessionSnapshot) emit,
  required SessionSnapshot Function() readState,
  required String mac,
}) async {
  final authKey = await auth.readBytes();
  if (store == null || authKey == null) {
    sessionLog.log('No auth key stored');
    emit(readState().copyWith(logs: sessionLog.logs));
    return;
  }
  final userBackfillDays = ref.read(backfillDaysProvider);
  await runFullSync(
    ref: ref,
    auth: auth,
    store: store,
    sessionLog: sessionLog,
    mac: mac,
    authKey: authKey,
    results: results,
    setPayload: setPayload,
    emit: emit,
    userBackfillDays: userBackfillDays,
  );
  if (userBackfillDays != null && readState().state != SessionState.error) {
    await auth.completeSetup();
    ref.read(backfillDaysProvider.notifier).state = null;
  }
}
