import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io' show Directory, Platform;
import 'package:flutter/foundation.dart';

class EnvConfig {
  static Future<void> load() async {
    try {
      // Ajout de la vérification du mode debug
      if (kDebugMode) {
        print('Tentative de chargement du fichier .env...');
      }

      await dotenv.load(fileName: ".env");

      // Liste des clés requises en fonction de la plateforme
      List<String> requiredKeys = [];
      
      // Ajout des clés Android si on est sur Android
      if (Platform.isAndroid) {
        requiredKeys.addAll([
          'FIREBASE_ANDROID_API_KEY',
          'FIREBASE_ANDROID_APP_ID',
        ]);
      }
      
      // Ajout des clés iOS si on est sur iOS
      if (Platform.isIOS) {
        requiredKeys.addAll([
          'FIREBASE_IOS_API_KEY',
          'FIREBASE_IOS_APP_ID',
        ]);
      }
      
      // Ajout des clés Web si on est sur le Web
      if (kIsWeb) {
        requiredKeys.addAll([
          'FIREBASE_WEB_API_KEY',
          'FIREBASE_WEB_APP_ID',
          'FIREBASE_WEB_PROJECT_ID',
          'FIREBASE_WEB_AUTH_DOMAIN',
          'FIREBASE_WEB_DATABASE_URL',
          'FIREBASE_WEB_STORAGE_BUCKET',
        ]);
      }

      // Vérification des clés requises pour la plateforme actuelle
      for (final key in requiredKeys) {
        if (dotenv.env[key]?.isEmpty ?? true) {
          throw Exception('Configuration manquante: $key n\'est pas défini dans le fichier .env');
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


  static String get firebaseWebApiKey => dotenv.env['FIREBASE_WEB_API_KEY'] ?? '';
  static String get firebaseWebAppId => dotenv.env['FIREBASE_WEB_APP_ID'] ?? '';
  static String get firebaseWebProjectId => dotenv.env['FIREBASE_WEB_PROJECT_ID'] ?? '';
  static String get firebaseWebAuthDomain => dotenv.env['FIREBASE_WEB_AUTH_DOMAIN'] ?? '';
  static String get firebaseWebDatabaseUrl => dotenv.env['FIREBASE_WEB_DATABASE_URL'] ?? '';
  static String get firebaseWebStorageBucket => dotenv.env['FIREBASE_WEB_STORAGE_BUCKET'] ?? '';

  static String get firebaseAndroidApiKey => dotenv.env['FIREBASE_ANDROID_API_KEY'] ?? '';
  static String get firebaseAndroidAppId => dotenv.env['FIREBASE_ANDROID_APP_ID'] ?? '';

  static String get firebaseIosApiKey => dotenv.env['FIREBASE_IOS_API_KEY'] ?? '';
  static String get firebaseIosAppId => dotenv.env['FIREBASE_IOS_APP_ID'] ?? '';
}