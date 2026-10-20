import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:heliolytics/constants/strap_health_constants.dart';
import 'package:heliolytics/services/ble/zepp/health_config_port.dart';
import 'package:heliolytics/services/ble/zepp/health_config_service.dart';

class FakeHealthPort implements HealthConfigPort {
  final List<Uint8List?> replies;
  final sent = <Uint8List>[];
  Completer<Uint8List?>? _waiter;
  int retired = 0;
  int canceled = 0;
  bool sendResult = true;
  Object? sendError;
  int? failOnSend;
  bool get hasWaiter => _waiter != null && !_waiter!.isCompleted;

  FakeHealthPort(this.replies);

  @override
  Future<Uint8List?> awaitEndpointPayload(
    int endpoint, {
    Duration timeout = const Duration(seconds: 4),
  }) {
    expect(endpoint, strapHealthConfigEndpoint);
    expect(
      hasWaiter,
      isFalse,
      reason: 'A new transaction must not replace a pending waiter',
    );
    final waiter = Completer<Uint8List?>();
    _waiter = waiter;
    return waiter.future.timeout(timeout, onTimeout: () => null);
  }

  @override
  Future<bool> sendEndpointPayload(
    int endpoint,
    Uint8List payload, {
    required bool encrypt,
  }) async {
    expect(endpoint, strapHealthConfigEndpoint);
    expect(encrypt, isTrue);
    expect(hasWaiter, isTrue, reason: 'Register the waiter before sending');
    if (retired != 0) return false;
    sent.add(Uint8List.fromList(payload));
    if (failOnSend == null || failOnSend == sent.length) {
      if (sendError != null) throw sendError!;
      if (!sendResult) return false;
    }
    if (replies.isNotEmpty) deliver(replies.removeAt(0));
    return true;
  }

  void deliver(Uint8List? frame) {
    if (retired == 0 && hasWaiter) _waiter!.complete(frame);
  }

  @override
  void cancelEndpointPayload(int endpoint) {
    canceled++;
    if (hasWaiter) _waiter!.complete(null);
  }

  @override
  Future<void> retireConfigChannel() async {
    retired++;
    if (hasWaiter) _waiter!.complete(null);
  }
}

class ThrowingRetirementHealthPort extends FakeHealthPort {
  ThrowingRetirementHealthPort(super.replies);

  @override
  Future<void> retireConfigChannel() async {
    await super.retireConfigChannel();
    throw StateError('retirement failed after channel closed');
  }
}

Uint8List response({
  bool allDay = true,
  int low = 85,
  List<int> options = const [0, 80, 85, 90],
  int version = 3,
}) => Uint8List.fromList([
  0x04,
  0x01,
  0x08,
  version,
  0x01,
  0x03,
  0x12,
  0x0b,
  0x00,
  0x31,
  0x0b,
  allDay ? 0x01 : 0x00,
  0x32,
  0x10,
  low,
  options.length,
  ...options,
]);

TypeMatcher<HealthConfigError> healthError(
  HealthConfigErrorKind kind, {
  bool reconnect = true,
}) => isA<HealthConfigError>()
    .having((e) => e.kind, 'kind', kind)
    .having((e) => e.requiresReconnect, 'requiresReconnect', reconnect);

void main() {
  test(
    'valid constrained BOOLs consume one byte and preserve the next key',
    () async {
      final port = FakeHealthPort([response()]);
      final actual = await HealthConfigService(log: (_) {}).read(port);
      expect(actual.version, 3);
      expect(actual.spo2AllDay, isTrue);
      expect(actual.sleepBreathing, isFalse);
      expect(actual.spo2LowAlert, 85);
      expect(port.sent, [
        [0x03, 0x01, 0x08, 0x03, 0x12, 0x31, 0x32],
      ]);
      expect(port.hasWaiter, isFalse);
      expect(port.retired, 0);
    },
  );

  test(
    'a low-alert value outside the option list is a valid observation',
    () async {
      final port = FakeHealthPort([
        response(low: 85, options: [80, 90]),
      ]);
      final actual = await HealthConfigService(log: (_) {}).read(port);
      expect(actual.spo2LowAlert, 85);
      expect(port.retired, 0);
    },
  );

  test('reported nonzero options preserve the low-alert value', () async {
    final port = FakeHealthPort([
      response(options: [80, 85, 90]),
    ]);
    final actual = await HealthConfigService(log: (_) {}).read(port);
    expect(actual.spo2LowAlert, 85);
    expect(port.retired, 0);
  });

  for (final status in [0, 1, 0xff]) {
    test(
      'ACK $status is uninterpreted; fresh readback decides success',
      () async {
        final port = FakeHealthPort([
          Uint8List.fromList([0x06, status]),
          response(),
        ]);
        final evidence = <String>[];
        final actual = await HealthConfigService(
          log: evidence.add,
        ).setAllDay(port, true, version: 3);
        expect(actual.spo2AllDay, isTrue);
        expect(evidence, ['HEALTH ACK status=$status (uninterpreted)']);
        expect(port.sent, [
          [0x05, 0x08, 0x03, 0x00, 0x01, 0x31, 0x0b, 0x01],
          [0x03, 0x01, 0x08, 0x03, 0x12, 0x31, 0x32],
        ]);
      },
    );
  }

  test('ACK without matching readback is uncertain, never success', () async {
    final port = FakeHealthPort([
      Uint8List.fromList([6, 1]),
      response(allDay: false),
    ]);
    await expectLater(
      HealthConfigService(log: (_) {}).setAllDay(port, true, version: 3),
      throwsA(
        healthError(
          HealthConfigErrorKind.uncertain,
          reconnect: false,
        ).having((e) => e.actual?.spo2AllDay, 'verified actual', false),
      ),
    );
    expect(port.sent, hasLength(2));
    expect(port.hasWaiter, isFalse);
    expect(port.retired, 0);
  });

  for (final bytes in [
    [6],
    [6, 1, 0],
    [4, 1],
  ]) {
    test('malformed ACK $bytes cancels and retires without readback', () async {
      final port = FakeHealthPort([Uint8List.fromList(bytes)]);
      await expectLater(
        HealthConfigService(log: (_) {}).setAllDay(port, true, version: 3),
        throwsA(healthError(HealthConfigErrorKind.protocol)),
      );
      expect(port.retired, 1);
      expect(port.canceled, greaterThan(0));
      expect(port.hasWaiter, isFalse);
      expect(port.sent, hasLength(1));
    });
  }

  final malformed = <String, List<int>>{
    'truncated header': [4, 1, 8],
    'wrong command': [5, 1, 8, 3, 1, 0],
    'wrong status': [4, 0, 8, 3, 1, 0],
    'wrong group': [4, 1, 9, 3, 1, 0],
    'unknown version': [4, 1, 8, 0, 1, 0],
    'wrong constraints flag': [4, 1, 8, 3, 0, 0],
    'excess count': [4, 1, 8, 3, 1, 4],
    'truncated count entries': [4, 1, 8, 3, 1, 1],
    'truncated key header': [4, 1, 8, 3, 1, 1, 0x31],
    'truncated BOOL value': [4, 1, 8, 3, 1, 1, 0x31, 0x0b],
    'invalid BOOL': [4, 1, 8, 3, 1, 1, 0x31, 0x0b, 2],
    'unknown BOOL type': [4, 1, 8, 3, 1, 1, 0x31, 0xff, 1],
    'unknown key': [4, 1, 8, 3, 1, 1, 0x33, 0x0b, 1],
    'duplicate key': [4, 1, 8, 3, 1, 2, 0x31, 0x0b, 1, 0x31, 0x0b, 1],
    'unknown BYTE type': [4, 1, 8, 3, 1, 1, 0x32, 0xff, 85, 1, 85],
    'truncated BYTE value': [4, 1, 8, 3, 1, 1, 0x32, 0x10],
    'truncated option count': [4, 1, 8, 3, 1, 1, 0x32, 0x10, 85],
    'truncated options': [4, 1, 8, 3, 1, 1, 0x32, 0x10, 85, 2, 85],
    'trailing bytes': [4, 1, 8, 3, 1, 0, 0xff],
  };
  for (final entry in malformed.entries) {
    test('${entry.key} is typed invalid, retired and never writable', () async {
      final port = FakeHealthPort([Uint8List.fromList(entry.value)]);
      await expectLater(
        HealthConfigService(log: (_) {}).read(port),
        throwsA(healthError(HealthConfigErrorKind.protocol)),
      );
      expect(port.retired, 1);
      expect(port.canceled, greaterThan(0));
      expect(port.hasWaiter, isFalse);
      expect(port.sent.single.first, 3);
    });
  }

  for (final failure in ['read', 'ACK', 'readback']) {
    test(
      'malformed $failure preserves protocol error when retirement throws',
      () async {
        final port = ThrowingRetirementHealthPort([
          if (failure == 'readback') Uint8List.fromList([6, 1]),
          Uint8List.fromList(failure == 'ACK' ? [6] : [4, 1, 8]),
        ]);
        final service = HealthConfigService(log: (_) {});
        await expectLater(
          failure == 'read'
              ? service.read(port)
              : service.setAllDay(port, true, version: 3),
          throwsA(
            healthError(HealthConfigErrorKind.protocol).having(
              (e) => e.message,
              'message',
              failure == 'ACK'
                  ? 'Malformed HEALTH ACK'
                  : 'Invalid HEALTH response header',
            ),
          ),
        );
        expect(port.retired, 1);
        expect(port.canceled, greaterThan(0));
        expect(port.hasWaiter, isFalse);
        expect(port.sent, hasLength(failure == 'readback' ? 2 : 1));
        expect(
          (await service.read(FakeHealthPort([response()]))).spo2AllDay,
          isTrue,
          reason: 'A fresh channel remains usable after protocol failure',
        );
      },
    );
  }

  for (final missing in [0x31, 0x32]) {
    test(
      'missing $missing remains unknown, with no guessed capability',
      () async {
        final bytes = missing == 0x31
            ? [4, 1, 8, 3, 1, 1, 0x32, 0x10, 85, 1, 85]
            : [4, 1, 8, 3, 1, 1, 0x31, 0x0b, 1];
        final port = FakeHealthPort([Uint8List.fromList(bytes)]);
        final actual = await HealthConfigService(log: (_) {}).read(port);
        expect(
          missing == 0x31 ? actual.spo2AllDay : actual.spo2LowAlert,
          isNull,
        );
        expect(port.sent, hasLength(1));
      },
    );
  }

  test('zero reported options keep the low-alert value', () async {
    final actual = await HealthConfigService(
      log: (_) {},
    ).read(FakeHealthPort([response(options: [])]));
    expect(actual.spo2AllDay, isTrue);
    expect(actual.spo2LowAlert, 85);
  });

  for (final failure in ['false', 'throw']) {
    test('send $failure cancels waiter and retires before reuse', () async {
      final port = FakeHealthPort([]);
      port.sendResult = failure != 'false';
      if (failure == 'throw') port.sendError = StateError('send failed');
      final service = HealthConfigService(log: (_) {});
      await expectLater(
        service.read(port),
        throwsA(healthError(HealthConfigErrorKind.disconnected)),
      );
      expect(port.hasWaiter, isFalse);
      expect(port.canceled, greaterThan(0));
      expect(port.retired, 1);
      final fresh = FakeHealthPort([response()]);
      expect(
        (await service.read(fresh)).spo2AllDay,
        isTrue,
        reason: 'A fresh channel remains usable after send failure',
      );
    });
  }

  test('missing ACK times out and retires without readback', () async {
    final port = FakeHealthPort([]);
    final service = HealthConfigService(
      log: (_) {},
      timeout: const Duration(milliseconds: 5),
    );
    await expectLater(
      service.setAllDay(port, true, version: 3),
      throwsA(healthError(HealthConfigErrorKind.timeout)),
    );
    expect(port.hasWaiter, isFalse);
    expect(port.retired, 1);
    expect(
      port.sent.where((frame) => frame.first == strapHealthConfigSet),
      hasLength(1),
    );
    expect(
      port.sent.where((frame) => frame.first == strapHealthConfigRequest),
      isEmpty,
    );
  });

  test(
    'disconnect during readback cancels and retires without false success',
    () async {
      final port = FakeHealthPort([
        Uint8List.fromList([6, 1]),
        Uint8List(0),
      ]);
      await expectLater(
        HealthConfigService(log: (_) {}).setAllDay(port, true, version: 3),
        throwsA(healthError(HealthConfigErrorKind.disconnected)),
      );
      expect(port.sent, hasLength(2));
      expect(port.hasWaiter, isFalse);
      expect(port.canceled, greaterThan(0));
      expect(port.retired, 1);
    },
  );

  test('low-alert SET uses only selected key and reported version', () async {
    final port = FakeHealthPort([
      Uint8List.fromList([6, 0]),
      response(low: 90, version: 7),
    ]);
    await HealthConfigService(log: (_) {}).setLowAlert(port, 90, version: 7);
    expect(port.sent.first, [5, 8, 7, 0, 1, 0x32, 0x10, 90]);
    expect(
      port.sent
          .where((bytes) => bytes.first == 5)
          .every((bytes) => bytes[5] != 0x12),
      isTrue,
    );
  });

  test('no SET ever targets key 0x12', () async {
    final port = FakeHealthPort([
      Uint8List.fromList([6, 1]),
      response(allDay: true),
      Uint8List.fromList([6, 1]),
      response(allDay: false),
      Uint8List.fromList([6, 1]),
      response(allDay: false, low: 0),
      Uint8List.fromList([6, 1]),
      response(allDay: false, low: 85),
    ]);
    final service = HealthConfigService(log: (_) {});

    await service.setAllDay(port, true, version: 3);
    await service.setAllDay(port, false, version: 3);
    await service.setLowAlert(port, 0, version: 3);
    await service.setLowAlert(port, 85, version: 3);

    final sets = port.sent.where((frame) => frame.first == 0x05);
    expect(sets, hasLength(4));
    for (final frame in sets) {
      expect(frame[5], isIn([0x31, 0x32]));
    }
  });
}
