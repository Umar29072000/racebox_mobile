import 'dart:io';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Pocket Foreground Mode Service Manager (FR-07 & SEC-07).
/// Keeps telemetry engine and GPS alive when phone is locked inside jacket pocket.
class ForegroundServiceManager {
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'racebox_pocket_service',
        channelName: 'Mode Saku RaceBox (Aktif)',
        channelDescription: 'Menjaga GPS dan pelacak akselerasi tetap berjalan saat HP di saku.',
        channelImportance: NotificationChannelImportance.MAX,
        priority: NotificationPriority.MAX,
        enableVibration: true,
        visibility: NotificationVisibility.VISIBILITY_PUBLIC,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
    _isInitialized = true;
  }

  static Future<void> requestPermissions() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      final NotificationPermission notificationPermission =
          await FlutterForegroundTask.checkNotificationPermission();
      if (notificationPermission != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }
      if (Platform.isAndroid) {
        if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
          await FlutterForegroundTask.requestIgnoreBatteryOptimization();
        }
      }
    } catch (_) {}
  }

  static Future<bool> startService() async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;
    try {
      await requestPermissions();
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.restartService();
        return true;
      }
      final result = await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: '🏁 Mode Saku RaceBox Aktif',
        notificationText: 'Siap gas! Layar mati & HP di saku tetap mencatat telemetri.',
      );
      return result is ServiceRequestSuccess;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> stopService() async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;
    try {
      final result = await FlutterForegroundTask.stopService();
      return result is ServiceRequestSuccess;
    } catch (_) {
      return false;
    }
  }

  static Future<void> updateNotification({
    required String title,
    required String text,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      await FlutterForegroundTask.updateService(
        notificationTitle: title,
        notificationText: text,
      );
    } catch (_) {}
  }
}
