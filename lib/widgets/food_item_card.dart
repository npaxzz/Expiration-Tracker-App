import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/food_item.dart';
import '../theme/app_theme.dart';

class FoodItemCard extends StatelessWidget {
  final FoodItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const FoodItemCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final days = item.daysUntilExpiration;
    final statusColor = item.status.color;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: item.isExpired || item.isExpiringSoon
                ? statusColor.withValues(alpha: 0.3)
                : AppTheme.divider,
          ),
          boxShadow: [
            BoxShadow(
              color: item.isExpired
                  ? AppTheme.expiredColor.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                children: [
                  _buildCategoryIcon(),
                  const SizedBox(width: 12),
                  Expanded(child: _buildItemInfo(days)),
                  _buildActions(context, statusColor),
                ],
              ),
            ),
            _buildExpiryBar(days),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryIcon() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: item.category.lightColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(item.category.emoji, style: const TextStyle(fontSize: 24)),
      ),
    );
  }

  Widget _buildItemInfo(int days) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.name,
          style: GoogleFonts.sarabun(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Text(
              DateFormat('d MMM yyyy').format(item.expirationDate),
              style: GoogleFonts.sarabun(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Text('•',
                style: GoogleFonts.sarabun(color: AppTheme.textSecondary)),
            const SizedBox(width: 6),
            Text(
              'Qty: ${item.quantity}',
              style: GoogleFonts.sarabun(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        _buildDaysChip(days),
      ],
    );
  }

  Widget _buildDaysChip(int days) {
    final color = item.status.color;
    String text;
    if (days < 0) {
      text = 'Expired ${days.abs()}d ago';
    } else if (days == 0) {
      text = '⚡ Expires today!';
    } else {
      text = '${days}d left';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.sarabun(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, Color statusColor) {
    return Column(
      children: [
        _actionButton(Icons.edit_rounded, AppTheme.primary, onEdit),
        const SizedBox(height: 6),
        _actionButton(
          Icons.delete_outline_rounded,
          AppTheme.expiredColor,
          onDelete,
        ),
      ],
    );
  }

  Widget _actionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _buildExpiryBar(int days) {
    final color = item.status.color;
    double progress;
    if (item.isExpired) {
      progress = 0.0;
    } else {
      progress = (days / 30.0).clamp(0.0, 1.0);
    }

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(18),
        bottomRight: Radius.circular(18),
      ),
      child: SizedBox(
        height: 4,
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: color.withValues(alpha: 0.1),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }
}
