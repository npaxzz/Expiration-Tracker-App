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
    if (_initialized) return;

    tz.initializeTimeZones();

    // เปิด settings box
    if (!Hive.isBoxOpen(_settingsBoxName)) {
      await Hive.openBox(_settingsBoxName);
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  // ============================================================
  // SETTINGS
  // ============================================================

  static Box get _settingsBox {
    return Hive.box(_settingsBoxName);
  }

  /// เปิด/ปิด notification ทั้งหมด
  static bool get notificationsEnabled {
    return _settingsBox.get(
      _notificationsEnabledKey,
      defaultValue: true,
    ) as bool;
  }

  /// เปิด/ปิด Daily Summary
  static bool get dailyReminder {
    return _settingsBox.get(
      _dailyReminderKey,
      defaultValue: true,
    ) as bool;
  }

  /// จำนวนวันที่ต้องการแจ้งก่อนหมดอายุ
  static int get alertDaysBefore {
    return _settingsBox.get(
      _alertDaysBeforeKey,
      defaultValue: 3,
    ) as int;
  }

  static Future<void> setNotificationsEnabled(
    bool value,
  ) async {
    await _settingsBox.put(
      _notificationsEnabledKey,
      value,
    );

    if (!value) {
      await cancelAll();
    }
  }

  static Future<void> setDailyReminder(
    bool value,
  ) async {
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

  static Future<void> setAlertDaysBefore(
    int value,
  ) async {
    final days = value.clamp(1, 7);

    await _settingsBox.put(
      _alertDaysBeforeKey,
      days,
    );
  }

  // ============================================================
  // NOTIFICATION DETAILS
  // ============================================================

  static const NotificationDetails _expiryDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'expiry_channel',
      'Expiry Alerts',
      channelDescription: 'Alerts for expiring food items',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    ),
    iOS: DarwinNotificationDetails(),
  );

  static const NotificationDetails _dailyDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'daily_summary_channel',
      'Daily Expiration Summary',
      channelDescription: 'Daily reminder for food expiration',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    ),
    iOS: DarwinNotificationDetails(),
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
  // SCHEDULE ITEM EXPIRY
  // ============================================================

  static Future<void> scheduleExpiryAlert({
    required FoodItem item,
    int? daysBefore,
  }) async {
    if (!notificationsEnabled) {
      return;
    }

    final days = daysBefore ?? alertDaysBefore;

    final alertDate = item.expirationDate.subtract(
      Duration(days: days),
    );

    final now = DateTime.now();

    // ถ้าถึงเวลาที่ควรแจ้งไปแล้ว
    // ไม่ต้อง schedule ย้อนหลัง
    if (!alertDate.isAfter(now)) {
      return;
    }

    final scheduledTime = tz.TZDateTime.from(
      alertDate,
      tz.local,
    );

    await _plugin.zonedSchedule(
      item.id.hashCode,
      days == 0
          ? '⚠️ ${item.name} expires today!'
          : '🔔 ${item.name} expires in '
              '$days day${days > 1 ? 's' : ''}',
      'Check your fridge — ${item.category.displayName}',
      scheduledTime,
      _expiryDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ============================================================
  // CANCEL ITEM
  // ============================================================

  static Future<void> cancelForItem(
    String itemId,
  ) async {
    await _plugin.cancel(
      itemId.hashCode,
    );
  }

  // ============================================================
  // CANCEL ALL
  // ============================================================

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ============================================================
  // CHECK EXPIRATION
  // ============================================================

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

      // --------------------------------------------------------
      // EXPIRED
      // --------------------------------------------------------

      if (days < 0) {
        await showNow(
          id: item.id.hashCode,
          title: '❌ ${item.name} has expired!',
          body: 'Please check and remove it from your fridge.',
        );
      }

      // --------------------------------------------------------
      // EXPIRES TODAY
      // --------------------------------------------------------

      else if (days == 0) {
        await showNow(
          id: item.id.hashCode,
          title: '⚠️ ${item.name} expires today!',
          body: 'Use it before it\'s too late.',
        );
      }

      // --------------------------------------------------------
      // EXPIRING SOON
      // --------------------------------------------------------

      else if (days <= daysBefore) {
        await showNow(
          id: item.id.hashCode,
          title: '🔔 ${item.name} expires in '
              '$days day${days > 1 ? 's' : ''}',
          body: item.category.displayName,
        );
      }

      // --------------------------------------------------------
      // SCHEDULE FUTURE ALERT
      // --------------------------------------------------------

      await scheduleExpiryAlert(
        item: item,
        daysBefore: daysBefore,
      );
    }
  }

  // ============================================================
  // DAILY 9 AM SUMMARY
  // ============================================================

  static const int dailySummaryNotificationId = 9001;

  static Future<void> scheduleDailySummary() async {
    if (!notificationsEnabled || !dailyReminder) {
      await cancelDailySummary();
      return;
    }

    // ยกเลิกของเดิมก่อน
    await cancelDailySummary();

    final now = tz.TZDateTime.now(
      tz.local,
    );

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      9,
      0,
    );

    // ถ้าเลย 09:00 แล้ว
    // ตั้งเป็นพรุ่งนี้ 09:00
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(
        const Duration(days: 1),
      );
    }

    await _plugin.zonedSchedule(
      dailySummaryNotificationId,
      '🔔 Expiration Tracker',
      'Check your fridge for food that is expiring.',
      scheduled,
      _dailyDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelDailySummary() async {
    await _plugin.cancel(
      dailySummaryNotificationId,
    );
  }
}
