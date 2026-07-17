import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Set true by AppLifecycleScope on resume when Bluetooth is off and the
/// app has a paired strap. HeliolyticsApp watches this to show a dialog.
final bluetoothPromptProvider = StateProvider<bool>((ref) => false);
