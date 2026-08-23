import 'package:flutter_test/flutter_test.dart';
import 'package:heliolytics/services/cache/cache_box_bootstrap.dart';

void main() {
  test('recreates the disposable cache after the first open fails', () async {
    var opens = 0;
    var deletes = 0;

    final ready = await ensureDailyBundleCacheBox(
      openBox: () async {
        opens++;
        if (opens == 1) throw StateError('corrupt cache');
      },
      deleteBox: () async => deletes++,
    );

    expect(ready, isTrue);
    expect(opens, 2);
    expect(deletes, 1);
  });

  test('disables disk cache when recreation also fails', () async {
    final ready = await ensureDailyBundleCacheBox(
      openBox: () async => throw StateError('still corrupt'),
      deleteBox: () async {},
    );

    expect(ready, isFalse);
  });
}
