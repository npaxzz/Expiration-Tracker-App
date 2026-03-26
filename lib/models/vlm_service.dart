import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'ai_config.dart';
import 'expiry_defaults.dart';
import 'food_item.dart';
import 'scan_result.dart';

/// Gemini Vision Service
/// ส่ง 2 รูป (ฉลาก + สินค้า) → ได้ ชื่อสินค้า + หมวดหมู่ + วันหมดอายุ
class VlmService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// วิเคราะห์ด้วย Gemini Vision โดยใช้ 2 รูป
  static Future<ScanResult> analyze({
    required String labelImagePath,
    required String productImagePath,
  }) async {
    final labelBase64 = await _imageToBase64(labelImagePath);
    final productBase64 = await _imageToBase64(productImagePath);
    final response = await _callGeminiWithRetry(
      labelBase64: labelBase64,
      productBase64: productBase64,
    );
    return _parseResponse(response);
  }

  static Future<String> _imageToBase64(String imagePath) async {
    if (kIsWeb) {
      final response = await http.get(Uri.parse(imagePath));
      return base64Encode(response.bodyBytes);
    } else {
      final bytes = await File(imagePath).readAsBytes();
      return base64Encode(bytes);
    }
  }

  static Future<Map<String, dynamic>> _callGemini({
    required String labelBase64,
    required String productBase64,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/${AiConfig.geminiModel}:generateContent?key=${AiConfig.geminiApiKey}',
    );

    const prompt = '''
You are an AI that extracts structured data from 1 or 2 product images.

Return ONLY a valid JSON object.
- No explanation
- No markdown
- No extra text
- No trailing commas
- All strings must be properly escaped (valid JSON)

JSON format:
{
  "product_name": string (max 30 characters),
  "category": one of ["fruits_vegetables", "eggs_dairy", "meat_frozen", "dry_food", "canned_bottled", "bakery_snacks"],
  "expiry_date": "YYYY-MM-DD" or null,
}

Instructions:
- Use Image 1 (label) to find expiry date (EXP, BB, Best Before, หมดอายุ, etc.)
- Use Image 2 (product photo) to identify product name and category
- Combine both images if needed
- If expiry date is not clearly visible, return null
- Keep product_name concise and clean (no symbols, no line breaks)
- Ensure the JSON is syntactically correct
''';

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': labelBase64,
              }
            },
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': productBase64,
              }
            },
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.1,
        'maxOutputTokens': 1024,
      }
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    //print('Status code: ${response.statusCode}');
    //print('Response: ${response.body}');

    if (response.statusCode == 429) {
      throw Exception(
          'API rate limit reached. Please wait a moment and try again');
    }
    if (response.statusCode == 400) {
      throw Exception(
          'Invalid request. Please check your images and try again.');
    }
    if (response.statusCode == 403) {
      throw Exception(
          'Invalid API key. Please check your Gemini API key in ai_config.dart');
    }
    if (response.statusCode != 200) {
      throw Exception(
          'Gemini API error (${response.statusCode}). Please try again.');
    }

    final data = jsonDecode(response.body);
    if (data['candidates'] == null ||
        data['candidates'].isEmpty ||
        data['candidates'][0]['content'] == null) {
      throw Exception('Invalid Gemini response format');
    }

    final text = data['candidates'][0]['content']['parts'][0]['text'] as String;

    print('### Gemini raw text:\n$text');
    if (!text.trim().endsWith('}')) {
      throw Exception('Incomplete JSON response');
    }

    return _safeParse(text);
  }

  static Future<Map<String, dynamic>> _callGeminiWithRetry({
    required String labelBase64,
    required String productBase64,
    int retry = 1,
  }) async {
    try {
      return await _callGemini(
        labelBase64: labelBase64,
        productBase64: productBase64,
      );
    } catch (e) {
      if (retry > 0) {
        print('### Retrying Gemini...');
        await Future.delayed(const Duration(seconds: 2));
        return _callGeminiWithRetry(
          labelBase64: labelBase64,
          productBase64: productBase64,
          retry: retry - 1,
        );
      }
      rethrow;
    }
  }

  static Map<String, dynamic> _safeParse(String text) {
    try {
      final trimmed = text.trim();

      final start = trimmed.indexOf('{');
      final end = trimmed.lastIndexOf('}') + 1;

      if (start == -1 || end <= start) {
        throw Exception('No valid JSON found');
      }

      final clean = trimmed.substring(start, end);

      return jsonDecode(clean) as Map<String, dynamic>;
    } catch (e) {
      print('### JSON parse error: $e');
      print('### Raw text: $text');

      return {
        "product_name": "Unknown Product",
        "category": "dry_food",
        "expiry_date": null,
        "confidence": 0.0
      };
    }
  }

  static ScanResult _parseResponse(Map<String, dynamic> data) {
    final productName = (data['product_name'] as String?) ?? 'Unknown Product';
    final categoryStr = (data['category'] as String?) ?? 'dry_food';
    final expiryStr = data['expiry_date'] as String?;
    final confidence = (data['confidence'] as num?)?.toDouble() ?? 0.8;

    final category = _parseCategory(categoryStr);
    final expiryDate = _parseDate(expiryStr, category);

    return ScanResult(
      productName: productName,
      category: category,
      expirationDate: expiryDate,
      ocrFoundDate: expiryStr != null,
      confidence: confidence,
    );
  }

  static FoodCategory _parseCategory(String s) {
    switch (s) {
      case 'fruits_vegetables':
        return FoodCategory.fruitsVegetables;
      case 'eggs_dairy':
        return FoodCategory.eggsDairy;
      case 'meat_frozen':
        return FoodCategory.meatFrozen;
      case 'dry_food':
        return FoodCategory.dryFood;
      case 'canned_bottled':
        return FoodCategory.cannedBottled;
      case 'bakery_snacks':
        return FoodCategory.bakerySnacks;
      default:
        return FoodCategory.dryFood;
    }
  }

  static DateTime _parseDate(String? dateStr, FoodCategory category) {
    if (dateStr != null) {
      try {
        return DateTime.parse(dateStr);
      } catch (_) {}
    }
    return ExpiryDefaults.getDefaultDate(category);
  }

  static ScanResult _fallbackResult() {
    return ScanResult(
      productName: 'Unknown Product',
      category: FoodCategory.dryFood,
      expirationDate: DateTime.now().add(const Duration(days: 7)),
      ocrFoundDate: false,
      confidence: 0.0,
    );
  }
}
