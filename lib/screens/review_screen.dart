import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/ai_config.dart';
import '../models/ai_service.dart';
import '../models/food_item.dart';
import '../models/food_provider.dart';
import '../theme/app_theme.dart';

class ReviewScreen extends StatefulWidget {
  final ScanResult scanResult;
  final String? productImagePath;

  const ReviewScreen({
    super.key,
    required this.scanResult,
    this.productImagePath,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late TextEditingController _nameController;
  late FoodCategory _category;
  late DateTime _expirationDate;
  final _quantityController = TextEditingController(text: '1');
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.scanResult.productName);
    _category = widget.scanResult.category;
    _expirationDate = widget.scanResult.expirationDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

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
                border: Border.all(color: AppTheme.divider)),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: AppTheme.textPrimary),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Review Result',
            style: GoogleFonts.sarabun(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildAiBadge(),
          const SizedBox(height: 20),
          _buildNameField(),
          const SizedBox(height: 16),
          _buildCategorySection(),
          const SizedBox(height: 16),
          _buildDateSection(),
          const SizedBox(height: 16),
          _buildQuantityRow(),
          const SizedBox(height: 32),
          _buildConfirmButton(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAiBadge() {
    final isVlm = AiConfig.useVlm;
    final engineLabel = isVlm ? 'Gemini Vision' : 'OCR + Image Class';
    final engineIcon =
        isVlm ? Icons.auto_awesome_rounded : Icons.document_scanner_rounded;
    final engineColor = isVlm ? const Color(0xFF1565C0) : AppTheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          engineColor.withValues(alpha: 0.08),
          const Color(0xFF6A1B9A).withValues(alpha: 0.04),
        ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: engineColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Engine badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: engineColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(children: [
                  Icon(engineIcon, color: Colors.white, size: 13),
                  const SizedBox(width: 4),
                  Text(engineLabel,
                      style: GoogleFonts.sarabun(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ]),
              ),
              const Spacer(),
              if (!widget.scanResult.ocrFoundDate)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppTheme.soonColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text('Default date',
                      style: GoogleFonts.sarabun(
                          fontSize: 11,
                          color: AppTheme.soonColor,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(children: [
            _chip(
              isVlm
                  ? Icons.auto_awesome_rounded
                  : Icons.document_scanner_rounded,
              isVlm
                  ? (widget.scanResult.ocrFoundDate
                      ? 'Expiry: detected'
                      : 'Expiry: not found → default')
                  : (widget.scanResult.ocrFoundDate
                      ? 'OCR: Date found'
                      : 'OCR: Using default'),
              widget.scanResult.ocrFoundDate
                  ? AppTheme.freshColor
                  : AppTheme.soonColor,
            ),
            const SizedBox(width: 8),
            _chip(
              isVlm ? Icons.category_rounded : Icons.camera_enhance_rounded,
              isVlm ? 'Category: detected' : 'Image Class: detected',
              engineColor,
            ),
          ]),
          const SizedBox(height: 8),
          Text('Review and edit below before saving',
              style: GoogleFonts.sarabun(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Expanded(
              child: Text(label,
                  style: GoogleFonts.sarabun(
                      fontSize: 11, color: color, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }

  Widget _buildNameField() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('Product Name'),
      const SizedBox(height: 8),
      TextFormField(
        controller: _nameController,
        style: GoogleFonts.sarabun(fontSize: 15),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.label_rounded,
              color: AppTheme.primary, size: 20),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.divider)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.divider)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppTheme.primary, width: 1.5)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    ]);
  }

  Widget _buildCategorySection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _label('Category'),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6)),
          child: Text('AI detected',
              style: GoogleFonts.sarabun(
                  fontSize: 10,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600)),
        ),
      ]),
      const SizedBox(height: 10),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.8,
        children: FoodCategory.values.map((cat) {
          final isSelected = _category == cat;
          return GestureDetector(
            onTap: () => setState(() => _category = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected ? cat.color : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isSelected ? cat.color : AppTheme.divider,
                    width: isSelected ? 2 : 1),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: cat.color.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ]
                    : [],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(children: [
                Text(cat.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(cat.displayName,
                        style: GoogleFonts.sarabun(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
              ]),
            ),
          );
        }).toList(),
      ),
    ]);
  }

  Widget _buildDateSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _label('Expiration Date'),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: widget.scanResult.ocrFoundDate
                ? AppTheme.freshColor.withValues(alpha: 0.1)
                : AppTheme.soonColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
              widget.scanResult.ocrFoundDate
                  ? 'OCR detected'
                  : 'Default (no label)',
              style: GoogleFonts.sarabun(
                  fontSize: 10,
                  color: widget.scanResult.ocrFoundDate
                      ? AppTheme.freshColor
                      : AppTheme.soonColor,
                  fontWeight: FontWeight.w600)),
        ),
      ]),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: _pickDate,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.divider)),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.calendar_today_rounded,
                  color: AppTheme.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        DateFormat('EEEE, d MMMM yyyy').format(_expirationDate),
                        style: GoogleFonts.sarabun(
                            fontSize: 15, fontWeight: FontWeight.w500)),
                    Text(_daysText(),
                        style: GoogleFonts.sarabun(
                            fontSize: 12, color: _daysColor())),
                  ]),
            ),
            const Icon(Icons.edit_rounded,
                color: AppTheme.textSecondary, size: 18),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildQuantityRow() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('Quantity'),
      const SizedBox(height: 8),
      Row(children: [
        _qtyBtn(Icons.remove_rounded, () {
          final v = int.tryParse(_quantityController.text) ?? 1;
          if (v > 1)
            setState(() => _quantityController.text = (v - 1).toString());
        }),
        Expanded(
            child: TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: GoogleFonts.sarabun(
                    fontSize: 16, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero))),
        _qtyBtn(Icons.add_rounded, () {
          final v = int.tryParse(_quantityController.text) ?? 1;
          setState(() => _quantityController.text = (v + 1).toString());
        }),
      ]),
    ]);
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppTheme.primary, size: 20)));
  }

  Widget _buildConfirmButton() {
    return ElevatedButton.icon(
      onPressed: _isSaving ? null : _save,
      icon: _isSaving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2))
          : const Icon(Icons.check_circle_rounded, size: 20),
      label: Text(_isSaving ? 'Saving...' : 'Confirm & Add to Fridge',
          style:
              GoogleFonts.sarabun(fontSize: 16, fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          minimumSize: const Size(double.infinity, 0)),
    );
  }

  Widget _label(String text) => Text(text,
      style: GoogleFonts.sarabun(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
          letterSpacing: 0.5));

  String _daysText() {
    final days = _expirationDate.difference(DateTime.now()).inDays;
    if (days < 0) return 'Already expired!';
    if (days == 0) return 'Expires today';
    return 'Expires in $days days';
  }

  Color _daysColor() {
    final days = _expirationDate.difference(DateTime.now()).inDays;
    if (days < 0) return AppTheme.expiredColor;
    if (days <= 3) return AppTheme.soonColor;
    if (days <= 7) return AppTheme.weekColor;
    return AppTheme.freshColor;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1825)),
      builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(primary: AppTheme.primary)),
          child: child!),
    );
    if (picked != null) setState(() => _expirationDate = picked);
  }

  Future<String?> _saveImagePermanently(String? tempPath) async {
    if (tempPath == null) return null;
    if (kIsWeb) return tempPath;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'food_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = p.join(appDir.path, fileName);
      await File(tempPath).copy(savedPath);
      return savedPath;
    } catch (_) {
      return null;
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final savedImagePath =
          await _saveImagePermanently(widget.productImagePath);
      await context.read<FoodProvider>().addItem(
            name: _nameController.text.trim().isEmpty
                ? 'Unknown Product'
                : _nameController.text.trim(),
            category: _category,
            expirationDate: _expirationDate,
            quantity: int.tryParse(_quantityController.text) ?? 1,
            imagePath: savedImagePath,
          );
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Added to fridge! 🎉',
            style: GoogleFonts.sarabun(fontWeight: FontWeight.w500)),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
