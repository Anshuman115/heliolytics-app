import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/constants/strap_health_constants.dart';
import 'package:heliolytics/models/band_session_state.dart';
import 'package:heliolytics/models/strap_health_config.dart';
import 'package:heliolytics/providers/band_session_provider.dart';
import 'package:heliolytics/services/ble/band_link.dart';
import 'package:heliolytics/services/ble/zepp/health_config_port.dart';
import 'package:heliolytics/services/ble/zepp/health_config_service.dart';
import 'package:heliolytics/services/config/strap_health_preferences_storage.dart';
import 'package:heliolytics/utils/app_logger.dart';

class StrapHealthConfigNotifier extends Notifier<StrapHealthConfigState> {
  @override
  StrapHealthConfigState build() => const StrapHealthConfigState();

  void invalidateActualState({bool disconnected = false}) {
    state = StrapHealthConfigState(
      phase: disconnected
          ? StrapHealthConfigPhase.error
          : StrapHealthConfigPhase.idle,
      desired: state.desired,
      error: disconnected ? 'Strap disconnected.' : null,
    );
  }

  Future<void> load() async {
    if (state.isBusy) return;
    await _withBand((link) async {
      await reconcileWithinSession(link);
    });
  }

  Future<void> setAllDay(bool on) async {
    if (state.isBusy) return;
    await _withBand(
      (link) => _applyUserChange(
        link,
        (service, port, config) => config.spo2AllDay == on
            ? Future.value(config)
            : service.setAllDay(port, on, version: config.version),
      ),
      saveChoice: () async {
        await ref.read(strapHealthPreferencesStorageProvider).saveAllDay(on);
        state = state.copyWith(
          desired: StrapHealthDesiredState(
            allDay: on,
            lowAlert: state.desired.lowAlert,
          ),
        );
      },
    );
  }

  Future<void> setLowAlert(int value) async {
    if (!strapHealthLowAlertChoices.contains(value)) {
      throw ArgumentError.value(value, 'value', 'must be 0, 80, 85 or 90');
    }
    if (state.isBusy) return;
    await _withBand(
      (link) => _applyUserChange(
        link,
        (service, port, config) => config.spo2LowAlert == value
            ? Future.value(config)
            : service.setLowAlert(port, value, version: config.version),
      ),
      saveChoice: () async {
        await ref
            .read(strapHealthPreferencesStorageProvider)
            .saveLowAlert(value);
        state = state.copyWith(
          desired: StrapHealthDesiredState(
            allDay: state.desired.allDay,
            lowAlert: value,
          ),
        );
      },
    );
  }

  /// Called only while the setup or sync lane is held.
  Future<HealthConfigSnapshot> reconcileWithinSession(BandLink link) async {
    state = state.copyWith(
      phase: StrapHealthConfigPhase.loading,
      clearError: true,
    );
    try {
      _validateLink(link);
      final port = BandLinkHealthConfigPort(link);
      final service = HealthConfigService(log: _log);
      var config = await service.read(port);
      _validateLink(link);
      final desired = await ref
          .read(strapHealthPreferencesStorageProvider)
          .load();
      _validateLink(link);
      state = state.copyWith(desired: desired);
      if (desired.allDay != null && desired.allDay != config.spo2AllDay) {
        state = state.copyWith(
          phase: StrapHealthConfigPhase.applying,
          config: config,
        );
        config = await service.setAllDay(
          port,
          desired.allDay!,
          version: config.version,
        );
        _validateLink(link);
      }
      if (desired.lowAlert != null && desired.lowAlert != config.spo2LowAlert) {
        state = state.copyWith(
          phase: StrapHealthConfigPhase.applying,
          config: config,
        );
        config = await service.setLowAlert(
          port,
          desired.lowAlert!,
          version: config.version,
        );
        _validateLink(link);
      }
      state = state.copyWith(
        phase: StrapHealthConfigPhase.ready,
        config: config,
        clearError: true,
      );
      return config;
    } on HealthConfigError catch (error) {
      _showError(error);
      rethrow;
    }
  }

  void _validateLink(BandLink link) {
    final band = ref.read(bandSessionProvider.notifier);
    if (identical(band.session.link, link) && band.session.isReady) return;
    throw const HealthConfigError(
      HealthConfigErrorKind.disconnected,
      'Strap disconnected. Reconnect before reading health settings.',
      requiresReconnect: true,
    );
  }

  Future<void> _applyUserChange(
    BandLink link,
    Future<HealthConfigSnapshot> Function(
      HealthConfigService service,
      HealthConfigPort port,
      HealthConfigSnapshot config,
    )
    apply,
  ) async {
    final port = BandLinkHealthConfigPort(link);
    final service = HealthConfigService(log: _log);
    final config = await service.read(port);
    _validateLink(link);
    final next = await apply(service, port, config);
    _validateLink(link);
    state = state.copyWith(
      phase: StrapHealthConfigPhase.ready,
      config: next,
      clearError: true,
    );
  }

  Future<void> _withBand(
    Future<void> Function(BandLink) operation, {
    Future<void> Function()? saveChoice,
  }) async {
    final band = ref.read(bandSessionProvider.notifier);
    final blocked = band.tryAcquire(BandSessionOp.strapConfig);
    if (blocked != null) {
      state = state.copyWith(
        phase: StrapHealthConfigPhase.error,
        error: blocked,
      );
      return;
    }
    try {
      state = state.copyWith(
        phase: saveChoice == null
            ? StrapHealthConfigPhase.loading
            : StrapHealthConfigPhase.applying,
        clearError: true,
      );
      if (saveChoice != null) {
        try {
          await saveChoice();
        } catch (_) {
          state = state.copyWith(
            phase: StrapHealthConfigPhase.error,
            error: 'Could not save the health setting.',
          );
          return;
        }
      }
      if (!await band.ensureConnected()) {
        throw const HealthConfigError(
          HealthConfigErrorKind.disconnected,
          'Could not connect to the strap.',
          requiresReconnect: true,
        );
      }
      final link = band.session.link;
      if (link == null) {
        throw const HealthConfigError(
          HealthConfigErrorKind.disconnected,
          'Strap link unavailable.',
          requiresReconnect: true,
        );
      }
      await operation(link);
    } on HealthConfigError catch (error) {
      _showError(error);
    } finally {
      band.release(BandSessionOp.strapConfig);
    }
  }

  void _showError(HealthConfigError error) {
    state = state.copyWith(
      phase: StrapHealthConfigPhase.error,
      config: error.requiresReconnect ? null : error.actual,
      error: error.message,
      clearConfig: error.requiresReconnect || error.actual == null,
    );
  }

  void _log(String message) =>
      AppLogger.instance.log(message, tag: 'strap_health_config');
}

final strapHealthConfigProvider =
    NotifierProvider<StrapHealthConfigNotifier, StrapHealthConfigState>(
      StrapHealthConfigNotifier.new,
    );
