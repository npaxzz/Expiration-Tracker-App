import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'food_item.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// helper — copy รูปไปเก็บถาวรใน app directory
Future<String?> _saveImagePermanently(String? tempPath) async {
  if (tempPath == null) return null;
  if (kIsWeb) return tempPath; // Web ยังไม่รองรับ

  try {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'food_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedPath = p.join(appDir.path, fileName);
    await File(tempPath).copy(savedPath);
    return savedPath;
  } catch (e) {
    return null;
  }
}

class FoodProvider extends ChangeNotifier {
  List<FoodItem> _items = [];
  static const String _storageKey = 'food_items';
  final _uuid = const Uuid();

  List<FoodItem> get items => List.unmodifiable(_items);

  int get totalItems => _items.length;

  int get expiringSoonCount =>
      _items.where((item) => item.isExpiringSoon || item.isExpired).length;

  List<FoodItem> getByCategory(FoodCategory category) =>
      _items.where((item) => item.category == category).toList()
        ..sort((a, b) => a.expirationDate.compareTo(b.expirationDate));

  List<FoodItem> get expiredItems =>
      _items.where((item) => item.isExpired).toList()
        ..sort((a, b) => a.expirationDate.compareTo(b.expirationDate));

  List<FoodItem> get expiringSoonItems =>
      _items.where((item) => item.isExpiringSoon).toList()
        ..sort((a, b) => a.expirationDate.compareTo(b.expirationDate));

  List<FoodItem> get allSorted => List.from(_items)
    ..sort((a, b) => a.expirationDate.compareTo(b.expirationDate));

  FoodProvider() {
    _loadFromStorage();
    _addSampleData();
  }

  void _addSampleData() {
    if (_items.isEmpty) {
      final now = DateTime.now();
      _items = [
        FoodItem(
          id: _uuid.v4(),
          name: 'Organic Milk',
          category: FoodCategory.eggsDairy,
          expirationDate: now.add(const Duration(days: 2)),
          quantity: 1,
        ),
        FoodItem(
          id: _uuid.v4(),
          name: 'Greek Yogurt',
          category: FoodCategory.eggsDairy,
          expirationDate: now.add(const Duration(days: 5)),
          quantity: 2,
        ),
        FoodItem(
          id: _uuid.v4(),
          name: 'Baby Spinach',
          category: FoodCategory.fruitsVegetables,
          expirationDate: now.add(const Duration(days: 1)),
          quantity: 1,
        ),
        FoodItem(
          id: _uuid.v4(),
          name: 'Chicken Breast',
          category: FoodCategory.meatFrozen,
          expirationDate: now.subtract(const Duration(days: 1)),
          quantity: 3,
        ),
        FoodItem(
          id: _uuid.v4(),
          name: 'Sourdough Bread',
          category: FoodCategory.bakerySnacks,
          expirationDate: now.add(const Duration(days: 3)),
          quantity: 1,
        ),
        FoodItem(
          id: _uuid.v4(),
          name: 'Cheddar Cheese',
          category: FoodCategory.eggsDairy,
          expirationDate: now.add(const Duration(days: 14)),
          quantity: 1,
        ),
        FoodItem(
          id: _uuid.v4(),
          name: 'Strawberries',
          category: FoodCategory.fruitsVegetables,
          expirationDate: now.add(const Duration(days: 4)),
          quantity: 1,
        ),
        FoodItem(
          id: _uuid.v4(),
          name: 'Pasta',
          category: FoodCategory.dryFood,
          expirationDate: now.add(const Duration(days: 180)),
          quantity: 2,
        ),
        FoodItem(
          id: _uuid.v4(),
          name: 'Tomato Sauce',
          category: FoodCategory.cannedBottled,
          expirationDate: now.add(const Duration(days: 365)),
          quantity: 3,
        ),
        FoodItem(
          id: _uuid.v4(),
          name: 'Eggs',
          category: FoodCategory.eggsDairy,
          expirationDate: now.add(const Duration(days: 21)),
          quantity: 12,
        ),
      ];
      _saveToStorage();
    }
  }

  Future<void> addItem({
    required String name,
    required FoodCategory category,
    required DateTime expirationDate,
    int quantity = 1,
    String? notes,
    String? imagePath,
  }) async {
    final permanentPath = await _saveImagePermanently(imagePath);
    final item = FoodItem(
      id: _uuid.v4(),
      name: name,
      category: category,
      expirationDate: expirationDate,
      quantity: quantity,
      notes: notes,
      imagePath: permanentPath,
    );
    _items.add(item);
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> updateItem(FoodItem updated) async {
    final index = _items.indexWhere((item) => item.id == updated.id);
    if (index != -1) {
      _items[index] = updated;
      await _saveToStorage();
      notifyListeners();
    }
  }

  Future<void> deleteItem(String id) async {
    _items.removeWhere((item) => item.id == id);
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _items.map((item) => jsonEncode(item.toMap())).toList();
    await prefs.setStringList(_storageKey, data);
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_storageKey);
    if (data != null) {
      _items = data.map((str) => FoodItem.fromMap(jsonDecode(str))).toList();
      notifyListeners();
    }
  }
}
