import 'food_item.dart';

/// AI Service - Placeholder
/// เมื่อ model พร้อม ให้แก้ไขใน 2 ฟังก์ชันนี้:
///   - runOCR()  → เชื่อม OCR model
///   - runImageClassification() → เชื่อม Image Classification model

class AiService {
  // Default shelf life (days) per category when OCR finds no date
  static const Map<FoodCategory, int> defaultShelfLife = {
    FoodCategory.fruitsVegetables: 5,
    FoodCategory.eggsDairy: 7,
    FoodCategory.meatFrozen: 3,
    FoodCategory.dryFood: 180,
    FoodCategory.cannedBottled: 365,
    FoodCategory.bakerySnacks: 4,
  };

  /// OCR: อ่านวันหมดอายุจากรูปฉลาก
  /// TODO: แทนที่ด้วย API call จริง เมื่อ model พร้อม
  /// Input: imagePath (String) — path หรือ base64
  /// Output: DateTime? — null ถ้าหาไม่เจอ
  static Future<DateTime?> runOCR(String imagePath) async {
    // === PLACEHOLDER ===
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    // Mock: return null เพื่อ simulate ว่า OCR หาวันไม่เจอ
    // เมื่อ model พร้อม ให้ return DateTime จาก response จริง
    return null;
    // === END PLACEHOLDER ===
  }

  /// Image Classification: แยกหมวดหมู่จากรูปสินค้า
  /// TODO: แทนที่ด้วย API call จริงเมื่อ model พร้อม
  /// Input: imagePath (String) — path หรือ base64
  /// Output: AiClassificationResult
  static Future<AiClassificationResult> runImageClassification(
      String imagePath) async {
    // === PLACEHOLDER ===
    await Future.delayed(const Duration(seconds: 2));
    // Mock result — สุ่มหมวดหมู่เพื่อ demo
    const mockCategory = FoodCategory.eggsDairy;
    const mockName = 'Detected Product';
    const mockConfidence = 0.87;
    return const AiClassificationResult(
      category: mockCategory,
      productName: mockName,
      confidence: mockConfidence,
    );
    // === END PLACEHOLDER ===
  }

  /// รวม OCR + Image Classification แล้วคืน ScanResult
  static Future<ScanResult> analyze({
    required String labelImagePath,
    required String productImagePath,
  }) async {
    // Run both in parallel
    final results = await Future.wait([
      runOCR(labelImagePath),
      runImageClassification(productImagePath),
    ]);

    final expiryDate = results[0] as DateTime?;
    final classification = results[1] as AiClassificationResult;

    // If OCR found no date, use default shelf life for detected category
    final fallbackDate = DateTime.now()
        .add(Duration(days: defaultShelfLife[classification.category] ?? 7));

    return ScanResult(
      productName: classification.productName,
      category: classification.category,
      expirationDate: expiryDate ?? fallbackDate,
      ocrFoundDate: expiryDate != null,
      confidence: classification.confidence,
    );
  }
}

class AiClassificationResult {
  final FoodCategory category;
  final String productName;
  final double confidence;

  const AiClassificationResult({
    required this.category,
    required this.productName,
    required this.confidence,
  });
}

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
