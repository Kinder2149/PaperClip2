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

      try {
        await dotenv.load(fileName: ".env");
      } catch (e) {
        if (kDebugMode) {
          print('Erreur lors du chargement du fichier .env: $e');
          print('Utilisation des valeurs par défaut pour toutes les variables');
        }
        // On continue même si le fichier .env n'existe pas ou est invalide
      }

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

      // Vérification des clés sans bloquer l'exécution
      for (final key in requiredKeys) {
        if (dotenv.env[key]?.isEmpty ?? true) {
          if (kDebugMode) {
            print('Attention: $key n\'est pas défini dans le fichier .env');
          }
          // Injecter des valeurs par défaut pour certaines variables critiques
          switch(key) {
            case 'APPLE_CLIENT_ID':
              // Apple Auth est souvent optionnel, définir une valeur vide par défaut
              dotenv.env[key] = '';
              break;
          }
        }
      }

      if (kDebugMode) {
        print('Configuration de l\'environnement terminée');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'initialisation des variables d\'environnement: $e');
        print('Chemin de recherche du fichier: ${Directory.current.path}');
      }
    }
  }

  // Configuration API
  static String get apiBaseUrl {
    // Priorité à API_BASE_URL si défini
    if (dotenv.env['API_BASE_URL']?.isNotEmpty ?? false) {
      return dotenv.env['API_BASE_URL']!;
    }
    
    // Sinon utiliser l'URL appropriée selon l'environnement
    return kDebugMode 
      ? (dotenv.env['API_DEV_URL'] ?? 'http://10.0.2.2:8000/api') 
      : (dotenv.env['API_PROD_URL'] ?? 'https://paperclip2-api.onrender.com/api');
  }
      
  static String get apiKey => dotenv.env['API_KEY'] ?? '';

  // Configuration stockage
  static String get s3BucketName => dotenv.env['S3_BUCKET_NAME'] ?? '';
  static String get s3Region => dotenv.env['S3_REGION'] ?? '';

  // Configuration d'authentification
  static String get googleClientId => dotenv.env['GOOGLE_CLIENT_ID'] ?? '65117274232-he1plcjjh5auj4j5e79otl2id09hsap3.apps.googleusercontent.com';
  static String get appleClientId => dotenv.env['APPLE_CLIENT_ID'] ?? '';
  
  // Vérifier si Apple Auth est configuré
  static bool get isAppleAuthConfigured => appleClientId.isNotEmpty;
  
  // Vérifier si Google Auth est configuré
  static bool get isGoogleAuthConfigured => googleClientId.isNotEmpty;
}