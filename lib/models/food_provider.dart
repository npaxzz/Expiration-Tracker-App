import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import 'food_item.dart';
import 'notification_service.dart';

class FoodProvider extends ChangeNotifier {
  static const String _boxName = 'food_items';

  // Box จะถูกเปิดก่อน runApp()
  late Box<FoodItem> _box;

  final _uuid = const Uuid();

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
      Hive.registerAdapter(FoodItemAdapter());
    }

    // เปิด box ตั้งแต่ก่อน runApp()
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<FoodItem>(_boxName);
    }
  }

  /// เชื่อมต่อกับ box ที่เปิดไว้แล้ว
  ///
  /// ไม่ต้อง await Hive.openBox() ซ้ำ
  Future<void> init() async {
    if (Hive.isBoxOpen(_boxName)) {
      _box = Hive.box<FoodItem>(_boxName);
    } else {
      _box = await Hive.openBox<FoodItem>(_boxName);
    }

    // เช็ควันหมดอายุทุกครั้งที่เปิดแอป
    await NotificationService.checkAndNotify(items);

    notifyListeners();
  }

  // ============================================================
  // GETTERS
  // ============================================================

  List<FoodItem> get items => _box.values.toList();

  int get totalItems => _box.length;

  int get expiringSoonCount =>
      items.where((item) => item.isExpiringSoon || item.isExpired).length;

  List<FoodItem> getByCategory(FoodCategory category) {
    final result = items.where((item) => item.category == category).toList();

    result.sort(
      (a, b) => a.expirationDate.compareTo(b.expirationDate),
    );

    return result;
  }

  List<FoodItem> get expiredItems {
    final result = items.where((item) => item.isExpired).toList();

    result.sort(
      (a, b) => a.expirationDate.compareTo(b.expirationDate),
    );

    return result;
  }

  List<FoodItem> get expiringSoonItems {
    final result = items.where((item) => item.isExpiringSoon).toList();

    result.sort(
      (a, b) => a.expirationDate.compareTo(b.expirationDate),
    );

    return result;
  }

  List<FoodItem> get allSorted {
    final result = List<FoodItem>.from(items);

    result.sort(
      (a, b) => a.expirationDate.compareTo(b.expirationDate),
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

    await _box.put(item.id, item);

    // Schedule notification สำหรับ item ใหม่
    await NotificationService.scheduleExpiryAlert(
      item: item,
      daysBefore: 3,
    );

    notifyListeners();
  }

  // ============================================================
  // UPDATE ITEM
  // ============================================================

  Future<void> updateItem(FoodItem updated) async {
    await _box.put(updated.id, updated);

    // ยกเลิก notification เดิม
    await NotificationService.cancelForItem(updated.id);

    // สร้าง notification ใหม่
    await NotificationService.scheduleExpiryAlert(
      item: updated,
      daysBefore: 3,
    );

    notifyListeners();
  }

  // ============================================================
  // DELETE ITEM
  // ============================================================

  Future<void> deleteItem(String id) async {
    await _box.delete(id);

    // ยกเลิก notification
    await NotificationService.cancelForItem(id);

    notifyListeners();
  }

  // ============================================================
  // CHECK EXPIRATION
  // ============================================================

  Future<void> checkExpiryAndNotify({
    int alertDaysBefore = 3,
  }) async {
    await NotificationService.checkAndNotify(
      items,
      alertDaysBefore: alertDaysBefore,
    );
  }
}
