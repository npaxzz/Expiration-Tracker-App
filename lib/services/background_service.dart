import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart';

import '../models/food_item.dart';

const String _dailyCheckTask = 'daily_expiry_check';

const String _foodBoxName = 'food_items';

const String _settingsBoxName = 'app_settings';

const String _notificationsEnabledKey = 'notifications_enabled';

const String _dailyReminderKey = 'daily_reminder';

const String _alertDaysBeforeKey = 'alert_days_before';

@pragma('vm:entry-point')
void backgroundDispatcher() {
  Workmanager().executeTask(
    (taskName, inputData) async {
      try {
        if (taskName == _dailyCheckTask) {
          await _runDailyCheck();
        }

        return true;
      } catch (e) {
        return false;
      }
    },
  );
}

// ============================================================
// BACKGROUND CHECK
// ============================================================

Future<void> _runDailyCheck() async {
  // ----------------------------------------------------------
  // HIVE
  // ----------------------------------------------------------

  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(FoodItemAdapter());
  }

  final foodBox = await Hive.openBox<FoodItem>(
    _foodBoxName,
  );

  final items = foodBox.values.toList();

  // ----------------------------------------------------------
  // SETTINGS
  // ----------------------------------------------------------

  final settingsBox = await Hive.openBox(
    _settingsBoxName,
  );

  final notificationsEnabled = settingsBox.get(
    _notificationsEnabledKey,
    defaultValue: true,
  ) as bool;

  final dailyReminder = settingsBox.get(
    _dailyReminderKey,
    defaultValue: true,
  ) as bool;

  final alertDaysBefore = settingsBox.get(
    _alertDaysBeforeKey,
    defaultValue: 3,
  ) as int;

  // ถ้าปิด notification
  // ไม่ต้องทำอะไร
  if (!notificationsEnabled) {
    await foodBox.close();
    await settingsBox.close();
    return;
  }

  // ----------------------------------------------------------
  // NOTIFICATION PLUGIN
  // ----------------------------------------------------------

  final plugin = FlutterLocalNotificationsPlugin();

  await plugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      ),
      iOS: DarwinInitializationSettings(),
    ),
  );

  // ----------------------------------------------------------
  // FIND EXPIRING ITEMS
  // ----------------------------------------------------------

  final expired = <FoodItem>[];
  final expiringSoon = <FoodItem>[];

  for (final item in items) {
    final days = item.daysUntilExpiration;

    if (days < 0) {
      expired.add(item);
    } else if (days <= alertDaysBefore) {
      expiringSoon.add(item);
    }
  }

  // ----------------------------------------------------------
  // EXPIRED NOTIFICATION
  // ----------------------------------------------------------

  if (expired.isNotEmpty) {
    final names = expired.map((item) => item.name).join(', ');

    await plugin.show(
      1001,
      '❌ ${expired.length} expired '
      'item${expired.length > 1 ? 's' : ''}',
      names,
      _notificationDetails(),
    );
  }

  // ----------------------------------------------------------
  // EXPIRING SOON
  // ----------------------------------------------------------

  if (expiringSoon.isNotEmpty) {
    final names = expiringSoon
        .map(
          (item) => '${item.name} '
              '(${item.daysUntilExpiration}d)',
        )
        .join(', ');

    await plugin.show(
      1002,
      '⏰ ${expiringSoon.length} item'
      '${expiringSoon.length > 1 ? 's are' : ' is'} '
      'expiring soon',
      names,
      _notificationDetails(),
    );
  }

  // ----------------------------------------------------------
  // DAILY SUMMARY
  // ----------------------------------------------------------

  // ถ้าเปิด Daily Summary
  // แสดงทุกครั้งที่ background task ทำงาน
  if (dailyReminder) {
    String title;
    String body;

    if (expired.isEmpty && expiringSoon.isEmpty) {
      title = '✅ Fridge looks good!';
      body = 'No food items are expiring soon.';
    } else {
      final parts = <String>[];

      if (expired.isNotEmpty) {
        parts.add(
          '${expired.length} expired',
        );
      }

      if (expiringSoon.isNotEmpty) {
        parts.add(
          '${expiringSoon.length} expiring soon',
        );
      }

      title = '🔔 Daily Fridge Summary';
      body = parts.join(' • ');
    }

    await plugin.show(
      9001,
      title,
      body,
      _dailyNotificationDetails(),
    );
  }

  await foodBox.close();
  await settingsBox.close();
}

// ============================================================
// NOTIFICATION DETAILS
// ============================================================

NotificationDetails _notificationDetails() {
  return const NotificationDetails(
    android: AndroidNotificationDetails(
      'daily_expiry_check',
      'Daily Expiry Check',
      channelDescription: 'Daily check for expiring food items',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    ),
    iOS: DarwinNotificationDetails(),
  );
}

NotificationDetails _dailyNotificationDetails() {
  return const NotificationDetails(
    android: AndroidNotificationDetails(
      'daily_summary_channel',
      'Daily Expiration Summary',
      channelDescription: 'Daily expiration summary',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    ),
    iOS: DarwinNotificationDetails(),
  );
}

// ============================================================
// BACKGROUND SERVICE
// ============================================================
class BackgroundService {
  static Future<void> init() async {
    // ==========================================================
    // WEB
    // ==========================================================
    // WorkManager ไม่รองรับ Flutter Web
    // ถ้าเรียกบน Chrome จะเกิด:
    // UnimplementedError
    // PluginUtilities.getCallbackHandle
    //
    // ดังนั้นให้ข้าม WorkManager ไปเลย
    if (kIsWeb) {
      debugPrint(
        'BackgroundService: Web detected - WorkManager skipped.',
      );
      return;
    }

    // ==========================================================
    // ANDROID / IOS
    // ==========================================================

    try {
      await Workmanager().initialize(
        backgroundDispatcher,
        isInDebugMode: false,
      );

      debugPrint(
        'BackgroundService: WorkManager initialized.',
      );
    } catch (e) {
      debugPrint(
        'BackgroundService: initialize failed: $e',
      );
    }
  }

  static Future<void> scheduleDailyCheck() async {
    // Web ไม่สามารถใช้ WorkManager
    if (kIsWeb) {
      debugPrint(
        'BackgroundService: Web detected - schedule skipped.',
      );
      return;
    }

    final now = DateTime.now();

    var next9am = DateTime(
      now.year,
      now.month,
      now.day,
      9,
      0,
    );

    // ถ้าเลย 09:00 แล้ว
    // ให้เริ่มตรวจรอบถัดไปพรุ่งนี้ 09:00
    if (!now.isBefore(next9am)) {
      next9am = next9am.add(
        const Duration(days: 1),
      );
    }

    final initialDelay = next9am.difference(now);

    debugPrint(
      'BackgroundService: Next daily check: $next9am',
    );

    try {
      await Workmanager().registerPeriodicTask(
        _dailyCheckTask,
        _dailyCheckTask,
        frequency: const Duration(hours: 24),
        initialDelay: initialDelay,
        constraints: Constraints(
          networkType: NetworkType.notRequired,
          requiresBatteryNotLow: false,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      );

      debugPrint(
        'BackgroundService: Daily check scheduled.',
      );
    } catch (e) {
      debugPrint(
        'BackgroundService: schedule failed: $e',
      );
    }
  }

  static Future<void> cancel() async {
    // Web ไม่มี WorkManager
    if (kIsWeb) {
      debugPrint(
        'BackgroundService: Web detected - cancel skipped.',
      );
      return;
    }

    try {
      await Workmanager().cancelByUniqueName(
        _dailyCheckTask,
      );

      debugPrint(
        'BackgroundService: Daily check cancelled.',
      );
    } catch (e) {
      debugPrint(
        'BackgroundService: cancel failed: $e',
      );
    }
  }
}
