import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/food_provider.dart';
import '../models/food_item.dart';
import '../theme/app_theme.dart';
import '../widgets/food_item_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/category_filter.dart';
import 'add_item_screen.dart';
import 'item_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  FoodCategory? _selectedCategory;
  late AnimationController _headerController;
  late Animation<double> _headerAnimation;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerAnimation = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutCubic,
    );
    _headerController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        body: Consumer<FoodProvider>(
          builder: (context, provider, _) {
            final displayItems = _selectedCategory == null
                ? provider.allSorted
                : provider.getByCategory(_selectedCategory!);

            return CustomScrollView(
              slivers: [
                _buildSliverAppBar(provider),
                SliverToBoxAdapter(
                  child: _buildStatsRow(provider),
                ),
                SliverToBoxAdapter(
                  child: _buildCategoryFilter(),
                ),
                displayItems.isEmpty
                    ? SliverToBoxAdapter(child: _buildEmptyState())
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = displayItems[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                left: 20,
                                right: 20,
                                top: index == 0 ? 8 : 6,
                                bottom:
                                    index == displayItems.length - 1 ? 100 : 6,
                              ),
                              child: FoodItemCard(
                                item: item,
                                onEdit: () => _editItem(context, item),
                                onDelete: () =>
                                    _deleteItem(context, provider, item),
                                onTap: () => _viewDetail(context, item),
                              ),
                            );
                          },
                          childCount: displayItems.length,
                        ),
                      ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(FoodProvider provider) {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.surface,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1B5E20),
                Color(0xFF2E7D32),
                Color(0xFF388E3C),
              ],
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _headerAnimation,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Smart Expiration',
                              style: GoogleFonts.sarabun(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                            Text(
                              'Tracker',
                              style: GoogleFonts.sarabun(
                                fontSize: 26,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.85),
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: const Icon(
                            Icons.kitchen_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      title: const SizedBox.shrink(),
    );
  }

  Widget _buildStatsRow(FoodProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: StatCard(
              title: 'Total Items',
              value: provider.totalItems.toString(),
              icon: Icons.inventory_2_rounded,
              color: AppTheme.primary,
              bgColor: const Color(0xFFE8F5E9),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: StatCard(
              title: 'Expiring Soon',
              value: provider.expiringSoonCount.toString(),
              icon: Icons.warning_amber_rounded,
              color: provider.expiringSoonCount > 0
                  ? AppTheme.soonColor
                  : AppTheme.freshColor,
              bgColor: provider.expiringSoonCount > 0
                  ? const Color(0xFFFFF3E0)
                  : const Color(0xFFE8F5E9),
              showAlert: provider.expiringSoonCount > 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 20, bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Family Fridge 🏠',
                  style: GoogleFonts.sarabun(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          CategoryFilter(
            selectedCategory: _selectedCategory,
            onCategorySelected: (cat) {
              setState(() => _selectedCategory = cat);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_shopping_cart_rounded,
              size: 36,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No items here',
            style: GoogleFonts.sarabun(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first item',
            style: GoogleFonts.sarabun(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _editItem(BuildContext context, FoodItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddItemScreen(existingItem: item),
      ),
    );
  }

  void _viewDetail(BuildContext context, FoodItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ItemDetailScreen(item: item),
      ),
    );
  }

  void _deleteItem(BuildContext context, FoodProvider provider, FoodItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Item?',
          style: GoogleFonts.sarabun(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Remove "${item.name}" from your fridge?',
          style: GoogleFonts.sarabun(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.sarabun(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteItem(item.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${item.name} removed'),
                  backgroundColor: AppTheme.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.expiredColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('Delete', style: GoogleFonts.sarabun()),
          ),
        ],
      ),
    );
  }
}
