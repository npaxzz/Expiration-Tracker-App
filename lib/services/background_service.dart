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

const String _languageKey = 'language';

// ============================================================
// BACKGROUND DISPATCHER
// ============================================================

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
        debugPrint(
          'BackgroundService: task failed: $e',
        );

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
    Hive.registerAdapter(
      FoodItemAdapter(),
    );
  }

  final foodBox = await Hive.openBox<FoodItem>(
    _foodBoxName,
  );

  final settingsBox = await Hive.openBox(
    _settingsBoxName,
  );

  try {
    // --------------------------------------------------------
    // SETTINGS
    // --------------------------------------------------------

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

    final languageCode = settingsBox.get(
      _languageKey,
      defaultValue: 'en',
    ) as String;

    final isThai = languageCode == 'th';

    debugPrint(
      'BackgroundService: '
      'notificationsEnabled=$notificationsEnabled, '
      'dailyReminder=$dailyReminder, '
      'alertDaysBefore=$alertDaysBefore',
    );

    // --------------------------------------------------------
    // MASTER SWITCH
    // --------------------------------------------------------

    if (!notificationsEnabled) {
      debugPrint(
        'BackgroundService: Notifications disabled.',
      );

      return;
    }

    // --------------------------------------------------------
    // DAILY REMINDER SWITCH
    // --------------------------------------------------------

    if (!dailyReminder) {
      debugPrint(
        'BackgroundService: Daily Reminder disabled.',
      );

      return;
    }

    // --------------------------------------------------------
    // READ LATEST FOOD DATA
    // --------------------------------------------------------

    final items = foodBox.values.toList();

    // --------------------------------------------------------
    // FIND ITEMS WITHIN THRESHOLD
    // --------------------------------------------------------

    final expiringSoon = <FoodItem>[];

    for (final item in items) {
      final days = item.daysUntilExpiration;

      // สำคัญ:
      //
      // days == 0
      // หมดอายุวันนี้
      //
      // days > 0
      // ยังไม่หมดอายุ
      //
      // days < 0
      // หมดอายุไปแล้ว
      //
      // Daily Reminder สนใจเฉพาะ:
      // 0 <= days <= alertDaysBefore

      if (days >= 0 && days <= alertDaysBefore) {
        expiringSoon.add(
          item,
        );
      }
    }

    // --------------------------------------------------------
    // NOTHING TO NOTIFY
    // --------------------------------------------------------

    if (expiringSoon.isEmpty) {
      debugPrint(
        'BackgroundService: '
        'No items within expiration threshold.',
      );

      return;
    }

    // --------------------------------------------------------
    // NOTIFICATION PLUGIN
    // --------------------------------------------------------

    final plugin = FlutterLocalNotificationsPlugin();

    await plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings(
          '@mipmap/ic_launcher',
        ),
        iOS: DarwinInitializationSettings(),
      ),
    );

    // --------------------------------------------------------
    // BUILD ONE DAILY SUMMARY
    // --------------------------------------------------------

    final names = expiringSoon.map(
      (item) {
        final days = item.daysUntilExpiration;

        if (isThai) {
          if (days == 0) {
            return '${item.name} (วันนี้)';
          }

          return '${item.name} (อีก $days วัน)';
        }

        if (days == 0) {
          return '${item.name} (today)';
        }

        return '${item.name} '
            '(in $days day'
            '${days > 1 ? 's' : ''})';
      },
    ).join(', ');

    final title = isThai
        ? '🔔 รายการใกล้หมดอายุ ${expiringSoon.length} รายการ'
        : '🔔 ${expiringSoon.length} '
            'item'
            '${expiringSoon.length > 1 ? 's' : ''} '
            'expiring soon';

    // --------------------------------------------------------
    // SHOW ONE NOTIFICATION
    // --------------------------------------------------------

    await plugin.show(
      9001,
      title,
      names,
      _dailyNotificationDetails(),
    );

    debugPrint(
      'BackgroundService: '
      'Daily summary sent: $names',
    );
  } finally {
    // --------------------------------------------------------
    // CLOSE HIVE
    // --------------------------------------------------------

    await foodBox.close();
    await settingsBox.close();
  }
}

// ============================================================
// DAILY NOTIFICATION DETAILS
// ============================================================

NotificationDetails _dailyNotificationDetails() {
  return const NotificationDetails(
    android: AndroidNotificationDetails(
      'daily_expiration_summary',
      'Daily Expiration Summary',
      channelDescription: 'Daily food expiration summary',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    ),
    iOS: DarwinNotificationDetails(),
  );
}

// ============================================================
// BACKGROUND SERVICE
// ============================================================

class BackgroundService {
  // ==========================================================
  // INIT
  // ==========================================================

  static Future<void> init() async {
    // WorkManager ไม่รองรับ Flutter Web
    if (kIsWeb) {
      debugPrint(
        'BackgroundService: '
        'Web detected - WorkManager skipped.',
      );

      return;
    }

    try {
      await Workmanager().initialize(
        backgroundDispatcher,
        isInDebugMode: false,
      );

      debugPrint(
        'BackgroundService: '
        'WorkManager initialized.',
      );
    } catch (e) {
      debugPrint(
        'BackgroundService: '
        'initialize failed: $e',
      );
    }
  }

  static Future<void> testDailyCheckNow() async {
    await Workmanager().registerOneOffTask(
      'daily_expiry_check_test',
      _dailyCheckTask,
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  // ==========================================================
  // SCHEDULE DAILY CHECK
  // ==========================================================

  static Future<void> scheduleDailyCheck() async {
    if (kIsWeb) {
      debugPrint(
        'BackgroundService: '
        'Web detected - schedule skipped.',
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
    // ให้เริ่มรอบถัดไปพรุ่งนี้ 09:00
    if (!now.isBefore(next9am)) {
      next9am = next9am.add(
        const Duration(
          days: 1,
        ),
      );
    }

    final initialDelay = next9am.difference(now);

    debugPrint(
      'BackgroundService: '
      'Next daily check: $next9am',
    );

    try {
      await Workmanager().registerPeriodicTask(
        _dailyCheckTask,
        _dailyCheckTask,
        frequency: const Duration(
          hours: 24,
        ),
        initialDelay: initialDelay,
        constraints: Constraints(
          networkType: NetworkType.notRequired,
          requiresBatteryNotLow: false,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );

      debugPrint(
        'BackgroundService: '
        'Daily check scheduled.',
      );
    } catch (e) {
      debugPrint(
        'BackgroundService: '
        'schedule failed: $e',
      );
    }
  }

  // ==========================================================
  // CANCEL
  // ==========================================================

  static Future<void> cancel() async {
    if (kIsWeb) {
      debugPrint(
        'BackgroundService: '
        'Web detected - cancel skipped.',
      );

      return;
    }

    try {
      await Workmanager().cancelByUniqueName(
        _dailyCheckTask,
      );

      debugPrint(
        'BackgroundService: '
        'Daily check cancelled.',
      );
    } catch (e) {
      debugPrint(
        'BackgroundService: '
        'cancel failed: $e',
      );
    }
  }
}
