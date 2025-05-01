import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../../services/save_manager.dart';
export '../../services/save_manager.dart' show SaveGame, SaveGameInfo, SaveError, ValidationResult, SaveDataValidator;
import '../../models/game_config.dart';
import 'save_data_provider.dart';
import 'save_migration_service.dart';
import 'save_recovery_service.dart';
import '../../utils/date_utils.dart';

class LocalSaveService {
  static const String SAVE_PREFIX = 'paperclip_save_';

  Future<void> saveGame(SaveGame saveGame) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getSaveKey(saveGame.name);

      // Appliquer une migration préventive pour assurer la compatibilité
      final gameData = SaveMigrationService.migrateIfNeeded(saveGame.gameData);
      saveGame = SaveGame(
        id: saveGame.id,
        name: saveGame.name,
        lastSaveTime: saveGame.lastSaveTime,
        gameData: gameData,
        version: saveGame.version,
        gameMode: saveGame.gameMode,
        isSyncedWithCloud: saveGame.isSyncedWithCloud,
        cloudId: saveGame.cloudId,
      );

      await prefs.setString(key, jsonEncode(saveGame.toJson()));
    } catch (e, stack) {
      print('Erreur lors de la sauvegarde: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Save error');
      rethrow;
    }
  }

  Future<SaveGame?> loadGame(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$SAVE_PREFIX$name';
      final savedData = prefs.getString(key);

      if (savedData == null) {
        return null;
      }

      try {
        // Tenter de décoder et valider normalement
        final jsonData = jsonDecode(savedData) as Map<String, dynamic>;

        // Appliquer les migrations nécessaires
        final migratedData = SaveMigrationService.migrateIfNeeded(jsonData);

        // Validation des données
        final validationResult = SaveDataValidator.validate(migratedData);
        if (!validationResult.isValid) {
          // Si invalide, tenter la récupération
          final recoveredData = await SaveRecoveryService.attemptRecovery(savedData, name);
          if (recoveredData != null) {
            // Log la récupération
            print('Sauvegarde récupérée avec succès: $name');

            // Créer un SaveGame avec les données récupérées
            return _createSaveGameFromData(recoveredData, name, key);
          }

          // Si récupération échouée, lancer l'erreur
          throw SaveError(
            'VALIDATION_ERROR',
            'Données corrompues ou invalides:\n${validationResult.errors.join('\n')}',
          );
        }

        // Si validation réussie, créer l'objet SaveGame
        return _createSaveGameFromData(migratedData, name, key);
      } catch (e, stack) {
        // Capture toutes les erreurs et tente la récupération
        print('Erreur lors de la validation/chargement: $e');
        FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Load validation error');

        // Tenter la récupération
        final recoveredData = await SaveRecoveryService.attemptRecovery(savedData, name);
        if (recoveredData != null) {
          print('Récupération après erreur réussie: $name');
          return _createSaveGameFromData(recoveredData, name, key);
        }

        // Si tout échoue, relancer l'erreur
        rethrow;
      }
    } catch (e, stack) {
      print('Erreur lors du chargement: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Load error');
      rethrow;
    }
  }

  // Méthode auxiliaire pour créer un SaveGame à partir des données
  SaveGame _createSaveGameFromData(Map<String, dynamic> data, String name, String key) {
    // Déterminer le mode de jeu
    GameMode gameMode = GameMode.INFINITE;
    if (data['gameMode'] != null) {
      int modeIndex = _toInt(data['gameMode']) ?? 0;
      gameMode = GameMode.values[modeIndex];
    } else if (data['gameData']?['gameMode'] != null) {
      int modeIndex = _toInt(data['gameData']['gameMode']) ?? 0;
      gameMode = GameMode.values[modeIndex];
    }

    // Déterminer la version
    String version = data['version'] as String? ?? GameConstants.VERSION;

    // Déterminer la date de dernière sauvegarde
    DateTime lastSaveTime;
    try {
      lastSaveTime = DateTime.parse(data['timestamp'] as String);
    } catch (e) {
      print('Erreur de format de date: ${data['timestamp']}');
      lastSaveTime = DateTime.now();
    }

    // Créer l'objet SaveGame
    return SaveGame(
      id: data['id'] as String? ?? key.substring(SAVE_PREFIX.length),
      name: name,
      lastSaveTime: lastSaveTime,
      gameData: data,
      version: version,
      isSyncedWithCloud: data['isSyncedWithCloud'] as bool? ?? false,
      cloudId: data['cloudId'] as String?,
      gameMode: gameMode,
    );
  }

  Future<List<SaveGameInfo>> listSaves() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saves = <SaveGameInfo>[];

      for (final key in prefs.getKeys()) {
        if (key.startsWith(SAVE_PREFIX)) {
          try {
            final savedData = prefs.getString(key) ?? '{}';
            final data = jsonDecode(savedData);

            // Extraction du mode de jeu
            GameMode gameMode = GameMode.INFINITE;
            if (data['gameMode'] != null) {
              int modeIndex = _toInt(data['gameMode']) ?? 0;
              gameMode = GameMode.values[modeIndex];
            } else if (data['gameData']?['gameMode'] != null) {
              int modeIndex = _toInt(data['gameData']['gameMode']) ?? 0;
              gameMode = GameMode.values[modeIndex];
            }

            // Gestion sécurisée des dates
            DateTime timestamp;
            try {
              timestamp = DateTime.parse(data['timestamp'] ?? '');
            } catch (e) {
              timestamp = DateTime.now();
              print('Date invalide dans la sauvegarde: ${data['timestamp']}');
            }

            // Extraction sécurisée des données numériques
            double paperclips = 0.0;
            double money = 0.0;

            // Essayer de récupérer paperclips depuis playerManager ou productionManager
            if (data['gameData']?['playerManager']?['paperclips'] != null) {
              paperclips = _toDouble(data['gameData']['playerManager']['paperclips']) ?? 0.0;
            } else if (data['gameData']?['productionManager']?['paperclips'] != null) {
              paperclips = _toDouble(data['gameData']['productionManager']['paperclips']) ?? 0.0;
            } else if (data['playerManager']?['paperclips'] != null) {
              paperclips = _toDouble(data['playerManager']['paperclips']) ?? 0.0;
            } else if (data['productionManager']?['paperclips'] != null) {
              paperclips = _toDouble(data['productionManager']['paperclips']) ?? 0.0;
            }

            // Récupérer l'argent depuis playerManager
            if (data['gameData']?['playerManager']?['money'] != null) {
              money = _toDouble(data['gameData']['playerManager']['money']) ?? 0.0;
            } else if (data['playerManager']?['money'] != null) {
              money = _toDouble(data['playerManager']['money']) ?? 0.0;
            }

            saves.add(SaveGameInfo(
              id: data['id'] ?? key.substring(SAVE_PREFIX.length),
              name: key.substring(SAVE_PREFIX.length),
              timestamp: timestamp,
              version: data['version'] ?? '',
              paperclips: paperclips,
              money: money,
              isSyncedWithCloud: data['isSyncedWithCloud'] ?? false,
              cloudId: data['cloudId'],
              gameMode: gameMode,
            ));
          } catch (e) {
            print('Erreur lors du chargement de la sauvegarde $key: $e');
          }
        }
      }

      // Trier par date de sauvegarde (plus récent d'abord)
      saves.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return saves;
    } catch (e) {
      print('Erreur lors de la liste des sauvegardes: $e');
      return [];
    }
  }

  Future<void> deleteSave(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$SAVE_PREFIX$name');
    } catch (e) {
      print('Erreur lors de la suppression: $e');
      rethrow;
    }
  }

  Future<bool> saveExists(String name) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_getSaveKey(name));
  }

  Future<void> restoreFromBackup(String backupName, SaveDataProvider provider) async {
    try {
      final backup = await loadGame(backupName);
      if (backup == null) return;

      // Créer une sauvegarde de l'état actuel
      if (provider.gameName != null) {
        final currentGameData = provider.prepareGameData();
        final currentSave = SaveGame(
          name: provider.gameName!,
          lastSaveTime: DateTime.now(),
          gameData: currentGameData,
          version: GameConstants.VERSION,
          gameMode: provider.gameMode,
        );

        await saveGame(currentSave);
      }
    } catch (e) {
      print('Erreur lors de la restauration: $e');
      rethrow;
    }
  }

  String _getSaveKey(String gameName) => '$SAVE_PREFIX$gameName';

  // Utilitaires de conversion sécurisée
  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}