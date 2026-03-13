// lib/services/theme_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

class ThemeService extends ChangeNotifier {
  static const String _themePreferenceKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.light;
  
  ThemeMode get themeMode => _themeMode;

  // Singleton pattern
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();
  
  // Initialisation du service
  Future<void> initialize() async {
    await _loadThemeMode();
  }
  
  // Chargement du thème depuis les préférences
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeIndex = prefs.getInt(_themePreferenceKey);
      if (themeModeIndex != null) {
        _themeMode = ThemeMode.values[themeModeIndex];
      } else {
        // Utiliser le mode clair par défaut
        _themeMode = ThemeMode.light;
      }
      notifyListeners();
    } catch (e) {
      appLogger.warn('[STATE] Erreur lors du chargement du thème: $e');
    }
  }
  
  // Enregistrement du thème dans les préférences
  Future<void> _saveThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themePreferenceKey, _themeMode.index);
    } catch (e) {
      appLogger.warn('[STATE] Erreur lors de la sauvegarde du thème: $e');
    }
  }
  
  // Basculement entre mode clair et sombre
  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    await _saveThemeMode();
  }
  
  // Définition d'un mode de thème spécifique
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _saveThemeMode();
  }
  
  // Thèmes personnalisés
  ThemeData getLightTheme() {
    final scheme = ColorScheme.fromSeed(seedColor: Colors.deepPurple);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: Brightness.light,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF673AB7),
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
        ),
      ),
    );
  }
  
  ThemeData getDarkTheme() {
    final scheme = ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: Brightness.dark,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
        ),
      ),
      cardColor: const Color(0xFF1E1E1E),
    );
  }
}
