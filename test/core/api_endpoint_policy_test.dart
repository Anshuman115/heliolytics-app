import 'package:flutter_test/flutter_test.dart';

import 'package:heliolytics/services/network/api_endpoint_policy.dart';

void main() {
  test('accepts an https origin and drops a trailing slash', () {
    final origin = ApiEndpointPolicy.production.parseOrigin(
      'https://api.example.com/',
    );
    expect(origin.toString(), 'https://api.example.com');
  });

  test('rejects http for the production policy, even on loopback', () {
    for (final raw in [
      'http://127.0.0.1:8080',
      'http://localhost:8080',
      'http://api.example.com',
    ]) {
      expect(
        () => ApiEndpointPolicy.production.parseOrigin(raw),
        throwsA(isA<ApiEndpointException>()),
        reason: raw,
      );
    }
  });

  test('allows plain http only for loopback hosts in development', () {
    const policy = ApiEndpointPolicy.development;
    expect(policy.parseOrigin('http://127.0.0.1:8080').port, 8080);
    expect(policy.parseOrigin('http://localhost:8080').host, 'localhost');
    expect(policy.parseOrigin('http://10.0.2.2:8080').host, '10.0.2.2');
    expect(
      () => policy.parseOrigin('http://api.example.com'),
      throwsA(isA<ApiEndpointException>()),
    );
  });

  test('rejects userinfo, fragments, queries and path prefixes', () {
    const policy = ApiEndpointPolicy.development;
    for (final raw in [
      'https://user:pass@api.example.com',
      'https://api.example.com/#frag',
      'https://api.example.com?x=1',
      'https://api.example.com/api/v1',
      'ftp://api.example.com',
      'api.example.com',
      '',
    ]) {
      expect(
        () => policy.parseOrigin(raw),
        throwsA(isA<ApiEndpointException>()),
        reason: raw,
      );
    }
  });

  test('resolves the exact escaped path and raw query that are signed', () {
    const policy = ApiEndpointPolicy.production;
    final origin = policy.parseOrigin('https://api.example.com');
    final uri = policy.resolve(
      origin,
      '/api/v1/metrics/series',
      query: {'from': '2026-10-01', 'to': '2026-10-19'},
    );
    expect(uri.path, '/api/v1/metrics/series');
    expect(uri.query, 'from=2026-10-01&to=2026-10-19');
    expect(
      uri.toString(),
      'https://api.example.com/api/v1/metrics/series?'
      'from=2026-10-01&to=2026-10-19',
    );
  });

  test('encodes a query value exactly once', () {
    const policy = ApiEndpointPolicy.production;
    final origin = policy.parseOrigin('https://api.example.com');
    final uri = policy.resolve(origin, '/api/v1/sleep', query: {'note': 'a b'});
    expect(uri.query, 'note=a+b');
  });

  test('refuses a path without a leading slash', () {
    const policy = ApiEndpointPolicy.production;
    final origin = policy.parseOrigin('https://api.example.com');
    expect(
      () => policy.resolve(origin, 'api/v1/sleep'),
      throwsA(isA<ApiEndpointException>()),
    );
  });
}
