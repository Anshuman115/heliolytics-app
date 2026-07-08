/// Persisted band alerts preferences.
class BandAlertsConfig {
  final bool enabled;
  final bool forwardCalls;
  final bool callsOnly;
  final Set<String> allowedPackages;

  const BandAlertsConfig({
    this.enabled = false,
    this.forwardCalls = true,
    this.callsOnly = false,
    this.allowedPackages = const {},
  });

  bool get hasForwardingTarget =>
      allowedPackages.isNotEmpty || (callsOnly && forwardCalls);

  bool needsNotificationListener() => allowedPackages.isNotEmpty;

  bool needsPhonePermission() => forwardCalls;

  BandAlertsConfig copyWith({
    bool? enabled,
    bool? forwardCalls,
    bool? callsOnly,
    Set<String>? allowedPackages,
    bool clearAllowlist = false,
  }) =>
      BandAlertsConfig(
        enabled: enabled ?? this.enabled,
        forwardCalls: forwardCalls ?? this.forwardCalls,
        callsOnly: callsOnly ?? this.callsOnly,
        allowedPackages: clearAllowlist
            ? const {}
            : (allowedPackages ?? this.allowedPackages),
      );
}
