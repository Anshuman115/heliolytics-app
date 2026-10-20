/// Raised when a successful response does not match the published C2/C3 shape.
class ProtocolException implements Exception {
  const ProtocolException(this.message, {this.path});

  final String message;
  final String? path;

  @override
  String toString() => path == null
      ? 'ProtocolException($message)'
      : 'ProtocolException($path: $message)';
}
