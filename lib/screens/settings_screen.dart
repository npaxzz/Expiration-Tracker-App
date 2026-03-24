import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _dailyReminder = true;
  int _alertDaysBefore = 3;
  String _familyName = 'Family Fridge';
  final _nameController = TextEditingController(text: 'Family Fridge');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Settings',
          style: GoogleFonts.sarabun(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildProfileSection(),
          const SizedBox(height: 20),
          _buildNotificationSection(),
          const SizedBox(height: 20),
          _buildAlertSection(),
          const SizedBox(height: 20),
          _buildAboutSection(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return _buildSection(
      title: 'Profile',
      icon: '👨‍👩‍👧‍👦',
      children: [
        _buildTextSetting(
          label: 'Fridge Name',
          controller: _nameController,
          hint: 'e.g. Family Fridge',
          onChanged: (v) => setState(() => _familyName = v),
        ),
      ],
    );
  }

  Widget _buildNotificationSection() {
    return _buildSection(
      title: 'Notifications',
      icon: '🔔',
      children: [
        _buildSwitchTile(
          title: 'Enable Notifications',
          subtitle: 'Get alerts when items are expiring',
          value: _notificationsEnabled,
          onChanged: (v) => setState(() => _notificationsEnabled = v),
        ),
        const Divider(height: 1, color: AppTheme.divider),
        _buildSwitchTile(
          title: 'Daily Summary',
          subtitle: 'Morning report of expiring items',
          value: _dailyReminder,
          onChanged: _notificationsEnabled
              ? (v) => setState(() => _dailyReminder = v)
              : null,
        ),
      ],
    );
  }

  Widget _buildAlertSection() {
    return _buildSection(
      title: 'Alert Preferences',
      icon: '⏰',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Alert me $_alertDaysBefore days before expiry',
                style: GoogleFonts.sarabun(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppTheme.primary,
                  thumbColor: AppTheme.primary,
                  inactiveTrackColor: AppTheme.divider,
                  overlayColor: AppTheme.primary.withValues(alpha: 0.1),
                ),
                child: Slider(
                  value: _alertDaysBefore.toDouble(),
                  min: 1,
                  max: 7,
                  divisions: 6,
                  label: '$_alertDaysBefore days',
                  onChanged: (v) =>
                      setState(() => _alertDaysBefore = v.round()),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '1 day',
                    style: GoogleFonts.sarabun(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    '7 days',
                    style: GoogleFonts.sarabun(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _buildSection(
      title: 'About',
      icon: 'ℹ️',
      children: [
        _buildInfoTile('Version', '1.0.0'),
        const Divider(height: 1, color: AppTheme.divider),
        _buildInfoTile('OCR Scanning', 'Coming Soon'),
        const Divider(height: 1, color: AppTheme.divider),
        _buildInfoTile('Data Storage', 'Local Device'),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required String icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.sarabun(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.divider),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: GoogleFonts.sarabun(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color:
              onChanged == null ? AppTheme.textSecondary : AppTheme.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.sarabun(fontSize: 12, color: AppTheme.textSecondary),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppTheme.primary,
    );
  }

  Widget _buildTextSetting({
    required String label,
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.sarabun(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            onChanged: onChanged,
            style: GoogleFonts.sarabun(fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.sarabun(color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.sarabun(
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.sarabun(
              fontSize: 14,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
