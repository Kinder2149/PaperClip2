// lib/services/save_manager.dart

import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class GameSave {
  final String id;
  final String name;
  final DateTime lastSaveTime;
  final Map<String, dynamic> gameData;

  GameSave({
    required this.id,
    required this.name,
    required this.lastSaveTime,
    required this.gameData,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'lastSaveTime': lastSaveTime.toIso8601String(),
    'gameData': gameData,
  };

  factory GameSave.fromJson(Map<String, dynamic> json) => GameSave(
    id: json['id'],
    name: json['name'],
    lastSaveTime: DateTime.parse(json['lastSaveTime']),
    gameData: json['gameData'],
  );
}

class SaveManager {
  static final SaveManager _instance = SaveManager._internal();
  factory SaveManager() => _instance;
  SaveManager._internal();

  Future<String> get _saveDirPath async {
    final appDir = await getApplicationDocumentsDirectory();
    final saveDir = Directory('${appDir.path}/saves');
    if (!await saveDir.exists()) {
      await saveDir.create(recursive: true);
    }
    return saveDir.path;
  }

  // Sauvegarde ou met à jour une partie
  Future<void> saveGame(Map<String, dynamic> gameData, String gameId, String gameName) async {
    final saveDirPath = await _saveDirPath;
    final save = GameSave(
      id: gameId,
      name: gameName,
      lastSaveTime: DateTime.now(),
      gameData: gameData,
    );

    // Sauvegarde dans un fichier unique pour cette partie
    final saveFile = File('$saveDirPath/$gameId.sav');
    await saveFile.writeAsString(jsonEncode(save.toJson()));

    // Met à jour le fichier d'index des parties
    await _updateGameIndex(save);
  }

  // Met à jour l'index des parties
  Future<void> _updateGameIndex(GameSave save) async {
    final saveDirPath = await _saveDirPath;
    final indexFile = File('$saveDirPath/games_index.json');

    Map<String, dynamic> gamesIndex = {};
    if (await indexFile.exists()) {
      final content = await indexFile.readAsString();
      gamesIndex = jsonDecode(content);
    }

    // Met à jour les informations de la partie dans l'index
    gamesIndex[save.id] = {
      'name': save.name,
      'lastSaveTime': save.lastSaveTime.toIso8601String(),
    };

    await indexFile.writeAsString(jsonEncode(gamesIndex));
  }

  // Liste toutes les parties sauvegardées
  Future<List<Map<String, dynamic>>> listGames() async {
    final saveDirPath = await _saveDirPath;
    final indexFile = File('$saveDirPath/games_index.json');

    if (!await indexFile.exists()) {
      return [];
    }

    final content = await indexFile.readAsString();
    final Map<String, dynamic> gamesIndex = jsonDecode(content);

    return gamesIndex.entries.map((entry) => {
      'id': entry.key,
      'name': entry.value['name'],
      'lastSaveTime': DateTime.parse(entry.value['lastSaveTime']),
    }).toList()
      ..sort((a, b) => (b['lastSaveTime'] as DateTime)
          .compareTo(a['lastSaveTime'] as DateTime));
  }

  // Charge une partie spécifique
  Future<Map<String, dynamic>?> loadGame(String gameId) async {
    final saveDirPath = await _saveDirPath;
    final saveFile = File('$saveDirPath/$gameId.sav');

    if (!await saveFile.exists()) {
      return null;
    }

    final content = await saveFile.readAsString();
    final save = GameSave.fromJson(jsonDecode(content));
    return save.gameData;
  }

  // Supprime une partie
  Future<void> deleteGame(String gameId) async {
    final saveDirPath = await _saveDirPath;

    // Supprime le fichier de sauvegarde
    final saveFile = File('$saveDirPath/$gameId.sav');
    if (await saveFile.exists()) {
      await saveFile.delete();
    }

    // Met à jour l'index
    final indexFile = File('$saveDirPath/games_index.json');
    if (await indexFile.exists()) {
      final content = await indexFile.readAsString();
      final Map<String, dynamic> gamesIndex = jsonDecode(content);
      gamesIndex.remove(gameId);
      await indexFile.writeAsString(jsonEncode(gamesIndex));
    }
  }
}