import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/food_provider.dart';
import '../models/recipe_preference.dart';
import '../services/recipe_service.dart';
import '../theme/app_theme.dart';
import '../widgets/recipe_preference_popup.dart';

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key});

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  List<RecipeRecommendation>? _recipes;

  bool _isLoading = false;

  String? _error;

  /// true = กำลังหา Recipe ใหม่จาก Gemini
  bool _isRefreshing = false;

  /// true = ผู้ใช้กดค้นหาแล้ว แต่ไม่มีวัตถุดิบ
  bool _noIngredients = false;

  @override
  void initState() {
    super.initState();

    // ----------------------------------------------------------
    // โหลดจาก CACHE เท่านั้น
    // ไม่เรียก Gemini ตอนเปิดหน้า
    // ----------------------------------------------------------

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCachedRecipes();
    });
  }

  // ============================================================
  // CACHE
  // ============================================================

  Future<void> _loadCachedRecipes() async {
    if (!mounted) return;

    try {
      final cached = await RecipeService.getCachedRecipes();

      if (!mounted) return;

      if (cached.isNotEmpty) {
        setState(() {
          _recipes = cached;
          _error = null;
          _noIngredients = false;
        });

        debugPrint(
          'RecipeScreen: showing cached recipes',
        );
      } else {
        setState(() {
          _recipes = null;
          _error = null;
          _noIngredients = false;
        });

        debugPrint(
          'RecipeScreen: no recipe cache',
        );
      }
    } catch (e) {
      debugPrint(
        'RecipeScreen cache error: $e',
      );
    }
  }

  // ============================================================
  // PREFERENCE POPUP -> GEMINI
  // ============================================================

  /// จุดเข้าเดียวสำหรับทุกปุ่มที่ต้อง "ยิง Gemini ใหม่"
  /// (Find Recipes / Refresh / Try Again)
  ///
  /// เปิด popup ถามความต้องการก่อนเสมอ ถ้าผู้ใช้กด Cancel
  /// จะไม่เรียก Gemini เลย
  Future<void> _onRequestNewRecipes() async {
    if (_isLoading) return;

    final RecipePreference? preference =
        await showRecipePreferencePopup(context);

    if (preference == null) {
      // ผู้ใช้ปิด popup โดยไม่กด "Find Recipes"
      return;
    }

    if (!mounted) return;

    await _loadRecipes(
      forceRefresh: true,
      preference: preference,
    );
  }

  /// เรียก Gemini ใหม่
  ///
  /// ใช้เมื่อ:
  /// - กด Find Recipes
  /// - กด Refresh
  ///
  /// จะตรวจวัตถุดิบเฉพาะตอนผู้ใช้กดค้นหา
  Future<void> _loadRecipes({
    bool forceRefresh = false,
    RecipePreference? preference,
  }) async {
    if (_isLoading) return;

    if (!mounted) return;

    final provider = context.read<FoodProvider>();

    // ----------------------------------------------------------
    // ตรวจวัตถุดิบเฉพาะตอนกด Find Recipes / Refresh
    // ----------------------------------------------------------

    if (provider.totalItems == 0) {
      setState(() {
        _recipes = [];
        _isLoading = false;
        _isRefreshing = false;
        _error = null;
        _noIngredients = true;
      });

      return;
    }

    setState(() {
      _isLoading = true;
      _isRefreshing = forceRefresh;
      _error = null;
      _noIngredients = false;
    });

    try {
      debugPrint(
        'RecipeScreen: requesting NEW recipes',
      );

      final recipes = await RecipeService.getRecommendations(
        provider.allSorted,
        count: 3,
        preference: preference,
      );

      if (!mounted) return;

      setState(() {
        _recipes = recipes;
        _isLoading = false;
        _isRefreshing = false;
        _error = null;
        _noIngredients = false;
      });
    } catch (e) {
      if (!mounted) return;

      String errorMessage;

      if (e is RecipeRateLimitException) {
        errorMessage = 'Recipe service is temporarily busy.\n'
            'Please try again in a moment.';
      } else {
        errorMessage = e.toString().replaceFirst(
              'Exception: ',
              '',
            );
      }

      setState(() {
        _error = errorMessage;
        _isLoading = false;
        _isRefreshing = false;
        _noIngredients = false;
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.divider,
              ),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: AppTheme.textPrimary,
            ),
          ),

          // กลับหน้าแรก
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/');
            }
          },
        ),
        title: Text(
          'Recipe Ideas',
          style: GoogleFonts.sarabun(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppTheme.primary,
            ),

            // Refresh = ถามความต้องการใหม่ แล้วบังคับหาใหม่
            onPressed: _isLoading ? null : _onRequestNewRecipes,

            tooltip: 'Get new suggestions',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoading();
    }

    if (_error != null) {
      return _buildError();
    }

    if (_noIngredients) {
      return _buildNoIngredients();
    }

    if (_recipes == null || _recipes!.isEmpty) {
      return _buildEmpty();
    }

    return _buildRecipeList();
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant_menu_rounded,
              color: AppTheme.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Finding new recipes...',
            style: GoogleFonts.sarabun(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Prioritizing expiring ingredients',
            style: GoogleFonts.sarabun(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          const CircularProgressIndicator(
            color: AppTheme.primary,
            strokeWidth: 3,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppTheme.expiredColor,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Could not get recipes',
              style: GoogleFonts.sarabun(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.sarabun(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _onRequestNewRecipes,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: Text(
                'Try Again',
                style: GoogleFonts.sarabun(),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  /// ไม่มี cache ตอนเปิดหน้า
  ///
  /// สำคัญ:
  /// ไม่ตรวจ FoodProvider ตรงนี้
  /// เพราะยังไม่ควรสนใจว่ามีวัตถุดิบหรือไม่
  /// จนกว่าผู้ใช้จะกด Find Recipes
  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.restaurant_menu_rounded,
              color: AppTheme.primary,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Ready to cook?',
              style: GoogleFonts.sarabun(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Find recipe ideas based on your ingredients',
              textAlign: TextAlign.center,
              style: GoogleFonts.sarabun(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _onRequestNewRecipes,
              icon: const Icon(
                Icons.restaurant_menu_rounded,
              ),
              label: Text(
                'Find Recipes',
                style: GoogleFonts.sarabun(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NO INGREDIENTS
  // ============================================================

  /// แสดงเฉพาะหลังจากผู้ใช้กด Find Recipes
  /// แล้วพบว่าไม่มีวัตถุดิบ
  Widget _buildNoIngredients() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.kitchen_rounded,
              color: AppTheme.textSecondary,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No ingredients yet',
              style: GoogleFonts.sarabun(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add food items to your fridge first',
              textAlign: TextAlign.center,
              style: GoogleFonts.sarabun(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // RECIPE LIST
  // ============================================================

  Widget _buildRecipeList() {
    final hasExpiring = _recipes!.any(
      (r) => r.expiringIngredientsUsed > 0,
    );

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // แสดงว่าเป็นข้อมูลจาก cache
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(
            bottom: 16,
          ),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.history_rounded,
                color: AppTheme.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Showing saved recipe ideas. '
                  'Tap refresh to find new ones.',
                  style: GoogleFonts.sarabun(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),

        if (hasExpiring)
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(
              bottom: 20,
            ),
            decoration: BoxDecoration(
              color: AppTheme.soonColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.soonColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppTheme.soonColor,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Recipes prioritize your '
                    'expiring ingredients',
                    style: GoogleFonts.sarabun(
                      fontSize: 13,
                      color: AppTheme.soonColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

        ..._recipes!.asMap().entries.map(
          (entry) {
            return _buildRecipeCard(
              entry.value,
              entry.key + 1,
            );
          },
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  // ============================================================
  // RECIPE CARD
  // ============================================================

  Widget _buildRecipeCard(
    RecipeRecommendation recipe,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16,
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$index',
                style: GoogleFonts.sarabun(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
          title: Text(
            recipe.title,
            style: GoogleFonts.sarabun(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                recipe.description,
                style: GoogleFonts.sarabun(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (recipe.expiringIngredientsUsed > 0) ...[
                    _miniChip(
                      '⏰ Uses '
                      '${recipe.expiringIngredientsUsed} '
                      'expiring',
                      AppTheme.soonColor,
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (recipe.needsExtraIngredients)
                    _miniChip(
                      '🛒 Buy '
                      '${recipe.missingIngredients.length} '
                      'more',
                      const Color(
                        0xFF5C6BC0,
                      ),
                    )
                  else
                    _miniChip(
                      '✅ No shopping needed',
                      AppTheme.freshColor,
                    ),
                ],
              ),
            ],
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 12),
            _sectionTitle(
              '✅ Ingredients you have',
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: recipe.usedIngredients
                  .map(
                    (i) => _ingredientChip(
                      i,
                      AppTheme.freshColor,
                    ),
                  )
                  .toList(),
            ),
            if (recipe.needsExtraIngredients) ...[
              const SizedBox(height: 12),
              _sectionTitle(
                '🛒 Need to buy',
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: recipe.missingIngredients
                    .map(
                      (i) => _ingredientChip(
                        i,
                        const Color(
                          0xFF5C6BC0,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            _sectionTitle(
              '📋 Instructions',
            ),
            const SizedBox(height: 6),
            Text(
              recipe.instructions,
              style: GoogleFonts.sarabun(
                fontSize: 13,
                color: AppTheme.textPrimary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // UI HELPERS
  // ============================================================

  Widget _miniChip(
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.1,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.sarabun(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _ingredientChip(
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(
            alpha: 0.3,
          ),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.sarabun(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _sectionTitle(
    String title,
  ) {
    return Text(
      title,
      style: GoogleFonts.sarabun(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.textSecondary,
      ),
    );
  }
}
