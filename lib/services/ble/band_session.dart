import 'dart:async';
import 'dart:typed_data';

import 'package:heliolytics/services/ble/band_link.dart';
import 'package:heliolytics/utils/app_logger.dart';

/// Owns a single [BandLink] for the app session.
class BandSession {
  BandLink? _link;
  Completer<bool>? _connecting;

  BandLink? get link => _link;
  bool get isReady => _link?.isCommsReady ?? false;
  int? get batteryPercent => _link?.batteryPercent;

  void _log(String msg) => AppLogger.instance.log(msg, tag: 'band_session');

  Future<bool> ensureConnected({
    required String mac,
    required Uint8List authKey,
  }) async {
    if (isReady) return true;

    if (_connecting != null) {
      return _connecting!.future;
    }

    final done = Completer<bool>();
    _connecting = done;

    try {
      await disconnect();
      final link = BandLink(_log);
      _link = link;

      var ok = await link.connectAndAuth(mac: mac, authKey: authKey);
      if (!ok) {
        _log('• connect/auth retry');
        await Future<void>.delayed(const Duration(seconds: 1));
        ok = await link.connectAndAuth(mac: mac, authKey: authKey);
      }
      if (!ok) {
        await disconnect();
      }
      done.complete(ok);
      return ok;
    } catch (e) {
      _log('✗ ensureConnected: $e');
      await disconnect();
      done.complete(false);
      return false;
    } finally {
      _connecting = null;
    }
  }

  Future<void> disconnect() async {
    final link = _link;
    _link = null;
    if (link == null) return;
    try {
      await link.disconnect();
      _log('• disconnected');
    } catch (e) {
      _log('• disconnect error: $e');
    }
  }
}
