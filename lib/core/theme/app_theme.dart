// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Couleurs de base
  static const Color _primaryColor = Color(0xFF6A1B9A);
  static const Color _accentColor = Color(0xFFAA00FF);
  static const Color _backgroundColor = Color(0xFFF5F5F5);

  // Thème clair
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: _primaryColor,
      accentColor: _accentColor,
      scaffoldBackgroundColor: _backgroundColor,

      // Configuration de la police
      fontFamily: 'Roboto',

      // AppBar
      appBarTheme: AppBarTheme(
        color: _primaryColor,
        elevation: 4,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Boutons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          primary: _primaryColor,
          onPrimary: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Textes
      textTheme: TextTheme(
        headline1: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        headline2: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        bodyText1: TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        bodyText2: TextStyle(
          fontSize: 14,
          color: Colors.black54,
        ),
      ),

      // Cartes
      cardTheme: CardTheme(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        shadowColor: Colors.black26,
      ),

      // Entrées de texte
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _primaryColor.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
      ),

      // Autres configurations
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  // Thème sombre
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: _primaryColor,
      colorScheme.secondary : _accentColor,
      scaffoldBackgroundColor: Colors.grey[900],

      // Similar configuration to lightTheme,
      // but with dark mode specific colors
      appBarTheme: AppBarTheme(
        color: Colors.grey[850],
        elevation: 4,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      // Autres configurations sombres...
    );
  }

  // Méthodes utilitaires
  static SystemUiOverlayStyle get systemUiOverlayStyle =>
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      );
}