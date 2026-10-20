/// ZeppOS encrypted HEALTH configuration endpoint and wire identifiers.
const int strapHealthConfigEndpoint = 0x000a;
const int strapHealthConfigRequest = 0x03;
const int strapHealthConfigResponse = 0x04;
const int strapHealthConfigSet = 0x05;
const int strapHealthConfigAck = 0x06;
const int strapHealthGroup = 0x08;
const int strapHealthTypeBool = 0x0b;
const int strapHealthTypeByte = 0x10;
const int strapHealthKeySleepBreathing = 0x12;
const int strapHealthKeyAllDay = 0x31;
const int strapHealthKeyLowAlert = 0x32;

const List<int> strapHealthLowAlertChoices = [0, 80, 85, 90];
