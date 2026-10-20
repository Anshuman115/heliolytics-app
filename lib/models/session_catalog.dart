import 'package:heliolytics/models/dump_entry.dart';
import 'package:heliolytics/models/strap_health_config.dart';
import 'package:heliolytics/models/unsolicited_entry.dart';

class SessionCatalog {
  final String sessionId;
  final List<DumpEntry> chunked;
  final List<UnsolicitedEntry> unsolicited;
  final HealthConfigSnapshot? strapConfig;

  const SessionCatalog({
    required this.sessionId,
    required this.chunked,
    required this.unsolicited,
    this.strapConfig,
  });

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'chunked': chunked.map((e) => e.toJson()).toList(),
    'unsolicited': unsolicited.map((e) => e.toJson()).toList(),
    if (strapConfig != null) 'strapConfig': strapConfig!.toJson(),
  };

  factory SessionCatalog.fromJson(Map<String, dynamic> j) => SessionCatalog(
    sessionId: j['sessionId'] as String,
    chunked: List.unmodifiable(
      (j['chunked'] as List<dynamic>).map(
        (e) => DumpEntry.fromJson(e as Map<String, dynamic>),
      ),
    ),
    unsolicited: List.unmodifiable(
      (j['unsolicited'] as List<dynamic>).map(
        (e) => UnsolicitedEntry.fromJson(e as Map<String, dynamic>),
      ),
    ),
    strapConfig: j['strapConfig'] is Map<String, dynamic>
        ? HealthConfigSnapshot.fromJson(
            j['strapConfig'] as Map<String, dynamic>,
          )
        : null,
  );
}
