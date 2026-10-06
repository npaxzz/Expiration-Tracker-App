import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import 'food_item.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static const String _settingsBoxName = 'app_settings';

  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _dailyReminderKey = 'daily_reminder';
  static const String _alertDaysBeforeKey = 'alert_days_before';

  // ============================================================
  // INIT
  // ============================================================

  static Future<void> init() async {
    if (_initialized) {
      return;
    }

    // Timezone
    tz.initializeTimeZones();

    // Hive settings
    if (!Hive.isBoxOpen(_settingsBoxName)) {
      await Hive.openBox(_settingsBoxName);
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(
      initializationSettings,
    );

    // Android 13+
    final androidImplementation = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.requestNotificationsPermission();

    _initialized = true;
  }

  // ============================================================
  // SETTINGS
  // ============================================================

  static Box get _settingsBox {
    if (!Hive.isBoxOpen(_settingsBoxName)) {
      throw Exception('Settings box is not open');
    }

    return Hive.box(_settingsBoxName);
  }

  static bool get notificationsEnabled {
    return _settingsBox.get(
      _notificationsEnabledKey,
      defaultValue: true,
    ) as bool;
  }

  static bool get dailyReminder {
    return _settingsBox.get(
      _dailyReminderKey,
      defaultValue: true,
    ) as bool;
  }

  static int get alertDaysBefore {
    return _settingsBox.get(
      _alertDaysBeforeKey,
      defaultValue: 3,
    ) as int;
  }

  static Future<void> setNotificationsEnabled(bool value) async {
    await _settingsBox.put(
      _notificationsEnabledKey,
      value,
    );

    if (!value) {
      await cancelAll();
    }
  }

  static Future<void> setDailyReminder(bool value) async {
    await _settingsBox.put(
      _dailyReminderKey,
      value,
    );

    if (value && notificationsEnabled) {
      await scheduleDailySummary();
    } else {
      await cancelDailySummary();
    }
  }

  static Future<void> setAlertDaysBefore(int days) async {
    await _settingsBox.put(
      _alertDaysBeforeKey,
      days,
    );
  }

  // ============================================================
  // NOTIFICATION DETAILS
  // ============================================================

  static const AndroidNotificationDetails _expiryAndroidDetails =
      AndroidNotificationDetails(
    'expiration_alerts',
    'Expiration Alerts',
    channelDescription: 'Food expiration notifications',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const NotificationDetails _expiryDetails = NotificationDetails(
    android: _expiryAndroidDetails,
  );

  static const AndroidNotificationDetails _dailyAndroidDetails =
      AndroidNotificationDetails(
    'daily_expiration_summary',
    'Daily Expiration Summary',
    channelDescription: 'Daily food expiration summary',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  static const NotificationDetails _dailyDetails = NotificationDetails(
    android: _dailyAndroidDetails,
  );

  // ============================================================
  // SHOW NOW
  // ============================================================

  static Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!notificationsEnabled) {
      return;
    }

    await _plugin.show(
      id,
      title,
      body,
      _expiryDetails,
    );
  }

  // ============================================================
  // APP OPEN NOTIFICATION
  // ============================================================

  /// เรียกตอนเปิดแอป
  ///
  /// แจ้งเฉพาะรายการที่ "หมดอายุวันนี้"
  ///
  /// ไม่แจ้ง:
  /// - รายการที่หมดอายุไปแล้ว
  /// - รายการที่ใกล้หมดอายุ
  static Future<void> checkAndNotifyExpiredToday(
    List<FoodItem> items,
  ) async {
    if (!notificationsEnabled) {
      return;
    }

    for (final item in items) {
      if (item.daysUntilExpiration == 0) {
        await showNow(
          id: item.id.hashCode,
          title: '⚠️ ${item.name} expires today!',
          body: 'Use it before it\'s too late.',
        );
      }
    }
  }

  // ============================================================
  // EXPIRY ALERT
  // ============================================================

  static Future<void> scheduleExpiryAlert({
    required FoodItem item,
    int? daysBefore,
  }) async {
    if (!notificationsEnabled) {
      return;
    }

    final days = daysBefore ?? alertDaysBefore;

    final expirationDate = item.expirationDate;

    final scheduledDate = tz.TZDateTime(
      tz.local,
      expirationDate.year,
      expirationDate.month,
      expirationDate.day,
      9,
      0,
    ).subtract(
      Duration(days: days),
    );

    final now = tz.TZDateTime.now(tz.local);

    if (scheduledDate.isBefore(now)) {
      return;
    }

    await _plugin.zonedSchedule(
      item.id.hashCode,
      '🔔 ${item.name} expiration reminder',
      'Expires in $days day${days > 1 ? 's' : ''}.',
      scheduledDate,
      _expiryDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ============================================================
  // CANCEL ITEM NOTIFICATION
  // ============================================================

  static Future<void> cancelForItem(String id) async {
    await _plugin.cancel(
      id.hashCode,
    );
  }

  // ============================================================
  // CANCEL ALL
  // ============================================================

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ============================================================
  // CHECK AND NOTIFY
  // ============================================================

  /// ใช้สำหรับการตรวจแจ้งเตือนตาม threshold
  ///
  /// ฟังก์ชันนี้ยังคงทำงานแบบเดิม:
  /// - หมดอายุแล้ว
  /// - หมดอายุวันนี้
  /// - ใกล้หมดอายุตามจำนวนวันที่ตั้งไว้
  ///
  /// ไม่ควรเรียกฟังก์ชันนี้ตอนเปิดแอป
  static Future<void> checkAndNotify(
    List<FoodItem> items, {
    int? alertDaysBefore,
  }) async {
    if (!notificationsEnabled) {
      return;
    }

    final daysBefore = alertDaysBefore ?? NotificationService.alertDaysBefore;

    for (final item in items) {
      final days = item.daysUntilExpiration;

      if (days < 0) {
        await showNow(
          id: item.id.hashCode,
          title: '❌ ${item.name} has expired!',
          body: 'Please check and remove it from your fridge.',
        );
      } else if (days == 0) {
        await showNow(
          id: item.id.hashCode,
          title: '⚠️ ${item.name} expires today!',
          body: 'Use it before it\'s too late.',
        );
      } else if (days <= daysBefore) {
        await showNow(
          id: item.id.hashCode,
          title: '🔔 ${item.name} expires in '
              '$days day${days > 1 ? 's' : ''}',
          body: item.category.displayName,
        );
      }

      await scheduleExpiryAlert(
        item: item,
        daysBefore: daysBefore,
      );
    }
  }

  // ============================================================
  // DAILY SUMMARY
  // ============================================================

  static Future<void> scheduleDailySummary() async {
    if (!notificationsEnabled || !dailyReminder) {
      return;
    }

    await cancelDailySummary();

    final now = tz.TZDateTime.now(tz.local);

    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      9,
      0,
    );

    if (!scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(
        const Duration(days: 1),
      );
    }

    await _plugin.zonedSchedule(
      9001,
      '⏰ Daily Expiration Reminder',
      'Check your food items that are expiring soon.',
      scheduledDate,
      _dailyDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ============================================================
  // CANCEL DAILY SUMMARY
  // ============================================================

  static Future<void> cancelDailySummary() async {
    await _plugin.cancel(
      9001,
    );
  }
}
