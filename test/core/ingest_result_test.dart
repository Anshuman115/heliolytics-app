import 'package:flutter_test/flutter_test.dart';

import 'package:heliolytics/models/ingest_result.dart';
import 'package:heliolytics/models/protocol_exception.dart';

Map<String, dynamic> _response() => {
  'sessionId': 'sess-0001',
  'complete': false,
  'types': {
    '0x01': {
      'status': 'partial',
      'rows': 1234,
      'dropped': 0,
      'trailingBytes': 4,
      'warnings': ['trailing_fragment offset=16892 count=4'],
      'dataThrough': '2026-10-01T18:30:00Z',
    },
    '0x26': {
      'status': 'raw_only',
      'rows': 0,
      'dropped': 13,
      'trailingBytes': 0,
      'warnings': ['spo2_sleep_placeholder offset=1 count=13'],
      'dataThrough': null,
    },
  },
  'warnings': <String>[],
};

void main() {
  test('parses the C2 response with every key present', () {
    final result = IngestResult.fromJson(_response());
    expect(result.sessionId, 'sess-0001');
    expect(result.complete, isFalse);
    expect(result.types, hasLength(2));
    expect(result.types['0x01']!.status, IngestStatus.partial);
    expect(result.types['0x01']!.rows, 1234);
    expect(result.types['0x01']!.trailingBytes, 4);
    expect(result.types['0x01']!.dataThrough, isNotNull);
    expect(result.types['0x26']!.status, IngestStatus.rawOnly);
    expect(result.types['0x26']!.dataThrough, isNull);
    expect(result.partialCodes, ['0x01']);
    expect(result.hasPartial, isTrue);
    expect(result.droppedRows, 13);
  });

  test('raw-only placeholders are not measurements', () {
    const rawOnly = IngestResult(
      sessionId: 's',
      complete: true,
      types: {
        '0x26': IngestTypeResult(
          code: '0x26',
          status: IngestStatus.rawOnly,
          rows: 0,
          dropped: 5,
          trailingBytes: 0,
        ),
      },
    );
    expect(rawOnly.measured, isEmpty);
    expect(rawOnly.hasPartial, isFalse);
  });

  test('rejects a session id mismatch', () {
    expect(
      () => IngestResult.fromJson(_response(), expectedSessionId: 'other'),
      throwsA(isA<ProtocolException>()),
    );
  });

  test('rejects missing top-level keys', () {
    for (final mutate in <void Function(Map<String, dynamic>)>[
      (j) => j.remove('sessionId'),
      (j) => j.remove('complete'),
      (j) => j.remove('types'),
      (j) => j.remove('warnings'),
      (j) => j['complete'] = 'yes',
    ]) {
      final response = _response();
      mutate(response);
      expect(
        () => IngestResult.fromJson(response),
        throwsA(isA<ProtocolException>()),
      );
    }
  });

  test('rejects an unknown status and non-numeric counts', () {
    final badStatus = _response();
    (badStatus['types'] as Map)['0x01']['status'] = 'skipped';
    expect(
      () => IngestResult.fromJson(badStatus),
      throwsA(isA<ProtocolException>()),
    );

    final badCount = _response();
    (badCount['types'] as Map)['0x01']['rows'] = 'many';
    expect(
      () => IngestResult.fromJson(badCount),
      throwsA(isA<ProtocolException>()),
    );
  });
}
