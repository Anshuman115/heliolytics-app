import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:heliolytics/services/ble/type_sync_engine.dart';
import 'package:heliolytics/utils/huami_time.dart';

void main() {
  for (final code in [0x05, 0x06]) {
    test(
      '0x${code.toRadixString(16)} uses selected range and keeps empty data',
      () async {
        final writes = <List<int>>[];
        final engine = TypeSyncEngine((bytes) async {
          writes.add(List<int>.from(bytes));
        });
        final since = DateTime(2026, 7, 12, 13, 42);

        final fetched = engine.fetchType(code, since);
        engine.onControl(
          Uint8List.fromList([
            0x10,
            0x01,
            0x01,
            0,
            0,
            0,
            0,
            0xea,
            0x07,
            7,
            12,
            13,
            42,
            0,
          ]),
        );

        expect(await fetched, isEmpty);
        expect(writes, [
          [0x01, code, ...HuamiTime.fromDateTime(since)],
          [0x03, 0x09],
        ]);
        expect(engine.lastExpected, 0);
        expect(engine.firstRoundStart, isNull);
      },
    );
  }

  test('0x06 pages from the final detail block timestamp', () async {
    final writes = <List<int>>[];
    final engine = TypeSyncEngine((bytes) async {
      writes.add(List<int>.from(bytes));
    });
    final since = DateTime(2026, 6, 26, 15);
    final roundStart = DateTime(2026, 6, 28, 16, 41, 30);
    final finalBlock = DateTime(2026, 6, 28, 17, 40, 21, 970);

    final fetched = engine.fetchType(0x06, since);
    engine.onControl(_startReply(expected: 16, start: roundStart));
    engine.onData(Uint8List.fromList([0, ..._detailBlock(finalBlock)]));
    engine.onControl(Uint8List.fromList([0x10, 0x02, 0x01]));

    expect(writes.last, [
      0x01,
      0x06,
      ...HuamiTime.fromDateTime(finalBlock.add(const Duration(minutes: 1))),
    ]);

    engine.onControl(_startReply(expected: 0, start: finalBlock));
    expect(await fetched, isNotEmpty);
    expect(engine.roundSegments, hasLength(1));
  });
}

Uint8List _startReply({required int expected, required DateTime start}) {
  return Uint8List.fromList([
    0x10,
    0x01,
    0x01,
    expected & 0xff,
    (expected >> 8) & 0xff,
    (expected >> 16) & 0xff,
    (expected >> 24) & 0xff,
    ...HuamiTime.fromDateTime(start),
  ]);
}

List<int> _detailBlock(DateTime timestamp) {
  final millis = timestamp.millisecondsSinceEpoch;
  return [
    0x01,
    0x0c,
    0x70,
    0x73,
    0x6d,
    0x68,
    for (var index = 0; index < 6; index++) (millis >> (8 * index)) & 0xff,
    0x00,
    0x00,
    0x08,
    0x03,
  ];
}
