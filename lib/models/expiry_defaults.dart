import 'food_item.dart';

/// Default shelf life (days) per category
/// Used when AI/OCR cannot detect expiry date from label
class ExpiryDefaults {
  static const Map<FoodCategory, int> shelfLife = {
    FoodCategory.fruitsVegetables: 14,
    FoodCategory.eggsDairy: 14,
    FoodCategory.meatFrozen: 180,
    FoodCategory.dryFood: 510,
    FoodCategory.cannedBottled: 730,
    FoodCategory.bakerySnacks: 5,
  };

  static DateTime getDefaultDate(FoodCategory category) {
    final days = shelfLife[category] ?? 7;
    return DateTime.now().add(Duration(days: days));
  }
}
