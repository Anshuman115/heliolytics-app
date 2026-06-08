import 'package:heliolytics/features/ble_discovery/domain/models/dump_entry.dart';
import 'package:heliolytics/features/ble_discovery/domain/models/unsolicited_entry.dart';

class SessionCatalog {
  static const int schemaVersion = 1;
  final String sessionId;
  final List<DumpEntry> chunked;
  final List<UnsolicitedEntry> unsolicited;

  const SessionCatalog({
    required this.sessionId,
    required this.chunked,
    required this.unsolicited,
  });

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'sessionId': sessionId,
        'chunked': chunked.map((e) => e.toJson()).toList(),
        'unsolicited': unsolicited.map((e) => e.toJson()).toList(),
      };

  factory SessionCatalog.fromJson(Map<String, dynamic> j) => SessionCatalog(
        sessionId: j['sessionId'] as String,
        chunked: (j['chunked'] as List<dynamic>)
            .map((e) => DumpEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        unsolicited: (j['unsolicited'] as List<dynamic>)
            .map((e) => UnsolicitedEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
