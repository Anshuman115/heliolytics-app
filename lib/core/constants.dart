const String huamiServiceUUID = '0000fee0-0000-1000-8000-00805f9b34fb';
const String chunkedWriteUUID = '00000016-0000-3512-2118-0009af100700';
/// Chunked notify characteristic (0x0017) — used for auth responses.
const String chunkedNotifyUUID = '00000017-0000-3512-2118-0009af100700';

/// Deprecated alias for [chunkedNotifyUUID]. Kept for backward compatibility.
const String chunkedReadUUID = chunkedNotifyUUID;
const String activityControlUUID = '00000004-0000-3512-2118-0009af100700';
const String activityDataUUID    = '00000005-0000-3512-2118-0009af100700';
const String liveHeartRateUUID   = '00002a37-0000-1000-8000-00805f9b34fb';

/// Confirmed type codes from Gadgetbridge HuamiFetchDataType enum + our own testing.
const List<String> knownTypeCodes = [
  '0x01', // ACTIVITY — per-minute HR/steps/intensity (Gadgetbridge confirmed)
  '0x49', // HRV (Gadgetbridge confirmed, 2025 addition)
  '0x25', // SPO2_NORMAL — spot SpO2 (Gadgetbridge confirmed)
  '0x26', // SPO2_SLEEP — sleep SpO2 (Gadgetbridge confirmed)
  '0x2E', // TEMPERATURE — skin temp (Gadgetbridge confirmed)
  '0x13', // STRESS_AUTOMATIC (Gadgetbridge confirmed)
  '0x12', // STRESS_MANUAL (Gadgetbridge confirmed)
  '0x38', // SLEEP_RESPIRATORY_RATE (Gadgetbridge confirmed)
  '0x3A', // RESTING_HEART_RATE (Gadgetbridge confirmed)
  '0x3D', // MAX_HEART_RATE (Gadgetbridge confirmed)
  '0x48', // SLEEP_SESSION (Gadgetbridge confirmed, 2025 addition)
  '0x05', // SPORTS_SUMMARIES — workout summaries (Gadgetbridge confirmed)
  '0x06', // SPORTS_DETAILS — workout GPS/per-second data (Gadgetbridge confirmed)
  '0x02', // MANUAL_HEART_RATE — user-triggered HR (Gadgetbridge confirmed)
  '0x0D', // PAI — Personal Activity Intelligence daily scores (Gadgetbridge confirmed)
  '0x2C', // STATISTICS — aggregate statistics (Gadgetbridge confirmed)
  '0x07', // DEBUG_LOGS — device debug data (Gadgetbridge confirmed, can be huge)
];

/// Undocumented codes to probe — brute-force scan of the full range.
/// Codes not in knownTypeCodes, covering 0x03–0x7F.
/// Source: gaps in Gadgetbridge enum + extended range for 2025 Helio firmware.
const List<String> probeTypeCodes = [
  // Gap in 0x03–0x04 (not in Gadgetbridge enum)
  '0x03', '0x04',
  // 0x08–0x0C (gap)
  '0x08', '0x09', '0x0A', '0x0B', '0x0C',
  // 0x0E–0x11 (gap)
  '0x0E', '0x0F', '0x10', '0x11',
  // 0x14–0x24 (gap)
  '0x14', '0x15', '0x16', '0x17', '0x18', '0x19',
  '0x1A', '0x1B', '0x1C', '0x1D', '0x1E', '0x1F',
  '0x20', '0x21', '0x22', '0x23', '0x24',
  // 0x27–0x2B (gap)
  '0x27', '0x28', '0x29', '0x2A', '0x2B',
  // 0x2D (gap)
  '0x2D',
  // 0x2F–0x37 (gap)
  '0x2F', '0x30', '0x31', '0x32', '0x33', '0x34', '0x35', '0x36', '0x37',
  // 0x39 (gap)
  '0x39',
  // 0x3B–0x3C (gap)
  '0x3B', '0x3C',
  // 0x3E–0x47 (gap)
  '0x3E', '0x3F', '0x40', '0x41', '0x42', '0x43', '0x44', '0x45', '0x46', '0x47',
  // 0x4A–0x7F (beyond Gadgetbridge enum — Helio 2025 firmware territory)
  '0x4A', '0x4B', '0x4C', '0x4D', '0x4E', '0x4F',
  '0x50', '0x51', '0x52', '0x53', '0x54', '0x55', '0x56', '0x57', '0x58', '0x59',
  '0x5A', '0x5B', '0x5C', '0x5D', '0x5E', '0x5F',
  '0x60', '0x61', '0x62', '0x63', '0x64', '0x65', '0x66', '0x67', '0x68', '0x69',
  '0x6A', '0x6B', '0x6C', '0x6D', '0x6E', '0x6F',
  '0x70', '0x71', '0x72', '0x73', '0x74', '0x75', '0x76', '0x77', '0x78', '0x79',
  '0x7A', '0x7B', '0x7C', '0x7D', '0x7E', '0x7F',
  // 0x80–0xFF (extended range — uncharted Helio 2025 / Zepp OS 4.x territory)
  '0x80', '0x81', '0x82', '0x83', '0x84', '0x85', '0x86', '0x87', '0x88', '0x89',
  '0x8A', '0x8B', '0x8C', '0x8D', '0x8E', '0x8F',
  '0x90', '0x91', '0x92', '0x93', '0x94', '0x95', '0x96', '0x97', '0x98', '0x99',
  '0x9A', '0x9B', '0x9C', '0x9D', '0x9E', '0x9F',
  '0xA0', '0xA1', '0xA2', '0xA3', '0xA4', '0xA5', '0xA6', '0xA7', '0xA8', '0xA9',
  '0xAA', '0xAB', '0xAC', '0xAD', '0xAE', '0xAF',
  '0xB0', '0xB1', '0xB2', '0xB3', '0xB4', '0xB5', '0xB6', '0xB7', '0xB8', '0xB9',
  '0xBA', '0xBB', '0xBC', '0xBD', '0xBE', '0xBF',
  '0xC0', '0xC1', '0xC2', '0xC3', '0xC4', '0xC5', '0xC6', '0xC7', '0xC8', '0xC9',
  '0xCA', '0xCB', '0xCC', '0xCD', '0xCE', '0xCF',
  '0xD0', '0xD1', '0xD2', '0xD3', '0xD4', '0xD5', '0xD6', '0xD7', '0xD8', '0xD9',
  '0xDA', '0xDB', '0xDC', '0xDD', '0xDE', '0xDF',
  '0xE0', '0xE1', '0xE2', '0xE3', '0xE4', '0xE5', '0xE6', '0xE7', '0xE8', '0xE9',
  '0xEA', '0xEB', '0xEC', '0xED', '0xEE', '0xEF',
  '0xF0', '0xF1', '0xF2', '0xF3', '0xF4', '0xF5', '0xF6', '0xF7', '0xF8', '0xF9',
  '0xFA', '0xFB', '0xFC', '0xFD', '0xFE', '0xFF',
];

/// Combined list: all known + all probe codes, deduplicated.
const List<String> allTypeCodes = [
  ...knownTypeCodes,
  ...probeTypeCodes,
];

/// Only confirmed data-returning codes for the 30-day full dump.
/// Skips all probe codes to avoid 2+ minutes of 1.5s timeouts.
const List<String> dumpTypeCodes = [
  '0x01', // HR + steps + activity per-minute
  '0x02', // Manual HR
  '0x05', // Workout summaries
  '0x06', // Workout details (per-second HR/cadence) — large, no probe
  '0x0D', // PAI scores
  '0x12', // Stress manual
  '0x13', // Stress auto
  '0x25', // SpO2
  '0x26', // SpO2 sleep
  '0x27', // Accelerometer stream
  '0x2C', // Device metadata / statistics
  '0x2E', // Temperature
  '0x38', // Sleep respiratory rate
  '0x3A', // Resting HR
  '0x3B', // Activity sessions (protobuf)
  '0x3D', // Max HR
  '0x46', // Continuous HR (PPG session)
  '0x48', // Sleep session blobs
  '0x49', // HRV
  '0x4A', // HRV trend
  '0x4E', // Sleep segments / nap log
];

/// Friendly labels for each type code.
const Map<String, String> typeCodeLabels = {
  '0x01': 'HR samples',
  // Gadgetbridge-confirmed codes
  '0x02': 'Manual HR',
  '0x05': 'Workouts',
  '0x06': 'Workout details',
  '0x07': 'Debug logs',
  '0x0D': 'PAI scores',
  '0x12': 'Stress manual',
  '0x13': 'Stress auto',
  '0x25': 'SpO2',
  '0x26': 'SpO2 sleep',
  '0x2C': 'Device metadata',
  '0x2E': 'Temperature',
  '0x38': 'Sleep resp rate',
  '0x3A': 'Resting HR',
  '0x3D': 'Max HR',
  '0x48': 'Sleep session',
  '0x49': 'HRV',
  // Gap probes (not in Gadgetbridge enum)
  '0x03': 'probe-03',
  '0x04': 'probe-04',
  '0x08': 'probe-08', '0x09': 'probe-09', '0x0A': 'probe-0A',
  '0x0B': 'probe-0B', '0x0C': 'probe-0C',
  '0x0E': 'probe-0E', '0x0F': 'probe-0F', '0x10': 'probe-10', '0x11': 'probe-11',
  '0x14': 'probe-14', '0x15': 'probe-15', '0x16': 'probe-16', '0x17': 'probe-17',
  '0x18': 'probe-18', '0x19': 'probe-19', '0x1A': 'probe-1A', '0x1B': 'probe-1B',
  '0x1C': 'probe-1C', '0x1D': 'probe-1D', '0x1E': 'probe-1E', '0x1F': 'probe-1F',
  '0x20': 'probe-20', '0x21': 'probe-21', '0x22': 'probe-22', '0x23': 'probe-23',
  '0x24': 'probe-24',
  '0x27': 'Accelerometer', // raw wrist accel stream — XYZ i8 @ 1/min
  '0x28': 'probe-28', '0x29': 'probe-29',
  '0x2A': 'probe-2A', '0x2B': 'probe-2B', '0x2D': 'probe-2D',
  '0x2F': 'probe-2F', '0x30': 'probe-30', '0x31': 'probe-31', '0x32': 'probe-32',
  '0x33': 'probe-33', '0x34': 'probe-34', '0x35': 'probe-35', '0x36': 'probe-36',
  '0x37': 'probe-37', '0x39': 'probe-39',
  '0x3B': 'Activity sessions', // auto-detected activity bouts, protobuf
  '0x3C': 'probe-3C',
  '0x3E': 'probe-3E', '0x3F': 'probe-3F', '0x40': 'probe-40', '0x41': 'probe-41',
  '0x42': 'probe-42', '0x43': 'probe-43', '0x44': 'probe-44', '0x45': 'probe-45',
  '0x46': 'Continuous HR',  // PPG HR session — 180 samples @ 1/min
  '0x47': 'probe-47',
  // Beyond Gadgetbridge enum — Helio 2025 territory
  '0x4A': 'HRV trend',      // confirmed data
  '0x4B': 'probe-4B', '0x4C': 'probe-4C', '0x4D': 'probe-4D',
  '0x4E': 'Sleep segments', // nap/sleep windows — ts + tz + duration
  '0x4F': 'probe-4F',
  '0x50': 'probe-50', '0x51': 'probe-51', '0x52': 'probe-52', '0x53': 'probe-53',
  '0x54': 'probe-54', '0x55': 'probe-55', '0x56': 'probe-56', '0x57': 'probe-57',
  '0x58': 'Raw PPG dump',   // 859k pkts — full-res PPG/accel, like 0x07
  '0x59': 'probe-59', '0x5A': 'probe-5A', '0x5B': 'probe-5B',
  '0x5C': 'probe-5C', '0x5D': 'probe-5D', '0x5E': 'probe-5E', '0x5F': 'probe-5F',
  '0x60': 'probe-60', '0x61': 'probe-61', '0x62': 'probe-62', '0x63': 'probe-63',
  '0x64': 'probe-64', '0x65': 'probe-65', '0x66': 'probe-66', '0x67': 'probe-67',
  '0x68': 'probe-68', '0x69': 'probe-69', '0x6A': 'probe-6A', '0x6B': 'probe-6B',
  '0x6C': 'probe-6C', '0x6D': 'probe-6D', '0x6E': 'probe-6E', '0x6F': 'probe-6F',
  '0x70': 'probe-70', '0x71': 'probe-71', '0x72': 'probe-72', '0x73': 'probe-73',
  '0x74': 'probe-74', '0x75': 'probe-75', '0x76': 'probe-76', '0x77': 'probe-77',
  '0x78': 'probe-78', '0x79': 'probe-79', '0x7A': 'probe-7A', '0x7B': 'probe-7B',
  '0x7C': 'probe-7C', '0x7D': 'probe-7D', '0x7E': 'probe-7E', '0x7F': 'probe-7F',
  // 0x80–0xFF extended range
  '0x80': 'probe-80', '0x81': 'probe-81', '0x82': 'probe-82', '0x83': 'probe-83',
  '0x84': 'probe-84', '0x85': 'probe-85', '0x86': 'probe-86', '0x87': 'probe-87',
  '0x88': 'probe-88', '0x89': 'probe-89', '0x8A': 'probe-8A', '0x8B': 'probe-8B',
  '0x8C': 'probe-8C', '0x8D': 'probe-8D', '0x8E': 'probe-8E', '0x8F': 'probe-8F',
  '0x90': 'probe-90', '0x91': 'probe-91', '0x92': 'probe-92', '0x93': 'probe-93',
  '0x94': 'probe-94', '0x95': 'probe-95', '0x96': 'probe-96', '0x97': 'probe-97',
  '0x98': 'probe-98', '0x99': 'probe-99', '0x9A': 'probe-9A', '0x9B': 'probe-9B',
  '0x9C': 'probe-9C', '0x9D': 'probe-9D', '0x9E': 'probe-9E', '0x9F': 'probe-9F',
  '0xA0': 'probe-A0', '0xA1': 'probe-A1', '0xA2': 'probe-A2', '0xA3': 'probe-A3',
  '0xA4': 'probe-A4', '0xA5': 'probe-A5', '0xA6': 'probe-A6', '0xA7': 'probe-A7',
  '0xA8': 'probe-A8', '0xA9': 'probe-A9', '0xAA': 'probe-AA', '0xAB': 'probe-AB',
  '0xAC': 'probe-AC', '0xAD': 'probe-AD', '0xAE': 'probe-AE', '0xAF': 'probe-AF',
  '0xB0': 'probe-B0', '0xB1': 'probe-B1', '0xB2': 'probe-B2', '0xB3': 'probe-B3',
  '0xB4': 'probe-B4', '0xB5': 'probe-B5', '0xB6': 'probe-B6', '0xB7': 'probe-B7',
  '0xB8': 'probe-B8', '0xB9': 'probe-B9', '0xBA': 'probe-BA', '0xBB': 'probe-BB',
  '0xBC': 'probe-BC', '0xBD': 'probe-BD', '0xBE': 'probe-BE', '0xBF': 'probe-BF',
  '0xC0': 'probe-C0', '0xC1': 'probe-C1', '0xC2': 'probe-C2', '0xC3': 'probe-C3',
  '0xC4': 'probe-C4', '0xC5': 'probe-C5', '0xC6': 'probe-C6', '0xC7': 'probe-C7',
  '0xC8': 'probe-C8', '0xC9': 'probe-C9', '0xCA': 'probe-CA', '0xCB': 'probe-CB',
  '0xCC': 'probe-CC', '0xCD': 'probe-CD', '0xCE': 'probe-CE', '0xCF': 'probe-CF',
  '0xD0': 'probe-D0', '0xD1': 'probe-D1', '0xD2': 'probe-D2', '0xD3': 'probe-D3',
  '0xD4': 'probe-D4', '0xD5': 'probe-D5', '0xD6': 'probe-D6', '0xD7': 'probe-D7',
  '0xD8': 'probe-D8', '0xD9': 'probe-D9', '0xDA': 'probe-DA', '0xDB': 'probe-DB',
  '0xDC': 'probe-DC', '0xDD': 'probe-DD', '0xDE': 'probe-DE', '0xDF': 'probe-DF',
  '0xE0': 'probe-E0', '0xE1': 'probe-E1', '0xE2': 'probe-E2', '0xE3': 'probe-E3',
  '0xE4': 'probe-E4', '0xE5': 'probe-E5', '0xE6': 'probe-E6', '0xE7': 'probe-E7',
  '0xE8': 'probe-E8', '0xE9': 'probe-E9', '0xEA': 'probe-EA', '0xEB': 'probe-EB',
  '0xEC': 'probe-EC', '0xED': 'probe-ED', '0xEE': 'probe-EE', '0xEF': 'probe-EF',
  '0xF0': 'probe-F0', '0xF1': 'probe-F1', '0xF2': 'probe-F2', '0xF3': 'probe-F3',
  '0xF4': 'probe-F4', '0xF5': 'probe-F5', '0xF6': 'probe-F6', '0xF7': 'probe-F7',
  '0xF8': 'probe-F8', '0xF9': 'probe-F9', '0xFA': 'probe-FA', '0xFB': 'probe-FB',
  '0xFC': 'probe-FC', '0xFD': 'probe-FD', '0xFE': 'probe-FE', '0xFF': 'probe-FF',
};

const String liveHeartRateTypeCode = '0x2a37';
const String appDocsSubdir = 'heliolytics';
const String sessionsSubdir = 'sessions';
const String authKeyStorageKey = 'heliolytics.auth_key';
const String strapMacStorageKey = 'heliolytics.strap_mac';
const int defaultFetchWindowHours = 48;
const int defaultListenDurationSec = 300;
const int scanTimeoutSec = 10;
const int chunkReceiveTimeoutSec = 5;
const int chunkRetryCount = 1;
