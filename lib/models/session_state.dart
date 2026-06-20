import 'package:heliolytics/models/models.dart';

enum SessionState {
  noAuthKey,
  idle,
  scanning,
  connecting,
  authenticating,
  connected,
  fetching,
  listening,
  error,
}

enum SessionError {
  none,
  scanTimeout,
  scanFailed,
  gattFailed,
  authRejected,
  authTimeout,
  chunkTimeout,
  bleDisconnected,
  unknown,
}

class SessionSnapshot {
  final SessionState state;
  final SessionError error;
  final String? currentTypeCode;
  final Session? lastSession;
  final String? lastErrorMessage;
  final List<String> logs;
  final List<TypeCodeResult> typeResults;

  const SessionSnapshot({
    required this.state,
    required this.error,
    this.currentTypeCode,
    this.lastSession,
    this.lastErrorMessage,
    this.logs = const [],
    this.typeResults = const [],
  });

  static const initial = SessionSnapshot(
    state: SessionState.noAuthKey,
    error: SessionError.none,
  );

  SessionSnapshot copyWith({
    SessionState? state,
    SessionError? error,
    String? currentTypeCode,
    Session? lastSession,
    String? lastErrorMessage,
    List<String>? logs,
    List<TypeCodeResult>? typeResults,
  }) =>
      SessionSnapshot(
        state: state ?? this.state,
        error: error ?? this.error,
        currentTypeCode: currentTypeCode ?? this.currentTypeCode,
        lastSession: lastSession ?? this.lastSession,
        lastErrorMessage: lastErrorMessage ?? this.lastErrorMessage,
        logs: logs ?? this.logs,
        typeResults: typeResults ?? this.typeResults,
      );
}

/// Result of fetching a single type code from the strap.
class TypeCodeResult {
  final String code;
  final String label;
  final String status; // 'ok', 'empty', 'rejected', 'error'
  final int bytes;
  final int samples;
  final String? rawHex;
  final String? errorMsg;

  const TypeCodeResult({
    required this.code,
    required this.label,
    required this.status,
    this.bytes = 0,
    this.samples = 0,
    this.rawHex,
    this.errorMsg,
  });
}
