import 'package:flutter/material.dart';

/// Interface pour les services de thème
abstract class ThemeInterface {
  /// Obtient le thème actuel
  ThemeData get currentTheme;
  
  /// Obtient le thème clair
  ThemeData get lightTheme;
  
  /// Obtient le thème sombre
  ThemeData get darkTheme;
  
  /// Obtient le mode de thème actuel
  ThemeMode get themeMode;
  
  /// Définit le mode de thème
  Future<void> setThemeMode(ThemeMode mode);
  
  /// Bascule entre les thèmes clair et sombre
  Future<void> toggleThemeMode();
  
  /// Vérifie si le thème actuel est sombre
  bool get isDarkMode;
  
  /// Obtient la couleur primaire
  Color get primaryColor;
  
  /// Obtient la couleur secondaire
  Color get secondaryColor;
  
  /// Obtient la couleur d'accentuation
  Color get accentColor;
  
  /// Obtient la couleur d'arrière-plan
  Color get backgroundColor;
  
  /// Obtient la couleur de carte
  Color get cardColor;
  
  /// Obtient la couleur de texte
  Color get textColor;
  
  /// Obtient la couleur de texte secondaire
  Color get secondaryTextColor;
  
  /// Obtient la couleur de succès
  Color get successColor;
  
  /// Obtient la couleur d'erreur
  Color get errorColor;
  
  /// Obtient la couleur d'avertissement
  Color get warningColor;
  
  /// Obtient la couleur d'information
  Color get infoColor;
  
  /// Obtient le style de texte pour les titres
  TextStyle get headlineStyle;
  
  /// Obtient le style de texte pour les sous-titres
  TextStyle get subtitleStyle;
  
  /// Obtient le style de texte pour le corps
  TextStyle get bodyStyle;
  
  /// Obtient le style de texte pour les petits textes
  TextStyle get captionStyle;
  
  /// Obtient le style de bouton élevé
  ButtonStyle get elevatedButtonStyle;
  
  /// Obtient le style de bouton texte
  ButtonStyle get textButtonStyle;
  
  /// Obtient le style de bouton contour
  ButtonStyle get outlinedButtonStyle;
  
  /// Obtient le style de carte
  CardTheme get cardTheme;
  
  /// Obtient le style d'appbar
  AppBarTheme get appBarTheme;
  
  /// Obtient le style de champ de texte
  InputDecorationTheme get inputDecorationTheme;
  
  /// Ajoute un écouteur pour les changements de thème
  void addListener(VoidCallback listener);
  
  /// Supprime un écouteur
  void removeListener(VoidCallback listener);
} 