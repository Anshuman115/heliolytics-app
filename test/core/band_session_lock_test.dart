import 'package:flutter_test/flutter_test.dart';
import 'package:heliolytics/models/band_session_state.dart';
import 'package:heliolytics/services/ble/band_session_lock.dart';

void main() {
  test('releasing a failed sync unblocks live HR and alerts', () {
    final lock = BandSessionLock();

    expect(lock.tryAcquire(BandSessionOp.sync), isNull);
    expect(lock.tryAcquire(BandSessionOp.liveHr), isNotNull);

    lock.release(BandSessionOp.sync);

    expect(lock.tryAcquire(BandSessionOp.liveHr), isNull);
    lock.release(BandSessionOp.liveHr);
    expect(lock.tryAcquire(BandSessionOp.bandAlerts), isNull);
  });
}
