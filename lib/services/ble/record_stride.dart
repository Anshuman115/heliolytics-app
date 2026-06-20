/// Record sizes for round-relative Huami activity-fetch streams.
int recordStride(int code, int rawLength) {
  switch (code) {
    case 0x01:
      return rawLength % 8 == 0 ? 8 : 4;
    case 0x13:
      return 1;
    case 0x2E:
      return 8;
    default:
      return 4;
  }
}

bool isRoundRelative(int code) => code == 0x01 || code == 0x13 || code == 0x2E;
