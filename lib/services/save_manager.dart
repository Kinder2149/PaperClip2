// lib/services/save_manager.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_state.dart';
import '../models/game_config.dart';

class SaveError implements Exception {
  final String code;
  final String message;
  SaveError(this.code, this.message);

  @override
  String toString() => '$code: $message';
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
        gameData: (json['gameData'] as Map<String, dynamic>?) ?? {},
        version: json['version'] as String? ?? GameConstants.VERSION,
      );
    } catch (e) {
      print('Error creating SaveGame from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'timestamp': lastSaveTime.toIso8601String(),
    'gameData': gameData,
    'version': version,
  };
}




class SaveManager {
  static const String SAVE_PREFIX = 'paperclip_save_';
  static final DateTime CURRENT_DATE = DateTime(2025, 1, 23, 15, 15, 49);
  static const String CURRENT_USER = 'Kinder2149';
  static const String CURRENT_VERSION = '1.0.0';
  static String _getSaveKey(String gameName) => '$SAVE_PREFIX$gameName';

  // Obtenir la clé de sauvegarde unique pour une partie


  // Sauvegarder une partie
  static Future<void> saveGame(GameState gameState, String name) async {
    try {
      if (name.isEmpty) {
        throw SaveError('INVALID_NAME', 'Le nom de la sauvegarde ne peut pas être vide');
      }

      final prefs = await SharedPreferences.getInstance();
      final saveData = SaveGame(
        name: name,
        lastSaveTime: DateTime.now(),
        version: GameConstants.VERSION,
        gameData: {
          'playerManager': gameState.playerManager.toJson(),
          'marketManager': gameState.marketManager.toJson(),
          'levelSystem': gameState.levelSystem.toJson(),
          'totalTimePlayedInSeconds': gameState.totalTimePlayed,
          'totalPaperclipsProduced': gameState.totalPaperclipsProduced,
        },
      );

      final key = _getSaveKey(name);
      await prefs.setString(key, jsonEncode(saveData.toJson()));
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
      throw SaveError('SAVE_FAILED', 'Erreur lors de la sauvegarde: $e');
    }
  }
  static Future<SaveGameInfo?> getLastSave() async {
    final saves = await listSaves();
    return saves.isNotEmpty ? saves.first : null;
  }

  static Future<bool> saveExists(String name) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_getSaveKey(name));
  }


  // Charger une partie spécifique
  // Modifier cette méthode pour retourner un SaveGame au lieu d'un Map
  static Future<SaveGame?> loadGame(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$SAVE_PREFIX$name';
      final savedData = prefs.getString(key);

      if (savedData == null) {
        return null;
      }

      final jsonData = jsonDecode(savedData) as Map<String, dynamic>;

      // Validation après chargement
      if (!_validateSaveData(jsonData)) {
        throw SaveError('CORRUPTED_DATA', 'Les données de sauvegarde sont corrompues');
      }

      // Créer et retourner un objet SaveGame
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
            final data = jsonDecode(prefs.getString(key) ?? '{}');
            saves.add(SaveGameInfo(
              name: key.substring(SAVE_PREFIX.length),
              timestamp: DateTime.parse(data['timestamp'] ?? ''),
              version: data['version'] ?? '',
              paperclips: data['gameData']?['playerManager']?['paperclips'] ?? 0,
              money: data['gameData']?['playerManager']?['money'] ?? 0,
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
  final String name;
  final DateTime timestamp;
  final String version;
  final double paperclips;
  final double money;

  SaveGameInfo({
    required this.name,
    required this.timestamp,
    required this.version,
    required this.paperclips,
    required this.money,
  });
}