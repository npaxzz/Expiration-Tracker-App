import 'package:flutter/material.dart';

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
        return const Color(0xFFFFF176).withValues(alpha: 1);
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

class FoodItem {
  final String id;
  String name;
  FoodCategory category;
  DateTime expirationDate;
  DateTime addedDate;
  int quantity;
  String? notes;
  String? imagePath;

  FoodItem({
    required this.id,
    required this.name,
    required this.category,
    required this.expirationDate,
    DateTime? addedDate,
    this.quantity = 1,
    this.notes,
    this.imagePath,
  }) : addedDate = addedDate ?? DateTime.now();

  int get daysUntilExpiration {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
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
    if (isExpired) return ExpirationStatus.expired;
    if (isExpiringSoon) return ExpirationStatus.soon;
    if (isExpiringThisWeek) return ExpirationStatus.thisWeek;
    return ExpirationStatus.good;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category.index,
      'expirationDate': expirationDate.toIso8601String(),
      'addedDate': addedDate.toIso8601String(),
      'quantity': quantity,
      'notes': notes,
      'imagePath': imagePath,
    };
  }

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'],
      name: map['name'],
      category: FoodCategory.values[map['category']],
      expirationDate: DateTime.parse(map['expirationDate']),
      addedDate: DateTime.parse(map['addedDate']),
      quantity: map['quantity'] ?? 1,
      notes: map['notes'],
      imagePath: map['imagePath'],
    );
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
      category: category ?? this.category,
      expirationDate: expirationDate ?? this.expirationDate,
      addedDate: addedDate,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

enum ExpirationStatus { expired, soon, thisWeek, good }

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
