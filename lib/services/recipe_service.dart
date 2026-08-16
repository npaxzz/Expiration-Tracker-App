import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

import '../models/food_item.dart';
import '../models/ai_config.dart';
import '../models/recipe_cache.dart';

class RecipeRateLimitException implements Exception {
  final String message;

  const RecipeRateLimitException([
    this.message = 'Recipe service is temporarily busy.',
  ]);

  @override
  String toString() => message;
}

class RecipeRecommendation {
  final String title;
  final String description;
  final List<String> usedIngredients;
  final List<String> missingIngredients;
  final String instructions;
  final int expiringIngredientsUsed;

  const RecipeRecommendation({
    required this.title,
    required this.description,
    required this.usedIngredients,
    required this.missingIngredients,
    required this.instructions,
    required this.expiringIngredientsUsed,
  });

  factory RecipeRecommendation.fromJson(
    Map<String, dynamic> json,
  ) {
    return RecipeRecommendation(
      title: json['title'] ?? 'Unknown Recipe',
      description: json['description'] ?? '',
      usedIngredients: List<String>.from(
        json['used_ingredients'] ?? [],
      ),
      missingIngredients: List<String>.from(
        json['missing_ingredients'] ?? [],
      ),
      instructions: json['instructions'] ?? '',
      expiringIngredientsUsed: json['expiring_ingredients_used'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'used_ingredients': usedIngredients,
      'missing_ingredients': missingIngredients,
      'instructions': instructions,
      'expiring_ingredients_used': expiringIngredientsUsed,
    };
  }

  bool get needsExtraIngredients => missingIngredients.isNotEmpty;
}

class RecipeService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  // ============================================================
  // HIVE CACHE
  // ============================================================

  static const String _cacheBoxName = 'recipe_cache';

  static const String _cacheKey = 'latest_recipes';

  /// เปิด Hive box ของ Recipe cache
  static Future<Box<String>> _openCacheBox() async {
    if (Hive.isBoxOpen(_cacheBoxName)) {
      return Hive.box<String>(_cacheBoxName);
    }

    return await Hive.openBox<String>(_cacheBoxName);
  }

  /// อ่าน Recipe ที่เคยสร้างไว้
  static Future<List<RecipeRecommendation>> getCachedRecipes() async {
    try {
      final box = await _openCacheBox();

      final cachedString = box.get(_cacheKey);

      if (cachedString == null || cachedString.isEmpty) {
        debugPrint('RECIPE CACHE: empty');
        return [];
      }

      final cache = RecipeCache.decode(cachedString);

      final List<dynamic> jsonList = jsonDecode(cache.recipesJson);

      final recipes = jsonList
          .map(
            (item) => RecipeRecommendation.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();

      debugPrint(
        'RECIPE CACHE: loaded ${recipes.length} recipes',
      );

      debugPrint(
        'RECIPE CACHE SAVED AT: ${cache.savedAt}',
      );

      return recipes;
    } catch (e) {
      debugPrint(
        'RECIPE CACHE READ ERROR: $e',
      );

      return [];
    }
  }

  /// บันทึก Recipe ลง Hive
  static Future<void> saveCachedRecipes(
    List<RecipeRecommendation> recipes,
  ) async {
    try {
      final box = await _openCacheBox();

      final recipesJson = jsonEncode(
        recipes.map((recipe) => recipe.toJson()).toList(),
      );

      final cache = RecipeCache(
        recipesJson: recipesJson,
        savedAt: DateTime.now(),
      );

      await box.put(
        _cacheKey,
        cache.encode(),
      );

      debugPrint(
        'RECIPE CACHE: saved ${recipes.length} recipes',
      );
    } catch (e) {
      debugPrint(
        'RECIPE CACHE SAVE ERROR: $e',
      );
    }
  }

  /// ลบ Recipe cache
  static Future<void> clearCache() async {
    try {
      final box = await _openCacheBox();

      await box.delete(_cacheKey);

      debugPrint('RECIPE CACHE: cleared');
    } catch (e) {
      debugPrint(
        'RECIPE CACHE CLEAR ERROR: $e',
      );
    }
  }

  // ============================================================
  // GEMINI
  // ============================================================

  /// ขอ Recipe ใหม่จาก Gemini
  ///
  /// ฟังก์ชันนี้จะยิง Gemini ก็ต่อเมื่อถูกเรียกโดยตรง
  ///
  /// ไม่ได้ถูกเรียกอัตโนมัติจาก FoodProvider
  static Future<List<RecipeRecommendation>> getRecommendations(
    List<FoodItem> items, {
    int count = 3,
  }) async {
    if (items.isEmpty) {
      return [];
    }

    final expiring = items
        .where(
          (item) => item.isExpiringSoon || item.isExpiringThisWeek,
        )
        .toList()
      ..sort(
        (a, b) => a.daysUntilExpiration.compareTo(
          b.daysUntilExpiration,
        ),
      );

    final others = items
        .where(
          (item) => !item.isExpiringSoon && !item.isExpiringThisWeek,
        )
        .toList();

    final expiringList = expiring
        .map(
          (e) => '${e.name} '
              '(expires in ${e.daysUntilExpiration} days)',
        )
        .join(', ');

    final otherList = others.map((e) => e.name).join(', ');

    final prompt = '''
You are a helpful chef. I have these food items in my fridge:

EXPIRING SOON (use these first!):
${expiringList.isEmpty ? 'None' : expiringList}

OTHER AVAILABLE INGREDIENTS:
${otherList.isEmpty ? 'None' : otherList}

Please suggest $count recipes that:
1. PRIORITIZE using the expiring ingredients
2. Use as many available ingredients as possible
3. Minimize the number of missing ingredients to buy
4. Prefer recipes that require NO additional ingredients when possible
5. Are practical and easy to cook

IMPORTANT:
- Prefer recipes that can be made entirely from available ingredients.
- If a recipe can be made without buying anything, prefer it.
- Do not add unnecessary missing ingredients.
- Only put ingredients not in the available list into missing_ingredients.

Respond ONLY with a valid JSON array, no markdown, no explanation:

[
  {
    "title": "Recipe name",
    "description": "Short 1-2 sentence description",
    "used_ingredients": ["ingredient1", "ingredient2"],
    "missing_ingredients": ["ingredient to buy1"],
    "instructions": "Brief step-by-step cooking instructions",
    "expiring_ingredients_used": 2
  }
]

Rules:
- used_ingredients: only from the available list above
- missing_ingredients: additional ingredients needed but not in the list
- expiring_ingredients_used: count of expiring soon items used
- Sort recipes by expiring_ingredients_used (highest first)
- Keep instructions concise (3-5 steps)
- If no expiring items, suggest based on available ingredients
''';

    try {
      debugPrint('CALLING GEMINI...');
      debugPrint(
        'Model: ${AiConfig.geminiModel}',
      );

      final url = Uri.parse(
        '$_baseUrl/'
        '${AiConfig.geminiModel}'
        ':generateContent'
        '?key=${AiConfig.geminiApiKey}',
      );

      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text': prompt,
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 4096,
        }
      });

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );

      debugPrint(
        'GEMINI RESPONSE: ${response.statusCode}',
      );

      // --------------------------------------------------------
      // 429
      // --------------------------------------------------------

      if (response.statusCode == 429) {
        throw const RecipeRateLimitException(
          'Recipe service is temporarily busy. '
          'Please try again in a moment.',
        );
      }

      // --------------------------------------------------------
      // OTHER ERROR
      // --------------------------------------------------------

      if (response.statusCode != 200) {
        debugPrint(
          'GEMINI ERROR BODY: ${response.body}',
        );

        throw Exception(
          'Gemini API error: ${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body);

      final candidates = data['candidates'];

      if (candidates == null || candidates is! List || candidates.isEmpty) {
        throw Exception(
          'Gemini returned no recipe results.',
        );
      }

      final parts = candidates[0]['content']?['parts'];

      if (parts == null || parts is! List || parts.isEmpty) {
        throw Exception(
          'Gemini returned an empty response.',
        );
      }

      final text = parts[0]['text'] as String;

      debugPrint(
        'GEMINI RAW TEXT:\n$text',
      );

      final cleaned =
          text.replaceAll('```json', '').replaceAll('```', '').trim();

      final List<dynamic> jsonList = jsonDecode(cleaned);

      final recipes = jsonList
          .map(
            (item) => RecipeRecommendation.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();

      // --------------------------------------------------------
      // SAVE CACHE
      // --------------------------------------------------------

      await saveCachedRecipes(recipes);

      return recipes;
    } on RecipeRateLimitException {
      rethrow;
    } catch (e) {
      debugPrint(
        'RECIPE SERVICE ERROR: $e',
      );

      throw Exception(
        'Failed to get recipe recommendations: $e',
      );
    }
  }
}
