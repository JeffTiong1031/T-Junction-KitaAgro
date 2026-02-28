import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported locales for the app
enum AppLanguage {
  english('en', 'English', '🇬🇧'),
  malay('ms', 'Bahasa Melayu', '🇲🇾'),
  chinese('zh', '中文', '🇨🇳');

  final String code;
  final String displayName;
  final String flag;

  const AppLanguage(this.code, this.displayName, this.flag);

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => AppLanguage.english,
    );
  }
}

/// LanguageService manages the current language and persists the selection.
/// It extends ChangeNotifier so the whole widget tree can rebuild on changes.
class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';

  AppLanguage _currentLanguage = AppLanguage.english;
  AppLanguage get currentLanguage => _currentLanguage;

  LanguageService() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_languageKey) ?? 'en';
    _currentLanguage = AppLanguage.fromCode(code);
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_currentLanguage == language) return;
    _currentLanguage = language;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language.code);
  }

  /// Get the Locale for MaterialApp
  Locale get locale => Locale(_currentLanguage.code);
}
