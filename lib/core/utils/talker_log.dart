import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talker/talker.dart';

/// Shared Talker instance for HTTP and app diagnostics (debug/profile only).
Talker createAppTalker() {
  return Talker(
    settings: TalkerSettings(
      enabled: !kReleaseMode,
      useConsoleLogs: !kReleaseMode,
    ),
  );
}

Talker? _appTalker;

/// Single process-wide Talker (used by [talkerProvider] and [main] error hooks).
Talker appTalker() => _appTalker ??= createAppTalker();

final talkerProvider = Provider<Talker>((ref) => appTalker());
