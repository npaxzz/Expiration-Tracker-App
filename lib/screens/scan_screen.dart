import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ai_config.dart';
import '../models/ai_service.dart';
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
  XFile? _labelImage;
  XFile? _productImage;
  bool _isAnalyzing = false;
  final _picker = ImagePicker();

  Future<void> _pickImage({
    required bool isLabel,
    required ImageSource source,
  }) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 50,
        maxWidth: 800,
      );
      if (picked == null) return;
      setState(() {
        if (isLabel) {
          _labelImage = picked;
        } else {
          _productImage = picked;
        }
      });
    } catch (e) {
      _showSnack('Could not open camera/gallery: $e');
    }
  }

  void _showSourceSheet({required bool isLabel}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Text(
              isLabel ? 'Label Photo' : 'Product Photo',
              style: GoogleFonts.sarabun(
                  fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            Row(children: [
              // Camera — ซ่อนบน Web เพราะบางเบราว์เซอร์ไม่รองรับ
              if (!kIsWeb) ...[
                Expanded(
                  child: _sourceButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    color: AppTheme.primary,
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(isLabel: isLabel, source: ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: _sourceButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  color: const Color(0xFF1565C0),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(isLabel: isLabel, source: ImageSource.gallery);
                  },
                ),
              ),
            ]),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _sourceButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
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
          Icon(icon, color: color, size: 30),
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
    if (_labelImage == null || _productImage == null) {
      _showSnack('Please add both photos first');
      return;
    }
    setState(() => _isAnalyzing = true);
    try {
      ScanResult result;
      if (AiConfig.useVlm) {
        result = await VlmService.analyze(
          labelImagePath: _labelImage!.path,
          productImagePath: _productImage!.path,
        );
      } else {
        result = await AiService.analyze(
          labelImagePath: _labelImage!.path,
          productImagePath: _productImage!.path,
        );
      }
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ReviewScreen(
                    scanResult: result,
                    productImagePath: _productImage?.path,
                  )));
    } catch (e) {
      setState(() => _isAnalyzing = false);
      _showSnack('Analysis failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bothReady = _labelImage != null && _productImage != null;
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
      body: _isAnalyzing ? _buildAnalyzingState() : _buildScanForm(bothReady),
    );
  }

  Widget _buildScanForm(bool bothReady) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Info banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.info_outline_rounded,
                color: AppTheme.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AiConfig.useVlm
                    ? 'VLM Mode: Add product photo\n→ Gemini Vision detects name, category & expiry date automatically'
                    : 'Add product photos:\n• Label photo → OCR reads expiry date\n• Product photo → AI detects category',
                style: GoogleFonts.sarabun(
                    fontSize: 13, color: AppTheme.primary, height: 1.5),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 24),

        // Label slot
        _buildPhotoSlot(
          index: 1,
          title: 'Label / Expiry Date',
          subtitle: 'Reads expiration date from label',
          icon: Icons.document_scanner_rounded,
          color: const Color(0xFF1565C0),
          lightColor: const Color(0xFFE3F2FD),
          image: _labelImage,
          onTap: () => _showSourceSheet(isLabel: true),
        ),
        const SizedBox(height: 16),
        Row(children: [
          const Expanded(child: Divider(color: AppTheme.divider)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('+',
                style: GoogleFonts.sarabun(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary)),
          ),
          const Expanded(child: Divider(color: AppTheme.divider)),
        ]),
        const SizedBox(height: 16),

        // Product slot
        _buildPhotoSlot(
          index: 2,
          title: 'Product / Packaging',
          subtitle: 'Identifies product name and category',
          icon: Icons.camera_enhance_rounded,
          color: const Color(0xFF6A1B9A),
          lightColor: const Color(0xFFF3E5F5),
          image: _productImage,
          onTap: () => _showSourceSheet(isLabel: false),
        ),
        const SizedBox(height: 24),

        // Status dots
        if (_labelImage != null || _productImage != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider)),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statusDot('Label', _labelImage != null),
                  Container(width: 1, height: 20, color: AppTheme.divider),
                  _statusDot('Product', _productImage != null),
                ]),
          ),
        const SizedBox(height: 20),

        // Analyze button
        AnimatedOpacity(
          opacity: bothReady ? 1.0 : 0.4,
          duration: const Duration(milliseconds: 300),
          child: ElevatedButton.icon(
            onPressed: bothReady ? _analyze : null,
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

  Widget _buildPhotoSlot({
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color lightColor,
    required XFile? image,
    required VoidCallback onTap,
  }) {
    final hasImage = image != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: hasImage ? 180 : 110,
        decoration: BoxDecoration(
          color: hasImage ? lightColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: hasImage ? color : AppTheme.divider,
              width: hasImage ? 2 : 1),
          boxShadow: hasImage
              ? [
                  BoxShadow(
                      color: color.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        clipBehavior: Clip.hardEdge,
        child: hasImage
            ? Stack(fit: StackFit.expand, children: [
                // Show image preview
                kIsWeb
                    ? Image.network(image.path, fit: BoxFit.cover)
                    : Image.file(File(image.path), fit: BoxFit.cover),
                // Overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
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
                      Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                              color: color, shape: BoxShape.circle),
                          child: Center(
                              child: Text('$index',
                                  style: GoogleFonts.sarabun(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)))),
                      const SizedBox(width: 8),
                      Text(title,
                          style: GoogleFonts.sarabun(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
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
                padding: const EdgeInsets.all(20),
                child: Row(children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                        color: lightColor,
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: color.withValues(alpha: 0.3))),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Row(children: [
                          Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                  color: color, shape: BoxShape.circle),
                              child: Center(
                                  child: Text('$index',
                                      style: GoogleFonts.sarabun(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white)))),
                          const SizedBox(width: 8),
                          Text(title,
                              style: GoogleFonts.sarabun(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary)),
                        ]),
                        const SizedBox(height: 4),
                        Text(subtitle,
                            style: GoogleFonts.sarabun(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                height: 1.4)),
                      ])),
                  Icon(Icons.add_photo_alternate_rounded,
                      color: color, size: 24),
                ]),
              ),
      ),
    );
  }

  Widget _statusDot(String label, bool done) {
    return Row(children: [
      Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
              color: done ? AppTheme.freshColor : AppTheme.divider,
              shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label,
          style: GoogleFonts.sarabun(
              fontSize: 13,
              color: done ? AppTheme.textPrimary : AppTheme.textSecondary,
              fontWeight: done ? FontWeight.w600 : FontWeight.w400)),
    ]);
  }

  Widget _buildAnalyzingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome_rounded,
                color: AppTheme.primary, size: 48),
          ),
          const SizedBox(height: 28),
          Text('Analyzing...',
              style: GoogleFonts.sarabun(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          Text('Running OCR & Image Classification\nThis may take a moment',
              textAlign: TextAlign.center,
              style: GoogleFonts.sarabun(
                  fontSize: 14, color: AppTheme.textSecondary, height: 1.6)),
          const SizedBox(height: 32),
          _analyzeStep('📷', 'Reading label for expiry date (OCR)'),
          const SizedBox(height: 10),
          _analyzeStep('🔍', 'Detecting product category (Image Class)'),
          const SizedBox(height: 10),
          _analyzeStep('✨', 'Preparing review screen'),
          const SizedBox(height: 32),
          const CircularProgressIndicator(
              color: AppTheme.primary, strokeWidth: 3),
        ]),
      ),
    );
  }

  Widget _analyzeStep(String emoji, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Expanded(
            child: Text(label,
                style: GoogleFonts.sarabun(
                    fontSize: 13, color: AppTheme.primary))),
        const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppTheme.primary)),
      ]),
    );
  }
}
