import 'expiry_defaults.dart';
import 'food_item.dart';
import 'scan_result.dart';

/// OCR + Image Classification Service — Placeholder
/// TODO: เชื่อม model จริงใน runOCR() และ runImageClassification()
class AiService {
  /// OCR: อ่านวันหมดอายุจากรูปฉลาก
  static Future<DateTime?> runOCR(String imagePath) async {
    await Future.delayed(const Duration(seconds: 2));
    return null; // TODO: return DateTime จาก model จริง
  }

  /// Image Classification: แยกหมวดหมู่จากรูปสินค้า
  static Future<AiClassificationResult> runImageClassification(
      String imagePath) async {
    await Future.delayed(const Duration(seconds: 2));
    return const AiClassificationResult(
      category: FoodCategory.dryFood,
      productName: 'Detected Product',
    );
  }

  /// รวม OCR + Image Classification
  static Future<ScanResult> analyze({
    String? labelImagePath,
    required String productImagePath,
  }) async {
    final results = await Future.wait([
      if (labelImagePath != null)
        runOCR(labelImagePath)
      else
        Future.value(null),
      runImageClassification(productImagePath),
    ]);

    final expiryDate = results[0] as DateTime?;
    final classification = results[1] as AiClassificationResult;
    final category = classification.category;

    return ScanResult(
      productName: classification.productName,
      category: category,
      expirationDate: expiryDate ?? ExpiryDefaults.getDefaultDate(category),
      ocrFoundDate: expiryDate != null,
      confidence: 0.8,
    );
  }
}

class AiClassificationResult {
  final FoodCategory category;
  final String productName;

  const AiClassificationResult({
    required this.category,
    required this.productName,
  });
}
