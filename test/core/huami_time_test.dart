import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:heliolytics/utils/huami_time.dart';

void main() {
  test('empty activity response does not invent a start timestamp', () {
    final response = Uint8List(14)
      ..[0] = 0x10
      ..[1] = 0x01
      ..[2] = 0x01;

    final parsed = HuamiTime.parseStartDate(response);

    expect(parsed?.expected, 0);
    expect(parsed?.start, isNull);
  });
}
