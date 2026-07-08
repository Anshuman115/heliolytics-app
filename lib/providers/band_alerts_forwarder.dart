import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/models/band_alert_event.dart';
import 'package:heliolytics/models/band_alerts_config.dart';
import 'package:heliolytics/providers/band_alerts_app_patterns_provider.dart';
import 'package:heliolytics/providers/band_alerts_call_pattern_provider.dart';
import 'package:heliolytics/providers/band_alerts_provider.dart';
import 'package:heliolytics/providers/band_session_provider.dart';
import 'package:heliolytics/services/band_alerts/band_alerts_platform.dart';
import 'package:heliolytics/services/ble/band_link.dart';
import 'package:heliolytics/services/ble/band_notification_service.dart';
import 'package:heliolytics/services/ble/zepp/vibration_pattern_service.dart';
import 'package:heliolytics/utils/app_logger.dart';

/// Forwards Android phone/notification events to the strap.
class BandAlertsForwarder extends Notifier<void> {
  StreamSubscription<dynamic>? _sub;
  final _notify = BandNotificationService(log: _log);
  final _patterns = VibrationPatternService(log: _log);
  var _callActive = false;
  var _callBuzzing = false;

  static void _log(String msg) =>
      AppLogger.instance.log(msg, tag: 'band_alerts_fwd');

  @override
  void build() {
    ref.onDispose(stop);
  }

  void start() {
    stop();
    _sub = BandAlertsPlatform.eventStream().listen(
      (raw) => unawaited(_onEvent(raw)),
      onError: (e) => _status('event error: $e'),
    );
    _log('forwarder started');
    _status('Listening for phone and app events');
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _callActive = false;
    _callBuzzing = false;
  }

  void _status(String msg) {
    _log(msg);
    ref.read(bandAlertsProvider.notifier).setForwardStatus(msg);
  }

  Future<void> _onEvent(dynamic raw) async {
    if (raw is! Map) return;
    final event = BandAlertEvent.fromMap(raw);
    final alerts = ref.read(bandAlertsProvider);
    final config = alerts.config;
    if (!config.enabled) {
      _status('ignored — band alerts off');
      return;
    }

    final link = ref.read(bandSessionProvider.notifier).session.link;
    if (link is! BandLink || !link.isCommsReady) {
      _status('ignored — strap not connected');
      return;
    }

    if (event.isCallRing) {
      if (!config.forwardCalls) {
        _status('ignored call — forward calls off');
        return;
      }
      _callActive = true;
      await _notify.sendIncomingCall(
        link,
        name: event.callerName,
        number: event.callerNumber,
      );
      _callBuzzing = true;
      unawaited(_repeatCallPattern(link));
      _status('Call pattern buzzing');
      return;
    }

    if (event.isCallEnd) {
      if (!config.forwardCalls || !_callActive) return;
      _callActive = false;
      _callBuzzing = false;
      await _notify.sendCallEnd(link);
      _status('Call pattern stopped');
      return;
    }

    if (event.isAppNotification) {
      final pkg = event.packageId ?? '';
      if (!_allowsApp(config, pkg)) {
        _status('ignored $pkg — not in allowlist');
        return;
      }
      final id = event.notificationId ?? pkg.hashCode;
      final appLabel = bandAlertsSuggestedApps
          .where((e) => e.key == pkg)
          .map((e) => e.value)
          .firstOrNull;
      await _notify.sendAppNotification(
        link,
        id: id,
        packageId: pkg,
        title: event.title,
        body: event.body,
        appName: appLabel ?? pkg,
        caps: alerts.notificationCaps,
      );
      final label = event.title?.isNotEmpty == true ? event.title! : pkg;
      if (_callBuzzing) {
        _status('Forwarded: $label (call buzz active)');
        return;
      }
      try {
        final onOffMs =
            ref.read(bandAlertsAppPatternsProvider.notifier).patternFor(pkg);
        await _patterns.testBuzz(
          link,
          type: vibrationTypeAppAlerts,
          onOffMs: onOffMs,
        );
        _status('Pattern buzzed: $label');
      } catch (e) {
        _status('Pattern buzz failed for $label: $e');
      }
    }
  }

  bool _allowsApp(BandAlertsConfig config, String packageId) {
    if (packageId.isEmpty) return false;
    return config.allowedPackages.contains(packageId);
  }

  Future<void> _repeatCallPattern(BandLink link) async {
    while (_callActive && _callBuzzing) {
      final onOffMs = ref.read(bandAlertsCallPatternProvider);
      try {
        await _patterns.testBuzz(
          link,
          type: vibrationTypeIncomingCall,
          onOffMs: onOffMs,
        );
      } catch (e) {
        _status('Call pattern failed: $e');
        break;
      }
      if (!_callActive || !_callBuzzing) break;
      final durationMs = onOffMs.fold<int>(0, (sum, ms) => sum + ms);
      await Future<void>.delayed(
        Duration(milliseconds: durationMs + bandAlertsCallPatternRepeatGapMs),
      );
    }
  }
}

final bandAlertsForwarderProvider =
    NotifierProvider<BandAlertsForwarder, void>(BandAlertsForwarder.new);
