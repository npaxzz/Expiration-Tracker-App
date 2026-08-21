import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../models/recipe_preference.dart';

/// Opens the preference popup and resolves with the user's picks,
/// or null if they cancelled/dismissed it.
Future<RecipePreference?> showRecipePreferencePopup(BuildContext context) {
  return showDialog<RecipePreference>(
    context: context,
    barrierDismissible: true,
    builder: (context) => const RecipePreferencePopup(),
  );
}

class RecipePreferencePopup extends StatefulWidget {
  const RecipePreferencePopup({super.key});

  @override
  State<RecipePreferencePopup> createState() => _RecipePreferencePopupState();
}

class _RecipePreferencePopupState extends State<RecipePreferencePopup> {
  final List<String> _tasteOptions = const [
    'Spicy',
    'Sweet',
    'Salty',
    'Sour',
    'Well-balanced',
  ];

  final List<String> _cuisineOptions = const [
    '🇹🇭 Thai',
    '🇯🇵 Japanese',
    '🇰🇷 Korean',
    '🇨🇳 Chinese',
    '🌎 Western',
  ];

  final List<String> _menuTypeOptions = const [
    '🍛 Main dish',
    '🍜 Noodles',
    '🥘 Soup / Curry',
    '🥗 Light meal',
  ];

  final Set<String> _selectedTastes = {};
  final Set<String> _selectedCuisines = {};
  final Set<String> _selectedMenuTypes = {};

  /// Plain multi-select toggle for a chip within a given category.
  void _toggle(Set<String> selectedSet, String option) {
    setState(() {
      if (selectedSet.contains(option)) {
        selectedSet.remove(option);
      } else {
        selectedSet.add(option);
      }
    });
  }

  Widget _buildSection({
    required String title,
    required List<String> options,
    required Set<String> selectedSet,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.sarabun(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final bool selected = selectedSet.contains(option);
            return FilterChip(
              label: Text(
                option,
                style: GoogleFonts.sarabun(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? AppTheme.primary : AppTheme.textPrimary,
                ),
              ),
              selected: selected,
              onSelected: (_) => _toggle(selectedSet, option),
              backgroundColor: Colors.white,
              selectedColor: AppTheme.primary.withValues(alpha: 0.12),
              checkmarkColor: AppTheme.primary,
              side: BorderSide(
                color: selected ? AppTheme.primary : AppTheme.divider,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  void _handleConfirm() {
    Navigator.of(context).pop(
      RecipePreference(
        tastes: _selectedTastes.toList(),
        cuisines: _selectedCuisines.toList(),
        menuTypes: _selectedMenuTypes.toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🍳 What do you feel like eating today?',
                style: GoogleFonts.sarabun(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pick as many as you like in each category.',
                style: GoogleFonts.sarabun(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection(
                        title: 'Taste you feel like',
                        options: _tasteOptions,
                        selectedSet: _selectedTastes,
                      ),
                      _buildSection(
                        title: 'Cuisine style',
                        options: _cuisineOptions,
                        selectedSet: _selectedCuisines,
                      ),
                      _buildSection(
                        title: 'Menu type',
                        options: _menuTypeOptions,
                        selectedSet: _selectedMenuTypes,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel', style: GoogleFonts.sarabun()),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _handleConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Find Recipes',
                      style: GoogleFonts.sarabun(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
