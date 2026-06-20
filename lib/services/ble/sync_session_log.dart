import 'package:heliolytics/utils/app_logger.dart';

class SyncSessionLog {
  final List<String> _logs = [];

  List<String> get logs => List.unmodifiable(_logs);

  void clear() => _logs.clear();

  void log(String msg) {
    final ts = DateTime.now();
    final tsStr =
        '${ts.hour.toString().padLeft(2, '0')}:'
        '${ts.minute.toString().padLeft(2, '0')}:'
        '${ts.second.toString().padLeft(2, '0')}';
    _logs.add('[$tsStr] $msg');
    AppLogger.instance.log(msg, tag: 'sync');
  }
}
