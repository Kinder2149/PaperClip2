// lib/services/save/storage/local_storage_engine.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../save_types.dart';
import '../save_utils.dart';
import 'storage_engine.dart';
import '../../../models/game_config.dart';

class LocalStorageEngine implements StorageEngine {
  static const String SAVE_PREFIX = 'paperclip_save_';
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    _initialized = true;
  }

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> save(SaveGame saveGame) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getSaveKey(saveGame.name);

      // Migrer les données si nécessaire (pour compatibilité)
      final migratedData = SaveUtils.migrateIfNeeded(saveGame.gameData);
      final updatedSave = SaveGame(
        id: saveGame.id,
        name: saveGame.name,
        lastSaveTime: saveGame.lastSaveTime,
        gameData: migratedData,
        version: saveGame.version,
        isSyncedWithCloud: saveGame.isSyncedWithCloud,
        cloudId: saveGame.cloudId,
        gameMode: saveGame.gameMode,
      );

      await prefs.setString(key, jsonEncode(updatedSave.toJson()));
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde locale: $e');
      rethrow;
    }
  }

  @override
  Future<SaveGame?> load(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getSaveKey(name);
      final savedData = prefs.getString(key);

      if (savedData == null) return null;

      try {
        // Décoder les données
        final jsonData = jsonDecode(savedData) as Map<String, dynamic>;

        // Migrer si nécessaire
        final migratedData = SaveUtils.migrateIfNeeded(jsonData);

        // Valider les données
        final validationResult = SaveUtils.validateSaveData(migratedData);
        if (!validationResult.isValid) {
          // Tenter la récupération
          final recoveredData = await SaveUtils.attemptRecovery(savedData, name);
          if (recoveredData != null) {
            return SaveGame.fromJson(recoveredData);
          }

          // Si la récupération échoue
          throw SaveError(
            'VALIDATION_ERROR',
            'Données corrompues: ${validationResult.errors.join(', ')}',
          );
        }

        return SaveGame.fromJson(migratedData);
      } catch (e) {
        // En cas d'erreur, tenter la récupération
        final recoveredData = await SaveUtils.attemptRecovery(savedData, name);
        if (recoveredData != null) {
          return SaveGame.fromJson(recoveredData);
        }
        rethrow;
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement local: $e');
      rethrow;
    }
  }

  @override
  Future<List<SaveGameInfo>> listSaves() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saves = <SaveGameInfo>[];

      for (final key in prefs.getKeys()) {
        if (key.startsWith(SAVE_PREFIX)) {
          try {
            final savedData = prefs.getString(key) ?? '{}';
            final data = jsonDecode(savedData) as Map<String, dynamic>;

            // Extraire le mode de jeu
            final gameMode = _extractGameMode(data);

            // Extraire les métadonnées
            saves.add(SaveGameInfo(
              id: data['id'] ?? key.substring(SAVE_PREFIX.length),
              name: key.substring(SAVE_PREFIX.length),
              timestamp: DateTime.parse(data['timestamp'] ?? DateTime.now().toIso8601String()),
              version: data['version'] ?? GameConstants.VERSION,
              paperclips: _extractPaperclips(data),
              money: _extractMoney(data),
              isSyncedWithCloud: data['isSyncedWithCloud'] ?? false,
              cloudId: data['cloudId'],
              gameMode: gameMode,
            ));
          } catch (e) {
            debugPrint('Erreur lors du chargement des métadonnées: $e');
          }
        }
      }

      // Trier par date (plus récent d'abord)
      saves.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return saves;
    } catch (e) {
      debugPrint('Erreur lors de la liste des sauvegardes: $e');
      return [];
    }
  }

  @override
  Future<void> delete(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_getSaveKey(name));
    } catch (e) {
      debugPrint('Erreur lors de la suppression: $e');
      rethrow;
    }
  }

  @override
  Future<bool> exists(String name) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_getSaveKey(name));
  }

  // Utilitaires privés
  String _getSaveKey(String name) => '$SAVE_PREFIX$name';

  GameMode _extractGameMode(Map<String, dynamic> data) {
    try {
      if (data['gameMode'] != null) {
        return GameMode.values[data['gameMode'] as int];
      } else if (data['gameData']?['gameMode'] != null) {
        return GameMode.values[data['gameData']['gameMode'] as int];
      }
    } catch (e) {
      debugPrint('Erreur extraction mode de jeu: $e');
    }
    return GameMode.INFINITE;
  }

  double _extractPaperclips(Map<String, dynamic> data) {
    try {
      // Chercher dans plusieurs emplacements possibles
      final locations = [
        data['gameData']?['playerManager']?['paperclips'],
        data['gameData']?['productionManager']?['paperclips'],
        data['playerManager']?['paperclips'],
        data['productionManager']?['paperclips'],
      ];

      for (final value in locations) {
        if (value != null) {
          if (value is double) return value;
          if (value is int) return value.toDouble();
          if (value is String) {
            try { return double.parse(value); } catch (_) {}
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur extraction paperclips: $e');
    }
    return 0.0;
  }

  double _extractMoney(Map<String, dynamic> data) {
    try {
      final locations = [
        data['gameData']?['playerManager']?['money'],
        data['playerManager']?['money'],
      ];

      for (final value in locations) {
        if (value != null) {
          if (value is double) return value;
          if (value is int) return value.toDouble();
          if (value is String) {
            try { return double.parse(value); } catch (_) {}
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur extraction money: $e');
    }
    return 0.0;
  }
}