import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io' show Directory;
import 'package:flutter/foundation.dart';

class EnvConfig {
  static Future<void> load() async {
    try {
      // Ajout de la vérification du mode debug
      if (kDebugMode) {
        print('Tentative de chargement du fichier .env...');
      }

      await dotenv.load(fileName: ".env");

      final requiredKeys = [
        'API_BASE_URL',
        'API_KEY',
        'API_PROD_URL',
        'API_DEV_URL',
        'S3_BUCKET_NAME',
        'S3_REGION',
        'GOOGLE_CLIENT_ID',
        'APPLE_CLIENT_ID'
      ];

      // Vérification des clés
      for (final key in requiredKeys) {
        if (dotenv.env[key]?.isEmpty ?? true) {
          if (kDebugMode) {
            print('Attention: $key n\'est pas défini dans le fichier .env');
          }
        }
      }

      if (kDebugMode) {
        print('Fichier .env chargé avec succès');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors du chargement du fichier .env: $e');
        print('Chemin de recherche du fichier: ${Directory.current.path}');
      }
      rethrow;
    }
  }

  // Configuration API
  static String get apiBaseUrl => kDebugMode 
      ? (dotenv.env['API_DEV_URL'] ?? 'http://10.0.2.2:8000/api') 
      : (dotenv.env['API_PROD_URL'] ?? 'https://paperclip2-api.onrender.com/api');
      
  static String get apiKey => dotenv.env['API_KEY'] ?? '';

  // Configuration stockage
  static String get s3BucketName => dotenv.env['S3_BUCKET_NAME'] ?? '';
  static String get s3Region => dotenv.env['S3_REGION'] ?? '';

  // Configuration d'authentification
  static String get googleClientId => dotenv.env['GOOGLE_CLIENT_ID'] ?? '';
  static String get appleClientId => dotenv.env['APPLE_CLIENT_ID'] ?? '';
}