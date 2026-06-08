enum SessionMode { fetchAndListen, listenOnly }

extension SessionModeX on SessionMode {
  String get label => switch (this) {
        SessionMode.fetchAndListen => 'fetch+listen',
        SessionMode.listenOnly => 'listen-only',
      };
  static SessionMode parse(String s) => switch (s) {
        'fetch+listen' => SessionMode.fetchAndListen,
        'listen-only' => SessionMode.listenOnly,
        _ => throw FormatException('Unknown SessionMode: $s'),
      };
}
