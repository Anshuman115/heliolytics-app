import 'package:flutter/material.dart';
import 'package:heliolytics/models/session_state.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';

/// Strap connection status → accent color (for dots, icons, borders).
Color syncStatusColor(SessionState state) => switch (state) {
      SessionState.connected => HelioColors.optimalGreen,
      SessionState.fetching ||
      SessionState.connecting ||
      SessionState.authenticating =>
        HelioColors.recoveryMid,
      SessionState.error => HelioColors.recoveryLow,
      _ => HelioColors.textMuted,
    };

/// Strap connection status → human label.
String syncStatusLabel(SessionState state) => switch (state) {
      SessionState.idle => 'Ready to sync',
      SessionState.noAuthKey => 'Auth key required',
      SessionState.scanning => 'Scanning…',
      SessionState.connecting => 'Connecting…',
      SessionState.authenticating => 'Pairing…',
      SessionState.connected => 'Connected',
      SessionState.fetching => 'Syncing data…',
      SessionState.listening => 'Listening…',
      SessionState.error => 'Sync error',
    };
