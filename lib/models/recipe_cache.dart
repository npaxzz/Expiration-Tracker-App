import 'dart:convert';

/// ข้อมูล cache ของ Recipe
///
/// เก็บเป็น JSON String ใน Hive
/// เพื่อไม่ต้องสร้าง Hive TypeAdapter เพิ่ม
class RecipeCache {
  final String recipesJson;
  final DateTime savedAt;

  const RecipeCache({
    required this.recipesJson,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'recipes': recipesJson,
      'saved_at': savedAt.toIso8601String(),
    };
  }

  factory RecipeCache.fromJson(Map<String, dynamic> json) {
    return RecipeCache(
      recipesJson: json['recipes'] ?? '[]',
      savedAt: DateTime.tryParse(
            json['saved_at'] ?? '',
          ) ??
          DateTime.now(),
    );
  }

  String encode() {
    return jsonEncode(toJson());
  }

  factory RecipeCache.decode(String value) {
    return RecipeCache.fromJson(
      jsonDecode(value) as Map<String, dynamic>,
    );
  }
}
