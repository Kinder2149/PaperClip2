import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

mixin GameStateSave on ChangeNotifier {
  Future<void> saveGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gameData = prepareGameData();
      await prefs.setString(GameConstants.SAVE_KEY, jsonEncode(gameData));
    } catch (e) {
      print('Error saving game: $e');
    }
  }

  Future<void> loadGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString(GameConstants.SAVE_KEY);
      if (savedData != null) {
        final gameData = jsonDecode(savedData);
        _loadGameData(gameData);
      }
    } catch (e) {
      print('Error loading game: $e');
    }
  }

  Map<String, dynamic> prepareGameData();
  void _loadGameData(Map<String, dynamic> gameData);
}