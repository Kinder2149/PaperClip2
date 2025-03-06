// lib/services/save_manager.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paperclip2/domain/entities/game_state_entity.dart';
import 'package:paperclip2/domain/entities/save_game_info.dart';
import 'package:paperclip2/core/constants/game_constants.dart';
import 'package:paperclip2/core/constants/enums.dart';

class SaveError extends Error {
  final String code;
  final String message;

  SaveError(this.code, this.message);

  @override
  String toString() => 'SaveError[$code]: $message';
}

class SaveManager {
  static const String _savePrefix = 'paperclip_save_';
  static const String _lastSaveKey = 'last_save_key';

  // Save a game state
  static Future<void> saveGame(GameStateEntity gameState, {String? name}) async {
    final prefs = await SharedPreferences.getInstance();
    final saveName = name ?? gameState.gameName ?? 'game_${DateTime.now().millisecondsSinceEpoch}';

    try {
      // Convert game state to JSON and save
      final Map<String, dynamic> gameData = {
        'playerManager': gameState.player.toJson(),
        'marketManager': gameState.market.toJson(),
        'levelSystem': gameState.levelSystem.toJson(),
        'statistics': gameState.statistics.toJson(),
        'totalPaperclipsProduced': gameState.totalPaperclipsProduced,
        'totalTimePlayedInSeconds': gameState.totalTimePlayedInSeconds,
        'isInCrisisMode': gameState.isInCrisisMode,
        'gameMode': gameState.gameMode.index,
        'version': GameConstants.VERSION,
        'timestamp': DateTime.now().toIso8601String(),
        'gameName': saveName,
      };

      await prefs.setString('$_savePrefix$saveName', json.encode(gameData));

      // Update last save info
      await prefs.setString(_lastSaveKey, saveName);
    } catch (e) {
      throw SaveError('SAVE_FAILED', 'Failed to save game: $e');
    }
  }

  // Load a game state by name
  static Future<GameStateEntity?> loadGame(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('$_savePrefix$name');

    if (savedData == null) {
      return null;
    }

    try {
      final jsonData = json.decode(savedData);
      // This is a placeholder - actual implementation would depend on your model classes
      // Return a GameStateEntity with the loaded data
      return GameStateEntity.fromJson(jsonData);
    } catch (e) {
      throw SaveError('LOAD_FAILED', 'Failed to load game: $e');
    }
  }

  // List all available saves
  static Future<List<SaveGameInfo>> listSaves() async {
    final prefs = await SharedPreferences.getInstance();
    final List<SaveGameInfo> saves = [];

    try {
      for (final key in prefs.getKeys()) {
        if (key.startsWith(_savePrefix)) {
          final savedData = prefs.getString(key);
          if (savedData != null) {
            final jsonData = json.decode(savedData);

            saves.add(SaveGameInfo(
              name: key.substring(_savePrefix.length),
              timestamp: DateTime.parse(jsonData['timestamp'] ?? DateTime.now().toIso8601String()),
              paperclips: (jsonData['playerManager']?['paperclips'] as num?)?.toDouble() ?? 0.0,
              money: (jsonData['playerManager']?['money'] as num?)?.toDouble() ?? 0.0,
              gameMode: GameMode.values[jsonData['gameMode'] as int? ?? 0],
              isSyncedWithCloud: jsonData['cloudSync'] == true,
              cloudId: jsonData['cloudId'] as String?,
            ));
          }
        }
      }

      // Sort by timestamp (newest first)
      saves.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return saves;
    } catch (e) {
      throw SaveError('LIST_FAILED', 'Failed to list saves: $e');
    }
  }

  // Delete a save by name
  static Future<bool> deleteSave(String name) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove('$_savePrefix$name');
  }

  // Check if a save exists
  static Future<bool> saveExists(String name) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('$_savePrefix$name');
  }

  // Get the last save information
  static Future<SaveGameInfo?> getLastSave() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSaveName = prefs.getString(_lastSaveKey);

    if (lastSaveName == null) return null;

    final savedData = prefs.getString('$_savePrefix$lastSaveName');
    if (savedData == null) return null;

    try {
      final jsonData = json.decode(savedData);

      return SaveGameInfo(
        name: lastSaveName,
        timestamp: DateTime.parse(jsonData['timestamp'] ?? DateTime.now().toIso8601String()),
        paperclips: (jsonData['playerManager']?['paperclips'] as num?)?.toDouble() ?? 0.0,
        money: (jsonData['playerManager']?['money'] as num?)?.toDouble() ?? 0.0,
        gameMode: GameMode.values[jsonData['gameMode'] as int? ?? 0],
        isSyncedWithCloud: jsonData['cloudSync'] == true,
        cloudId: jsonData['cloudId'] as String?,
      );
    } catch (e) {
      return null;
    }
  }
}