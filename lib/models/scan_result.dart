import 'food_item.dart';

/// Result from AI processing (OCR + Image Classification)
class ScanResult {
  final String? detectedName; // from OCR or image label
  final FoodCategory? detectedCategory; // from Image Classification
  final DateTime? detectedExpiry; // from OCR
  final bool expiryFromOCR; // true = OCR found it, false = used default
  final String? imagePath;
  final double? categoryConfidence; // 0.0 - 1.0

  ScanResult({
    this.detectedName,
    this.detectedCategory,
    this.detectedExpiry,
    this.expiryFromOCR = false,
    this.imagePath,
    this.categoryConfidence,
  });
}
