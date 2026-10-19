/// Verified state reported by the strap, never a desired local preference.
class HealthConfigSnapshot {
  final int version;
  final bool? spo2AllDay;
  final bool? sleepBreathing;
  final int? spo2LowAlert;

  const HealthConfigSnapshot({
    required this.version,
    required this.spo2AllDay,
    required this.sleepBreathing,
    required this.spo2LowAlert,
  });

  Map<String, dynamic> toJson() => {
    'spo2AllDay': spo2AllDay,
    'spo2LowAlert': spo2LowAlert,
    'sleepBreathing': sleepBreathing,
    'version': version,
  };

  factory HealthConfigSnapshot.fromJson(Map<String, dynamic> json) =>
      HealthConfigSnapshot(
        version: (json['version'] as num).toInt(),
        spo2AllDay: json['spo2AllDay'] as bool?,
        spo2LowAlert: (json['spo2LowAlert'] as num?)?.toInt(),
        sleepBreathing: json['sleepBreathing'] as bool?,
      );
}

/// Explicit user choices. Null means no choice; false and zero are saved choices.
class StrapHealthDesiredState {
  final bool? allDay;
  final int? lowAlert;

  const StrapHealthDesiredState({this.allDay, this.lowAlert});
}

enum StrapHealthConfigPhase { idle, loading, ready, applying, error }

class StrapHealthConfigState {
  final StrapHealthConfigPhase phase;
  final HealthConfigSnapshot? config;
  final StrapHealthDesiredState desired;
  final String? error;

  const StrapHealthConfigState({
    this.phase = StrapHealthConfigPhase.idle,
    this.config,
    this.desired = const StrapHealthDesiredState(),
    this.error,
  });

  bool get isBusy =>
      phase == StrapHealthConfigPhase.loading ||
      phase == StrapHealthConfigPhase.applying;

  StrapHealthConfigState copyWith({
    StrapHealthConfigPhase? phase,
    HealthConfigSnapshot? config,
    StrapHealthDesiredState? desired,
    String? error,
    bool clearConfig = false,
    bool clearError = false,
  }) => StrapHealthConfigState(
    phase: phase ?? this.phase,
    config: clearConfig ? null : (config ?? this.config),
    desired: desired ?? this.desired,
    error: clearError ? null : (error ?? this.error),
  );
}
