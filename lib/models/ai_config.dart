/// ============================================
/// AI Config
/// ============================================

enum AiMode {
  /// ใช้ OCR + Image Classification model ที่เทรนเอง
  /// ต้องการรูป 2 รูป (ฉลาก + สินค้า)
  ocrAndClassification,

  /// ใช้ Gemini Vision (VLM)
  /// ใช้รูป ได้ทั้ง ชื่อ + หมวดหมู่ + วันหมดอายุ
  geminiVision,
}

class AiConfig {
  static const AiMode mode = AiMode.geminiVision;

  // static const AiMode mode = AiMode.ocrAndClassification;

  // ======================================================

  /// Gemini API Key
  static const String geminiApiKey = 'YOUR_API_KEY';

  /// Gemini model
  static const String geminiModel = 'gemini-2.5-flash';

  /// true = ใช้ VLM, false = ใช้ OCR + Image Class
  static bool get useVlm => mode == AiMode.geminiVision;
}
