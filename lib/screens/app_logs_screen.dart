import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:heliolytics/utils/app_logger.dart';

/// Thin wrapper around talker_flutter's ready-made viewer — deliberately
/// not restyled to match HelioTheme; this is a diagnostics screen.
class AppLogsScreen extends StatelessWidget {
  const AppLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TalkerScreen(talker: AppLogger.instance.talker);
  }
}
