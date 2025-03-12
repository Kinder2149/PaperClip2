import 'package:flutter/material.dart';
import 'theme_service.dart';

/// Adaptateur pour assurer la compatibilité avec l'ancien code
class ThemeAdapter {
  final ThemeService _themeService;
  
  /// Constructeur
  ThemeAdapter(this._themeService);
  
  /// Obtient le thème actuel (compatible avec l'ancien code)
  ThemeData get currentTheme => _themeService.currentTheme;
  
  /// Obtient le thème clair (compatible avec l'ancien code)
  ThemeData get lightTheme => _themeService.lightTheme;
  
  /// Obtient le thème sombre (compatible avec l'ancien code)
  ThemeData get darkTheme => _themeService.darkTheme;
  
  /// Obtient le mode de thème actuel (compatible avec l'ancien code)
  ThemeMode get themeMode => _themeService.themeMode;
  
  /// Définit le mode de thème (compatible avec l'ancien code)
  Future<void> setThemeMode(ThemeMode mode) async {
    await _themeService.setThemeMode(mode);
  }
  
  /// Bascule entre les thèmes clair et sombre (compatible avec l'ancien code)
  Future<void> toggleThemeMode() async {
    await _themeService.toggleThemeMode();
  }
  
  /// Vérifie si le thème actuel est sombre (compatible avec l'ancien code)
  bool get isDarkMode => _themeService.isDarkMode;
  
  /// Obtient la couleur primaire (compatible avec l'ancien code)
  Color get primaryColor => _themeService.primaryColor;
  
  /// Obtient la couleur secondaire (compatible avec l'ancien code)
  Color get secondaryColor => _themeService.secondaryColor;
  
  /// Obtient la couleur d'accentuation (compatible avec l'ancien code)
  Color get accentColor => _themeService.accentColor;
  
  /// Obtient la couleur d'arrière-plan (compatible avec l'ancien code)
  Color get backgroundColor => _themeService.backgroundColor;
  
  /// Obtient la couleur de carte (compatible avec l'ancien code)
  Color get cardColor => _themeService.cardColor;
  
  /// Obtient la couleur de texte (compatible avec l'ancien code)
  Color get textColor => _themeService.textColor;
  
  /// Obtient la couleur de texte secondaire (compatible avec l'ancien code)
  Color get secondaryTextColor => _themeService.secondaryTextColor;
  
  /// Obtient la couleur de succès (compatible avec l'ancien code)
  Color get successColor => _themeService.successColor;
  
  /// Obtient la couleur d'erreur (compatible avec l'ancien code)
  Color get errorColor => _themeService.errorColor;
  
  /// Obtient la couleur d'avertissement (compatible avec l'ancien code)
  Color get warningColor => _themeService.warningColor;
  
  /// Obtient la couleur d'information (compatible avec l'ancien code)
  Color get infoColor => _themeService.infoColor;
  
  /// Obtient le style de texte pour les titres (compatible avec l'ancien code)
  TextStyle get headlineStyle => _themeService.headlineStyle;
  
  /// Obtient le style de texte pour les sous-titres (compatible avec l'ancien code)
  TextStyle get subtitleStyle => _themeService.subtitleStyle;
  
  /// Obtient le style de texte pour le corps (compatible avec l'ancien code)
  TextStyle get bodyStyle => _themeService.bodyStyle;
  
  /// Obtient le style de texte pour les petits textes (compatible avec l'ancien code)
  TextStyle get captionStyle => _themeService.captionStyle;
  
  /// Obtient le style de bouton élevé (compatible avec l'ancien code)
  ButtonStyle get elevatedButtonStyle => _themeService.elevatedButtonStyle;
  
  /// Obtient le style de bouton texte (compatible avec l'ancien code)
  ButtonStyle get textButtonStyle => _themeService.textButtonStyle;
  
  /// Obtient le style de bouton contour (compatible avec l'ancien code)
  ButtonStyle get outlinedButtonStyle => _themeService.outlinedButtonStyle;
  
  /// Obtient le style de carte (compatible avec l'ancien code)
  CardTheme get cardTheme => _themeService.cardTheme;
  
  /// Obtient le style d'appbar (compatible avec l'ancien code)
  AppBarTheme get appBarTheme => _themeService.appBarTheme;
  
  /// Obtient le style de champ de texte (compatible avec l'ancien code)
  InputDecorationTheme get inputDecorationTheme => _themeService.inputDecorationTheme;
  
  /// Ajoute un écouteur pour les changements de thème (compatible avec l'ancien code)
  void addListener(VoidCallback listener) {
    _themeService.addListener(listener);
  }
  
  /// Supprime un écouteur (compatible avec l'ancien code)
  void removeListener(VoidCallback listener) {
    _themeService.removeListener(listener);
  }
} 