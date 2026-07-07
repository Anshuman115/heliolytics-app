import 'dart:typed_data';
import '../lib/utils/crypto.dart';
import '../lib/services/ble/pairing_curve_b163.dart';

void main() {
  final data = Uint8List.fromList([0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38]);
  print('crc32=${crc32Huami(data).toRadixString(16)}');
  final key = Uint8List.fromList(List.generate(16, (i) => i));
  final plain = Uint8List.fromList(List.generate(16, (i) => i + 1));
  final enc = CryptoUtils.aes128EcbEncrypt(plain, key);
  print('aes=${enc.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}');
  final priv = Uint8List.fromList(List.generate(24, (i) => (i + 1) & 0xFF));
  final kp = PairingCurveB163.generateKeypair(privateKeyBytes: priv);
  print('pub=${kp.$2.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}');
  final remoteKp = PairingCurveB163.generateKeypair(
    privateKeyBytes: Uint8List.fromList(List.generate(24, (i) => (i + 50) & 0xFF)),
  );
  final remote = remoteKp.$2;
  final shared = PairingCurveB163.generateShared(kp.$1, remote);
  print('shared=${shared.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}');
}
