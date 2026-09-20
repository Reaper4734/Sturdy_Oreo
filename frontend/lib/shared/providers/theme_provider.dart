import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kThemePrefKey = 'oreo_app_theme_mode';

/// Manages the application theme mode ('Dark', 'Light', 'System') with persistent storage.
class ThemeModeNotifier extends StateNotifier<String> {
  ThemeModeNotifier() : super('Light') {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kThemePrefKey);
      if (saved != null && (saved == 'Dark' || saved == 'Light' || saved == 'System')) {
        state = saved;
      }
    } catch (e) {
      debugPrint('Failed to load theme mode preference: $e');
    }
  }

  Future<void> setThemeMode(String mode) async {
    if (mode != 'Dark' && mode != 'Light' && mode != 'System') return;
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kThemePrefKey, mode);
    } catch (e) {
      debugPrint('Failed to save theme mode preference: $e');
    }
  }

  ThemeMode get currentThemeMode {
    switch (state) {
      case 'Dark':
        return ThemeMode.dark;
      case 'System':
        return ThemeMode.system;
      case 'Light':
      default:
        return ThemeMode.light;
    }
  }
}

/// Global provider for theme mode state ('Dark', 'Light', 'System').
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, String>((ref) {
  return ThemeModeNotifier();
});
