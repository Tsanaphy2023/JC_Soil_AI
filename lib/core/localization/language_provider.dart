import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'app_localizations.dart';

class LanguageProvider extends ChangeNotifier {
  AppLanguage _currentLanguage = AppLanguage.thai; // Default language: Thai
  bool _isLoaded = false;

  AppLanguage get currentLanguage => _currentLanguage;
  String get currentFlag => _currentLanguage.flag;
  String get currentLabel => _currentLanguage.label;
  bool get isLoaded => _isLoaded;
  AppLocalizations get localizations => AppLocalizations(_currentLanguage);

  /// Translate key in current active language
  String t(String key) => localizations.t(key);

  /// Load user's saved language preference from local disk
  Future<void> loadPreferences() async {
    try {
      final file = await _getPrefsFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final data = jsonDecode(content) as Map<String, dynamic>;
          final code = data['language'] as String?;
          _currentLanguage = AppLanguage.fromCode(code);
        }
      }
    } catch (e) {
      debugPrint('[LanguageProvider] Error loading language preference: $e');
      _currentLanguage = AppLanguage.thai;
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Switch language, notify listeners, and persist selection
  Future<void> setLanguage(AppLanguage language) async {
    if (_currentLanguage == language) return;

    _currentLanguage = language;
    notifyListeners();

    try {
      final file = await _getPrefsFile();
      final data = {'language': language.code};
      await file.writeAsString(jsonEncode(data));
      debugPrint('[LanguageProvider] Saved language preference: ${language.code}');
    } catch (e) {
      debugPrint('[LanguageProvider] Error saving language preference: $e');
    }
  }

  Future<File> _getPrefsFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/app_preferences.json');
  }
}
