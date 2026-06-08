import 'dart:math';
import 'dart:typed_data';

/// Pure-Dart port of the Huami sect163k1 (B-163) ECDH used by the
/// Amazfit/Zepp BLE auth handshake.
///
/// is itself validated against real devices, and cross-checked against
/// Gadgetbridge's `ECDH_B163.java`. Interop-focused, NOT constant-time — do
/// not reuse for anything security-sensitive beyond talking to the strap.
///
/// Representation: a field element / scalar is a little-endian `Uint32List` of
/// 6 words (192 bits, of which 163 are used). Private key = 24 bytes,
/// public key = 48 bytes (x[24] || y[24]).
///
/// Curve: y^2 + x*y = x^3 + x^2 + b  over GF(2^163),
/// reduction polynomial x^163 + x^7 + x^6 + x^3 + 1.
class PairingCurveB163 {
  static const int _words = 6;
  static const int _curveDegree = 163;
  static const int _polyLow = 0xC9; // x^7+x^6+x^3+1  (word 0)
  static const int _polyW5 = 0x08; // x^163          (word 5, bit 3)

  static final Uint32List _baseX = Uint32List.fromList(
      [0xE8343E36, 0xD4994637, 0xA0991168, 0x86A2D57E, 0xF0EBA162, 0x00000003]);
  static final Uint32List _baseY = Uint32List.fromList(
      [0x797324F1, 0xB11C5C0C, 0xA2CDD545, 0x71A0094F, 0xD51FBC6C, 0x00000000]);
  static final Uint32List _coeffB = Uint32List.fromList(
      [0x4A3205FD, 0x512F7874, 0x1481EB10, 0xB8C953CA, 0x0A601907, 0x00000002]);

  // ---- low-level bit-vector helpers ----

  static Uint32List _zero() => Uint32List(_words);

  static Uint32List _copy(Uint32List v) => Uint32List.fromList(v);

  static bool _isZero(Uint32List v) {
    for (var i = 0; i < _words; i++) {
      if (v[i] != 0) return false;
    }
    return true;
  }

  static bool _isOne(Uint32List v) {
    if (v[0] != 1) return false;
    for (var i = 1; i < _words; i++) {
      if (v[i] != 0) return false;
    }
    return true;
  }

  static bool _eq(Uint32List a, Uint32List b) {
    for (var i = 0; i < _words; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Highest set bit index + 1 (0 if all-zero). Matches Swift
  /// `i*32 + (32 - leadingZeroBitCount)` via Dart's `int.bitLength`.
  static int _degree(Uint32List v) {
    for (var i = _words - 1; i >= 0; i--) {
      if (v[i] != 0) return i * 32 + v[i].bitLength;
    }
    return 0;
  }

  static int _getBit(Uint32List v, int pos) =>
      (v[pos >> 5] >> (pos & 31)) & 1;

  static void _xorInplace(Uint32List a, Uint32List b) {
    for (var i = 0; i < _words; i++) {
      a[i] ^= b[i];
    }
  }

  static void _lshift1(Uint32List v) {
    var carry = 0;
    for (var i = 0; i < _words; i++) {
      final nc = (v[i] >> 31) & 1;
      v[i] = ((v[i] << 1) | carry) & 0xFFFFFFFF;
      carry = nc;
    }
  }

  static Uint32List _lshift(Uint32List input, int n) {
    final v = _copy(input);
    var k = n;
    while (k >= 32) {
      for (var i = _words - 1; i >= 1; i--) {
        v[i] = v[i - 1];
      }
      v[0] = 0;
      k -= 32;
    }
    while (k > 0) {
      _lshift1(v);
      k -= 1;
    }
    return v;
  }

  static void _reduceOnce(Uint32List tmp) {
    if (((tmp[5] >> 3) & 1) == 1) {
      tmp[5] ^= _polyW5;
      tmp[0] ^= _polyLow;
    }
  }

  static Uint32List _gfMul(Uint32List x, Uint32List y) {
    final tmp = _copy(x);
    final z = (y[0] & 1) == 1 ? _copy(x) : _zero();
    for (var i = 1; i < _curveDegree; i++) {
      _lshift1(tmp);
      _reduceOnce(tmp);
      if (_getBit(y, i) == 1) _xorInplace(z, tmp);
    }
    return z;
  }

  static Uint32List _gfInv(Uint32List x) {
    if (_isZero(x)) throw StateError('gfInv(0)');
    var u = _copy(x);
    var v = _zero();
    v[0] = _polyLow;
    v[5] = _polyW5;
    var g = _zero();
    var z = _zero();
    z[0] = 1;
    while (!_isOne(u)) {
      var i = _degree(u) - _degree(v);
      if (i < 0) {
        final tu = u; u = v; v = tu;
        final tg = g; g = z; z = tg;
        i = -i;
      }
      final vs = _lshift(v, i);
      final gs = _lshift(g, i);
      _xorInplace(u, vs);
      _xorInplace(z, gs);
    }
    return z;
  }

  static (Uint32List, Uint32List) _ptDouble(Uint32List x, Uint32List y) {
    if (_isZero(x)) return (x, _zero());
    final inv = _gfInv(x);
    final l = _gfMul(inv, y);
    final ny = _gfMul(x, x);
    _xorInplace(l, x);
    final nx = _gfMul(l, l);
    l[0] ^= 1;
    _xorInplace(nx, l);
    final t = _gfMul(l, nx);
    _xorInplace(ny, t);
    return (nx, ny);
  }

  static (Uint32List, Uint32List) _ptAdd(
      Uint32List x1, Uint32List y1, Uint32List x2, Uint32List y2) {
    if (_isZero(x2) && _isZero(y2)) return (x1, y1);
    if (_isZero(x1) && _isZero(y1)) return (x2, y2);
    if (_eq(x1, x2)) {
      if (_eq(y1, y2)) return _ptDouble(x1, y1);
      return (_zero(), _zero());
    }
    final a = _copy(y1);
    _xorInplace(a, y2);
    final b = _copy(x1);
    _xorInplace(b, x2);
    final inv = _gfInv(b);
    final c = _gfMul(inv, a);
    final d = _gfMul(c, c);
    _xorInplace(d, c);
    _xorInplace(d, b);
    d[0] ^= 1;
    final nx = _copy(x1);
    _xorInplace(nx, d);
    final t = _gfMul(nx, c);
    _xorInplace(t, d);
    final ny = _copy(y1);
    _xorInplace(ny, t);
    return (d, ny);
  }

  static (Uint32List, Uint32List) _ptMul(
      Uint32List x, Uint32List y, Uint32List exp) {
    var tx = _zero(), ty = _zero();
    for (var i = _degree(exp) - 1; i >= 0; i--) {
      final d = _ptDouble(tx, ty);
      tx = d.$1; ty = d.$2;
      if (_getBit(exp, i) == 1) {
        final a = _ptAdd(tx, ty, x, y);
        tx = a.$1; ty = a.$2;
      }
    }
    return (tx, ty);
  }

  static bool _ptOnCurve(Uint32List x, Uint32List y) {
    if (_isZero(x) && _isZero(y)) return false;
    final a = _gfMul(x, x);
    final b = _gfMul(a, x);
    _xorInplace(a, b);
    _xorInplace(a, _coeffB);
    final yy = _gfMul(y, y);
    _xorInplace(a, yy);
    final xy = _gfMul(x, y);
    return _eq(a, xy);
  }

  // ---- byte <-> bit-vector ----

  static Uint32List _bytesToBV(Uint8List data, int n) {
    final v = _zero();
    final m = n < data.length ? n : data.length;
    for (var i = 0; i < m; i++) {
      v[i ~/ 4] |= data[i] << ((i % 4) * 8);
    }
    return v;
  }

  static Uint8List _bvToBytes(Uint32List v, int n) {
    final out = Uint8List(n);
    for (var i = 0; i < n; i++) {
      out[i] = (v[i ~/ 4] >> ((i % 4) * 8)) & 0xFF;
    }
    return out;
  }

  static Uint32List _sanitize(Uint32List p) {
    final x = _copy(p);
    x[5] &= 0x03;
    return x;
  }

  // ---- public API (mirrors HuamiECDH) ----

  /// Returns (privateKey 24 bytes, publicKey 48 bytes = x||y).
  /// Pass [privateKeyBytes] to make it deterministic (tests); otherwise random.
  static (Uint8List priv, Uint8List pub) generateKeypair(
      {Uint8List? privateKeyBytes}) {
    final rng = Random.secure();
    for (var attempt = 0; attempt < 64; attempt++) {
      final Uint8List privBytes;
      if (privateKeyBytes != null) {
        privBytes = Uint8List.fromList(privateKeyBytes);
      } else {
        privBytes = Uint8List.fromList(
            List<int>.generate(24, (_) => rng.nextInt(256)));
      }
      final priv = _sanitize(_bytesToBV(privBytes, 24));
      if (_degree(priv) < _curveDegree ~/ 2) {
        if (privateKeyBytes != null) {
          throw ArgumentError('supplied private key too small');
        }
        continue;
      }
      final p = _ptMul(_baseX, _baseY, priv);
      final pub = Uint8List(48)
        ..setRange(0, 24, _bvToBytes(p.$1, 24))
        ..setRange(24, 48, _bvToBytes(p.$2, 24));
      return (_bvToBytes(priv, 24), pub);
    }
    throw StateError('keypair generation failed');
  }

  /// ECDH: returns the 48-byte shared point (x||y).
  static Uint8List generateShared(Uint8List privateKey, Uint8List remotePub) {
    if (privateKey.length != 24 || remotePub.length != 48) {
      throw ArgumentError('bad key sizes');
    }
    final priv = _sanitize(_bytesToBV(privateKey, 24));
    final rx = _bytesToBV(Uint8List.sublistView(remotePub, 0, 24), 24);
    final ry = _bytesToBV(Uint8List.sublistView(remotePub, 24, 48), 24);
    if (_isZero(rx) && _isZero(ry)) throw ArgumentError('remote point is zero');
    if (!_ptOnCurve(rx, ry)) throw ArgumentError('remote point not on curve');
    final s = _ptMul(rx, ry, priv);
    final out = Uint8List(48)
      ..setRange(0, 24, _bvToBytes(s.$1, 24))
      ..setRange(24, 48, _bvToBytes(s.$2, 24));
    return out;
  }
}
