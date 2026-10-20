import 'package:flutter/foundation.dart';

/// Raised when the configured API origin or a route cannot be used.
class ApiEndpointException implements Exception {
  const ApiEndpointException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Validates the Settings API origin and resolves the exact signed URI.
/// Plain HTTP is limited to loopback development hosts and is always refused
/// in release builds.
class ApiEndpointPolicy {
  const ApiEndpointPolicy({required this.allowInsecureLocal});

  /// Release policy: HTTPS only.
  static const ApiEndpointPolicy production = ApiEndpointPolicy(
    allowInsecureLocal: false,
  );

  /// Development policy: loopback HTTP allowed outside release builds.
  static const ApiEndpointPolicy development = ApiEndpointPolicy(
    allowInsecureLocal: true,
  );

  /// Explicit loopback allowance for the local live-contract test harness.
  static const ApiEndpointPolicy testLoopback = ApiEndpointPolicy(
    allowInsecureLocal: true,
  );

  /// The policy the running build must use: release is HTTPS only.
  static ApiEndpointPolicy get current =>
      kReleaseMode ? production : development;

  static const Set<String> _localHosts = {
    '127.0.0.1',
    'localhost',
    '::1',
    '10.0.2.2',
  };

  final bool allowInsecureLocal;

  bool get _mayUsePlainHttp => !kReleaseMode && allowInsecureLocal;

  /// Parses the stored origin, throwing [ApiEndpointException] when unusable.
  Uri parseOrigin(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      throw const ApiEndpointException('Set the API URL in Settings.');
    }
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) {
      throw const ApiEndpointException('Enter a valid API URL.');
    }
    if (uri.userInfo.isNotEmpty) {
      throw const ApiEndpointException(
        'The API URL must not contain credentials.',
      );
    }
    if (uri.hasQuery) {
      throw const ApiEndpointException('The API URL must not contain a query.');
    }
    if (uri.hasFragment) {
      throw const ApiEndpointException(
        'The API URL must not contain a fragment.',
      );
    }
    if (uri.host.isEmpty) {
      throw const ApiEndpointException('The API URL needs a host name.');
    }
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'https' && scheme != 'http') {
      throw const ApiEndpointException('The API URL must start with https://.');
    }
    if (uri.path.isNotEmpty && uri.path != '/') {
      throw const ApiEndpointException(
        'The API URL must be an origin without a path.',
      );
    }
    if (scheme == 'http') _requirePlainHttpAllowed(uri.host);
    return Uri(
      scheme: scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
    );
  }

  /// Resolves [path] and [query] against [origin], encoding each value once.
  Uri resolve(Uri origin, String path, {Map<String, String>? query}) {
    if (!path.startsWith('/')) {
      throw const ApiEndpointException('API paths must start with a slash.');
    }
    final buffer = StringBuffer(origin.toString())..write(path);
    if (query != null && query.isNotEmpty) {
      buffer.write('?');
      var first = true;
      for (final entry in query.entries) {
        if (!first) buffer.write('&');
        first = false;
        buffer
          ..write(Uri.encodeQueryComponent(entry.key))
          ..write('=')
          ..write(Uri.encodeQueryComponent(entry.value));
      }
    }
    return Uri.parse(buffer.toString());
  }

  void _requirePlainHttpAllowed(String host) {
    if (!_mayUsePlainHttp) {
      throw const ApiEndpointException('The API URL must use https://.');
    }
    if (!_localHosts.contains(host)) {
      throw const ApiEndpointException(
        'Plain HTTP is allowed only for a loopback development host.',
      );
    }
  }
}
