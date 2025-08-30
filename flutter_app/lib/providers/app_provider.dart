import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppProvider with ChangeNotifier {
  bool _isFirstLaunch = true;
  bool _isDarkMode = false;
  bool _isOfflineMode = false;
  String? _error;

  bool get isFirstLaunch => _isFirstLaunch;
  bool get isDarkMode => _isDarkMode;
  bool get isOfflineMode => _isOfflineMode;
  String? get error => _error;

  AppProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isFirstLaunch = prefs.getBool('is_first_launch') ?? true;
    _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    _isOfflineMode = prefs.getBool('is_offline_mode') ?? false;
    notifyListeners();
  }

  Future<void> setFirstLaunch(bool value) async {
    _isFirstLaunch = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_launch', value);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', value);
    notifyListeners();
  }

  Future<void> setOfflineMode(bool value) async {
    _isOfflineMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_offline_mode', value);
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
