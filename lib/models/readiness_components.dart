/// Readiness status reported by the backend for a day.
enum ReadinessStatus {
  scored,
  calibrating,
  noBaseline,
  noData;

  static ReadinessStatus? parse(Object? raw) => switch (raw) {
    'scored' => scored,
    'calibrating' => calibrating,
    'no_baseline' => noBaseline,
    'no_data' => noData,
    _ => null,
  };

  String get wire => switch (this) {
    ReadinessStatus.scored => 'scored',
    ReadinessStatus.calibrating => 'calibrating',
    ReadinessStatus.noBaseline => 'no_baseline',
    ReadinessStatus.noData => 'no_data',
  };
}

/// Display band for a stored readiness score.
enum ReadinessBand {
  good,
  fair,
  low;

  static ReadinessBand? parse(Object? raw) => switch (raw) {
    'good' => good,
    'fair' => fair,
    'low' => low,
    _ => null,
  };
}

/// One readiness component exactly as the backend persists it.
///
/// Fields that do not apply to a component stay null; nothing is inferred.
class ReadinessComponent {
  const ReadinessComponent({
    required this.name,
    this.value,
    this.x,
    this.center,
    this.sd,
    this.sdPersonal,
    this.n,
    this.z,
    this.sub,
    this.weight,
    this.points,
    this.nights,
    this.chronic,
    this.ratio,
    this.dev,
  });

  final String name;
  final double? value;
  final double? x;
  final double? center;
  final double? sd;
  final double? sdPersonal;
  final int? n;
  final double? z;
  final double? sub;
  final double? weight;
  final double? points;
  final int? nights;
  final double? chronic;
  final double? ratio;
  final double? dev;

  factory ReadinessComponent.fromJson(Map<String, dynamic> j) {
    final name = j['name'];
    if (name is! String) {
      throw const FormatException('Readiness component has no name');
    }
    return ReadinessComponent(
      name: name,
      value: _double(j['value']),
      x: _double(j['x']),
      center: _double(j['center']),
      sd: _double(j['sd']),
      sdPersonal: _double(j['sdPersonal']),
      n: _int(j['n']),
      z: _double(j['z']),
      sub: _double(j['sub']),
      weight: _double(j['weight']),
      points: _double(j['points']),
      nights: _int(j['nights']),
      chronic: _double(j['chronic']),
      ratio: _double(j['ratio']),
      dev: _double(j['dev']),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'value': value,
    'x': x,
    'center': center,
    'sd': sd,
    'sdPersonal': sdPersonal,
    'n': n,
    'z': z,
    'sub': sub,
    'weight': weight,
    'points': points,
    'nights': nights,
    'chronic': chronic,
    'ratio': ratio,
    'dev': dev,
  };
}

/// Readiness explanation. The client never computes a score.
class ReadinessComponents {
  const ReadinessComponents({
    required this.status,
    required this.baselineNights,
    this.score,
    this.raw,
    this.components = const [],
    this.flags = const [],
  });

  final ReadinessStatus status;
  final int baselineNights;
  final int? score;
  final double? raw;
  final List<ReadinessComponent> components;
  final List<String> flags;

  factory ReadinessComponents.fromJson(Map<String, dynamic> j) {
    final status = ReadinessStatus.parse(j['status']);
    if (status == null) {
      throw FormatException('Unknown readiness status: ${j['status']}');
    }
    final baseline = j['baselineNights'];
    if (baseline is! num) {
      throw const FormatException('ReadinessComponents needs baselineNights');
    }
    final rawComponents = j['components'];
    if (rawComponents is! List) {
      throw const FormatException('ReadinessComponents needs components');
    }
    final rawFlags = j['flags'];
    if (rawFlags is! List) {
      throw const FormatException('ReadinessComponents needs flags');
    }
    return ReadinessComponents(
      status: status,
      baselineNights: baseline.toInt(),
      score: _int(j['score']),
      raw: _double(j['raw']),
      components: rawComponents
          .map(
            (e) => ReadinessComponent.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      flags: rawFlags.map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status.wire,
    'score': score,
    'raw': raw,
    'baselineNights': baselineNights,
    'components': components.map((c) => c.toJson()).toList(),
    'flags': flags,
  };
}

double? _double(Object? raw) => raw is num ? raw.toDouble() : null;

int? _int(Object? raw) => raw is num ? raw.toInt() : null;
