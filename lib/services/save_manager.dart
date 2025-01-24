// save_manager.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/game_state.dart';
import '../models/game_config.dart';
import '../models/market.dart';
import '../models/player_manager.dart';
import '../models/progression_system.dart';
import '../models/resource_manager.dart';

class SaveError extends Error {
  final String code;
  final String message;

  SaveError(this.code, this.message);

  @override
  String toString() => 'SaveError($code): $message';
}

class SaveGame {
  final String name;
  final DateTime lastSaveTime;
  final Map<String, dynamic> gameData;
  final String version;

  SaveGame({
    required this.name,
    required this.lastSaveTime,
    required this.gameData,
    required this.version,
  });

  factory SaveGame.fromJson(Map<String, dynamic> json) {
    try {
      return SaveGame(
        name: json['name'] as String,
        lastSaveTime: DateTime.parse(json['timestamp'] as String),
        gameData: json['gameData'] as Map<String, dynamic>,
        version: json['version'] as String? ?? GameConstants.VERSION,
      );
    } catch (e) {
      print('Error creating SaveGame from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() =>
      {
        'name': name,
        'timestamp': lastSaveTime.toIso8601String(),
        'gameData': gameData,
        'version': version,
      };


  static bool isValidGameData(Map<String, dynamic> data) {
    try {
      final playerManager = data['gameData']?['playerManager'];
      if (playerManager == null) return false;

      // Vérifiez les champs requis
      return playerManager['metal'] != null &&
          playerManager['money'] != null &&
          playerManager['paperclips'] != null;
    } catch (e) {
      print('Error validating game data: $e');
      return false;
    }
  }
}



class SaveManager {
  static const String SAVE_KEY_PREFIX = 'game_save_${GameConstants.VERSION}_';
  static final DateTime CURRENT_DATE = DateTime(2025, 1, 23, 15, 15, 49);
  static const String CURRENT_USER = 'Kinder2149';
  static const String CURRENT_VERSION = '1.0.0';

  // Obtenir la clé de sauvegarde unique pour une partie
  static String _getSaveKey(String gameName) => '$SAVE_KEY_PREFIX$gameName';


  // Sauvegarder une partie
  static Future<void> saveGame(GameState gameState, String gameName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saveData = {
        'name': gameName,
        'timestamp': DateTime.now().toIso8601String(),
        'version': GameConstants.VERSION,
        'gameData': {
          'playerManager': gameState.playerManager.toJson(),
          'marketManager': gameState.marketManager.toJson(),
          'levelSystem': gameState.levelSystem.toJson(),
          'totalTimePlayedInSeconds': gameState.totalTimePlayed,
          'totalPaperclipsProduced': gameState.totalPaperclipsProduced,
        }
      };

      final saveKey = _getSaveKey(gameName);
      await prefs.setString(saveKey, jsonEncode(saveData));
    } catch (e) {
      print('Error saving game: $e');
      throw SaveError('SAVE_FAILED', 'Erreur lors de la sauvegarde: $e');
    }
  }

  // Charger une partie spécifique
  static Future<SaveGame?> loadGame(String gameName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saveKey = _getSaveKey(gameName);
      final savedData = prefs.getString(saveKey);

      if (savedData == null) return null;

      final saveGame = SaveGame.fromJson(jsonDecode(savedData));
      return saveGame;
    } catch (e) {
      throw SaveError('LOAD_FAILED', 'Erreur lors du chargement: $e');
    }
  }

  // Récupérer la dernière sauvegarde
  static Future<SaveGame?> getLastSave() async {
    try {
      final allSaves = await getAllSaves();
      if (allSaves.isEmpty) return null;
      return allSaves.first; // Déjà trié par date
    } catch (e) {
      print('Erreur lors de la récupération de la dernière sauvegarde: $e');
      return null;
    }
  }
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

  // Récupérer toutes les sauvegardes
  static Future<List<SaveGame>> getAllSaves() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<SaveGame> saves = [];

      for (String key in prefs.getKeys()) {
        if (!key.startsWith(SAVE_KEY_PREFIX)) continue;

        try {
          final String? savedData = prefs.getString(key);
          if (savedData == null) continue;

          final Map<String, dynamic> json = jsonDecode(savedData);

          // Vérifiez que les données sont valides avant de créer le SaveGame
          if (json.containsKey('name') &&
              json.containsKey('timestamp') &&
              json.containsKey('gameData')) {
            saves.add(SaveGame.fromJson(json));
          } else {
            print('Invalid save data structure for key $key: $json');
          }
        } catch (e) {
          print('Error parsing save at key $key: $e');
        }
      }

      saves.sort((a, b) => b.lastSaveTime.compareTo(a.lastSaveTime));
      return saves;
    } catch (e) {
      print('Error getting all saves: $e');
      return [];
    }
  }

  // Supprimer une sauvegarde
  static Future<void> deleteGame(String gameName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_getSaveKey(gameName));
    } catch (e) {
      throw SaveError('DELETE_FAILED', 'Erreur lors de la suppression: $e');
    }
  }

  // Validation et conversion des données de sauvegarde
  static Map<String, dynamic> _validateGameData(Map<String, dynamic> data) {
    final requiredFields = [
      'playerManager',
      'marketManager',
      'levelSystem',
      'missionSystem',
      'totalTimePlayedInSeconds',
      'totalPaperclipsProduced'
    ];

    for (final field in requiredFields) {
      if (!data.containsKey(field)) {
        throw SaveError('VALIDATION_ERROR', 'Champ manquant: $field');
      }
    }

    return {
      ...data,
      'version': GameConstants.VERSION,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Vérifier si une sauvegarde existe
  static Future<bool> saveExists(String gameName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_getSaveKey(gameName));
  }
}