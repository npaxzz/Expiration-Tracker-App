import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ai_config.dart';
import '../models/ai_service.dart';
import '../models/scan_result.dart';
import '../models/vlm_service.dart';
import '../theme/app_theme.dart';
import 'review_screen.dart';
import 'add_item_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  XFile? _image1; // รูปแรก (ฉลาก หรือ รูปเดียวที่มีทั้งคู่)
  XFile? _image2; // รูปสอง (สินค้า) — optional
  bool _isAnalyzing = false;
  final _picker = ImagePicker();

  bool get _canAnalyze => _image1 != null || _image2 != null;

  String get _primaryImage => (_image1 ?? _image2)!.path;
  String? get _secondaryImage =>
      _image1 != null && _image2 != null ? _image2!.path : null;

  Future<void> _pickImage(
      {required int slot, required ImageSource source}) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 50,
        maxWidth: 800,
      );
      if (picked == null) return;
      setState(() {
        if (slot == 1)
          _image1 = picked;
        else
          _image2 = picked;
      });
    } catch (e) {
      _showSnack('Could not open camera/gallery');
    }
  }

  void _showSourceSheet(int slot) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(slot == 1 ? 'Photo 1' : 'Photo 2',
                style: GoogleFonts.sarabun(
                    fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Row(children: [
              if (!kIsWeb) ...[
                Expanded(
                    child: _sourceBtn(
                        Icons.camera_alt_rounded, 'Camera', AppTheme.primary,
                        () {
                  Navigator.pop(ctx);
                  _pickImage(slot: slot, source: ImageSource.camera);
                })),
                const SizedBox(width: 12),
              ],
              Expanded(
                  child: _sourceBtn(Icons.photo_library_rounded, 'Gallery',
                      const Color(0xFF1565C0), () {
                Navigator.pop(ctx);
                _pickImage(slot: slot, source: ImageSource.gallery);
              })),
            ]),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _sourceBtn(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(label,
              style: GoogleFonts.sarabun(
                  fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.sarabun()),
      backgroundColor: AppTheme.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _analyze() async {
    if (!_canAnalyze) return;
    setState(() => _isAnalyzing = true);
    try {
      ScanResult result;
      final primary = _primaryImage;
      final secondary = _secondaryImage;

      if (AiConfig.useVlm) {
        result = await VlmService.analyze(
          labelImagePath: primary,
          productImagePath: secondary ?? primary,
        );
      } else {
        result = await AiService.analyze(
          labelImagePath: primary,
          productImagePath: secondary ?? primary,
        );
      }
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReviewScreen(
              scanResult: result,
              productImagePath: secondary ?? primary,
            ),
          ));
    } catch (e) {
      setState(() => _isAnalyzing = false);
      _showSnack('Analysis failed: $e');
    }
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
        title: Text('Scan Product',
            style: GoogleFonts.sarabun(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary)),
      ),
      body: _isAnalyzing ? _buildAnalyzing() : _buildForm(),
    );
  }

  Widget _buildForm() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Info banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.info_outline_rounded,
                color: AppTheme.primary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                AiConfig.useVlm
                    ? 'Add 1 photo minimum — AI detects name, category & expiry date   — If No expiry label, will estimate based on category\nAdd a 2nd photo if label and product are in separate images'
                    : 'Add 1–2 photos for OCR & Image Classification\nNo expiry label? Default date will be used',
                style: GoogleFonts.sarabun(
                    fontSize: 13, color: AppTheme.primary, height: 1.5),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 24),

        // Photo 1 — optional
        _buildSlot(
          slot: 1,
          title: 'Expiry Date',
          subtitle: 'Add images with an expiration date',
          color: const Color(0xFF1565C0),
          lightColor: const Color(0xFFE3F2FD),
          image: _image1,
          required: true,
        ),
        const SizedBox(height: 12),

        // Photo 2 — optional
        _buildSlot(
          slot: 2,
          title: 'Product',
          subtitle:
              'Add an image showing the overall appearance of the product',
          color: const Color(0xFF6A1B9A),
          lightColor: const Color(0xFFF3E5F5),
          image: _image2,
          required: true,
        ),
        const SizedBox(height: 24),

        // Analyze button
        AnimatedOpacity(
          opacity: _canAnalyze ? 1.0 : 0.4,
          duration: const Duration(milliseconds: 300),
          child: ElevatedButton.icon(
            onPressed: _canAnalyze ? _analyze : null,
            icon: const Icon(Icons.auto_awesome_rounded, size: 20),
            label: Text('Analyze with AI',
                style: GoogleFonts.sarabun(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
              minimumSize: const Size(double.infinity, 0),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddItemScreen(),
              ),
            );
          },
          child: Text('Enter manually instead',
              style: GoogleFonts.sarabun(
                  color: AppTheme.textSecondary, fontSize: 13)),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSlot({
    required int slot,
    required String title,
    required String subtitle,
    required Color color,
    required Color lightColor,
    required XFile? image,
    required bool required,
  }) {
    final hasImage = image != null;
    return GestureDetector(
      onTap: () => _showSourceSheet(slot),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: hasImage ? 160 : 90,
        decoration: BoxDecoration(
          color: hasImage ? lightColor : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasImage
                ? color
                : (required
                    ? AppTheme.primary.withValues(alpha: 0.3)
                    : AppTheme.divider),
            width: hasImage ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.hardEdge,
        child: hasImage
            ? Stack(fit: StackFit.expand, children: [
                kIsWeb
                    ? Image.network(image.path, fit: BoxFit.cover)
                    : Image.file(File(image.path), fit: BoxFit.cover),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent
                        ],
                      ),
                    ),
                    child: Row(children: [
                      Text('Photo $slot',
                          style: GoogleFonts.sarabun(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text('Change',
                            style: GoogleFonts.sarabun(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ),
                    ]),
                  ),
                ),
              ])
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                        color: lightColor,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: color.withValues(alpha: 0.3))),
                    child: Icon(Icons.add_photo_alternate_rounded,
                        color: color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                        Row(children: [
                          Text(title,
                              style: GoogleFonts.sarabun(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary)),
                          const SizedBox(width: 6),
                          if (!required)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                  color: AppTheme.divider,
                                  borderRadius: BorderRadius.circular(6)),
                              child: Text('Optional',
                                  style: GoogleFonts.sarabun(
                                      fontSize: 10,
                                      color: AppTheme.textSecondary)),
                            ),
                        ]),
                        Text(subtitle,
                            style: GoogleFonts.sarabun(
                                fontSize: 12, color: AppTheme.textSecondary)),
                      ])),
                ]),
              ),
      ),
    );
  }

  Widget _buildAnalyzing() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome_rounded,
                color: AppTheme.primary, size: 44),
          ),
          const SizedBox(height: 24),
          Text('Analyzing...',
              style: GoogleFonts.sarabun(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 10),
          Text(
            _image2 != null
                ? '✨ Processing 2 photos with AI'
                : '✨ Processing photo with AI',
            style: GoogleFonts.sarabun(
                fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 28),
          const CircularProgressIndicator(
              color: AppTheme.primary, strokeWidth: 3),
        ]),
      ),
    );
  }
}
