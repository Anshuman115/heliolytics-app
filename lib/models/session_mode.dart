enum SessionMode { fetchAndListen }

extension SessionModeX on SessionMode {
  String get label => switch (this) {
        SessionMode.fetchAndListen => 'fetch+listen',
      };
  static SessionMode parse(String s) => switch (s) {
        'fetch+listen' => SessionMode.fetchAndListen,
        _ => throw FormatException('Unknown SessionMode: $s'),
      };
}
