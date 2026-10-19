import 'package:wakelock_plus/wakelock_plus.dart';

/// Manages WakeLock (FR-08: KeepScreenOn in Handlebar HUD mode)
class WakelockService {
  static Future<void> enable() async {
    try {
      await WakelockPlus.enable();
    } catch (_) {}
  }

  static Future<void> disable() async {
    try {
      await WakelockPlus.disable();
    } catch (_) {}
  }

  static Future<bool> isEnabled() async {
    try {
      return await WakelockPlus.enabled;
    } catch (_) {
      return false;
    }
  }
}
