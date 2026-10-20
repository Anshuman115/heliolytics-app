import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:heliolytics/models/session.dart';
import 'package:heliolytics/models/session_catalog.dart';
import 'package:heliolytics/models/session_mode.dart';
import 'package:heliolytics/models/sync_payload.dart';
import 'package:heliolytics/services/network/ingest_request_encoder.dart';

SyncPayload _payload({
  String mac = '02:00:00:00:00:01',
  DateTime? endedAt,
  Map<String, Uint8List>? raw,
}) {
  final start = DateTime.utc(2026, 10, 1, 20);
  return SyncPayload(
    session: Session(
      sessionId: 'sess-0001',
      startedAt: start,
      endedAt: endedAt ?? start.add(const Duration(hours: 8)),
      deviceMac: mac,
      fetchWindowHours: 24,
      listenDurationSec: 60,
      mode: SessionMode.fetchAndListen,
      entries: const [],
      unsolicited: const [],
      batteryPercent: 84,
    ),
    catalog: const SessionCatalog(
      sessionId: 'sess-0001',
      chunked: [],
      unsolicited: [],
    ),
    rawByCode:
        raw ??
        {
          '0x25': Uint8List.fromList([0x00, 0xFF, 0x0D, 0x0A, 0x7F, 0x80]),
        },
  );
}

void main() {
  final encoder = IngestRequestEncoder();

  test('finalizes one body whose boundary matches the returned type', () async {
    final encoded = await encoder.encode(_payload());
    final boundary = encoded.contentType.split('boundary=').last;
    expect(encoded.contentType, startsWith('multipart/form-data; boundary='));
    expect(boundary, isNotEmpty);

    final text = latin1.decode(encoded.body);
    expect(text, startsWith('--$boundary\r\n'));
    expect(text, endsWith('--$boundary--\r\n'));
    expect(text, contains('name="session"'));
    expect(text, contains('name="catalog"'));
    expect(text, contains('name="0x25_raw.bin"'));
    expect(text, contains('filename="0x25_raw.bin"'));
    expect(encoded.sessionId, 'sess-0001');
  });

  test('keeps binary bytes, CRLF and non-ASCII JSON intact', () async {
    final encoded = await encoder.encode(
      _payload(
        raw: {
          '0x01': Uint8List.fromList([0x00, 0xFF, 0x0D, 0x0A, 0x7F, 0x80]),
        },
      ),
    );
    final haystack = encoded.body;
    var found = false;
    for (var i = 0; i + 6 <= haystack.length; i++) {
      if (haystack[i] == 0x00 &&
          haystack[i + 1] == 0xFF &&
          haystack[i + 2] == 0x0D &&
          haystack[i + 3] == 0x0A &&
          haystack[i + 4] == 0x7F &&
          haystack[i + 5] == 0x80) {
        found = true;
        break;
      }
    }
    expect(found, isTrue, reason: 'raw part bytes must be copied verbatim');

    final session = utf8.decode(haystack, allowMalformed: true);
    expect(session, contains('"batteryPercent":84'));
    expect(session, contains('"deviceMac":"02:00:00:00:00:01"'));
  });

  test('a second encode freezes its own boundary', () async {
    final first = await encoder.encode(_payload());
    final second = await encoder.encode(_payload());
    expect(first.contentType, isNot(second.contentType));
    for (final encoded in [first, second]) {
      final boundary = encoded.contentType.split('boundary=').last;
      expect(latin1.decode(encoded.body), startsWith('--$boundary\r\n'));
    }
  });

  test('rejects a session without an end time', () async {
    await expectLater(
      encoder.encode(_payload(endedAt: DateTime.utc(2026, 10, 1, 19))),
      throwsA(isA<IngestEncodingException>()),
    );
    final missing = _payload();
    final withoutEnd = SyncPayload(
      session: Session(
        sessionId: missing.session.sessionId,
        startedAt: missing.session.startedAt,
        deviceMac: missing.session.deviceMac,
        fetchWindowHours: 24,
        listenDurationSec: 60,
        mode: SessionMode.fetchAndListen,
        entries: const [],
        unsolicited: const [],
      ),
      catalog: missing.catalog,
      rawByCode: missing.rawByCode,
    );
    await expectLater(
      encoder.encode(withoutEnd),
      throwsA(isA<IngestEncodingException>()),
    );
  });

  test('rejects an invalid MAC and an empty upload', () async {
    await expectLater(
      encoder.encode(_payload(mac: '00:11:22')),
      throwsA(isA<IngestEncodingException>()),
    );
    await expectLater(
      encoder.encode(_payload(raw: {})),
      throwsA(isA<IngestEncodingException>()),
    );
    await expectLater(
      encoder.encode(_payload(raw: {'0x25': Uint8List(0)})),
      throwsA(isA<IngestEncodingException>()),
    );
  });

  test('enforces the byte cap and the part cap', () async {
    final tiny = IngestRequestEncoder(maxBytes: 64);
    await expectLater(
      tiny.encode(_payload()),
      throwsA(isA<IngestEncodingException>()),
    );
    final onePart = IngestRequestEncoder(maxParts: 2);
    await expectLater(
      onePart.encode(_payload()),
      throwsA(isA<IngestEncodingException>()),
    );
  });

  test('ignores codes outside the production fetch list', () async {
    final encoded = await encoder.encode(
      _payload(
        raw: {
          '0x25': Uint8List.fromList([1, 2, 3]),
          '0x39': Uint8List.fromList([9, 9, 9]),
        },
      ),
    );
    final text = latin1.decode(encoded.body);
    expect(text, contains('0x25_raw.bin'));
    expect(text, isNot(contains('0x39_raw.bin')));
  });
}
