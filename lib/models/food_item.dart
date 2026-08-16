import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'food_item.g.dart';

enum FoodCategory {
  fruitsVegetables,
  eggsDairy,
  meatFrozen,
  dryFood,
  cannedBottled,
  bakerySnacks,
}

extension FoodCategoryExtension on FoodCategory {
  String get displayName {
    switch (this) {
      case FoodCategory.fruitsVegetables:
        return 'Fruits & Vegetables';
      case FoodCategory.eggsDairy:
        return 'Eggs & Dairy';
      case FoodCategory.meatFrozen:
        return 'Meat & Frozen Food';
      case FoodCategory.dryFood:
        return 'Dry Food';
      case FoodCategory.cannedBottled:
        return 'Canned, Bottled & Condiments';
      case FoodCategory.bakerySnacks:
        return 'Bakery & Snacks';
    }
  }

  String get emoji {
    switch (this) {
      case FoodCategory.fruitsVegetables:
        return '🥦';
      case FoodCategory.eggsDairy:
        return '🥛';
      case FoodCategory.meatFrozen:
        return '🥩';
      case FoodCategory.dryFood:
        return '🌾';
      case FoodCategory.cannedBottled:
        return '🥫';
      case FoodCategory.bakerySnacks:
        return '🥐';
    }
  }

  Color get color {
    switch (this) {
      case FoodCategory.fruitsVegetables:
        return const Color(0xFF4CAF50);
      case FoodCategory.eggsDairy:
        return const Color(0xFFFDD835);
      case FoodCategory.meatFrozen:
        return const Color(0xFFEF5350);
      case FoodCategory.dryFood:
        return const Color(0xFFFF9800);
      case FoodCategory.cannedBottled:
        return const Color(0xFF42A5F5);
      case FoodCategory.bakerySnacks:
        return const Color(0xFFAB47BC);
    }
  }

  Color get lightColor {
    switch (this) {
      case FoodCategory.fruitsVegetables:
        return const Color(0xFFE8F5E9);
      case FoodCategory.eggsDairy:
        return const Color(0xFFFFFDE7);
      case FoodCategory.meatFrozen:
        return const Color(0xFFFFEBEE);
      case FoodCategory.dryFood:
        return const Color(0xFFFFF3E0);
      case FoodCategory.cannedBottled:
        return const Color(0xFFE3F2FD);
      case FoodCategory.bakerySnacks:
        return const Color(0xFFF3E5F5);
    }
  }
}

@HiveType(typeId: 0)
class FoodItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int categoryIndex;

  @HiveField(3)
  DateTime expirationDate;

  @HiveField(4)
  DateTime addedDate;

  @HiveField(5)
  int quantity;

  @HiveField(6)
  String? notes;

  /// สามารถเก็บได้ทั้ง:
  ///
  /// 1. Base64 image
  ///    image_base64:<base64>
  ///
  /// 2. Local file path ของข้อมูลเก่า
  ///
  /// 3. URL ของข้อมูลเก่า
  ///
  String? imagePath;

  FoodItem({
    required this.id,
    required this.name,
    required this.categoryIndex,
    required this.expirationDate,
    DateTime? addedDate,
    this.quantity = 1,
    this.notes,
    this.imagePath,
  }) : addedDate = addedDate ?? DateTime.now();

  FoodCategory get category => FoodCategory.values[categoryIndex];

  set category(FoodCategory c) {
    categoryIndex = c.index;
  }

  int get daysUntilExpiration {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final expiry = DateTime(
      expirationDate.year,
      expirationDate.month,
      expirationDate.day,
    );

    return expiry.difference(today).inDays;
  }

  bool get isExpired => daysUntilExpiration < 0;

  bool get isExpiringSoon =>
      daysUntilExpiration >= 0 && daysUntilExpiration <= 3;

  bool get isExpiringThisWeek =>
      daysUntilExpiration >= 0 && daysUntilExpiration <= 7;

  ExpirationStatus get status {
    if (isExpired) {
      return ExpirationStatus.expired;
    }

    if (isExpiringSoon) {
      return ExpirationStatus.soon;
    }

    if (isExpiringThisWeek) {
      return ExpirationStatus.thisWeek;
    }

    return ExpirationStatus.good;
  }

  FoodItem copyWith({
    String? name,
    FoodCategory? category,
    DateTime? expirationDate,
    int? quantity,
    String? notes,
    String? imagePath,
  }) {
    return FoodItem(
      id: id,
      name: name ?? this.name,
      categoryIndex: category?.index ?? categoryIndex,
      expirationDate: expirationDate ?? this.expirationDate,
      addedDate: addedDate,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

enum ExpirationStatus {
  expired,
  soon,
  thisWeek,
  good,
}

extension ExpirationStatusExtension on ExpirationStatus {
  Color get color {
    switch (this) {
      case ExpirationStatus.expired:
        return const Color(0xFFE53935);

      case ExpirationStatus.soon:
        return const Color(0xFFF57C00);

      case ExpirationStatus.thisWeek:
        return const Color(0xFFFBC02D);

      case ExpirationStatus.good:
        return const Color(0xFF43A047);
    }
  }

  String get label {
    switch (this) {
      case ExpirationStatus.expired:
        return 'Expired';

      case ExpirationStatus.soon:
        return 'Soon';

      case ExpirationStatus.thisWeek:
        return 'This Week';

      case ExpirationStatus.good:
        return 'Fresh';
    }
  }
}
