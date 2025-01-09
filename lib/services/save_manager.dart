// lib/services/save_manager.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/game_state.dart';

class SaveManager {
  static const String SAVE_KEY = 'game_save';
  static const String VERSION_KEY = 'save_version';
  static const int CURRENT_SAVE_VERSION = 1;

  static Future<void> saveGame(GameState gameState) async {
    final prefs = await SharedPreferences.getInstance();
    final saveData = {
      'version': CURRENT_SAVE_VERSION,
      'timestamp': DateTime.now().toIso8601String(),
      'gameData': {
        'paperclips': gameState.paperclips,
        'metal': gameState.metal,
        'money': gameState.money,
        'sellPrice': gameState.sellPrice,
        'autoclippers': gameState.autoclippers,
        'totalPaperclipsProduced': gameState.totalPaperclipsProduced,
        'totalTimePlayedInSeconds': gameState.totalTimePlayed,
        'upgrades': gameState.upgrades.map((key, value) => MapEntry(key, value.toJson())),
        'marketReputation': gameState.marketManager.reputation,
        'marketingLevel': gameState.marketingLevel,
        'productionCost': gameState.productionCost,
      }
    };

    await prefs.setString(SAVE_KEY, jsonEncode(saveData));
  }

  static Future<Map<String, dynamic>?> loadGame() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString(SAVE_KEY);

    if (savedData == null) return null;

    final decodedData = jsonDecode(savedData);
    final saveVersion = decodedData['version'] ?? 0;

    if (saveVersion < CURRENT_SAVE_VERSION) {
      return await _migrateSaveData(decodedData);
    }

    return decodedData['gameData'];
  }

  static Future<Map<String, dynamic>> _migrateSaveData(Map<String, dynamic> oldData) async {
    // Handle migrations between versions
    final gameData = oldData['gameData'];

    // Example migration from version 0 to 1:
    if (oldData['version'] == 0) {
      gameData['marketingLevel'] = 0;
      gameData['productionCost'] = 0.05;
    }

    // Save migrated data
    final newSaveData = {
      'version': CURRENT_SAVE_VERSION,
      'timestamp': DateTime.now().toIso8601String(),
      'gameData': gameData,
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SAVE_KEY, jsonEncode(newSaveData));

    return gameData;
  }

  static Future<bool> hasSaveGame() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(SAVE_KEY);
  }
}