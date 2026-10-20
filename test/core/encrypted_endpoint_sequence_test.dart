import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:heliolytics/services/ble/band_link.dart';
import 'package:heliolytics/services/ble/encrypted_endpoint.dart';
import 'package:heliolytics/services/ble/gatt_framing.dart';
import 'package:heliolytics/utils/crypto.dart';

void main() {
  test(
    'overlapping encrypted sends match the entire ordered consecutive-sequence stream',
    () async {
      final key = Uint8List.fromList(List<int>.generate(16, (i) => i + 1));
      final a = Uint8List.fromList(List<int>.generate(80, (i) => i));
      final b = Uint8List.fromList(List<int>.generate(80, (i) => 0xff - i));
      final expectedEncoder = GattChunkEncoder(mtu: 32)..setEncryption(key, 7);
      final expectedFirst = expectedEncoder.encode(0x000a, a, encrypt: true);
      final expectedSecond = expectedEncoder.encode(0x000a, b, encrypt: true);
      final writes = <Uint8List>[];
      final firstChunk = Completer<void>();
      final release = Completer<void>();
      final endpoint = EncryptedEndpoint(
        sessionKey: key,
        sequence: 7,
        mtu: 32,
        writeChunk: (chunk) async {
          writes.add(Uint8List.fromList(chunk));
          if (!firstChunk.isCompleted) {
            firstChunk.complete();
            await release.future;
          }
        },
        writeAck: (_) async {},
        onPayload: (_, __) {},
      );
      final first = endpoint.send(0x000a, a, encrypt: true);
      await firstChunk.future;
      final second = endpoint.send(0x000a, b, encrypt: true);
      await Future<void>.delayed(Duration.zero);
      expect(writes, [
        expectedFirst.first,
      ], reason: 'Second send cannot interleave while first is blocked');
      release.complete();
      await Future.wait([first, second]);
      expect(writes, [...expectedFirst, ...expectedSecond]);
      final frames = [
        writes.take(expectedFirst.length).toList(),
        writes.skip(expectedFirst.length).toList(),
      ];
      for (var i = 0; i < frames.length; i++) {
        final chunks = frames[i];
        expect(chunks.first[1] & 1, 1);
        expect(chunks.last[1] & 6, 6);
        expect(chunks.map((c) => c[3]).toSet(), {i + 1});
        expect(
          chunks.map((c) => c[4]),
          List<int>.generate(chunks.length, (j) => j),
        );
        final ciphertext = BytesBuilder();
        for (var j = 0; j < chunks.length; j++) {
          ciphertext.add(chunks[j].sublist(j == 0 ? 11 : 5));
        }
        final messageKey = Uint8List.fromList(
          key.map((byte) => byte ^ (i + 1)).toList(),
        );
        final plain = CryptoUtils.aes128EcbDecrypt(
          ciphertext.toBytes(),
          messageKey,
        );
        expect(plain.sublist(0, 80), i == 0 ? a : b);
        expect(ByteData.sublistView(plain).getUint32(80, Endian.little), 7 + i);
      }
    },
  );

  test(
    'chunk failure rejects its caller and closes all queued sends before further writes',
    () async {
      final entered = Completer<void>();
      final release = Completer<void>();
      final original = StateError('transport failed');
      var attempts = 0;
      final endpoint = EncryptedEndpoint(
        mtu: 20,
        writeChunk: (_) async {
          attempts++;
          entered.complete();
          await release.future;
          throw original;
        },
        writeAck: (_) async {},
        onPayload: (_, __) {},
      );
      final first = endpoint.send(0x000a, Uint8List(80));
      await entered.future;
      final second = endpoint.send(0x000a, Uint8List(80));
      final firstFailure = expectLater(first, throwsA(same(original)));
      final queuedFailure = expectLater(second, throwsA(isA<StateError>()));
      release.complete();
      await Future.wait([firstFailure, queuedFailure]);
      await expectLater(
        endpoint.send(0x000a, Uint8List(1)),
        throwsA(isA<StateError>()),
      );
      expect(attempts, 1);
    },
  );

  test('send failure notifies the owner once', () async {
    final entered = Completer<void>();
    final release = Completer<void>();
    final original = StateError('chunk failed');
    var writes = 0;
    var notifications = 0;
    final endpoint = EncryptedEndpoint(
      writeChunk: (_) async {
        writes++;
        entered.complete();
        await release.future;
        throw original;
      },
      writeAck: (_) async {},
      onPayload: (_, __) {},
      onSendFailure: () => notifications++,
    );
    final first = endpoint.send(0x000a, Uint8List(1));
    await entered.future;
    final second = endpoint.send(0x000a, Uint8List(1));
    final third = endpoint.send(0x000a, Uint8List(1));
    final failures = [
      expectLater(first, throwsA(same(original))),
      expectLater(second, throwsA(isA<StateError>())),
      expectLater(third, throwsA(isA<StateError>())),
    ];
    release.complete();
    await Future.wait(failures);
    expect(notifications, 1);
    await expectLater(
      endpoint.send(0x000a, Uint8List(1)),
      throwsA(isA<StateError>()),
    );
    expect(notifications, 1);
    expect(writes, 1);
  });

  test('close does not notify send failure', () async {
    var notifications = 0;
    var writes = 0;
    final endpoint = EncryptedEndpoint(
      writeChunk: (_) async => writes++,
      writeAck: (_) async {},
      onPayload: (_, __) {},
      onSendFailure: () => notifications++,
    );
    endpoint.close();
    endpoint.close();
    expect(notifications, 0);
    await expectLater(
      endpoint.send(0x000a, Uint8List(1)),
      throwsA(isA<StateError>()),
    );
    expect(notifications, 0);
    expect(writes, 0);
  });

  test('encoding failure also closes the endpoint without any write', () async {
    var writes = 0;
    final endpoint = EncryptedEndpoint(
      writeChunk: (_) async => writes++,
      writeAck: (_) async {},
      onPayload: (_, __) {},
    );
    await expectLater(
      endpoint.send(10, Uint8List(1), encrypt: true),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      endpoint.send(10, Uint8List(1)),
      throwsA(isA<StateError>()),
    );
    expect(writes, 0);
  });

  test(
    'BandLink adapter retires transport and cancels every waiter after send failure',
    () async {
      final original = StateError('chunk failed');
      final link = BandLink((_) {});
      var lost = 0;
      var operationLost = 0;
      link.addDisconnectListener(() => lost++);
      link.onLinkLost = () => operationLost++;
      link.comms = EncryptedEndpoint(
        writeChunk: (_) async => throw original,
        writeAck: (_) async {},
        onPayload: (_, __) {},
      );
      final health = link.awaitEndpointPayload(10);
      final other = link.awaitEndpointPayload(20);
      await expectLater(
        link.sendEndpointPayload(10, [1]),
        throwsA(same(original)),
      );
      expect(await health, isEmpty);
      expect(await other, isEmpty);
      expect(link.comms, isNull);
      expect(link.isCommsReady, isFalse);
      expect(await link.sendEndpointPayload(10, [2]), isFalse);
      expect(lost, 1);
      expect(operationLost, 1);
      link.onLinkLost = null;
      await link.disconnect();
      expect(lost, 1, reason: 'Lifecycle notification is not duplicated');
    },
  );
}
