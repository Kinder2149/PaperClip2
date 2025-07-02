// lib/services/save_manager_improved.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/game_state.dart';
import '../models/game_config.dart';
import 'save_validator.dart';
import 'save_migration_service.dart';
import 'storage_constants.dart';

/// Exception spécifique pour les erreurs de sauvegarde
class SaveError implements Exception {
  final String code;
  final String message;
  
  SaveError(this.code, this.message);

  @override
  String toString() => '$code: $message';
}

/// Représentation d'une sauvegarde de jeu
class SaveGame {
  final String id; // UUID unique
  final String name;
  final DateTime lastSaveTime;
  final Map<String, dynamic> gameData;
  final String version;
  GameMode gameMode;

  SaveGame({
    String? id,
    required this.name,
    required this.lastSaveTime,
    required this.gameData,
    required this.version,
    GameMode? gameMode,
  }) :
    id = id ?? const Uuid().v4(),
    gameMode = gameMode ?? (gameData['gameMode'] != null
        ? GameMode.values[gameData['gameMode'] as int]
        : GameMode.INFINITE);

  /// Convertit l'objet SaveGame en Map pour la sérialisation
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'id': id,
      'name': name,
      'timestamp': lastSaveTime.toIso8601String(),
      'version': version,
      'gameMode': gameMode.index,
      'gameData': gameData,
    };

    return json;
  }

  /// Crée un objet SaveGame à partir des données désérialisées
  factory SaveGame.fromJson(Map<String, dynamic> json) {
    try {
      // Si les données sont dans gameData, utilise-les
      Map<String, dynamic> gameData = json['gameData'] as Map<String, dynamic>? ?? {};

      // Si les données sont à la racine, fusionne-les avec gameData
      if (json.containsKey('playerManager')) {
        gameData['playerManager'] = json['playerManager'];
      }
      if (json.containsKey('marketManager')) {
        gameData['marketManager'] = json['marketManager'];
      }
      if (json.containsKey('levelSystem')) {
        gameData['levelSystem'] = json['levelSystem'];
      }

      // Déterminer le mode de jeu
      GameMode mode = GameMode.INFINITE;
      if (json['gameMode'] != null) {
        int modeIndex = json['gameMode'] as int;
        mode = GameMode.values[modeIndex];
      } else if (gameData['gameMode'] != null) {
        int modeIndex = gameData['gameMode'] as int;
        mode = GameMode.values[modeIndex];
      }

      return SaveGame(
        id: json['id'] as String? ?? const Uuid().v4(),
        name: json['name'] as String,
        lastSaveTime: DateTime.parse(json['timestamp'] as String),
        gameData: gameData,
        version: json['version'] as String? ?? GameConstants.VERSION,
        gameMode: mode,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error creating SaveGame from JSON: $e');
      }
      rethrow;
    }
  }
}

/// Information résumée sur une sauvegarde pour l'UI
class SaveGameInfo {
  final String id;
  final String name;
  final DateTime timestamp;
  final String version;
  final double paperclips;
  final double money;
  final GameMode gameMode;
  final int totalPaperclipsSold;
  final int autoclippers;

  SaveGameInfo({
    required this.id,
    required this.name,
    required this.timestamp,
    required this.version,
    required this.paperclips,
    required this.money,
    required this.gameMode,
    this.totalPaperclipsSold = 0,
    this.autoclippers = 0,
  });
}

/// Gestionnaire centralisé des sauvegardes
class SaveManager {
  static const String SAVE_PREFIX = StorageConstants.SAVE_PREFIX;
  static const String BACKUP_PREFIX = StorageConstants.BACKUP_PREFIX;
  static const int MAX_BACKUPS = StorageConstants.MAX_BACKUPS;
  static const int COMPRESSION_CHUNK_SIZE = 1024 * 512; // 512KB chunks
  static const String CURRENT_SAVE_FORMAT_VERSION = StorageConstants.CURRENT_SAVE_FORMAT_VERSION;

  /// Obtient la clé de sauvegarde pour un nom de jeu donné
  static String _getSaveKey(String gameName) => '$SAVE_PREFIX$gameName';
  
  /// Obtient la clé de backup pour un nom de jeu donné
  static String _getBackupKey(String gameName, DateTime timestamp) => 
      '${BACKUP_PREFIX}${gameName}_${timestamp.millisecondsSinceEpoch}';

  /// Extrait les données de jeu d'un objet SaveGame
  static Map<String, dynamic> extractGameData(SaveGame? saveGame) {
    if (saveGame == null) return {};
    return saveGame.gameData;
  }

  /// Sauvegarde un jeu
  static Future<bool> saveGame(SaveGame saveGame, {bool compress = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saveKey = _getSaveKey(saveGame.name);
      
      // Convertir l'objet SaveGame en JSON
      Map<String, dynamic> jsonData = saveGame.toJson();
      
      // Vérifier que les données sont valides
      if (!SaveDataValidator.quickValidate(jsonData)) {
        throw SaveError(
          'VALIDATION_ERROR',
          'Les données de sauvegarde ne passent pas la validation rapide',
        );
      }
      
      // Sérialiser et compresser si nécessaire
      String dataToSave;
      if (compress) {
        dataToSave = await compressSaveData(jsonData);
      } else {
        dataToSave = jsonEncode(jsonData);
      }
      
      // Sauvegarder les données
      await prefs.setString(saveKey, dataToSave);
      
      if (kDebugMode) {
        print('Sauvegarde réussie: ${saveGame.name}');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la sauvegarde: $e');
      }
      rethrow;
    }
  }

  /// Crée une sauvegarde à partir de l'état du jeu actuel
  static Future<void> saveGameState(GameState gameState, String name) async {
    try {
      // Préparer les données du jeu
      Map<String, dynamic> gameData = gameState.prepareGameData();
      
      // Créer l'objet de sauvegarde
      SaveGame saveGame = SaveGame(
        name: name,
        lastSaveTime: DateTime.now(),
        gameData: gameData,
        version: CURRENT_SAVE_FORMAT_VERSION, // Utiliser la constante centralisée
        gameMode: gameState.gameMode,
      );
      
      // Sauvegarder
      await SaveManager.saveGame(saveGame);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la sauvegarde de l\'état: $e');
      }
      rethrow;
    }
  }

  /// Crée une sauvegarde de secours
  static Future<String?> createBackup(GameState gameState) async {
    try {
      if (gameState.gameName == null) return null;
      
      // Nom de base de la sauvegarde
      final baseName = gameState.gameName!;
      
      // Timestamp pour le backup
      final timestamp = DateTime.now();
      
      // Nom du backup
      final backupName = '${baseName}_backup_${timestamp.millisecondsSinceEpoch}';
      
      // Préparer les données du jeu
      Map<String, dynamic> gameData = gameState.prepareGameData();
      
      // Créer l'objet de sauvegarde
      SaveGame saveGame = SaveGame(
        name: backupName,
        lastSaveTime: timestamp,
        gameData: gameData,
        version: CURRENT_SAVE_FORMAT_VERSION, // Utiliser la constante centralisée
        gameMode: gameState.gameMode,
      );
      
      // Sauvegarder le backup
      await SaveManager.saveGame(saveGame);
      
      // Nettoyer les anciens backups
      await _cleanupOldBackups(baseName);
      
      return backupName;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la création du backup: $e');
      }
      return null;
    }
  }

  /// Nettoie les anciens backups pour ne conserver que les MAX_BACKUPS plus récents
  static Future<void> _cleanupOldBackups(String gameName) async {
    try {
      final saves = await listSaves();
      final backups = saves.where((save) =>
          save.name.contains('${gameName}_backup_')).toList();
      
      // Garder seulement les MAX_BACKUPS plus récents
      if (backups.length > MAX_BACKUPS) {
        backups.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        for (var i = MAX_BACKUPS; i < backups.length; i++) {
          await deleteSave(backups[i].name);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors du nettoyage des backups: $e');
      }
    }
  }

  /// Vérifie si une sauvegarde existe
  static Future<bool> saveExists(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_getSaveKey(name));
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la vérification de l\'existence de la sauvegarde: $e');
      }
      return false;
    }
  }

  /// Récupère la dernière sauvegarde
  static Future<SaveGame?> getLastSave() async {
    try {
      final saves = await listSaves();
      if (saves.isEmpty) return null;
      return await loadGame(saves.first.name);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la récupération de la dernière sauvegarde: $e');
      }
      return null;
    }
  }

  /// Charge une sauvegarde
  static Future<SaveGame> loadGame(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saveKey = _getSaveKey(name);
      
      // Vérifier si la sauvegarde existe
      if (!await saveExists(name)) {
        throw SaveError('NOT_FOUND', 'Sauvegarde $name non trouvée');
      }
      
      // Récupérer les données sauvegardées
      final savedData = prefs.getString(saveKey);
      if (savedData == null) {
        throw SaveError('EMPTY_DATA', 'Données de sauvegarde vides');
      }
      
      // Décoder les données (compressées ou non)
      final Map<String, dynamic> jsonData;
      try {
        // Tenter de décoder comme JSON standard
        jsonData = savedData.startsWith('{') 
            ? jsonDecode(savedData) 
            : jsonDecode(decompressSaveData(savedData));
      } catch (e) {
        throw SaveError(
          'DECODE_ERROR', 
          'Erreur lors du décodage des données: $e'
        );
      }
      
      // Vérifier la version et migrer si nécessaire
      String version = jsonData['version'] as String? ?? '1.0';
      Map<String, dynamic> processedData = jsonData;
      
      // Si la version est différente de la version actuelle, migrer les données
      if (version != CURRENT_SAVE_FORMAT_VERSION) {
        if (kDebugMode) {
          print('Migration des données de sauvegarde: $name (v$version -> v$CURRENT_SAVE_FORMAT_VERSION)');
        }
        processedData = await SaveMigrationService.migrateData(
          jsonData, 
          version, 
          CURRENT_SAVE_FORMAT_VERSION
        );
      }
      
      // Valider les données
      final validationResult = SaveDataValidator.validate(processedData);
      
      if (!validationResult.isValid) {
        throw SaveError(
          'VALIDATION_ERROR',
          'Données corrompues ou invalides:\n${validationResult.errors.join('\n')}',
        );
      }
      
      // Créer l'objet SaveGame
      return SaveGame.fromJson({
        ...processedData,
        'name': name,
        'version': CURRENT_SAVE_FORMAT_VERSION, // S'assurer que la version est à jour
      });
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors du chargement: $e');
      }
      rethrow;
    }
  }

  /// Restaure une sauvegarde à partir d'un backup
  static Future<bool> restoreFromBackup(String backupName, GameState gameState) async {
    try {
      // Charger le backup
      final backup = await loadGame(backupName);
      
      // Extraire les données du backup
      final gameData = extractGameData(backup);
      
      // Restaurer les données dans l'état du jeu
      await gameState.loadGame(backup.name.split('_backup_')[0]);
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la restauration depuis le backup: $e');
      }
      return false;
    }
  }

  /// Liste toutes les sauvegardes disponibles
  static Future<List<SaveGameInfo>> listSaves() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saves = <SaveGameInfo>[];
      
      for (final key in prefs.getKeys()) {
        if (key.startsWith(SAVE_PREFIX)) {
          try {
            final savedData = prefs.getString(key) ?? '{}';
            final data = savedData.startsWith('{') 
                ? jsonDecode(savedData) 
                : jsonDecode(decompressSaveData(savedData));
            
            // Extraction du mode de jeu
            GameMode gameMode = GameMode.INFINITE;
            if (data['gameMode'] != null) {
              int modeIndex = data['gameMode'] as int;
              gameMode = GameMode.values[modeIndex];
            } else if (data['gameData']?['gameMode'] != null) {
              int modeIndex = data['gameData']['gameMode'] as int;
              gameMode = GameMode.values[modeIndex];
            }
            
            // Extraction des données supplémentaires
            int totalPaperclipsSold = 0;
            int autoclippers = 0;
            
            // Essayer d'extraire les données de ventes totales
            if (data['gameData']?['totalPaperclipsProduced'] != null) {
              totalPaperclipsSold = (data['gameData']['totalPaperclipsProduced'] as num).toInt();
            } else if (data['gameData']?['statistics']?['totalPaperclipsSold'] != null) {
              totalPaperclipsSold = (data['gameData']['statistics']['totalPaperclipsSold'] as num).toInt();
            } else if (data['gameData']?['playerManager']?['totalPaperclipsSold'] != null) {
              totalPaperclipsSold = (data['gameData']['playerManager']['totalPaperclipsSold'] as num).toInt();
            } else if (data['gameData']?['totalPaperclipsSold'] != null) {
              totalPaperclipsSold = (data['gameData']['totalPaperclipsSold'] as num).toInt();
            }
            
            // Essayer d'extraire le nombre d'autoclippers
            if (data['gameData']?['playerManager']?['autoclippers'] != null) {
              autoclippers = (data['gameData']['playerManager']['autoclippers'] as num).toInt();
            } else if (data['gameData']?['player']?['autoclippers'] != null) {
              autoclippers = (data['gameData']['player']['autoclippers'] as num).toInt();
            }
            
            // Création de l'objet SaveGameInfo avec les nouvelles données
            saves.add(SaveGameInfo(
              id: data['id'] ?? key.substring(SAVE_PREFIX.length),
              name: key.substring(SAVE_PREFIX.length),
              timestamp: DateTime.parse(data['timestamp'] ?? ''),
              version: data['version'] ?? '',
              paperclips: data['gameData']?['playerManager']?['paperclips'] ?? 0,
              money: data['gameData']?['playerManager']?['money'] ?? 0,
              gameMode: gameMode,
              totalPaperclipsSold: totalPaperclipsSold,
              autoclippers: autoclippers,
            ));
          } catch (e) {
            if (kDebugMode) {
              print('Erreur lors du chargement de la sauvegarde $key: $e');
            }
          }
        }
      }
      
      // Trier par date de sauvegarde (plus récent d'abord)
      saves.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return saves;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la liste des sauvegardes: $e');
      }
      return [];
    }
  }

  /// Supprime une sauvegarde
  static Future<void> deleteSave(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_getSaveKey(name));
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la suppression: $e');
      }
      rethrow;
    }
  }

  /// Compresse les données de sauvegarde
  static Future<String> compressSaveData(Map<String, dynamic> data) async {
    try {
      final jsonString = jsonEncode(data);
      final bytes = utf8.encode(jsonString);
      final compressed = _compressBytes(bytes);
      return base64Encode(compressed);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la compression: $e');
      }
      // En cas d'erreur, retourner les données non compressées
      return jsonEncode(data);
    }
  }

  /// Compresse des bytes avec GZip
  static List<int> _compressBytes(List<int> input) {
    return GZipEncoder().encode(input) ?? input;
  }

  /// Décompresse les données de sauvegarde
  static String decompressSaveData(String compressed) {
    try {
      final bytes = base64Decode(compressed);
      final decompressed = GZipDecoder().decodeBytes(bytes);
      return utf8.decode(decompressed);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la décompression: $e');
      }
      return compressed; // Retourner les données telles quelles en cas d'erreur
    }
  }

  /// Affiche les données de débogage d'une sauvegarde
  static Future<void> debugSaveData(String gameName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saveKey = _getSaveKey(gameName);
      final savedData = prefs.getString(saveKey);
      
      if (kDebugMode) {
        print('Debug - Save data for $gameName:');
        print(savedData);
        
        if (savedData != null) {
          final decoded = savedData.startsWith('{') 
              ? jsonDecode(savedData) 
              : jsonDecode(decompressSaveData(savedData));
          
          print('Decoded data:');
          print(decoded);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Debug - Error reading save: $e');
      }
    }
  }
}
