import 'package:flutter_test/flutter_test.dart';
import 'package:heliolytics/models/sync_coverage.dart';

void main() {
  test('fromJson parses workout types with explicit null', () {
    final cov = SyncCoverage.fromJson({
      'hasData': true,
      'dataThrough': '2026-06-08T18:30:00Z',
      'types': {'0x05': null, '0x06': null, '0x3B': null},
    });

    expect(cov.types.containsKey('0x05'), isTrue);
    expect(cov.types['0x05'], isNull);
    expect(cov.types['0x3B'], isNull);
  });
}
