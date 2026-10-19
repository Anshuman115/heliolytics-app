import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliolytics/models/band_session_state.dart';
import 'package:heliolytics/models/session_state.dart';
import 'package:heliolytics/models/strap_health_config.dart';
import 'package:heliolytics/providers/band_session_provider.dart';
import 'package:heliolytics/providers/strap_health_config_provider.dart';
import 'package:heliolytics/services/ble/auth/auth_key_store.dart';
import 'package:heliolytics/services/ble/auth/auth_key_storage.dart';
import 'package:heliolytics/services/ble/band_link.dart';
import 'package:heliolytics/services/ble/band_session.dart';
import 'package:heliolytics/services/ble/sync_session_log.dart';
import 'package:heliolytics/services/ble/sync_setup_connector.dart';
import 'package:heliolytics/services/config/strap_health_preferences_storage.dart';

import 'health_config_service_test.dart'
    show FakeHealthPort, ThrowingRetirementHealthPort, response;

class MemoryStore implements AuthKeyStore {
  final data = <String, String>{};
  @override
  Future<void> write(String key, String value) async => data[key] = value;
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> delete(String key) async => data.remove(key);
}

class HealthBandLink extends BandLink {
  final FakeHealthPort port;
  bool ready = true;
  HealthBandLink(this.port) : super((_) {});
  @override
  bool get isCommsReady => ready;
  @override
  Future<Uint8List?> awaitEndpointPayload(
    int endpoint, {
    Duration timeout = const Duration(seconds: 4),
  }) => port.awaitEndpointPayload(endpoint, timeout: timeout);
  @override
  Future<bool> sendEndpointPayload(
    int endpoint,
    List<int> payload, {
    bool encrypt = false,
  }) => port.sendEndpointPayload(
    endpoint,
    Uint8List.fromList(payload),
    encrypt: encrypt,
  );
  @override
  void cancelEndpointPayload(int endpoint) =>
      port.cancelEndpointPayload(endpoint);
  @override
  Future<void> retireEndpoint(int endpoint) async {
    try {
      await port.retireConfigChannel();
    } finally {
      await disconnect();
    }
  }

  @override
  Future<void> disconnect() async {
    ready = false;
    port.cancelEndpointPayload(10);
    await super.disconnect();
  }
}

class TestBandSession extends BandSession {
  final HealthBandLink Function() createLink;
  HealthBandLink? current;
  int connects = 0;
  int disconnects = 0;
  TestBandSession(this.createLink);
  @override
  BandLink? get link => current;
  @override
  bool get isReady => current?.isCommsReady ?? false;
  @override
  int? get batteryPercent => null;
  @override
  Future<bool> ensureConnected({
    required String mac,
    required Uint8List authKey,
  }) async {
    connects++;
    current = createLink();
    return true;
  }

  @override
  Future<void> disconnect() async {
    disconnects++;
    final old = current;
    current = null;
    await old?.disconnect();
  }
}

Future<(ProviderContainer, AuthKeyStorage, StrapHealthPreferencesStorage)>
harness(TestBandSession session) async {
  final memory = MemoryStore();
  final auth = AuthKeyStorage(store: memory);
  await auth.save('0102030405060708090a0b0c0d0e0f10');
  await auth.saveMac('AA:BB');
  final preferences = StrapHealthPreferencesStorage(memory);
  final container = ProviderContainer(
    overrides: [
      authKeyStoreProvider.overrideWithValue(memory),
      bandSessionTransportProvider.overrideWithValue(session),
      strapHealthPreferencesStorageProvider.overrideWithValue(preferences),
    ],
  );
  addTearDown(container.dispose);
  return (container, auth, preferences);
}

Uint8List _frame(String hex) => Uint8List.fromList(
  hex.split(' ').map((byte) => int.parse(byte, radix: 16)).toList(),
);

const _f00 = '04 01 08 03 01 03 12 0b 01 31 0b 00 32 10 00 04 00 50 55 5a';
const _f10 = '04 01 08 03 01 03 12 0b 01 31 0b 01 32 10 00 04 00 50 55 5a';
const _f085 = '04 01 08 03 01 03 12 0b 01 31 0b 00 32 10 55 04 00 50 55 5a';
const _f090 = '04 01 08 03 01 03 12 0b 01 31 0b 00 32 10 5a 04 00 50 55 5a';
const _f185 = '04 01 08 03 01 03 12 0b 01 31 0b 01 32 10 55 04 00 50 55 5a';
const _ack = '06 01';
const _read = [0x03, 0x01, 0x08, 0x03, 0x12, 0x31, 0x32];
const _setOn = [0x05, 0x08, 0x03, 0x00, 0x01, 0x31, 0x0b, 0x01];
const _setLow85 = [0x05, 0x08, 0x03, 0x00, 0x01, 0x32, 0x10, 0x55];
const _setLow90 = [0x05, 0x08, 0x03, 0x00, 0x01, 0x32, 0x10, 0x5a];

Future<List<SessionSnapshot>> _connectForSetup(
  ProviderContainer container,
) async {
  var snapshot = SessionSnapshot.initial;
  final emitted = <SessionSnapshot>[];
  final setup = Provider<Future<void>>(
    (ref) => connectForInitialSetup(
      ref: ref,
      readState: () => snapshot,
      sessionLog: SyncSessionLog(),
      emit: (value) {
        snapshot = value;
        emitted.add(value);
      },
    ),
  );
  await container.read(setup);
  return emitted;
}

void main() {
  test('matching saved choices send no SET', () async {
    final port = FakeHealthPort([_frame(_f00)]);
    final (container, _, preferences) = await harness(
      TestBandSession(() => HealthBandLink(port)),
    );
    await preferences.saveAllDay(false);
    await preferences.saveLowAlert(0);

    final emitted = await _connectForSetup(container);

    expect(port.sent, [_read]);
    final state = container.read(strapHealthConfigProvider);
    expect(state.config!.spo2AllDay, isFalse);
    expect(state.config!.spo2LowAlert, 0);
    expect(state.phase, StrapHealthConfigPhase.ready);
    expect(state.error, isNull);
    expect(emitted.last.state, SessionState.connected);
  });

  test('matching saved on choices send no SET', () async {
    final port = FakeHealthPort([_frame(_f185)]);
    final (container, _, preferences) = await harness(
      TestBandSession(() => HealthBandLink(port)),
    );
    await preferences.saveAllDay(true);
    await preferences.saveLowAlert(85);

    final emitted = await _connectForSetup(container);

    expect(port.sent, [_read]);
    final state = container.read(strapHealthConfigProvider);
    expect(state.config!.spo2AllDay, isTrue);
    expect(state.config!.spo2LowAlert, 85);
    expect(state.error, isNull);
    expect(emitted.last.state, SessionState.connected);
  });

  test('unset choices only read', () async {
    final port = FakeHealthPort([_frame(_f185)]);
    final (container, _, preferences) = await harness(
      TestBandSession(() => HealthBandLink(port)),
    );

    await _connectForSetup(container);

    expect(port.sent, [_read]);
    final state = container.read(strapHealthConfigProvider);
    expect(state.desired.allDay, isNull);
    expect(state.desired.lowAlert, isNull);
    expect(state.config!.spo2AllDay, isTrue);
    expect(state.config!.spo2LowAlert, 85);
    expect(state.error, isNull);
    expect((await preferences.load()).allDay, isNull);
    expect((await preferences.load()).lowAlert, isNull);
  });

  test('differing all-day choice is sent once then read back', () async {
    final port = FakeHealthPort([_frame(_f00), _frame(_ack), _frame(_f10)]);
    final (container, _, preferences) = await harness(
      TestBandSession(() => HealthBandLink(port)),
    );
    await preferences.saveAllDay(true);

    await _connectForSetup(container);

    expect(port.sent, [_read, _setOn, _read]);
    final state = container.read(strapHealthConfigProvider);
    expect(state.config!.spo2AllDay, isTrue);
    expect(state.config!.spo2LowAlert, 0);
    expect(state.error, isNull);
  });

  test('low alert is sent while all-day is off', () async {
    final port = FakeHealthPort([_frame(_f00), _frame(_ack), _frame(_f085)]);
    final (container, _, preferences) = await harness(
      TestBandSession(() => HealthBandLink(port)),
    );
    await preferences.saveLowAlert(85);

    await _connectForSetup(container);

    expect(port.sent, [_read, _setLow85, _read]);
    final state = container.read(strapHealthConfigProvider);
    expect(state.config!.spo2AllDay, isFalse);
    expect(state.config!.spo2LowAlert, 85);
    expect(state.error, isNull);
  });

  test('only the differing choice is sent', () async {
    final port = FakeHealthPort([_frame(_f00), _frame(_ack), _frame(_f085)]);
    final (container, _, preferences) = await harness(
      TestBandSession(() => HealthBandLink(port)),
    );
    await preferences.saveAllDay(false);
    await preferences.saveLowAlert(85);

    await _connectForSetup(container);

    expect(port.sent, [_read, _setLow85, _read]);
    expect(port.sent.where((frame) => frame.first == 5), [_setLow85]);
    expect(container.read(strapHealthConfigProvider).error, isNull);
  });

  test('both differing choices are each sent once', () async {
    final port = FakeHealthPort([
      _frame(_f00),
      _frame(_ack),
      _frame(_f10),
      _frame(_ack),
      _frame(_f185),
    ]);
    final (container, _, preferences) = await harness(
      TestBandSession(() => HealthBandLink(port)),
    );
    await preferences.saveAllDay(true);
    await preferences.saveLowAlert(85);

    await _connectForSetup(container);

    expect(port.sent, [_read, _setOn, _read, _setLow85, _read]);
    final state = container.read(strapHealthConfigProvider);
    expect(state.config!.spo2AllDay, isTrue);
    expect(state.config!.spo2LowAlert, 85);
    expect(state.error, isNull);
  });

  test('readback mismatch shows an error and the actual value', () async {
    final port = FakeHealthPort([_frame(_f00), _frame(_ack), _frame(_f00)]);
    final (container, _, preferences) = await harness(
      TestBandSession(() => HealthBandLink(port)),
    );
    await preferences.saveAllDay(true);
    await preferences.saveLowAlert(85);

    await _connectForSetup(container);

    expect(port.sent, [_read, _setOn, _read]);
    final state = container.read(strapHealthConfigProvider);
    expect(state.phase, StrapHealthConfigPhase.error);
    expect(state.error, contains('did not match readback'));
    expect(state.config!.spo2AllDay, isFalse);
    expect(state.config!.spo2LowAlert, 0);
    expect(state.desired.allDay, isTrue);
    expect(state.desired.lowAlert, 85);
    expect((await preferences.load()).allDay, isTrue);
    expect((await preferences.load()).lowAlert, 85);
    expect(container.read(bandSessionProvider).activeOp, BandSessionOp.none);
  });

  test('unreadable reply shows an error without retry', () async {
    final port = FakeHealthPort([_frame('04 01 08')]);
    final session = TestBandSession(() => HealthBandLink(port));
    final (container, _, preferences) = await harness(session);
    await preferences.saveAllDay(true);

    final emitted = await _connectForSetup(container);

    expect(port.sent, [_read]);
    expect(emitted.last.state, SessionState.error);
    expect(emitted.last.error, SessionError.bleDisconnected);
    expect(
      emitted.where((value) => value.state == SessionState.connected),
      isEmpty,
    );
    final state = container.read(strapHealthConfigProvider);
    expect(state.phase, StrapHealthConfigPhase.error);
    expect(state.error, 'Invalid HEALTH response header');
    expect(state.config, isNull);
    expect(session.connects, 1);
    expect(port.retired, 1);
    expect(container.read(bandSessionProvider).activeOp, BandSessionOp.none);
  });

  test('user setLowAlert(90) with all-day off sends one SET', () async {
    final port = FakeHealthPort([
      _frame(_f00),
      _frame(_f00),
      _frame(_ack),
      _frame(_f090),
    ]);
    final (container, _, preferences) = await harness(
      TestBandSession(() => HealthBandLink(port)),
    );
    final health = container.read(strapHealthConfigProvider.notifier);
    await health.load();

    await health.setLowAlert(90);

    expect(port.sent, [_read, _read, _setLow90, _read]);
    expect(port.sent.where((frame) => frame.first == 5), [_setLow90]);
    final state = container.read(strapHealthConfigProvider);
    expect(state.config!.spo2AllDay, isFalse);
    expect(state.config!.spo2LowAlert, 90);
    expect(state.desired.allDay, isNull);
    expect(state.desired.lowAlert, 90);
    expect(state.error, isNull);
    expect((await preferences.load()).lowAlert, 90);
    expect((await preferences.load()).allDay, isNull);
  });

  test('setLowAlert rejects values outside 0/80/85/90', () async {
    final port = FakeHealthPort([]);
    final session = TestBandSession(() => HealthBandLink(port));
    final (container, _, preferences) = await harness(session);

    await expectLater(
      container.read(strapHealthConfigProvider.notifier).setLowAlert(70),
      throwsArgumentError,
    );

    expect((await preferences.load()).allDay, isNull);
    expect((await preferences.load()).lowAlert, isNull);
    expect(port.sent, isEmpty);
    expect(session.connects, 0);
  });

  test('blocked lane saves nothing', () async {
    final port = FakeHealthPort([]);
    final session = TestBandSession(() => HealthBandLink(port));
    final (container, _, preferences) = await harness(session);
    final band = container.read(bandSessionProvider.notifier);
    expect(band.tryAcquire(BandSessionOp.sync), isNull);

    await container.read(strapHealthConfigProvider.notifier).setAllDay(true);

    final state = container.read(strapHealthConfigProvider);
    expect(state.phase, StrapHealthConfigPhase.error);
    expect(state.error, isNotNull);
    expect(state.desired.allDay, isNull);
    expect((await preferences.load()).allDay, isNull);
    expect(port.sent, isEmpty);
    expect(session.connects, 0);
    expect(container.read(bandSessionProvider).activeOp, BandSessionOp.sync);
    band.release(BandSessionOp.sync);
    expect(container.read(bandSessionProvider).activeOp, BandSessionOp.none);
  });

  test(
    'saved preference is reapplied once and verified using reported version',
    () async {
      final port = FakeHealthPort([
        response(allDay: false, version: 7),
        Uint8List.fromList([6, 1]),
        response(version: 7),
      ]);
      final (container, _, preferences) = await harness(
        TestBandSession(() => HealthBandLink(port)),
      );
      await preferences.saveAllDay(true);
      await container.read(strapHealthConfigProvider.notifier).load();
      final state = container.read(strapHealthConfigProvider);
      expect(state.config!.spo2AllDay, isTrue);
      expect(port.sent, hasLength(3));
      expect(port.sent[1], [5, 8, 7, 0, 1, 0x31, 0x0b, 1]);
      expect(state.desired.allDay, isTrue);
      expect((await preferences.load()).allDay, isTrue);
      expect(container.read(bandSessionProvider).activeOp, BandSessionOp.none);
    },
  );

  for (final actual in [false, true]) {
    test(
      'unset choice with actual $actual remains read-only through setup reconciliation',
      () async {
        final port = FakeHealthPort([response(allDay: actual)]);
        final (container, _, preferences) = await harness(
          TestBandSession(() => HealthBandLink(port)),
        );
        await container.read(strapHealthConfigProvider.notifier).load();
        expect(port.sent.single.first, 3);
        expect(
          container.read(strapHealthConfigProvider).desired.allDay,
          isNull,
        );
        expect(
          container.read(strapHealthConfigProvider).config!.spo2AllDay,
          actual,
        );
        expect((await preferences.load()).allDay, isNull);
      },
    );
  }

  test('disconnect clears actual state and shows an error', () async {
    final port = FakeHealthPort([response()]);
    final session = TestBandSession(() => HealthBandLink(port));
    final (container, _, preferences) = await harness(session);
    await preferences.saveAllDay(true);
    await preferences.saveLowAlert(85);
    await container.read(strapHealthConfigProvider.notifier).load();
    final link = session.link!;
    link.onLinkLost = () {};
    link.onLinkLost = null;
    expect(container.read(strapHealthConfigProvider).config, isNotNull);
    await link.disconnect();
    final state = container.read(strapHealthConfigProvider);
    expect(state.config, isNull);
    expect(state.phase, StrapHealthConfigPhase.error);
    expect(state.error, 'Strap disconnected.');
    expect(state.desired.allDay, isTrue);
    expect(state.desired.lowAlert, 85);
    expect((await preferences.load()).allDay, isTrue);
    expect((await preferences.load()).lowAlert, 85);
    expect(container.read(bandSessionProvider).isConnected, isFalse);
  });

  test(
    'disconnect during user readback retains desire, clears actual and releases the lane',
    () async {
      final port = FakeHealthPort([
        response(allDay: false),
        response(allDay: false),
        Uint8List.fromList([6, 1]),
      ]);
      final session = TestBandSession(() => HealthBandLink(port));
      final (container, _, preferences) = await harness(session);
      final health = container.read(strapHealthConfigProvider.notifier);
      await health.load();
      final pending = health.setAllDay(true);
      await Future<void>.delayed(Duration.zero);
      expect(port.sent, hasLength(4));
      await session.link!.disconnect();
      await pending;
      final state = container.read(strapHealthConfigProvider);
      expect(state.config, isNull);
      expect(state.desired.allDay, isTrue);
      expect((await preferences.load()).allDay, isTrue);
      expect(container.read(bandSessionProvider).activeOp, BandSessionOp.none);
      expect(port.hasWaiter, isFalse);
      expect(port.retired, 1);
    },
  );

  test(
    'ACK with unchanged readback retains desire and exposes verified mismatch',
    () async {
      final port = FakeHealthPort([
        response(allDay: false),
        Uint8List.fromList([6, 1]),
        response(allDay: false),
      ]);
      final (container, _, preferences) = await harness(
        TestBandSession(() => HealthBandLink(port)),
      );
      await container.read(strapHealthConfigProvider.notifier).setAllDay(true);
      final state = container.read(strapHealthConfigProvider);
      expect(state.desired.allDay, isTrue);
      expect(state.config!.spo2AllDay, isFalse);
      expect(state.error, contains('did not match readback'));
      expect((await preferences.load()).allDay, isTrue);
      expect(container.read(bandSessionProvider).activeOp, BandSessionOp.none);
    },
  );

  test(
    'overlapping user operations keep one complete SET/readback lane and no superseded waiter',
    () async {
      final port = FakeHealthPort([]);
      final (container, _, preferences) = await harness(
        TestBandSession(() => HealthBandLink(port)),
      );
      final health = container.read(strapHealthConfigProvider.notifier);
      final first = health.setAllDay(true);
      await Future<void>.delayed(Duration.zero);
      expect(port.sent, hasLength(1));
      await health.setLowAlert(85);
      expect(port.sent, hasLength(1));
      port.replies.addAll([
        Uint8List.fromList([6, 1]),
        response(low: 0),
      ]);
      port.deliver(response(allDay: false, low: 0));
      await first;
      expect(port.sent.map((bytes) => bytes.first), [3, 5, 3]);
      expect(port.sent[1][5], 0x31);
      expect((await preferences.load()).lowAlert, isNull);
      expect(port.hasWaiter, isFalse);
      expect(container.read(bandSessionProvider).activeOp, BandSessionOp.none);
    },
  );

  for (final holder in [
    BandSessionOp.sync,
    BandSessionOp.liveHr,
    BandSessionOp.bandAlerts,
    BandSessionOp.strapConfig,
  ]) {
    test('$holder blocks health commands and releases its lock', () async {
      final port = FakeHealthPort([]);
      final (container, _, _) = await harness(
        TestBandSession(() => HealthBandLink(port)),
      );
      final band = container.read(bandSessionProvider.notifier);
      expect(band.tryAcquire(holder), isNull);
      await container.read(strapHealthConfigProvider.notifier).load();
      expect(port.sent, isEmpty);
      expect(container.read(bandSessionProvider).activeOp, holder);
      band.release(holder);
      expect(container.read(bandSessionProvider).activeOp, BandSessionOp.none);
    });
  }

  for (final failure in ['false', 'throw', 'timeout']) {
    test(
      'user SET $failure retains explicit desire, invalidates actual and cancels its lane',
      () async {
        final port = FakeHealthPort([
          response(allDay: false),
          response(allDay: false),
          if (failure == 'timeout') null,
        ]);
        if (failure != 'timeout') {
          port.failOnSend = 3;
          port.sendResult = failure != 'false';
          if (failure == 'throw') port.sendError = StateError('send failed');
        }
        final session = TestBandSession(() => HealthBandLink(port));
        final (container, _, preferences) = await harness(session);
        final health = container.read(strapHealthConfigProvider.notifier);
        await health.load();
        expect(container.read(strapHealthConfigProvider).config, isNotNull);
        await health.setAllDay(true);
        final state = container.read(strapHealthConfigProvider);
        expect(port.sent, hasLength(3));
        expect(port.sent.last, [5, 8, 3, 0, 1, 0x31, 0x0b, 1]);
        expect(port.canceled, greaterThan(0));
        expect(port.hasWaiter, isFalse);
        expect(port.retired, 1);
        expect(session.isReady, isFalse);
        expect(state.config, isNull);
        expect(state.desired.allDay, isTrue);
        expect(state.error, isNotNull);
        expect((await preferences.load()).allDay, isTrue);
        expect(
          container.read(bandSessionProvider).activeOp,
          BandSessionOp.none,
        );
      },
    );
  }

  for (final failure in ['read', 'ACK', 'readback']) {
    test(
      'user malformed $failure invalidates actual when retirement throws',
      () async {
        final port = ThrowingRetirementHealthPort([
          response(allDay: false),
          if (failure != 'read') response(allDay: false),
          if (failure == 'readback') Uint8List.fromList([6, 1]),
          Uint8List.fromList(failure == 'ACK' ? [6] : [4, 1, 8]),
        ]);
        final session = TestBandSession(() => HealthBandLink(port));
        final (container, _, preferences) = await harness(session);
        final health = container.read(strapHealthConfigProvider.notifier);
        await health.load();
        expect(container.read(strapHealthConfigProvider).config, isNotNull);
        await health.setAllDay(true);
        final state = container.read(strapHealthConfigProvider);
        expect(state.config, isNull);
        expect(state.isBusy, isFalse);
        expect(
          state.error,
          failure == 'ACK'
              ? 'Malformed HEALTH ACK'
              : 'Invalid HEALTH response header',
        );
        expect(state.desired.allDay, isTrue);
        expect((await preferences.load()).allDay, isTrue);
        expect(port.retired, 1);
        expect(port.canceled, greaterThan(0));
        expect(port.hasWaiter, isFalse);
        expect(session.isReady, isFalse);
        expect(container.read(bandSessionProvider).isConnected, isFalse);
        expect(
          container.read(bandSessionProvider).activeOp,
          BandSessionOp.none,
        );
      },
    );
  }

  test(
    'explicit low-alert on and off use supported values without writing any other key',
    () async {
      final port = FakeHealthPort([
        response(low: 0),
        Uint8List.fromList([6, 1]),
        response(low: 85),
        response(low: 85),
        Uint8List.fromList([6, 1]),
        response(low: 0),
      ]);
      final (container, _, preferences) = await harness(
        TestBandSession(() => HealthBandLink(port)),
      );
      final health = container.read(strapHealthConfigProvider.notifier);
      await health.setLowAlert(85);
      await health.setLowAlert(0);
      expect(port.sent.where((frame) => frame.first == 5), [
        [5, 8, 3, 0, 1, 0x32, 0x10, 85],
        [5, 8, 3, 0, 1, 0x32, 0x10, 0],
      ]);
      expect((await preferences.load()).lowAlert, 0);
      expect(container.read(strapHealthConfigProvider).config!.spo2LowAlert, 0);
    },
  );

  test(
    'malformed-read setup retires link and emits disconnected error, never successful connection',
    () async {
      final port = FakeHealthPort([
        Uint8List.fromList([4, 1, 8, 0, 1, 0]),
      ]);
      final session = TestBandSession(() => HealthBandLink(port));
      final (container, _, _) = await harness(session);
      var snapshot = SessionSnapshot.initial;
      final emitted = <SessionSnapshot>[];
      final setup = Provider<Future<void>>(
        (ref) => connectForInitialSetup(
          ref: ref,
          readState: () => snapshot,
          sessionLog: SyncSessionLog(),
          emit: (value) {
            snapshot = value;
            emitted.add(value);
          },
        ),
      );
      await container.read(setup);
      expect(snapshot.state, SessionState.error);
      expect(snapshot.error, SessionError.bleDisconnected);
      expect(snapshot.lastErrorMessage, 'Invalid HEALTH response header');
      expect(emitted.where((s) => s.state == SessionState.connected), isEmpty);
      expect(port.retired, 1);
      expect(session.isReady, isFalse);
      expect(container.read(strapHealthConfigProvider).config, isNull);
      expect(container.read(bandSessionProvider).activeOp, BandSessionOp.none);
    },
  );

  for (final failure in ['read', 'ACK', 'readback']) {
    test(
      'setup malformed $failure reaches terminal error when retirement throws',
      () async {
        final port = ThrowingRetirementHealthPort([
          response(allDay: false),
          if (failure != 'read') response(allDay: false),
          if (failure == 'readback') Uint8List.fromList([6, 1]),
          Uint8List.fromList(failure == 'ACK' ? [6] : [4, 1, 8]),
        ]);
        final session = TestBandSession(() => HealthBandLink(port));
        final (container, _, preferences) = await harness(session);
        await container.read(strapHealthConfigProvider.notifier).load();
        expect(container.read(strapHealthConfigProvider).config, isNotNull);
        if (failure != 'read') {
          await preferences.saveAllDay(true);
        }
        var snapshot = SessionSnapshot.initial;
        final emitted = <SessionSnapshot>[];
        final setup = Provider<Future<void>>(
          (ref) => connectForInitialSetup(
            ref: ref,
            readState: () => snapshot,
            sessionLog: SyncSessionLog(),
            emit: (value) {
              snapshot = value;
              emitted.add(value);
            },
          ),
        );
        await container.read(setup);
        expect(emitted.map((s) => s.state), [
          SessionState.connecting,
          SessionState.error,
        ]);
        expect(snapshot.state, SessionState.error);
        expect(snapshot.error, SessionError.bleDisconnected);
        expect(
          snapshot.lastErrorMessage,
          failure == 'ACK'
              ? 'Malformed HEALTH ACK'
              : 'Invalid HEALTH response header',
        );
        expect(port.retired, 1);
        expect(port.canceled, greaterThan(0));
        expect(port.hasWaiter, isFalse);
        expect(session.isReady, isFalse);
        expect(container.read(bandSessionProvider).isConnected, isFalse);
        expect(container.read(strapHealthConfigProvider).config, isNull);
        expect(
          container.read(bandSessionProvider).activeOp,
          BandSessionOp.none,
        );
      },
    );
  }
}
