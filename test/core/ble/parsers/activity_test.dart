import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliolytics/core/ble/parsers/activity.dart';

void main() {
  test('parses a single 4-byte sample', () {
    final bytes = Uint8List.fromList([0x01, 0x40, 0xAB, 0x48]);
    final s = ActivityParser.parse(bytes);
    expect(s.length, 1);
    expect(s[0].kind, 0x01);
    expect(s[0].intensity, 0x40);
    expect(s[0].steps, 0xAB);
    expect(s[0].heartRate, 72);
  });
  test('parses multiple 4-byte samples when length is not 8-aligned', () {
    final bytes = Uint8List.fromList([
      0x01, 0x40, 0x0A, 0x48,
      0x01, 0x80, 0x14, 0x50,
      0x01, 0x00, 0x01, 0x55,
    ]);
    final s = ActivityParser.parse(bytes);
    expect(s.length, 3);
    expect(s[1].heartRate, 0x50);
  });
  test('empty input returns empty list', () {
    expect(ActivityParser.parse(Uint8List(0)), isEmpty);
  });
  test('parses 8-byte records when payload is 8-aligned', () {
    final bytes = Uint8List.fromList([
      0x50, 0x40, 0x0A, 0x48, 0x01, 0xFF, 0x80, 0x80,
    ]);
    final s = ActivityParser.parse(bytes);
    expect(s.length, 1);
    expect(s[0].kind, 0x50);
    expect(s[0].b6, 0x80);
  });
  test('parseTimed assigns round-relative timestamps', () {
    final bytes = Uint8List.fromList([0x50, 0x40, 0x05, 0x60]);
    final rs = DateTime.utc(2026, 6, 7, 4, 0);
    final s = ActivityParser.parseTimed(bytes, rs);
    expect(s.length, 1);
    expect(s[0].timestamp, rs);
    expect(s[0].sample.steps, 0x05);
  });
  test('throws on non-multiple stride length', () {
    expect(() => ActivityParser.parse(Uint8List.fromList([0x01, 0x40, 0x00])),
        throwsArgumentError);
  });
}
