import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'food_item.dart';
import '../localization/app_language.dart';

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

    // ----------------------------------------------------------
    // HIVE SETTINGS
    // ----------------------------------------------------------

    if (!Hive.isBoxOpen(_settingsBoxName)) {
      await Hive.openBox(_settingsBoxName);
    }

    // ----------------------------------------------------------
    // NOTIFICATION PLUGIN
    // ----------------------------------------------------------

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(),
    );

    await _plugin.initialize(
      initializationSettings,
    );

    // ----------------------------------------------------------
    // ANDROID 13+
    // ----------------------------------------------------------

    final androidImplementation = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.requestNotificationsPermission();

    _initialized = true;
  }

  // ============================================================
  // SETTINGS BOX
  // ============================================================

  static Box get _settingsBox {
    if (!Hive.isBoxOpen(_settingsBoxName)) {
      throw Exception(
        'Settings box is not open',
      );
    }

    return Hive.box(
      _settingsBoxName,
    );
  }

  // ============================================================
  // SETTINGS GETTERS
  // ============================================================

  /// Master notification switch
  static bool get notificationsEnabled {
    return _settingsBox.get(
      _notificationsEnabledKey,
      defaultValue: true,
    ) as bool;
  }

  /// Daily 09:00 background reminder
  static bool get dailyReminder {
    return _settingsBox.get(
      _dailyReminderKey,
      defaultValue: true,
    ) as bool;
  }

  /// Number of days before expiration
  /// used by Daily Reminder
  static int get alertDaysBefore {
    return _settingsBox.get(
      _alertDaysBeforeKey,
      defaultValue: 3,
    ) as int;
  }

  // ============================================================
  // SET NOTIFICATIONS ENABLED
  // ============================================================

  static Future<void> setNotificationsEnabled(
    bool value,
  ) async {
    await _settingsBox.put(
      _notificationsEnabledKey,
      value,
    );

    // ถ้าปิด notification
    // ยกเลิก notification ที่ค้างอยู่ทั้งหมด
    if (!value) {
      await cancelAll();
    }
  }

  // ============================================================
  // SET DAILY REMINDER
  // ============================================================

  /// Daily Reminder ไม่ได้สร้าง scheduled notification เอง
  ///
  /// BackgroundService จะเป็นผู้ตรวจ Hive
  /// และสร้าง Daily Summary ทุกวันเวลา 09:00
  static Future<void> setDailyReminder(
    bool value,
  ) async {
    await _settingsBox.put(
      _dailyReminderKey,
      value,
    );

    // ถ้าปิด Daily Reminder
    // ยกเลิก notification ID เดิมจากระบบเก่า
    if (!value) {
      await cancelDailySummary();
    }
  }

  // ============================================================
  // SET ALERT DAYS BEFORE
  // ============================================================

  static Future<void> setAlertDaysBefore(
    int days,
  ) async {
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
    icon: '@mipmap/ic_launcher',
  );

  static const NotificationDetails _expiryDetails = NotificationDetails(
    android: _expiryAndroidDetails,
    iOS: DarwinNotificationDetails(),
  );

  // ============================================================
  // DAILY SUMMARY DETAILS
  // ============================================================

  static const AndroidNotificationDetails _dailyAndroidDetails =
      AndroidNotificationDetails(
    'daily_expiration_summary',
    'Daily Expiration Summary',
    channelDescription: 'Daily food expiration summary',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    icon: '@mipmap/ic_launcher',
  );

  static const NotificationDetails _dailyDetails = NotificationDetails(
    android: _dailyAndroidDetails,
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
  // APP OPEN NOTIFICATION
  // ============================================================

  /// เรียกตอนเปิดแอป
  ///
  /// แจ้งเฉพาะรายการที่หมดอายุวันนี้
  ///
  /// ถ้ามีหลายรายการ จะรวมเป็น 1 notification
  ///
  /// ไม่แจ้ง:
  /// - รายการที่หมดอายุไปแล้ว
  /// - รายการที่ใกล้หมดอายุ
  /// - รายการที่หมดอายุในวันอื่น
  static Future<void> checkAndNotifyExpiredToday(
    List<FoodItem> items,
  ) async {
    if (!notificationsEnabled) {
      return;
    }

    final expiringToday = items
        .where(
          (item) => item.daysUntilExpiration == 0,
        )
        .toList();

    if (expiringToday.isEmpty) {
      return;
    }

    final names = expiringToday
        .map(
          (item) => item.name,
        )
        .join(', ');

    final isThai = AppLanguage.currentLanguageCode == 'th';

    final title = isThai
        ? '⚠️ หมดอายุวันนี้ ${expiringToday.length} รายการ'
        : '⚠️ ${expiringToday.length} '
            'item${expiringToday.length > 1 ? 's' : ''} '
            'expire today';

    await showNow(
      id: 1000,
      title: title,
      body: names,
    );
  }

  // ============================================================
  // CANCEL ALL
  // ============================================================

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ============================================================
  // CANCEL DAILY SUMMARY
  // ============================================================

  /// ยกเลิก notification 9001
  ///
  /// ใช้สำหรับล้าง scheduled notification
  /// ที่สร้างจากระบบเวอร์ชันเก่า
  static Future<void> cancelDailySummary() async {
    await _plugin.cancel(
      9001,
    );
  }

  // ============================================================
  // DAILY SUMMARY DETAILS
  // ============================================================

  /// ใช้โดย BackgroundService
  ///
  /// BackgroundService จะอ่านข้อมูลจาก Hive ใหม่ทุกวัน
  /// แล้วส่งข้อความที่คำนวณจากข้อมูลล่าสุด
  static NotificationDetails get dailyDetails {
    return _dailyDetails;
  }
}
