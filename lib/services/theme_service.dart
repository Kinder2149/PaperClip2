// lib/services/theme_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';
import '../theme/paperclip_colors.dart';
import '../theme/paperclip_typography.dart';

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
  
  // Thèmes personnalisés "Paperclip"
  ThemeData getLightTheme() {
    final colorScheme = ColorScheme.light(
      primary: PaperclipColors.steelBlue,
      onPrimary: Colors.white,
      secondary: PaperclipColors.copperOrange,
      onSecondary: Colors.white,
      tertiary: PaperclipColors.electricCyan,
      onTertiary: Colors.white,
      error: PaperclipColors.error,
      onError: Colors.white,
      surface: Colors.white,
      onSurface: PaperclipColors.neutral900,
      surfaceContainerHighest: PaperclipColors.neutral100,
      outline: PaperclipColors.divider,
    );
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      scaffoldBackgroundColor: PaperclipColors.neutral50,
      textTheme: PaperclipTypography.getTextTheme(isDark: false),
      
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: PaperclipColors.steelBlue,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: PaperclipTypography.h3.copyWith(color: Colors.white),
      ),
      
      // Cards
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Colors.white,
      ),
      
      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PaperclipColors.steelBlue,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: PaperclipTypography.button,
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: PaperclipColors.steelBlue,
          side: const BorderSide(color: PaperclipColors.steelBlue, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: PaperclipTypography.button,
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: PaperclipColors.steelBlue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: PaperclipTypography.button,
        ),
      ),
      
      // Input
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: PaperclipColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: PaperclipColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: PaperclipColors.steelBlue, width: 2),
        ),
        filled: true,
        fillColor: PaperclipColors.neutral50,
      ),
      
      // Divider
      dividerTheme: const DividerThemeData(
        color: PaperclipColors.divider,
        thickness: 1,
      ),
    );
  }
  
  ThemeData getDarkTheme() {
    final colorScheme = ColorScheme.dark(
      primary: PaperclipColors.electricCyan,
      onPrimary: PaperclipColors.neutral900,
      secondary: PaperclipColors.copperOrangeLight,
      onSecondary: PaperclipColors.neutral900,
      tertiary: PaperclipColors.steelBlueLight,
      onTertiary: Colors.white,
      error: PaperclipColors.errorLight,
      onError: PaperclipColors.neutral900,
      surface: PaperclipColors.neutral800,
      onSurface: Colors.white,
      surfaceContainerHighest: PaperclipColors.neutral700,
      outline: PaperclipColors.dividerDark,
    );
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      scaffoldBackgroundColor: PaperclipColors.neutral900,
      textTheme: PaperclipTypography.getTextTheme(isDark: true),
      
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: PaperclipColors.neutral800,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: PaperclipTypography.h3.copyWith(color: Colors.white),
      ),
      
      // Cards
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: PaperclipColors.neutral800,
      ),
      
      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PaperclipColors.electricCyan,
          foregroundColor: PaperclipColors.neutral900,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: PaperclipTypography.button,
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: PaperclipColors.electricCyan,
          side: const BorderSide(color: PaperclipColors.electricCyan, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: PaperclipTypography.button,
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: PaperclipColors.electricCyan,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: PaperclipTypography.button,
        ),
      ),
      
      // Input
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: PaperclipColors.dividerDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: PaperclipColors.dividerDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: PaperclipColors.electricCyan, width: 2),
        ),
        filled: true,
        fillColor: PaperclipColors.neutral700,
      ),
      
      // Divider
      dividerTheme: const DividerThemeData(
        color: PaperclipColors.dividerDark,
        thickness: 1,
      ),
    );
  }
}
