import 'food_item.dart';

/// Default shelf life (days) per category
/// Used when OCR cannot detect expiration date
class ExpiryDefaults {
  static const Map<FoodCategory, int> defaultDays = {
    FoodCategory.fruitsVegetables: 5,
    FoodCategory.eggsDairy: 7,
    FoodCategory.meatFrozen: 3,
    FoodCategory.dryFood: 180,
    FoodCategory.cannedBottled: 365,
    FoodCategory.bakerySnacks: 5,
  };

  static DateTime getDefaultExpiry(FoodCategory category) {
    final days = defaultDays[category] ?? 7;
    return DateTime.now().add(Duration(days: days));
  }

  static String getDefaultDescription(FoodCategory category) {
    final days = defaultDays[category] ?? 7;
    return 'Default: ~$days days (no label detected)';
  }
}
