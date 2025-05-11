import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import '../firebase_options.dart';
import '../services/user/google_auth_service.dart';
import '../models/game_config.dart';
import './save/save_types.dart';
import 'save/storage/cloud_storage_engine.dart';

class FirebaseConfig {
  static final FirebaseStorage storage = FirebaseStorage.instance;
  static final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;

  static Future<void> initialize() async {
    try {
      // Configuration Remote Config
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      // Valeurs par défaut pour votre jeu
      await remoteConfig.setDefaults(const {
        'metal_per_paperclip': 0.15,
        'initial_price': 0.25,
        'efficiency_multiplier': 0.10,
        'max_efficiency_level': 8,
      });

      // Premier fetch avec gestion d'erreur
      await remoteConfig.fetchAndActivate();
    } catch (e, stack) {
      debugPrint('Error initializing Firebase Config: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }

  static Future<bool> saveGameToCloud(String userId, String saveData) async {
    try {
      // Récupérer le service d'authentification
      final authService = GoogleAuthService();
      final accessToken = await authService.getGoogleAccessToken();

      if (accessToken == null) {
        throw Exception('Impossible d\'obtenir un token d\'accès Google');
      }

      // Initialiser le stockage cloud
      final cloudEngine = CloudStorageEngine();
      final isInitialized = await cloudEngine.initialize();

      if (!isInitialized) {
        throw Exception('Échec de l\'initialisation du stockage Cloud');
      }

      // Créer un objet SaveGame temporaire pour la sauvegarde
      final saveJson = jsonDecode(saveData) as Map<String, dynamic>;
      final saveGameObj = SaveGame(
        id: userId, // Utiliser l'ID utilisateur comme ID de sauvegarde
        name: 'save_${DateTime.now().millisecondsSinceEpoch}',
        lastSaveTime: DateTime.now(),
        gameData: saveJson,
        version: GameConstants.VERSION,
      );

      // Sauvegarder dans le cloud
      await cloudEngine.save(saveGameObj);
      return true;
    } catch (e, stack) {
      debugPrint('Erreur lors de la sauvegarde dans le cloud: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
      return false;
    }
  }

  static Future<String?> loadGameFromCloud(String userId) async {
    try {
      // Récupérer le service d'authentification
      final authService = GoogleAuthService();
      final accessToken = await authService.getGoogleAccessToken();

      if (accessToken == null) {
        return null;
      }

      // Initialiser le stockage cloud
      final cloudEngine = CloudStorageEngine();
      final isInitialized = await cloudEngine.initialize();

      if (!isInitialized) {
        return null;
      }

      // Charger depuis le stockage cloud
      final saveGameObj = await cloudEngine.load(userId);
      if (saveGameObj == null) {
        return null;
      }

      // Convertir en chaîne JSON
      return jsonEncode(saveGameObj.toJson());
    } catch (e, stack) {
      debugPrint('Erreur lors du chargement depuis le cloud: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
      return null;
    }
  }

  static Future<bool> checkSaveExists(String userId) async {
    try {
      // Récupérer le service d'authentification
      final authService = GoogleAuthService();
      final accessToken = await authService.getGoogleAccessToken();

      if (accessToken == null) {
        return false;
      }

      // Initialiser le stockage cloud
      final cloudEngine = CloudStorageEngine();
      final isInitialized = await cloudEngine.initialize();

      if (!isInitialized) {
        return false;
      }

      // Vérifier si la sauvegarde existe
      final saveGameObj = await cloudEngine.load(userId);
      return saveGameObj != null;
    } catch (e) {
      return false;
    }
  }
}