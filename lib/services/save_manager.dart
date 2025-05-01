// lib/services/save_manager.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../models/game_state.dart';
import '../models/game_config.dart';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final Map<String, dynamic>? validatedData;

  ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.validatedData,
  });
}

class SaveDataValidator {
  static const Map<String, Map<String, dynamic>> _validationRules = {
    'playerManager': {
      'money': {'type': 'double', 'min': 0.0},
      'metal': {'type': 'double', 'min': 0.0},
      'paperclips': {'type': 'double', 'min': 0.0},
      'autoclippers': {'type': 'int', 'min': 0},
      'sellPrice': {'type': 'double', 'min': 0.01, 'max': 1.0},
      'upgrades': {'type': 'map'},
    },
    'marketManager': {
      'marketMetalStock': {'type': 'double', 'min': 0.0},
      'reputation': {'type': 'double', 'min': 0.0, 'max': 2.0},
      'dynamics': {'type': 'map'},
    },
    'levelSystem': {
      'experience': {'type': 'double', 'min': 0.0},
      'level': {'type': 'int', 'min': 1},
      'currentPath': {'type': 'int', 'min': 0},
      'xpMultiplier': {'type': 'double', 'min': 1.0},
    },
  };

  static ValidationResult validate(Map<String, dynamic> data) {
    List<String> errors = [];    // Correction ici : List<String> au lieu de final errors = <String>();

    // Vérification de base
    if (!data.containsKey('version') || !data.containsKey('timestamp')) {
      errors.add('Données de base manquantes (version ou timestamp)');
      return ValidationResult(isValid: false, errors: errors);
    }

    // Vérification des sections obligatoires
    if (!_validateMandatorySections(data, errors)) {
      return ValidationResult(isValid: false, errors: errors);
    }

    // Vérification des règles pour chaque section
    for (var sectionName in _validationRules.keys) {
      if (!data.containsKey(sectionName)) {
        errors.add('Section manquante: $sectionName');
        continue;
      }

      var sectionData = data[sectionName] as Map<String, dynamic>?;
      if (sectionData == null) {
        errors.add('Section invalide: $sectionName');
        continue;
      }

      // Vérifier chaque champ de la section
      var rules = _validationRules[sectionName]!;
      for (var fieldName in rules.keys) {
        if (!sectionData.containsKey(fieldName)) {
          errors.add('Champ manquant dans $sectionName: $fieldName');
          continue;
        }

        var value = sectionData[fieldName];
        var rule = rules[fieldName];

        if (!_validateField(value, rule as Map<String, dynamic>, errors, '$sectionName.$fieldName')) {
          continue;
        }
      }
    }

    // Si pas d'erreurs, les données sont valides
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      validatedData: data,
    );
  }

  static bool _validateMandatorySections(Map<String, dynamic> data, List<String> errors) {
    // Vérifier que playerManager existe
    if (!data.containsKey('playerManager')) {
      errors.add('Section manquante: playerManager');
      return false;
    }

    final playerData = data['playerManager'] as Map<String, dynamic>?;
    if (playerData == null) {
      errors.add('Données du joueur invalides');
      return false;
    }

    // Vérifier la présence de paperclips soit dans playerManager soit dans productionManager
    bool paperclipsFound = false;
    if (playerData.containsKey('paperclips')) {
      paperclipsFound = true;
    } else if (data.containsKey('productionManager')) {
      final productionData = data['productionManager'] as Map<String, dynamic>?;
      if (productionData != null && productionData.containsKey('paperclips')) {
        paperclipsFound = true;
        // On ne copie pas la valeur pour éviter de modifier les données d'entrée
      }
    }

    if (!paperclipsFound) {
      errors.add('Champ paperclips introuvable dans playerManager ou productionManager');
      return false;
    }

    // Vérifier les autres champs essentiels
    final requiredFields = ['money', 'metal'];
    for (var field in requiredFields) {
      // Vérifie dans playerManager d'abord
      if (!playerData.containsKey(field)) {
        // Si absent de playerManager, vérifier dans metalManager pour 'metal'
        if (field == 'metal' && data.containsKey('metalManager')) {
          final metalData = data['metalManager'] as Map<String, dynamic>?;
          if (metalData != null && metalData.containsKey('metal')) {
            continue; // Le champ existe dans metalManager, continuer la validation
          }
        }
        errors.add('Champ manquant dans playerManager: $field');
        return false;
      }
    }

    return true;
  }
  static Future<bool> quickValidate(Map<String, dynamic> data) async {
    try {
      // Vérifier les champs critiques minimaux
      if (!data.containsKey('version') || !data.containsKey('timestamp')) {
        return false;
      }

      // Vérifier la présence du joueur
      if (!data.containsKey('playerManager')) {
        return false;
      }

      // Vérifier les données de production
      bool paperclipsFound = false;

      final playerData = data['playerManager'] as Map<String, dynamic>?;
      if (playerData?.containsKey('paperclips') == true) {
        paperclipsFound = true;
      } else if (data.containsKey('productionManager')) {
        final productionData = data['productionManager'] as Map<String, dynamic>?;
        if (productionData?.containsKey('paperclips') == true) {
          paperclipsFound = true;
        }
      }

      // Vérifier money
      bool moneyFound = playerData?.containsKey('money') == true;

      // Vérifier metal
      bool metalFound = false;
      if (playerData?.containsKey('metal') == true) {
        metalFound = true;
      } else if (data.containsKey('metalManager')) {
        final metalData = data['metalManager'] as Map<String, dynamic>?;
        if (metalData?.containsKey('metal') == true) {
          metalFound = true;
        }
      }

      return paperclipsFound && moneyFound && metalFound;
    } catch (e) {
      print('Erreur de validation rapide: $e');
      return false;
    }
  }

  static bool _validateField(dynamic value, Map<String, dynamic> rule, List<String> errors, String fieldPath) {
    // Vérification du type
    if (!_validateType(value, rule['type'] as String)) {
      errors.add('Type invalide pour $fieldPath');
      return false;
    }

    // Vérification des limites pour les nombres
    if (value is num) {
      if (rule.containsKey('min') && value < rule['min']) {
        errors.add('Valeur trop petite pour $fieldPath');
        return false;
      }
      if (rule.containsKey('max') && value > rule['max']) {
        errors.add('Valeur trop grande pour $fieldPath');
        return false;
      }
    }

    return true;
  }
  

  static bool _validateType(dynamic value, String expectedType) {
    switch (expectedType) {
      case 'double':
        return value is num;
      case 'int':
        return value is int;
      case 'map':
        return value is Map;
      case 'list':
        return value is List;
      default:
        return false;
    }
  }
}

class SaveError implements Exception {
  final String code;
  final String message;
  SaveError(this.code, this.message);

  @override
  String toString() => '$code: $message';
}

class SaveGame {
  final String id; // UUID unique
  final String name;
  final DateTime lastSaveTime;
  final Map<String, dynamic> gameData;
  final String version;
  bool isSyncedWithCloud;
  String? cloudId;
  GameMode gameMode;

  SaveGame({
    String? id,
    required this.name,
    required this.lastSaveTime,
    required this.gameData,
    required this.version,
    this.isSyncedWithCloud = false,
    this.cloudId,
    GameMode? gameMode,
  }) :
        id = id ?? const Uuid().v4(),
        gameMode = gameMode ?? (gameData['gameMode'] != null
            ? GameMode.values[gameData['gameMode'] as int]
            : GameMode.INFINITE);

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'id': id,
      'name': name,
      'timestamp': lastSaveTime.toIso8601String(),
      'version': version,
      'isSyncedWithCloud': isSyncedWithCloud,
      'cloudId': cloudId,
      'gameMode': gameMode.index,
    };

    // Ajoute les données du jeu à la racine et dans gameData
    if (gameData.containsKey('playerManager')) {
      json['playerManager'] = gameData['playerManager'];
    }
    if (gameData.containsKey('marketManager')) {
      json['marketManager'] = gameData['marketManager'];
    }
    if (gameData.containsKey('levelSystem')) {
      json['levelSystem'] = gameData['levelSystem'];
    }

    // Sauvegarde complète des données
    json['gameData'] = gameData;

    return json;
  }

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
        isSyncedWithCloud: json['isSyncedWithCloud'] as bool? ?? false,
        cloudId: json['cloudId'] as String?,
        gameMode: mode,
      );
    } catch (e) {
      print('Error creating SaveGame from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }
}



class SaveManager {
  static const String SAVE_PREFIX = 'paperclip_save_';
  static final DateTime CURRENT_DATE = DateTime(2025, 1, 23, 15, 15, 49);
  static const String CURRENT_USER = 'Kinder2149';
  static const String CURRENT_VERSION = '1.0.0';
  static const int COMPRESSION_CHUNK_SIZE = 1024 * 512; // 512KB chunks
  static String _getSaveKey(String gameName) => '$SAVE_PREFIX$gameName';

  // Sauvegarder une partie
  static Future<void> saveGame(SaveGame saveGame) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getSaveKey(saveGame.name);
      await prefs.setString(key, jsonEncode(saveGame.toJson()));
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
      rethrow;
    }
  }

  static bool _quickValidate(Map<String, dynamic> data) {
    return data.containsKey('playerManager') &&
        data.containsKey('marketManager') &&
        data.containsKey('levelSystem');
  }

  static Future<SaveGameInfo?> getLastSave() async {
    final saves = await listSaves();
    return saves.isNotEmpty ? saves.first : null;
  }

  static Future<bool> saveExists(String name) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_getSaveKey(name));
  }
  // Ajouter ces méthodes
  Future<String> compressSaveData(Map<String, dynamic> data) async {
    final jsonString = jsonEncode(data);
    final bytes = utf8.encode(jsonString);

    // Utiliser compute pour déplacer la compression sur un autre thread
    final compressed = await compute(_compressBytes, bytes);
    return base64Encode(compressed);
  }

  static List<int> _compressBytes(List<int> input) {
    return GZipEncoder().encode(input) ?? [];
  }


  static Future<Map<String, dynamic>> decompressSaveData(String compressed) async {
    final decoded = base64Decode(compressed);
    final gzip = GZipCodec();
    final decompressed = gzip.decode(decoded);
    final jsonString = utf8.decode(decompressed);
    return jsonDecode(jsonString);
  }

  static Future<bool> restoreFromBackup(String backupName, GameState gameState) async {
    try {
      final backup = await loadGame(backupName);
      if (backup == null) return false;

      // Au lieu de : await saveGame(gameState, gameState.gameName!);
      // Créer un objet SaveGame avec les données actuelles du jeu
      final currentGameData = gameState.prepareGameData();
      final currentSave = SaveGame(
        name: gameState.gameName!,
        lastSaveTime: DateTime.now(),
        gameData: currentGameData,
        version: GameConstants.VERSION,
        gameMode: gameState.gameMode,
      );

      await saveGame(currentSave);
      return true;
    } catch (e) {
      print('Erreur lors de la restauration: $e');
      return false;
    }
  }


  static Future<Map<String, dynamic>?> debugSave(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saveKey = _getSaveKey(name);
      final savedData = prefs.getString(saveKey);

      print('=== Debug Save Data ===');
      print('Save Key: $saveKey');

      if (savedData == null) {
        print('Aucune sauvegarde trouvée pour: $name');
        return null;
      }

      final jsonData = jsonDecode(savedData) as Map<String, dynamic>;
      print('Version: ${jsonData['version']}');
      print('Timestamp: ${jsonData['timestamp']}');
      print('Contains playerManager: ${jsonData.containsKey('playerManager')}');
      print('Contains gameData: ${jsonData.containsKey('gameData')}');

      if (jsonData.containsKey('playerManager')) {
        print('PlayerManager data structure:');
        final playerData = jsonData['playerManager'] as Map<String, dynamic>;
        playerData.forEach((key, value) {
          print('  $key: $value');
        });
      }

      print('=====================');
      return jsonData;
    } catch (e) {
      print('Error debugging save: $e');
      print(e.toString());
      return null;
    }
  }
  // Méthode pour assurer la compatibilité avec l'ancien code
  // Ajouter cette méthode à la classe SaveManager
  static Future<void> saveGameState(GameState gameState, String name) async {
    try {
      if (name.isEmpty) {
        throw SaveError('INVALID_NAME', 'Le nom de la sauvegarde ne peut pas être vide');
      }

      final gameData = gameState.prepareGameData();

      // Validation simple et rapide
      if (!_quickValidate(gameData)) {
        throw SaveError('VALIDATION_ERROR', 'Données de base manquantes');
      }

      final saveData = SaveGame(
        name: name,
        lastSaveTime: DateTime.now(),
        gameData: gameData,
        version: GameConstants.VERSION,
        gameMode: gameState.gameMode,
      );

      await saveGame(saveData);
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
      rethrow;
    }
  }

  static Future<SaveGame?> loadGame(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$SAVE_PREFIX$name';
      final savedData = prefs.getString(key);

      if (savedData == null) {
        return null;
      }

      final jsonData = jsonDecode(savedData) as Map<String, dynamic>;

      // Validation des données
      final validationResult = SaveDataValidator.validate(jsonData);
      if (!validationResult.isValid) {
        throw SaveError(
          'VALIDATION_ERROR',
          'Données corrompues ou invalides:\n${validationResult.errors.join('\n')}',
        );
      }

      // Si la validation est OK, créer l'objet SaveGame
      return SaveGame.fromJson(jsonData);
    } catch (e) {
      print('Erreur lors du chargement: $e');
      rethrow;
    }
  }

  // Récupérer la dernière sauvegarde

  static Future<void> debugSaveData(String gameName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saveKey = _getSaveKey(gameName);
      final savedData = prefs.getString(saveKey);
      print('Debug - Save data for $gameName:');
      print(savedData);
      if (savedData != null) {
        final decoded = jsonDecode(savedData);
        print('Decoded data:');
        print(decoded);
      }
    } catch (e) {
      print('Debug - Error reading save: $e');
    }
  }
  static Future<List<SaveGameInfo>> listSaves() async {
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
              int modeIndex = data['gameMode'] as int;
              gameMode = GameMode.values[modeIndex];
            } else if (data['gameData']?['gameMode'] != null) {
              int modeIndex = data['gameData']['gameMode'] as int;
              gameMode = GameMode.values[modeIndex];
            }

            saves.add(SaveGameInfo(
              id: data['id'] ?? key.substring(SAVE_PREFIX.length),
              name: key.substring(SAVE_PREFIX.length),
              timestamp: DateTime.parse(data['timestamp'] ?? ''),
              version: data['version'] ?? '',
              paperclips: data['gameData']?['playerManager']?['paperclips'] ?? 0,
              money: data['gameData']?['playerManager']?['money'] ?? 0,
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


  // Supprimer une sauvegarde
  static Future<void> deleteSave(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$SAVE_PREFIX$name');
    } catch (e) {
      print('Erreur lors de la suppression: $e');
      rethrow;
    }
  }

  // Validation des données
  static bool _validateSaveData(Map<String, dynamic> data) {
    try {
      if (!data.containsKey('version') || !data.containsKey('timestamp')) {
        return false;
      }

      final gameData = data['gameData'] as Map<String, dynamic>?;
      if (gameData == null) return false;

      final playerManager = gameData['playerManager'] as Map<String, dynamic>?;
      if (playerManager == null) return false;

      // Vérifier les champs essentiels
      return playerManager.containsKey('paperclips') &&
          playerManager.containsKey('money') &&
          playerManager.containsKey('metal');
    } catch (e) {
      print('Erreur de validation: $e');
      return false;
    }
  }
}


class SaveGameInfo {
  final String id;
  final String name;
  final DateTime timestamp;
  final String version;
  final double paperclips;
  final double money;
  final bool isSyncedWithCloud;
  final String? cloudId;
  final GameMode gameMode;

  SaveGameInfo({
    required this.id,
    required this.name,
    required this.timestamp,
    required this.version,
    required this.paperclips,
    required this.money,
    this.isSyncedWithCloud = false,
    this.cloudId,
    required this.gameMode,
  });
}