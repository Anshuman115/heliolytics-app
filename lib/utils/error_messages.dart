import 'package:dio/dio.dart';

String friendlyError(Object error) {
  if (error is DioException) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout =>
        'Request timed out. Check your connection.',
      DioExceptionType.connectionError => _connectionHint(error),
      DioExceptionType.badCertificate => 'SSL certificate error. Use https:// with a valid cert.',
      DioExceptionType.badResponse when error.response?.statusCode == 401 =>
        'Unauthorized. Check the API key in Settings.',
      DioExceptionType.badResponse when error.response?.statusCode == 404 =>
        'API endpoint not found. Check the server URL in Settings.',
      DioExceptionType.badResponse =>
        'Server error (${error.response?.statusCode ?? 'unknown'}).',
      DioExceptionType.cancel => 'Request cancelled.',
      DioExceptionType.unknown => _unknownDio(error),
    };
  }
  final msg = error.toString().toLowerCase();
  if (msg.contains('socket') || msg.contains('connection refused')) {
    return _connectionHint(null);
  }
  if (msg.contains('stateerror') && msg.contains('api')) {
    return 'Set API URL and API key in Settings first.';
  }
  return 'Something went wrong. Try again.';
}

String _connectionHint(DioException? error) {
  final extra = (error?.message ?? '').toLowerCase();
  if (extra.contains('failed host lookup') || extra.contains('no address')) {
    return "Can't resolve API host. Check the URL in Settings → Cloud API.";
  }
  return "Can't reach the server. Phone must be on the same Wi‑Fi as your Mac, "
      'and the URL must be your Mac\'s LAN IP (not localhost).';
}

String _unknownDio(DioException error) {
  final msg = (error.message ?? error.toString()).toLowerCase();
  if (msg.contains('connection refused') ||
      msg.contains('failed host lookup') ||
      msg.contains('network is unreachable')) {
    return _connectionHint(error);
  }
  return 'Network error. Check Settings → Cloud API.';
}
