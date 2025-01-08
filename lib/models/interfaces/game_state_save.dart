// lib/models/interfaces/game_state_save.dart
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../constants.dart';

mixin GameStateSave on ChangeNotifier {
  String? get customSaveDirectory;
  set customSaveDirectory(String? value);

  Future<void> loadSaveDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    customSaveDirectory = prefs.getString(GameConstants.SAVE_DIR_KEY);
  }

  Future<String> get saveDirectory async {
    if (customSaveDirectory != null) {
      return customSaveDirectory!;
    }
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/saves';
  }

  Future<void> saveGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gameData = prepareGameData();
      await prefs.setString(GameConstants.SAVE_KEY, jsonEncode(gameData));
    } catch (e) {
      print('Error saving game: $e');
    }
  }

  Future<void> exportSave(String filename) async {
    final saveDir = await saveDirectory;
    final directory = Directory(saveDir);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final file = File('$saveDir/$filename.json');
    final gameData = prepareGameData();
    try {
      await file.writeAsString(jsonEncode(gameData));
      await saveGame();
    } catch (e) {
      print('Error saving game: $e');
      throw Exception('Error saving game');
    }
  }

  Future<void> loadGame();
  Map<String, dynamic> prepareGameData();
  Future<void> selectSaveDirectory();  // Ajout de cette méthode abstraite
}