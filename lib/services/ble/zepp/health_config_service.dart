import 'dart:typed_data';

import 'package:heliolytics/constants/strap_health_constants.dart';
import 'package:heliolytics/models/strap_health_config.dart';
import 'package:heliolytics/services/ble/zepp/health_config_port.dart';

class HealthConfigError implements Exception {
  final HealthConfigErrorKind kind;
  final String message;
  final bool requiresReconnect;
  final HealthConfigSnapshot? actual;

  const HealthConfigError(
    this.kind,
    this.message, {
    this.requiresReconnect = false,
    this.actual,
  });

  @override
  String toString() => message;
}

enum HealthConfigErrorKind { protocol, timeout, disconnected, uncertain }

/// Codec and transaction owner for the encrypted HEALTH endpoint.
class HealthConfigService {
  final void Function(String) log;
  final Duration timeout;

  HealthConfigService({
    required this.log,
    this.timeout = const Duration(seconds: 4),
  });

  Future<HealthConfigSnapshot> read(HealthConfigPort port) => _read(port);

  Future<HealthConfigSnapshot> setAllDay(
    HealthConfigPort port,
    bool on, {
    required int version,
  }) => _set(
    port,
    key: strapHealthKeyAllDay,
    type: strapHealthTypeBool,
    value: on ? 1 : 0,
    version: version,
    expectedAllDay: on,
  );

  Future<HealthConfigSnapshot> setLowAlert(
    HealthConfigPort port,
    int value, {
    required int version,
  }) => _set(
    port,
    key: strapHealthKeyLowAlert,
    type: strapHealthTypeByte,
    value: value,
    version: version,
    expectedLowAlert: value,
  );

  static HealthConfigSnapshot decodeResponse(Uint8List bytes) {
    if (bytes.length < 6 ||
        bytes[0] != strapHealthConfigResponse ||
        bytes[1] != 0x01 ||
        bytes[2] != strapHealthGroup ||
        bytes[3] == 0 ||
        bytes[4] != 0x01) {
      throw const HealthConfigError(
        HealthConfigErrorKind.protocol,
        'Invalid HEALTH response header',
      );
    }

    final count = bytes[5];
    if (count > 3) {
      throw const HealthConfigError(
        HealthConfigErrorKind.protocol,
        'Invalid HEALTH response count',
      );
    }

    var offset = 6;
    bool? allDay;
    bool? sleepBreathing;
    int? lowAlert;
    final seen = <int>{};

    for (var index = 0; index < count; index++) {
      if (offset + 2 > bytes.length) {
        throw const HealthConfigError(
          HealthConfigErrorKind.protocol,
          'Truncated HEALTH entry header',
        );
      }
      final key = bytes[offset++];
      final type = bytes[offset++];
      if (!seen.add(key) ||
          (key != strapHealthKeyAllDay &&
              key != strapHealthKeySleepBreathing &&
              key != strapHealthKeyLowAlert)) {
        throw const HealthConfigError(
          HealthConfigErrorKind.protocol,
          'Unknown or duplicate HEALTH key',
        );
      }

      if (key == strapHealthKeyAllDay || key == strapHealthKeySleepBreathing) {
        if (type != strapHealthTypeBool || offset >= bytes.length) {
          throw const HealthConfigError(
            HealthConfigErrorKind.protocol,
            'Invalid HEALTH BOOL entry',
          );
        }
        final value = bytes[offset++];
        if (value > 1) {
          throw const HealthConfigError(
            HealthConfigErrorKind.protocol,
            'Invalid HEALTH BOOL value',
          );
        }
        if (key == strapHealthKeyAllDay) {
          allDay = value == 1;
        } else {
          sleepBreathing = value == 1;
        }
        continue;
      }

      if (type != strapHealthTypeByte || offset + 2 > bytes.length) {
        throw const HealthConfigError(
          HealthConfigErrorKind.protocol,
          'Invalid HEALTH BYTE entry',
        );
      }
      final reported = bytes[offset++];
      final optionCount = bytes[offset++];
      if (offset + optionCount > bytes.length) {
        throw const HealthConfigError(
          HealthConfigErrorKind.protocol,
          'Truncated HEALTH BYTE options',
        );
      }
      offset += optionCount;
      lowAlert = reported;
    }

    if (offset != bytes.length) {
      throw const HealthConfigError(
        HealthConfigErrorKind.protocol,
        'Trailing unexplained HEALTH response bytes',
      );
    }

    return HealthConfigSnapshot(
      version: bytes[3],
      spo2AllDay: allDay,
      sleepBreathing: sleepBreathing,
      spo2LowAlert: lowAlert,
    );
  }

  static int _decodeAck(Uint8List bytes) {
    if (bytes.length != 2 || bytes[0] != strapHealthConfigAck) {
      throw const HealthConfigError(
        HealthConfigErrorKind.protocol,
        'Malformed HEALTH ACK',
        requiresReconnect: true,
      );
    }
    return bytes[1];
  }

  Future<HealthConfigSnapshot> _set(
    HealthConfigPort port, {
    required int key,
    required int type,
    required int value,
    required int version,
    bool? expectedAllDay,
    int? expectedLowAlert,
  }) async {
    final payload = Uint8List.fromList([
      strapHealthConfigSet,
      strapHealthGroup,
      version,
      0x00,
      0x01,
      key,
      type,
      value,
    ]);
    final ack = await _request(port, payload);
    int ackStatus;
    try {
      ackStatus = _decodeAck(ack);
    } on HealthConfigError {
      await _retire(port);
      rethrow;
    }
    log('HEALTH ACK status=$ackStatus (uninterpreted)');
    final actual = await _read(port);
    if (expectedAllDay != null && actual.spo2AllDay != expectedAllDay) {
      throw HealthConfigError(
        HealthConfigErrorKind.uncertain,
        'HEALTH all-day setting did not match readback',
        actual: actual,
      );
    }
    if (expectedLowAlert != null && actual.spo2LowAlert != expectedLowAlert) {
      throw HealthConfigError(
        HealthConfigErrorKind.uncertain,
        'HEALTH low-alert setting did not match readback',
        actual: actual,
      );
    }
    return actual;
  }

  Future<HealthConfigSnapshot> _read(HealthConfigPort port) async {
    final response = await _request(
      port,
      Uint8List.fromList([
        strapHealthConfigRequest,
        0x01,
        strapHealthGroup,
        0x03,
        strapHealthKeySleepBreathing,
        strapHealthKeyAllDay,
        strapHealthKeyLowAlert,
      ]),
    );
    try {
      return decodeResponse(response);
    } on HealthConfigError catch (error) {
      await _retire(port);
      throw HealthConfigError(
        error.kind,
        error.message,
        requiresReconnect: true,
      );
    }
  }

  Future<Uint8List> _request(HealthConfigPort port, Uint8List payload) async {
    final waiter = port.awaitEndpointPayload(
      strapHealthConfigEndpoint,
      timeout: timeout,
    );
    try {
      final sent = await port.sendEndpointPayload(
        strapHealthConfigEndpoint,
        payload,
        encrypt: true,
      );
      if (!sent) {
        port.cancelEndpointPayload(strapHealthConfigEndpoint);
        throw const HealthConfigError(
          HealthConfigErrorKind.disconnected,
          'HEALTH request could not be sent',
          requiresReconnect: true,
        );
      }
      final response = await waiter;
      if (response == null) {
        port.cancelEndpointPayload(strapHealthConfigEndpoint);
        throw const HealthConfigError(
          HealthConfigErrorKind.timeout,
          'HEALTH response timed out',
          requiresReconnect: true,
        );
      }
      if (response.isEmpty) {
        throw const HealthConfigError(
          HealthConfigErrorKind.disconnected,
          'Strap disconnected during HEALTH transaction',
          requiresReconnect: true,
        );
      }
      return response;
    } catch (error) {
      port.cancelEndpointPayload(strapHealthConfigEndpoint);
      try {
        await port.retireConfigChannel();
      } catch (_) {}
      if (error is HealthConfigError) rethrow;
      throw HealthConfigError(
        HealthConfigErrorKind.disconnected,
        'HEALTH request failed: $error',
        requiresReconnect: true,
      );
    }
  }

  Future<void> _retire(HealthConfigPort port) async {
    port.cancelEndpointPayload(strapHealthConfigEndpoint);
    try {
      await port.retireConfigChannel();
    } catch (_) {}
  }
}
