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

      // Liste des clés requises
      List<String> requiredKeys = [];
      
      // Ajoutez ici les nouvelles clés requises pour l'API si nécessaire
      // Exemple:
      // requiredKeys.addAll([
      //   'API_BASE_URL',
      //   'API_KEY',
      // ]);

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


  // Ajoutez ici les nouveaux getters pour les variables d'environnement API si nécessaire
  // Exemple:
  // static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? '';
  // static String get apiKey => dotenv.env['API_KEY'] ?? '';
}