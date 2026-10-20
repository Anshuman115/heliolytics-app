import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// One request whose wire bytes are fixed before signing: URI, body and
/// Content-Type are sent exactly as signed, while a retry only refreshes the
/// authorization headers.
class SignedRequest {
  SignedRequest({
    required this.method,
    required this.uri,
    required Uint8List body,
    required this.contentType,
  }) : body = Uint8List.fromList(body),
       bodySha256Hex = sha256.convert(body).toString();

  SignedRequest.get(this.uri)
    : method = 'GET',
      body = Uint8List(0),
      contentType = '',
      bodySha256Hex = sha256.convert(const <int>[]).toString();

  SignedRequest.json(Uri uri, List<int> body)
    : this(
        method: 'PUT',
        uri: uri,
        body: Uint8List.fromList(body),
        contentType: 'application/json',
      );

  final String method;
  final Uri uri;
  final Uint8List body;
  final String contentType;
  final String bodySha256Hex;

  /// Escaped path exactly as transmitted, matching Go's `r.URL.EscapedPath()`.
  String get escapedPath => uri.path;

  /// Serialized query exactly as transmitted, without re-encoding.
  String get rawQuery => uri.query;
}
