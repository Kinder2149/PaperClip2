// lib/core/constants/app_constants.dart
import 'package:flutter/material.dart';

enum Environment {
  development,
  staging,
  production
}

class AppConstants {
  static const String APP_NAME = 'PaperClip Empire';
  static const String VERSION = '1.0.3';
  static const String AUTHOR = 'Kinder2149';

  static const Environment currentEnvironment = Environment.production;

  // Autres constantes restent inchangées
  static const String ASSETS_PATH = 'assets/';
  static const String AUDIO_PATH = '${ASSETS_PATH}audio/';
  static const String IMAGES_PATH = '${ASSETS_PATH}images/';

  // Mettez à jour le thème pour utiliser les nouvelles propriétés de TextTheme
  static final ThemeData DEFAULT_THEME = ThemeData(
    primarySwatch: Colors.deepPurple,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    fontFamily: 'Roboto',
    textTheme: TextTheme(
      titleLarge: TextStyle(
        fontSize: 20.0,
        fontWeight: FontWeight.bold,
        color: Colors.deepPurple,
      ),
      bodyMedium: TextStyle(
        fontSize: 16.0,
        color: Colors.black87,
      ),
    ),
  );
}