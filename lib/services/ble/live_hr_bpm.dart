/// Parses BPM from a GATT Heart Rate Measurement (0x2A37) notification.
///
/// Byte 0 is the flags field per the BLE HR profile spec:
///   bit 0 = 0 → 8-bit BPM at byte 1
///   bit 0 = 1 → 16-bit BPM at bytes 1-2 (little-endian)
///
/// Returns null for malformed, out-of-range, or contact-lost packets.
int? bpmFromGattNotify(List<int> value) {
  if (value.length < 2) return null;
  final flags = value[0] & 0xff;
  final int bpm;
  if (flags & 0x01 == 0) {
    bpm = value[1] & 0xff;
  } else {
    if (value.length < 3) return null;
    bpm = (value[1] & 0xff) | ((value[2] & 0xff) << 8);
  }
  if (bpm < 20 || bpm > 240) return null;
  return bpm;
}
