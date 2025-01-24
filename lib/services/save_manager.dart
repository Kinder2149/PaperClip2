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
    return SaveGame(
      name: json['name'],
      lastSaveTime: DateTime.parse(json['lastSaveTime']),
      gameData: json['gameData'],
      version: json['version'],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'lastSaveTime': lastSaveTime.toIso8601String(),
    'gameData': gameData,
    'version': version,
  };
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
      final gameData = _validateGameData(gameState.prepareGameData());

      await prefs.setString(_getSaveKey(gameName), jsonEncode(gameData));
    } catch (e) {
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

  // Récupérer toutes les sauvegardes
  static Future<List<SaveGame>> getAllSaves() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<SaveGame> saves = [];

      for (String key in prefs.getKeys()) {
        if (key.startsWith(SAVE_KEY_PREFIX)) {
          try {
            final saveData = SaveGame.fromJson(
                jsonDecode(prefs.getString(key) ?? '{}')
            );
            saves.add(saveData);
          } catch (e) {
            print('Erreur lors de la lecture de la sauvegarde $key: $e');
          }
        }
      }

      // Tri par date décroissante
      saves.sort((a, b) => b.lastSaveTime.compareTo(a.lastSaveTime));
      return saves;
    } catch (e) {
      throw SaveError('LIST_FAILED', 'Erreur lors de la liste des sauvegardes: $e');
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