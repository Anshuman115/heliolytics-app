import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/models/notification_caps.dart';
import 'package:heliolytics/models/band_alerts_config.dart';
import 'package:heliolytics/models/band_alerts_readiness.dart';
import 'package:heliolytics/models/band_session_state.dart';
import 'package:heliolytics/providers/band_alerts_forwarder.dart';
import 'package:heliolytics/providers/band_session_provider.dart';
import 'package:heliolytics/services/band_alerts/band_alerts_permissions.dart';
import 'package:heliolytics/services/band_alerts/band_alerts_platform.dart';
import 'package:heliolytics/services/ble/band_alerts_init.dart';
import 'package:heliolytics/services/ble/band_link.dart';
import 'package:heliolytics/services/config/band_alerts_prefs_storage.dart';
import 'package:heliolytics/utils/app_logger.dart';

class BandAlertsState {
  final BandAlertsConfig config;
  final BandAlertsReadiness readiness;
  final bool isLoading;
  final String? errorMessage;
  final NotificationCaps notificationCaps;
  final String? lastForwardStatus;

  const BandAlertsState({
    this.config = const BandAlertsConfig(),
    this.readiness = const BandAlertsReadiness(),
    this.isLoading = true,
    this.errorMessage,
    this.notificationCaps = NotificationCaps.v4,
    this.lastForwardStatus,
  });

  bool get isReady => readiness.isReadyFor(config);

  BandAlertsState copyWith({
    BandAlertsConfig? config,
    BandAlertsReadiness? readiness,
    bool? isLoading,
    String? errorMessage,
    NotificationCaps? notificationCaps,
    String? lastForwardStatus,
    bool clearError = false,
    bool clearForwardStatus = false,
  }) =>
      BandAlertsState(
        config: config ?? this.config,
        readiness: readiness ?? this.readiness,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        notificationCaps: notificationCaps ?? this.notificationCaps,
        lastForwardStatus: clearForwardStatus
            ? null
            : (lastForwardStatus ?? this.lastForwardStatus),
      );
}

class BandAlertsNotifier extends Notifier<BandAlertsState> {
  final _permissions = BandAlertsPermissions();

  void _log(String msg) =>
      AppLogger.instance.log(msg, tag: 'band_alerts');

  void setForwardStatus(String msg) {
    state = state.copyWith(lastForwardStatus: msg);
  }

  @override
  BandAlertsState build() {
    ref.keepAlive();
    _bootstrap();
    return const BandAlertsState();
  }

  Future<void> _bootstrap() async {
    final storage = ref.read(bandAlertsPrefsStorageProvider);
    var config = await storage.load();
    final readiness = await _permissions.check(config);
    state = BandAlertsState(config: config, readiness: readiness);

    if (config.enabled && !readiness.isReadyFor(config)) {
      config = config.copyWith(enabled: false);
      await storage.save(config);
      state = state.copyWith(config: config, isLoading: false);
      return;
    }

    if (config.enabled) {
      final ok = await _activate(config);
      if (!ok) {
        state = state.copyWith(isLoading: false);
        return;
      }
    }
    state = state.copyWith(isLoading: false);
  }

  Future<void> refreshReadiness() async {
    final readiness = await _permissions.check(state.config);
    state = state.copyWith(readiness: readiness, clearError: true);
  }

  Future<void> requestPermissions() async {
    await _permissions.requestFor(state.config);
    await refreshReadiness();
  }

  Future<bool> setEnabled(bool enabled) async {
    if (enabled) {
      await refreshReadiness();
      if (!state.isReady) {
        state = state.copyWith(
          errorMessage: 'Complete setup before enabling band alerts',
        );
        return false;
      }
      final ok = await _activate(state.config);
      if (!ok) return false;
      final next = state.config.copyWith(enabled: true);
      await ref.read(bandAlertsPrefsStorageProvider).save(next);
      state = state.copyWith(config: next, clearError: true);
      return true;
    }

    await _deactivate();
    ref.read(bandAlertsForwarderProvider.notifier).stop();
    final next = state.config.copyWith(enabled: false);
    await ref.read(bandAlertsPrefsStorageProvider).save(next);
    state = state.copyWith(config: next, clearError: true);
    return true;
  }

  Future<void> setForwardCalls(bool value) async {
    var next = state.config.copyWith(forwardCalls: value);
    if (!value) next = next.copyWith(callsOnly: false);
    await _persistConfig(next);
  }

  Future<void> setCallsOnly(bool value) async {
    final next = state.config.copyWith(
      callsOnly: value,
      clearAllowlist: value,
    );
    await _persistConfig(next);
  }

  Future<void> togglePackage(String packageId, bool selected) async {
    final pkgs = Set<String>.from(state.config.allowedPackages);
    if (selected) {
      pkgs.add(packageId);
    } else {
      pkgs.remove(packageId);
    }
    final next = state.config.copyWith(
      allowedPackages: pkgs,
      callsOnly: false,
    );
    await _persistConfig(next);
  }

  Future<void> _persistConfig(BandAlertsConfig next) async {
    final wasEnabled = state.config.enabled;
    await ref.read(bandAlertsPrefsStorageProvider).save(next);
    final readiness = await _permissions.check(next);
    state = state.copyWith(config: next, readiness: readiness);

    if (wasEnabled && !readiness.isReadyFor(next)) {
      await setEnabled(false);
    } else if (next.enabled && readiness.isReadyFor(next)) {
      await _activate(next);
    }
  }

  Future<bool> _activate(BandAlertsConfig config) async {
    final band = ref.read(bandSessionProvider.notifier);
    final blocked = band.tryAcquire(BandSessionOp.bandAlerts);
    if (blocked != null) {
      state = state.copyWith(errorMessage: blocked);
      return false;
    }
    if (!await band.ensureConnected()) {
      band.release(BandSessionOp.bandAlerts);
      state = state.copyWith(
        errorMessage: ref.read(bandSessionProvider).errorMessage ??
            'Could not connect to strap',
      );
      return false;
    }

    final link = band.session.link;
    if (link is! BandLink) {
      band.release(BandSessionOp.bandAlerts);
      state = state.copyWith(errorMessage: 'Strap link unavailable');
      return false;
    }

    ref.read(bandAlertsForwarderProvider.notifier).start();

    final init = await BandAlertsInitService(log: _log).run(link, config);
    if (!init.success) {
      ref.read(bandAlertsForwarderProvider.notifier).stop();
      band.release(BandSessionOp.bandAlerts);
      state = state.copyWith(
        errorMessage: 'Strap setup failed — close Zepp if open, then retry',
      );
      return false;
    }

    state = state.copyWith(notificationCaps: init.notificationCaps);
    link.onLinkLost = () => handleLinkLost();
    await BandAlertsPlatform.startForeground();
    final apps = config.allowedPackages.length;
    setForwardStatus(
      apps == 0
          ? 'Ready — add apps to allowlist for message alerts'
          : 'Ready — listening ($apps app${apps == 1 ? '' : 's'})',
    );
    _log('band alerts active — sync and live HR blocked');
    return true;
  }

  Future<void> _deactivate() async {
    await BandAlertsPlatform.stopForeground();
    ref.read(bandSessionProvider.notifier).release(BandSessionOp.bandAlerts);
    final link = ref.read(bandSessionProvider.notifier).session.link;
    if (link is BandLink) link.onLinkLost = null;
    _log('band alerts off');
  }

  Future<void> handleLinkLost() async {
    if (!state.config.enabled) return;
    ref.read(bandAlertsForwarderProvider.notifier).stop();
    await BandAlertsPlatform.stopForeground();
    ref.read(bandSessionProvider.notifier).onLinkLost();
    ref.read(bandSessionProvider.notifier).release(BandSessionOp.bandAlerts);
    final next = state.config.copyWith(enabled: false);
    await ref.read(bandAlertsPrefsStorageProvider).save(next);
    state = state.copyWith(
      config: next,
      errorMessage:
          'Strap disconnected. Toggle band alerts off and on to recover.',
    );
    _log('link lost — band alerts disabled');
  }
}

final bandAlertsProvider =
    NotifierProvider<BandAlertsNotifier, BandAlertsState>(
  BandAlertsNotifier.new,
);
