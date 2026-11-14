import 'package:basic_bible/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// This provider holds the current language code (e.g., 'en', 'es')
final languageProvider = StateNotifierProvider<LanguageNotifier, String>(
  (ref) => LanguageNotifier(),
);

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super('en') {
    _loadLanguage();
  }

  /// Load saved language from persistent storage
  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('languageCode');
    if (savedLang != null && isSupportedLanguage(savedLang)) {
      state = savedLang;
    } else {
      // Auto-detect the system language on first launch. If the app has no
      // translation for it, use English (otherwise Flutter falls back to the
      // first supported locale, which is German).
      final systemLang =
          WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      final defaultLang = isSupportedLanguage(systemLang) ? systemLang : 'en';
      state = defaultLang;
      await prefs.setString('languageCode', defaultLang);
    }
  }

  /// Whether the app ships UI translations for [code].
  static bool isSupportedLanguage(String code) => AppLocalizations
      .supportedLocales
      .any((locale) => locale.languageCode == code);

  /// Update language and save it persistently
  Future<void> setLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', code);
    state = code;
  }
}
