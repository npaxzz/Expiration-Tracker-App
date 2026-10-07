import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import 'food_item.dart';
import 'notification_service.dart';

class FoodProvider extends ChangeNotifier {
  static const String _boxName = 'food_items';
  static const String _settingsBoxName = 'app_settings';

  // Box จะถูกเปิดก่อน runApp()
  late Box<FoodItem> _box;

  final _uuid = const Uuid();

  // ============================================================
  // HIVE INIT
  // ============================================================

  /// เรียกใน main.dart ก่อน runApp()
  ///
  /// ทำหน้าที่:
  /// 1. Init Hive
  /// 2. Register FoodItemAdapter
  /// 3. เปิด food_items box
  static Future<void> initHive() async {
    await Hive.initFlutter();

    // ป้องกัน register adapter ซ้ำ
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(
        FoodItemAdapter(),
      );
    }

    // เปิด box ตั้งแต่ก่อน runApp()
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<FoodItem>(
        _boxName,
      );
    }
  }

  // ============================================================
  // INIT PROVIDER
  // ============================================================

  /// เชื่อมต่อกับ box ที่เปิดไว้แล้ว
  ///
  /// ไม่ต้อง await Hive.openBox() ซ้ำ
  Future<void> init() async {
    if (Hive.isBoxOpen(_boxName)) {
      _box = Hive.box<FoodItem>(
        _boxName,
      );
    } else {
      _box = await Hive.openBox<FoodItem>(
        _boxName,
      );
    }

    // เปิด settings box ด้วย
    // เพื่อให้อ่านค่า alert_days_before ได้
    // เผื่อผู้ใช้ยังไม่เคยเข้าหน้า Settings มาก่อน
    if (!Hive.isBoxOpen(_settingsBoxName)) {
      await Hive.openBox(
        _settingsBoxName,
      );
    }

    // ============================================================
    // OPEN APP NOTIFICATION
    // ============================================================
    //
    // เมื่อเปิดแอป: แจ้งเฉพาะรายการที่หมดอายุวันนี้

    // ถ้ามีหลายรายการหมดอายุวันนี้
    // NotificationService จะรวมเป็น 1 notification

    await NotificationService.checkAndNotifyExpiredToday(
      items,
    );

    notifyListeners();
  }

  // ============================================================
  // SETTINGS
  // ============================================================

  /// จำนวนวันล่วงหน้าที่ผู้ใช้ตั้งค่าไว้ใน Settings
  ///
  /// default = 3 ถ้ายังไม่เคยตั้งค่า
  int get alertDaysBefore {
    if (!Hive.isBoxOpen(_settingsBoxName)) {
      return 3;
    }

    final box = Hive.box(
      _settingsBoxName,
    );

    return box.get(
      'alert_days_before',
      defaultValue: 3,
    ) as int;
  }

  /// เรียกจาก SettingsScreen เมื่อผู้ใช้เปลี่ยนค่า
  /// alert_days_before
  ///
  /// เพื่อให้หน้า Alerts
  /// และหน้าอื่นที่ฟัง FoodProvider rebuild ทันที
  void refreshAlertSettings() {
    notifyListeners();
  }

  // ============================================================
  // GETTERS
  // ============================================================

  List<FoodItem> get items => _box.values.toList();

  int get totalItems => _box.length;

  int get expiringSoonCount {
    return items.where((item) {
      final days = item.daysUntilExpiration;

      return days >= 0 && days <= alertDaysBefore;
    }).length;
  }

  List<FoodItem> getByCategory(
    FoodCategory category,
  ) {
    final result = items
        .where(
          (item) => item.category == category,
        )
        .toList();

    result.sort(
      (a, b) => a.expirationDate.compareTo(
        b.expirationDate,
      ),
    );

    return result;
  }

  List<FoodItem> get expiredItems {
    final result = items
        .where(
          (item) => item.isExpired,
        )
        .toList();

    result.sort(
      (a, b) => a.expirationDate.compareTo(
        b.expirationDate,
      ),
    );

    return result;
  }

  /// ของที่ "กำลังจะหมดอายุ"
  /// ตาม threshold ที่ผู้ใช้ตั้งไว้ใน Settings
  ///
  /// ใช้สำหรับหน้า Alerts / UI
  ///
  /// Daily Background Notification
  /// จะคำนวณข้อมูลจาก Hive โดยตรงอีกครั้ง
  /// เพื่อให้ได้ข้อมูลล่าสุด
  List<FoodItem> get expiringSoonItems {
    final threshold = alertDaysBefore;

    final result = items.where((item) {
      final days = item.daysUntilExpiration;

      return days >= 0 && days <= threshold;
    }).toList();

    result.sort(
      (a, b) => a.expirationDate.compareTo(
        b.expirationDate,
      ),
    );

    return result;
  }

  List<FoodItem> get allSorted {
    final result = List<FoodItem>.from(
      items,
    );

    result.sort(
      (a, b) => a.expirationDate.compareTo(
        b.expirationDate,
      ),
    );

    return result;
  }

  // ============================================================
  // ADD ITEM
  // ============================================================

  Future<void> addItem({
    required String name,
    required FoodCategory category,
    required DateTime expirationDate,
    int quantity = 1,
    String? notes,
    String? imagePath,
  }) async {
    final item = FoodItem(
      id: _uuid.v4(),
      name: name,
      categoryIndex: category.index,
      expirationDate: expirationDate,
      quantity: quantity,
      notes: notes,
      imagePath: imagePath,
    );

    await _box.put(
      item.id,
      item,
    );

    notifyListeners();
  }

  // ============================================================
  // UPDATE ITEM
  // ============================================================

  Future<void> updateItem(
    FoodItem updated,
  ) async {
    await _box.put(
      updated.id,
      updated,
    );

    notifyListeners();
  }

  // ============================================================
  // DELETE ITEM
  // ============================================================

  Future<void> deleteItem(
    String id,
  ) async {
    await _box.delete(
      id,
    );

    notifyListeners();
  }

  // ============================================================
  // CHECK EXPIRATION
  // ============================================================

  /// ระบบ notification หลักมี 2 จุด:
  ///
  /// 1. เปิดแอป
  ///    -> checkAndNotifyExpiredToday()
  ///    -> แจ้งเฉพาะหมดอายุวันนี้
  ///
  /// 2. BackgroundService
  ///    -> ตรวจทุกวัน
  ///    -> ใช้ Alert Days Before
  ///    -> รวมเป็น Daily Summary 1 notification
  ///

  Future<void> checkExpiryAndNotify({
    int? alertDaysBefore,
  }) async {
    return;
  }
}
