import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/models/band_session_state.dart';
import 'package:heliolytics/providers/strap_health_config_provider.dart';
import 'package:heliolytics/services/ble/auth/auth_key_storage.dart';
import 'package:heliolytics/services/ble/band_link.dart';
import 'package:heliolytics/services/ble/band_session.dart';
import 'package:heliolytics/services/ble/band_session_lock.dart';

final bandSessionTransportProvider = Provider<BandSession>(
  (ref) => BandSession(),
);

class BandSessionNotifier extends Notifier<BandSessionSnapshot> {
  late BandSession _session;
  final _lock = BandSessionLock();
  BandLink? _observedLink;
  Future<bool>? _connecting;

  @override
  BandSessionSnapshot build() {
    ref.keepAlive();
    _session = ref.read(bandSessionTransportProvider);
    ref.onDispose(() {
      _observedLink?.removeDisconnectListener(onLinkLost);
      _session.disconnect();
    });
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
    final pending = _connecting;
    if (pending != null) await pending;
    // Read the stored MAC and key only after a concurrent connect attempt finishes.
    final attempt = _ensureConnected();
    _connecting = attempt;
    try {
      return await attempt;
    } finally {
      if (identical(_connecting, attempt)) _connecting = null;
    }
  }

  Future<bool> _ensureConnected() async {
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
    if (!_session.isReady) {
      state = state.copyWith(
        linkState: BandLinkState.connecting,
        clearError: true,
      );
      final ok = await _session.ensureConnected(mac: mac, authKey: key);
      if (!ok) {
        state = state.copyWith(
          linkState: BandLinkState.error,
          errorMessage:
              'Could not connect. Close the Zepp app if it is open, then retry.',
        );
        return false;
      }
    }
    final link = _session.link;
    if (link == null || !_session.isReady) return false;
    if (!identical(_observedLink, link)) {
      _observedLink?.removeDisconnectListener(onLinkLost);
      _observedLink = link;
      link.addDisconnectListener(onLinkLost);
    }
    state = state.copyWith(
      linkState: BandLinkState.connected,
      batteryPercent: _session.batteryPercent,
      clearError: true,
    );
    return true;
  }

  Future<void> disconnect() async {
    ref.read(strapHealthConfigProvider.notifier).invalidateActualState();
    _observedLink?.removeDisconnectListener(onLinkLost);
    _observedLink = null;
    await _session.disconnect();
    state = state.copyWith(
      linkState: BandLinkState.disconnected,
      clearBattery: true,
      clearError: true,
    );
  }

  void onLinkLost() {
    ref
        .read(strapHealthConfigProvider.notifier)
        .invalidateActualState(disconnected: true);
    state = state.copyWith(
      linkState: BandLinkState.error,
      errorMessage: 'Strap disconnected. Open the app to reconnect.',
      clearBattery: true,
    );
  }

  Future<void> onAppResumed() async {
    if (state.isConnecting) return;
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
