import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppLanguage extends ChangeNotifier {
  static const String _boxName = 'app_settings';
  static const String _languageKey = 'language';

  static const Locale thai = Locale('th', 'TH');
  static const Locale english = Locale('en', 'US');

  static String get currentLanguageCode {
    return _currentLanguageCode;
  }

  static String _currentLanguageCode = 'th';

  Locale _locale = thai;

  Locale get locale => _locale;

  bool get isThai => _locale.languageCode == 'th';

  bool get isEnglish => _locale.languageCode == 'en';

  Future<void> init() async {
    final box = await Hive.openBox(_boxName);

    final savedLanguage = box.get(_languageKey, defaultValue: 'th');

    if (savedLanguage == 'en') {
      _locale = english;
      _currentLanguageCode = 'en';
    } else {
      _locale = thai;
      _currentLanguageCode = 'th';
    }

    notifyListeners();
  }

  Future<void> setLanguage(Locale locale) async {
    if (locale.languageCode == _locale.languageCode) {
      return;
    }

    _locale = locale;
    _currentLanguageCode = locale.languageCode;

    final box = await Hive.openBox(_boxName);

    await box.put(
      _languageKey,
      locale.languageCode,
    );

    notifyListeners();
  }

  Future<void> setThai() async {
    await setLanguage(thai);
  }

  Future<void> setEnglish() async {
    await setLanguage(english);
  }
}
