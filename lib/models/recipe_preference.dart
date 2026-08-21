/// Holds the user's selected recipe preferences from [RecipePreferencePopup].
/// All fields support multiple selections; empty (or "No preference") means "any".
class RecipePreference {
  final List<String> tastes;
  final List<String> cuisines;
  final List<String> menuTypes;

  const RecipePreference({
    required this.tastes,
    required this.cuisines,
    required this.menuTypes,
  });

  bool get isEmpty => tastes.isEmpty && cuisines.isEmpty && menuTypes.isEmpty;

  /// Human-readable block to append to the Gemini prompt in RecipeService.
  String toPromptText() {
    String describe(List<String> values, String label) {
      if (values.isEmpty || values.contains('No preference')) {
        return '$label: no preference (any is fine)';
      }
      return '$label: ${values.join(', ')}';
    }

    return '${describe(tastes, 'Preferred taste')}\n'
        '${describe(cuisines, 'Preferred cuisine style')}\n'
        '${describe(menuTypes, 'Preferred menu type')}';
  }
}
