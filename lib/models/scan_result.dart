import 'food_item.dart';

class ScanResult {
  final String productName;
  final FoodCategory category;
  final DateTime expirationDate;
  final bool ocrFoundDate;
  final double confidence;

  const ScanResult({
    required this.productName,
    required this.category,
    required this.expirationDate,
    required this.ocrFoundDate,
    required this.confidence,
  });
}
