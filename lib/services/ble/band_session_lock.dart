import 'package:heliolytics/models/band_session_state.dart';

/// Mutual exclusion for operations on the shared BLE link.
class BandSessionLock {
  BandSessionOp _holder = BandSessionOp.none;

  BandSessionOp get holder => _holder;

  /// Returns an error message when [op] cannot start, else null.
  String? tryAcquire(BandSessionOp op) {
    if (_holder == BandSessionOp.none) {
      _holder = op;
      return null;
    }
    if (_holder == op) return null;
    return _blockedMessage(op, _holder);
  }

  void release(BandSessionOp op) {
    if (_holder == op) _holder = BandSessionOp.none;
  }

  String _blockedMessage(BandSessionOp requested, BandSessionOp active) {
    final activeLabel = _label(active);
    if (requested == BandSessionOp.sync && active == BandSessionOp.bandAlerts) {
      return 'Turn off band alerts before syncing';
    }
    if (requested == BandSessionOp.liveHr && active == BandSessionOp.bandAlerts) {
      return 'Turn off band alerts before live HR';
    }
    if (requested == BandSessionOp.sync && active == BandSessionOp.liveHr) {
      return 'Stop live HR before syncing';
    }
    if (requested == BandSessionOp.liveHr && active == BandSessionOp.sync) {
      return 'Wait for sync to finish before live HR';
    }
    if (requested == BandSessionOp.motorProof) {
      return 'Wait for $activeLabel to finish';
    }
    return 'Strap busy ($activeLabel)';
  }

  String _label(BandSessionOp op) => switch (op) {
        BandSessionOp.sync => 'sync',
        BandSessionOp.liveHr => 'live HR',
        BandSessionOp.motorProof => 'test vibration',
        BandSessionOp.bandAlerts => 'band alerts',
        BandSessionOp.none => 'idle',
      };
}
