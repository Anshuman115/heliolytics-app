/// Shared BLE link lifecycle (independent of sync upload state).
enum BandLinkState {
  disconnected,
  connecting,
  connected,
  error,
}

/// Exclusive operation holding the shared [BandLink].
enum BandSessionOp {
  none,
  sync,
  liveHr,
  motorProof,
  bandAlerts,
}

class BandSessionSnapshot {
  final BandLinkState linkState;
  final BandSessionOp activeOp;
  final String? errorMessage;
  final int? batteryPercent;

  const BandSessionSnapshot({
    this.linkState = BandLinkState.disconnected,
    this.activeOp = BandSessionOp.none,
    this.errorMessage,
    this.batteryPercent,
  });

  bool get isConnected => linkState == BandLinkState.connected;
  bool get isConnecting => linkState == BandLinkState.connecting;
  bool get isBusy => activeOp != BandSessionOp.none;

  BandSessionSnapshot copyWith({
    BandLinkState? linkState,
    BandSessionOp? activeOp,
    String? errorMessage,
    int? batteryPercent,
    bool clearError = false,
    bool clearBattery = false,
  }) =>
      BandSessionSnapshot(
        linkState: linkState ?? this.linkState,
        activeOp: activeOp ?? this.activeOp,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        batteryPercent:
            clearBattery ? null : (batteryPercent ?? this.batteryPercent),
      );
}
