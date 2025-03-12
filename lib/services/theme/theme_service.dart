import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_interface.dart';

/// Implémentation du service de thème
class ThemeService extends ChangeNotifier implements ThemeInterface {
  static const String _themePreferenceKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.system;
  
  /// Constructeur
  ThemeService() {
    _loadThemeMode();
  }
  
  /// Charge le mode de thème depuis les préférences
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeIndex = prefs.getInt(_themePreferenceKey);
      
      if (themeModeIndex != null) {
        _themeMode = ThemeMode.values[themeModeIndex];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement du mode de thème: $e');
    }
  }
  
  /// Sauvegarde le mode de thème dans les préférences
  Future<void> _saveThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themePreferenceKey, mode.index);
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde du mode de thème: $e');
    }
  }
  
  @override
  ThemeData get currentTheme => isDarkMode ? darkTheme : lightTheme;
  
  @override
  ThemeData get lightTheme => _createLightTheme();
  
  @override
  ThemeData get darkTheme => _createDarkTheme();
  
  @override
  ThemeMode get themeMode => _themeMode;
  
  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _saveThemeMode(mode);
    notifyListeners();
  }
  
  @override
  Future<void> toggleThemeMode() async {
    final newMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(newMode);
  }
  
  @override
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.window.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }
  
  @override
  Color get primaryColor => isDarkMode ? Colors.blue.shade700 : Colors.blue.shade600;
  
  @override
  Color get secondaryColor => isDarkMode ? Colors.amber.shade700 : Colors.amber.shade600;
  
  @override
  Color get accentColor => isDarkMode ? Colors.tealAccent.shade400 : Colors.tealAccent.shade700;
  
  @override
  Color get backgroundColor => isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50;
  
  @override
  Color get cardColor => isDarkMode ? Colors.grey.shade800 : Colors.white;
  
  @override
  Color get textColor => isDarkMode ? Colors.white : Colors.black87;
  
  @override
  Color get secondaryTextColor => isDarkMode ? Colors.white70 : Colors.black54;
  
  @override
  Color get successColor => isDarkMode ? Colors.green.shade400 : Colors.green.shade600;
  
  @override
  Color get errorColor => isDarkMode ? Colors.red.shade400 : Colors.red.shade600;
  
  @override
  Color get warningColor => isDarkMode ? Colors.orange.shade400 : Colors.orange.shade700;
  
  @override
  Color get infoColor => isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700;
  
  @override
  TextStyle get headlineStyle => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textColor,
  );
  
  @override
  TextStyle get subtitleStyle => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: textColor,
  );
  
  @override
  TextStyle get bodyStyle => TextStyle(
    fontSize: 16,
    color: textColor,
  );
  
  @override
  TextStyle get captionStyle => TextStyle(
    fontSize: 14,
    color: secondaryTextColor,
  );
  
  @override
  ButtonStyle get elevatedButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );
  
  @override
  ButtonStyle get textButtonStyle => TextButton.styleFrom(
    foregroundColor: primaryColor,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );
  
  @override
  ButtonStyle get outlinedButtonStyle => OutlinedButton.styleFrom(
    foregroundColor: primaryColor,
    side: BorderSide(color: primaryColor),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );
  
  @override
  CardTheme get cardTheme => CardTheme(
    color: cardColor,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    margin: const EdgeInsets.all(8),
  );
  
  @override
  AppBarTheme get appBarTheme => AppBarTheme(
    backgroundColor: primaryColor,
    elevation: 0,
    centerTitle: true,
    iconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  );
  
  @override
  InputDecorationTheme get inputDecorationTheme => InputDecorationTheme(
    filled: true,
    fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: primaryColor, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );
  
  /// Crée le thème clair
  ThemeData _createLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: Colors.white,
        background: backgroundColor,
        error: errorColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      appBarTheme: appBarTheme,
      cardTheme: cardTheme,
      inputDecorationTheme: inputDecorationTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(style: elevatedButtonStyle),
      textButtonTheme: TextButtonThemeData(style: textButtonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(style: outlinedButtonStyle),
      textTheme: TextTheme(
        headlineMedium: headlineStyle,
        titleMedium: subtitleStyle,
        bodyMedium: bodyStyle,
        bodySmall: captionStyle,
      ),
    );
  }
  
  /// Crée le thème sombre
  ThemeData _createDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: Colors.grey.shade800,
        background: backgroundColor,
        error: errorColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      appBarTheme: appBarTheme,
      cardTheme: cardTheme,
      inputDecorationTheme: inputDecorationTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(style: elevatedButtonStyle),
      textButtonTheme: TextButtonThemeData(style: textButtonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(style: outlinedButtonStyle),
      textTheme: TextTheme(
        headlineMedium: headlineStyle,
        titleMedium: subtitleStyle,
        bodyMedium: bodyStyle,
        bodySmall: captionStyle,
      ),
    );
  }
} 