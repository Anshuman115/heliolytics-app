const String huamiServiceUUID = '0000fee0-0000-1000-8000-00805f9b34fb';
const String chunkedWriteUUID = '00000016-0000-3512-2118-0009af100700';
/// Chunked notify characteristic (0x0017) — used for auth responses.
const String chunkedNotifyUUID = '00000017-0000-3512-2118-0009af100700';

/// Deprecated alias for [chunkedNotifyUUID]. Kept for backward compatibility.
const String chunkedReadUUID = chunkedNotifyUUID;
const String activityControlUUID = '00000004-0000-3512-2118-0009af100700';
const String activityDataUUID    = '00000005-0000-3512-2118-0009af100700';
const String liveHeartRateUUID   = '00002a37-0000-1000-8000-00805f9b34fb';

/// All type codes the Helio Strap is known to support.
/// Ordered by priority — most useful first.
const List<String> knownTypeCodes = [
  '0x01', // HR samples
  '0x49', // HRV
  '0x25', // SpO2
  '0x26', // SpO2 during sleep
  '0x2E', // Skin temperature
  '0x13', // Stress
  '0x38', // Sleep respiratory rate
  '0x3A', // Resting HR
  '0x3D', // Max HR
  '0x48', // Sleep sessions
  '0x05', // Workout summaries
];

/// Additional type codes to probe — may or may not have data depending
/// on strap firmware and what the user has recorded.
const List<String> probeTypeCodes = [
  '0x02', // Activity detail?
  '0x03', // Steps?
  '0x04', // Calories?
  '0x06', // Workout detail?
  '0x07', // GPS?
  '0x12', // Blood pressure?
  '0x14', // Body composition?
  '0x15', // Menstrual cycle?
  '0x1A', // Sleep staging?
  '0x1B', // Sleep breathing?
  '0x1C', // Sleep quality?
  '0x1D', // Sleep score?
  '0x1E', // Sleep mask?
  '0x20', // Blood oxygen continuous?
  '0x21', // HR continuous?
  '0x22', // Activity realtime?
  '0x24', // All-day HR?
  '0x27', // PAI?
  '0x28', // Vigorous load?
  '0x29', // Standing?
  '0x2A', // Body battery?
  '0x2B', // Sleep animal?
  '0x2C', // Sleep nap?
  '0x2D', // Readiness?
  '0x2F', // Skin temp waveform?
  '0x30', // Stress continuous?
  '0x31', // Stress breathing?
  '0x32', // HRV nightly?
  '0x33', // HRV report?
  '0x34', // Resting HR trend?
  '0x35', // HR zone?
  '0x36', // HRV detail?
  '0x37', // Respiratory rate trend?
  '0x39', // Sleep apnea?
  '0x3B', // Resting HR detail?
  '0x3C', // HRV summary?
  '0x3E', // Max HR detail?
  '0x3F', // VO2max?
  '0x40', // Fitness age?
  '0x41', // Training load?
  '0x42', // Recovery time?
  '0x43', // Running index?
  '0x44', // Jump rope?
  '0x45', // Swimming?
  '0x46', // Cycling?
  '0x47', // Elliptical?
  '0x4A', // HRV trend?
  '0x4B', // Activity fetch service (encrypted)?
  '0x4C', // Blood pressure calibration?
];

/// Combined list: all known + all probe codes, deduplicated.
const List<String> allTypeCodes = [
  ...knownTypeCodes,
  ...probeTypeCodes,
];

/// Friendly labels for each type code.
const Map<String, String> typeCodeLabels = {
  '0x01': 'HR samples',
  '0x05': 'Workouts',
  '0x13': 'Stress',
  '0x25': 'SpO2',
  '0x26': 'SpO2 sleep',
  '0x2E': 'Temperature',
  '0x38': 'Sleep resp rate',
  '0x3A': 'Resting HR',
  '0x3D': 'Max HR',
  '0x48': 'Sleep sessions',
  '0x49': 'HRV',
  '0x02': 'Activity detail?',
  '0x03': 'Steps?',
  '0x04': 'Calories?',
  '0x06': 'Workout detail?',
  '0x07': 'GPS?',
  '0x12': 'Blood pressure?',
  '0x14': 'Body comp?',
  '0x15': 'Menstrual?',
  '0x1A': 'Sleep staging?',
  '0x1B': 'Sleep breathing?',
  '0x1C': 'Sleep quality?',
  '0x1D': 'Sleep score?',
  '0x1E': 'Sleep mask?',
  '0x20': 'SpO2 continuous?',
  '0x21': 'HR continuous?',
  '0x22': 'Activity realtime?',
  '0x24': 'All-day HR?',
  '0x27': 'PAI?',
  '0x28': 'Vigorous load?',
  '0x29': 'Standing?',
  '0x2A': 'Body battery?',
  '0x2B': 'Sleep animal?',
  '0x2C': 'Sleep nap?',
  '0x2D': 'Readiness?',
  '0x2F': 'Skin temp wave?',
  '0x30': 'Stress continuous?',
  '0x31': 'Stress breathing?',
  '0x32': 'HRV nightly?',
  '0x33': 'HRV report?',
  '0x34': 'Resting HR trend?',
  '0x35': 'HR zone?',
  '0x36': 'HRV detail?',
  '0x37': 'Resp rate trend?',
  '0x39': 'Sleep apnea?',
  '0x3B': 'Resting HR detail?',
  '0x3C': 'HRV summary?',
  '0x3E': 'Max HR detail?',
  '0x3F': 'VO2max?',
  '0x40': 'Fitness age?',
  '0x41': 'Training load?',
  '0x42': 'Recovery time?',
  '0x43': 'Running index?',
  '0x44': 'Jump rope?',
  '0x45': 'Swimming?',
  '0x46': 'Cycling?',
  '0x47': 'Elliptical?',
  '0x4A': 'HRV trend?',
  '0x4B': 'Encrypted service?',
  '0x4C': 'BP calibration?',
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
