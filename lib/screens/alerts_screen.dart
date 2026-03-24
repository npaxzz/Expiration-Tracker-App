import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/food_provider.dart';
import '../models/food_item.dart';
import '../theme/app_theme.dart';
import 'item_detail_screen.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Alerts',
          style: GoogleFonts.sarabun(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: Consumer<FoodProvider>(
        builder: (context, provider, _) {
          final expired = provider.expiredItems;
          final soon = provider.expiringSoonItems;

          if (expired.isEmpty && soon.isEmpty) {
            return _buildAllGoodState();
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (expired.isNotEmpty) ...[
                _buildSectionHeader(
                  '🚨 Expired',
                  '${expired.length} item${expired.length > 1 ? 's' : ''}',
                  AppTheme.expiredColor,
                ),
                const SizedBox(height: 10),
                ...expired.map((item) => _buildAlertCard(context, item)),
                const SizedBox(height: 20),
              ],
              if (soon.isNotEmpty) ...[
                _buildSectionHeader(
                  '⚠️ Expiring Soon',
                  '${soon.length} item${soon.length > 1 ? 's' : ''}',
                  AppTheme.soonColor,
                ),
                const SizedBox(height: 10),
                ...soon.map((item) => _buildAlertCard(context, item)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, String count, Color color) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.sarabun(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            count,
            style: GoogleFonts.sarabun(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertCard(BuildContext context, FoodItem item) {
    final days = item.daysUntilExpiration;
    final color = item.status.color;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: item.category.lightColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  item.category.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.sarabun(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    days < 0
                        ? 'Expired ${days.abs()} days ago'
                        : days == 0
                            ? 'Expires today!'
                            : 'Expires in $days days',
                    style: GoogleFonts.sarabun(
                      fontSize: 13,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    DateFormat('d MMM yyyy').format(item.expirationDate),
                    style: GoogleFonts.sarabun(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Qty: ${item.quantity}',
                style: GoogleFonts.sarabun(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllGoodState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.freshColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppTheme.freshColor,
              size: 50,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'All Good! 🎉',
            style: GoogleFonts.sarabun(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'No expiring items right now.\nYour fridge is in great shape!',
            textAlign: TextAlign.center,
            style: GoogleFonts.sarabun(
              fontSize: 15,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
