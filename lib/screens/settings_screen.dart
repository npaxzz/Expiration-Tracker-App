import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/notification_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _settingsBoxName = 'app_settings';

  static const String _familyNameKey = 'family_name';

  bool _notificationsEnabled = true;

  bool _dailyReminder = true;

  int _alertDaysBefore = 3;

  String _familyName = 'Family Fridge';

  final TextEditingController _nameController = TextEditingController(
    text: 'Family Fridge',
  );

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadSettings();
  }

  // ============================================================
  // LOAD SETTINGS
  // ============================================================

  Future<void> _loadSettings() async {
    if (!Hive.isBoxOpen(
      _settingsBoxName,
    )) {
      await Hive.openBox(
        _settingsBoxName,
      );
    }

    final box = Hive.box(_settingsBoxName);

    if (!mounted) return;

    setState(() {
      _notificationsEnabled = box.get(
        'notifications_enabled',
        defaultValue: true,
      ) as bool;

      _dailyReminder = box.get(
        'daily_reminder',
        defaultValue: true,
      ) as bool;

      _alertDaysBefore = box.get(
        'alert_days_before',
        defaultValue: 3,
      ) as int;

      _familyName = box.get(
        _familyNameKey,
        defaultValue: 'Family Fridge',
      ) as String;

      _nameController.text = _familyName;
    });
  }

  // ============================================================
  // NOTIFICATION SWITCH
  // ============================================================

  Future<void> _setNotificationsEnabled(
    bool value,
  ) async {
    setState(() {
      _notificationsEnabled = value;
    });

    await NotificationService.setNotificationsEnabled(
      value,
    );

    if (value) {
      await NotificationService.scheduleDailySummary();
    }
  }

  // ============================================================
  // DAILY SUMMARY
  // ============================================================

  Future<void> _setDailyReminder(
    bool value,
  ) async {
    setState(() {
      _dailyReminder = value;
    });

    await NotificationService.setDailyReminder(
      value,
    );
  }

  // ============================================================
  // ALERT DAYS
  // ============================================================

  Future<void> _setAlertDays(
    int value,
  ) async {
    setState(() {
      _alertDaysBefore = value;
    });

    await NotificationService.setAlertDaysBefore(
      value,
    );
  }

  // ============================================================
  // FAMILY NAME
  // ============================================================

  Future<void> _saveFamilyName(
    String value,
  ) async {
    setState(() {
      _familyName = value;
    });

    final box = Hive.box(
      _settingsBoxName,
    );

    await box.put(
      _familyNameKey,
      value,
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _nameController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
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
          const SizedBox(
            height: 20,
          ),
          _buildNotificationSection(),
          const SizedBox(
            height: 20,
          ),
          _buildAlertSection(),
          const SizedBox(
            height: 20,
          ),
          _buildAboutSection(),
          const SizedBox(
            height: 40,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROFILE
  // ============================================================

  Widget _buildProfileSection() {
    return _buildSection(
      title: 'Profile',
      icon: '👨‍👩‍👧‍👦',
      children: [
        _buildTextSetting(
          label: 'Fridge Name',
          controller: _nameController,
          hint: 'e.g. Family Fridge',
          onChanged: _saveFamilyName,
        ),
      ],
    );
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  Widget _buildNotificationSection() {
    return _buildSection(
      title: 'Notifications',
      icon: '🔔',
      children: [
        _buildSwitchTile(
          title: 'Enable Notifications',
          subtitle: 'Get alerts when items are expiring',
          value: _notificationsEnabled,
          onChanged: _setNotificationsEnabled,
        ),
        const Divider(
          height: 1,
          color: AppTheme.divider,
        ),
        _buildSwitchTile(
          title: 'Daily Summary',
          subtitle: 'Check your fridge every morning at 9:00 AM',
          value: _dailyReminder,
          onChanged: _notificationsEnabled ? _setDailyReminder : null,
        ),
      ],
    );
  }

  // ============================================================
  // ALERT PREFERENCES
  // ============================================================

  Widget _buildAlertSection() {
    return _buildSection(
      title: 'Alert Preferences',
      icon: '⏰',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Alert me $_alertDaysBefore '
                'days before expiry',
                style: GoogleFonts.sarabun(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppTheme.primary,
                  thumbColor: AppTheme.primary,
                  inactiveTrackColor: AppTheme.divider,
                  overlayColor: AppTheme.primary.withValues(
                    alpha: 0.1,
                  ),
                ),
                child: Slider(
                  value: _alertDaysBefore.toDouble(),
                  min: 1,
                  max: 7,
                  divisions: 6,
                  label: '$_alertDaysBefore days',
                  onChanged: _notificationsEnabled
                      ? (value) {
                          _setAlertDays(
                            value.round(),
                          );
                        }
                      : null,
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

  // ============================================================
  // ABOUT
  // ============================================================

  Widget _buildAboutSection() {
    return _buildSection(
      title: 'About',
      icon: 'ℹ️',
      children: [
        _buildInfoTile(
          'Version',
          '1.0.0',
        ),
        const Divider(
          height: 1,
          color: AppTheme.divider,
        ),
        _buildInfoTile(
          'OCR & Classification Scanning',
          'gemini-2.5-flash',
        ),
        const Divider(
          height: 1,
          color: AppTheme.divider,
        ),
        _buildInfoTile(
          'Data Storage',
          'Hive',
        ),
      ],
    );
  }

  // ============================================================
  // SECTION
  // ============================================================

  Widget _buildSection({
    required String title,
    required String icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            bottom: 10,
          ),
          child: Row(
            children: [
              Text(
                icon,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(
                width: 8,
              ),
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
            borderRadius: BorderRadius.circular(
              16,
            ),
            border: Border.all(
              color: AppTheme.divider,
            ),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SWITCH TILE
  // ============================================================

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
        style: GoogleFonts.sarabun(
          fontSize: 12,
          color: AppTheme.textSecondary,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppTheme.primary,
    );
  }

  // ============================================================
  // TEXT SETTING
  // ============================================================

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
          const SizedBox(
            height: 8,
          ),
          TextField(
            controller: controller,
            onChanged: onChanged,
            style: GoogleFonts.sarabun(
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.sarabun(
                color: AppTheme.textSecondary,
              ),
              filled: true,
              fillColor: AppTheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  10,
                ),
                borderSide: const BorderSide(
                  color: AppTheme.divider,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  10,
                ),
                borderSide: const BorderSide(
                  color: AppTheme.divider,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  10,
                ),
                borderSide: const BorderSide(
                  color: AppTheme.primary,
                ),
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

  // ============================================================
  // INFO TILE
  // ============================================================

  Widget _buildInfoTile(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.sarabun(
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(
            width: 12,
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
