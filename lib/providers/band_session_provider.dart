import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/models/band_session_state.dart';
import 'package:heliolytics/services/ble/auth/auth_key_storage.dart';
import 'package:heliolytics/services/ble/band_session.dart';
import 'package:heliolytics/services/ble/band_session_lock.dart';

class BandSessionNotifier extends Notifier<BandSessionSnapshot> {
  final _session = BandSession();
  final _lock = BandSessionLock();

  @override
  BandSessionSnapshot build() {
    ref.keepAlive();
    ref.onDispose(() => _session.disconnect());
    return const BandSessionSnapshot();
  }

  BandSession get session => _session;

  /// Returns null on success, or a user-facing block message.
  String? tryAcquire(BandSessionOp op) {
    final err = _lock.tryAcquire(op);
    if (err != null) return err;
    state = state.copyWith(activeOp: _lock.holder);
    return null;
  }

  void release(BandSessionOp op) {
    _lock.release(op);
    state = state.copyWith(activeOp: _lock.holder);
  }

  Future<bool> ensureConnected() async {
    if (_session.isReady) {
      state = state.copyWith(
        linkState: BandLinkState.connected,
        batteryPercent: _session.batteryPercent,
        clearError: true,
      );
      return true;
    }

    state = state.copyWith(
      linkState: BandLinkState.connecting,
      clearError: true,
    );

    final auth = AuthKeyStorage(store: ref.read(authKeyStoreProvider));
    final mac = await auth.readMac();
    final key = await auth.readBytes();
    if (mac == null || mac.isEmpty || key == null) {
      state = state.copyWith(
        linkState: BandLinkState.error,
        errorMessage: 'No strap paired',
      );
      return false;
    }

    final ok = await _session.ensureConnected(mac: mac, authKey: key);
    if (!ok) {
      state = state.copyWith(
        linkState: BandLinkState.error,
        errorMessage:
            'Could not connect. Close the Zepp app if it is open, then retry.',
      );
      return false;
    }

    state = state.copyWith(
      linkState: BandLinkState.connected,
      batteryPercent: _session.batteryPercent,
      clearError: true,
    );
    return true;
  }

  Future<void> disconnect() async {
    await _session.disconnect();
    state = state.copyWith(
      linkState: BandLinkState.disconnected,
      clearBattery: true,
      clearError: true,
    );
  }

  void onLinkLost() {
    state = state.copyWith(
      linkState: BandLinkState.error,
      errorMessage: 'Strap disconnected. Open the app to reconnect.',
      clearBattery: true,
    );
  }

  Future<void> onAppResumed() async {
    if (state.isConnected || state.isConnecting) return;
    final auth = AuthKeyStorage(store: ref.read(authKeyStoreProvider));
    if (!await auth.hasKey() || !await auth.hasMac()) return;
    await ensureConnected();
  }

  Future<void> onAppPaused() async {
    if (_lock.holder == BandSessionOp.bandAlerts) return;
    if (_lock.holder != BandSessionOp.none) return;
    await disconnect();
  }
}

final bandSessionProvider =
    NotifierProvider<BandSessionNotifier, BandSessionSnapshot>(
  BandSessionNotifier.new,
);
