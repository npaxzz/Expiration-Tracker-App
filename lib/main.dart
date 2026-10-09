import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/food_provider.dart';
import 'models/notification_service.dart';
import 'services/background_service.dart';

import 'screens/home_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/recipe_screen.dart';

import 'theme/app_theme.dart';
import 'localization/app_language.dart';
import 'localization/app_text.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================================
  // HIVE
  // ============================================================

  await FoodProvider.initHive();

  // ============================================================
  // LANGUAGE
  // ============================================================

  final appLanguage = AppLanguage();
  await appLanguage.init();

  // ============================================================
  // NOTIFICATION
  // ============================================================

  await NotificationService.init();

  // ============================================================
  // BACKGROUND SERVICE
  // ============================================================

  await BackgroundService.init();

  // ============================================================
  // DAILY 9 AM NOTIFICATION
  // ============================================================

  //check การแจ้งเตือน
  //await BackgroundService.testDailyCheckNow();

  await BackgroundService.scheduleDailyCheck();

  // ============================================================
  // SYSTEM UI
  // ============================================================

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // ============================================================
  // APP
  // ============================================================

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppLanguage>.value(
          value: appLanguage,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final language = context.watch<AppLanguage>();

    return ChangeNotifierProvider(
      create: (_) => FoodProvider()..init(),
      child: MaterialApp(
        title: 'Smart Expiration Tracker',
        theme: AppTheme.theme,
        debugShowCheckedModeBanner: false,

        // ========================================================
        // GLOBAL LANGUAGE
        // ========================================================

        locale: language.locale,

        supportedLocales: const [
          AppLanguage.thai,
          AppLanguage.english,
        ],

        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        home: const MainNavigation(),
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({
    super.key,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    AlertsScreen(),
    RecipeScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(
    BuildContext context,
  ) {
    context.watch<AppLanguage>();
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildFAB() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2E7D32),
            Color(0xFF1B5E20),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withValues(
              alpha: 0.4,
            ),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ScanScreen(),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(
          Icons.add_rounded,
          size: 30,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.08,
            ),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(
                0,
                Icons.home_rounded,
                Icons.home_outlined,
                AppText.home,
              ),
              _navItem(
                1,
                Icons.notifications_rounded,
                Icons.notifications_none_rounded,
                AppText.alerts,
                showBadge: true,
              ),
              const SizedBox(
                width: 60,
              ),
              _navItem(
                2,
                Icons.restaurant_menu_rounded,
                Icons.restaurant_menu_outlined,
                AppText.recipes,
              ),
              _navItem(
                3,
                Icons.settings_rounded,
                Icons.settings_outlined,
                AppText.settings,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label, {
    bool showBadge = false,
  }) {
    final isSelected = _selectedIndex == index;

    final provider = context.watch<FoodProvider>();

    final hasAlerts = provider.expiredItems.isNotEmpty ||
        provider.expiringSoonItems.isNotEmpty;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 200,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(
                  alpha: 0.08,
                )
              : Colors.transparent,
          borderRadius: BorderRadius.circular(
            12,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? activeIcon : inactiveIcon,
                  color:
                      isSelected ? AppTheme.primary : const Color(0xFFB0BEC5),
                  size: 24,
                ),
                if (showBadge && hasAlerts)
                  Positioned(
                    top: -2,
                    right: -3,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(
              height: 3,
            ),
            Text(
              label,
              style: GoogleFonts.sarabun(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected
                    ? AppTheme.primary
                    : const Color(
                        0xFFB0BEC5,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
