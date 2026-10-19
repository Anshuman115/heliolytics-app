/// Type codes fetched by a normal production sync. Dump commands may fetch others.
const List<String> productionFetchTypeCodes = [
  '0x01',
  '0x05',
  '0x06',
  '0x0D',
  '0x13',
  '0x25',
  '0x26',
  '0x2E',
  '0x38',
  '0x46',
  '0x48',
  '0x49',
];

bool isProductionFetchType(String code) =>
    productionFetchTypeCodes.contains(code);
