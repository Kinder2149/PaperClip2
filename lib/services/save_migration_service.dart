// lib/services/save_migration_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_config.dart';
import '../services/save_manager_improved.dart';
import 'storage_constants.dart';

/// Service responsable de la migration des sauvegardes entre différentes versions
class SaveMigrationService {
  /// Préfixe utilisé par l'ancien système de sauvegarde
  static const String OLD_SAVE_PREFIX = StorageConstants.SAVE_PREFIX;
  
  /// Version actuelle du format de sauvegarde
  static const String CURRENT_SAVE_FORMAT_VERSION = StorageConstants.CURRENT_SAVE_FORMAT_VERSION;

  /// Migre toutes les sauvegardes existantes vers le nouveau format
  static Future<int> migrateAllSaves() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int migratedCount = 0;
      
      // Parcourir toutes les clés SharedPreferences
      final allKeys = prefs.getKeys();
      final savesToMigrate = allKeys.where((key) => key.startsWith(OLD_SAVE_PREFIX));
      
      // Migrer chaque sauvegarde
      for (final saveKey in savesToMigrate) {
        final savedData = prefs.getString(saveKey);
        if (savedData == null) continue;
        
        try {
          // Décoder les données de sauvegarde
          final data = jsonDecode(savedData);
          
          // Vérifier la version
          final version = data['version'] as String? ?? '1.0';
          
          // Si déjà en version actuelle, ignorer
          if (version == CURRENT_SAVE_FORMAT_VERSION) continue;
          
          // Migrer les données
          final migratedData = await migrateData(data, version, CURRENT_SAVE_FORMAT_VERSION);
          
          // Sauvegarder les données migrées
          final saveName = saveKey.substring(OLD_SAVE_PREFIX.length);
          final saveGame = _createSaveGameFromMigratedData(migratedData, saveName);
          await SaveManager.saveGame(saveGame);
          
          // Supprimer l'ancienne sauvegarde après migration réussie
          await prefs.remove(saveKey);
          
          migratedCount++;
          if (kDebugMode) {
            print('Sauvegarde migrée avec succès et ancienne sauvegarde supprimée: $saveName');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Erreur lors de la migration de la sauvegarde $saveKey: $e');
          }
        }
      }
      
      return migratedCount;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la migration des sauvegardes: $e');
      }
      return 0;
    }
  }

  /// Migre les données d'une version à une autre
  /// Applique les transformations nécessaires selon les versions
  static Future<Map<String, dynamic>> migrateData(
    Map<String, dynamic> oldData,
    String fromVersion,
    String toVersion
  ) async {
    // Copier les données pour ne pas modifier l'original
    final Map<String, dynamic> migratedData = Map.from(oldData);
    
    // Stratégie de migration par étapes
    if (fromVersion == '1.0' && toVersion == '2.0') {
      return _migrateFrom1To2(migratedData);
    } else {
      // Migration par défaut - supposer que le format est compatible
      migratedData['version'] = toVersion;
      return migratedData;
    }
  }

  /// Migration spécifique de la version 1.0 à 2.0
  static Future<Map<String, dynamic>> _migrateFrom1To2(Map<String, dynamic> data) async {
    final Map<String, dynamic> migratedData = Map.from(data);
    
    // Ajouter la version du format
    migratedData['version'] = CURRENT_SAVE_FORMAT_VERSION;
    
    // Restructurer les données si nécessaire
    if (!migratedData.containsKey('gameData')) {
      final Map<String, dynamic> gameData = {};
      
      // Déplacer les données du jeu dans un sous-objet gameData
      if (migratedData.containsKey('playerManager')) {
        gameData['playerManager'] = migratedData.remove('playerManager');
      }
      if (migratedData.containsKey('marketManager')) {
        gameData['marketManager'] = migratedData.remove('marketManager');
      }
      if (migratedData.containsKey('levelSystem')) {
        gameData['levelSystem'] = migratedData.remove('levelSystem');
      }
      
      // Ajouter le mode de jeu
      if (migratedData.containsKey('gameMode')) {
        gameData['gameMode'] = migratedData['gameMode'];
      } else {
        // Par défaut: mode infini
        gameData['gameMode'] = GameMode.INFINITE.index;
      }
      
      migratedData['gameData'] = gameData;
    }
    
    return migratedData;
  }

  /// Crée un objet SaveGame à partir des données migrées
  static SaveGame _createSaveGameFromMigratedData(Map<String, dynamic> data, String saveName) {
    // Extraire le timestamp
    final timestamp = data['timestamp'] != null 
        ? DateTime.parse(data['timestamp']) 
        : DateTime.now();
    
    // Extraire la version
    final version = data['version'] as String? ?? CURRENT_SAVE_FORMAT_VERSION;
    
    // Extraire le mode de jeu
    GameMode gameMode = GameMode.INFINITE;
    if (data['gameMode'] != null) {
      int modeIndex = data['gameMode'] as int;
      gameMode = GameMode.values[modeIndex];
    } else if (data['gameData']?['gameMode'] != null) {
      int modeIndex = data['gameData']['gameMode'] as int;
      gameMode = GameMode.values[modeIndex];
    }
    
    // Créer l'objet SaveGame
    return SaveGame(
      name: saveName,
      lastSaveTime: timestamp,
      gameData: data['gameData'] as Map<String, dynamic>? ?? {},
      version: version,
      gameMode: gameMode,
    );
  }
}
