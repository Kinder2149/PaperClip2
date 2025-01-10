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
      'gameData': gameState.prepareGameData(),
    };

    await prefs.setString(SAVE_KEY, jsonEncode(saveData));
    print('Game saved: $saveData'); // Log to check save data
  }

  static Future<Map<String, dynamic>?> loadGame() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString(SAVE_KEY);

    if (savedData == null) {
      print('No saved game found.');
      return null;
    }

    final decodedData = jsonDecode(savedData);
    final saveVersion = decodedData['version'] ?? 0;

    if (saveVersion < CURRENT_SAVE_VERSION) {
      return await _migrateSaveData(decodedData);
    }

    print('Game loaded: ${decodedData['gameData']}'); // Log to check loaded data
    return decodedData['gameData'];
  }

  static Future<Map<String, dynamic>> _migrateSaveData(Map<String, dynamic> oldData) async {
    final gameData = oldData['gameData'];

    if (oldData['version'] == 0) {
      gameData['marketingLevel'] = 0;
      gameData['productionCost'] = 0.05;
    }

    final newSaveData = {
      'version': CURRENT_SAVE_VERSION,
      'timestamp': DateTime.now().toIso8601String(),
      'gameData': gameData,
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SAVE_KEY, jsonEncode(newSaveData));

    print('Game data migrated: $newSaveData'); // Log to check migrated data
    return gameData;
  }

  static Future<bool> hasSaveGame() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(SAVE_KEY);
  }

  static Future<void> deleteGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(SAVE_KEY);
  }
}