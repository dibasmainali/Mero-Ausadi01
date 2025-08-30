import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class LanguageProvider with ChangeNotifier {
  Locale _currentLocale = const Locale('en', 'US');
  static const String _languageKey = 'selected_language';

  Locale get currentLocale => _currentLocale;
  bool get isEnglish => _currentLocale.languageCode == 'en';
  bool get isNepali => _currentLocale.languageCode == 'ne';

  LanguageProvider() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString(_languageKey);
    
    if (languageCode != null) {
      _currentLocale = Locale(languageCode);
      notifyListeners();
    }
  }

  Future<void> setLanguage(String languageCode) async {
    _currentLocale = Locale(languageCode);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
    
    notifyListeners();
  }

  String getString(String key) {
    final Map<String, String> strings = isEnglish ? AppStrings.en : AppStrings.ne;
    return strings[key] ?? key;
  }
}
