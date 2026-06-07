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
];

/// Combined list: all known + all probe codes, deduplicated.
const List<String> allTypeCodes = [
  ...knownTypeCodes,
  ...probeTypeCodes,
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
  '0x2C': 'Statistics',
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
  '0x27': 'unknown-27',    // confirmed data (486 bytes) — Helio-specific
  '0x28': 'probe-28', '0x29': 'probe-29',
  '0x2A': 'probe-2A', '0x2B': 'probe-2B', '0x2D': 'probe-2D',
  '0x2F': 'probe-2F', '0x30': 'probe-30', '0x31': 'probe-31', '0x32': 'probe-32',
  '0x33': 'probe-33', '0x34': 'probe-34', '0x35': 'probe-35', '0x36': 'probe-36',
  '0x37': 'probe-37', '0x39': 'probe-39',
  '0x3B': 'unknown-3B',    // confirmed data (1404 bytes) — Helio-specific
  '0x3C': 'probe-3C',
  '0x3E': 'probe-3E', '0x3F': 'probe-3F', '0x40': 'probe-40', '0x41': 'probe-41',
  '0x42': 'probe-42', '0x43': 'probe-43', '0x44': 'probe-44', '0x45': 'probe-45',
  '0x46': 'unknown-46',    // confirmed data (188 bytes) — likely cycling detail
  '0x47': 'probe-47',
  // Beyond Gadgetbridge enum — Helio 2025 territory
  '0x4A': 'HRV trend',      // confirmed data
  '0x4B': 'probe-4B', '0x4C': 'probe-4C', '0x4D': 'probe-4D',
  '0x4E': 'unknown-4E',    // confirmed data (45 bytes) — Helio-specific
  '0x4F': 'probe-4F',
  '0x50': 'probe-50', '0x51': 'probe-51', '0x52': 'probe-52', '0x53': 'probe-53',
  '0x54': 'probe-54', '0x55': 'probe-55', '0x56': 'probe-56', '0x57': 'probe-57',
  '0x58': 'dump-58',       // confirmed huge dump (859k pkts) — like 0x07
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
