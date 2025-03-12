import 'package:paperclip2/models/game_config.dart';
import 'package:uuid/uuid.dart';
import 'save_service.dart';
import 'save_strategy.dart';

/// Classe pour assurer la compatibilité avec l'ancien code
class SaveAdapter {
  final SaveService _saveService;
  
  SaveAdapter(this._saveService);
  
  /// Sauvegarde une partie (compatible avec l'ancien code)
  Future<void> saveGame(SaveGame saveGame) async {
    await _saveService.saveGame(
      saveGame.name,
      saveGame.gameData,
      gameMode: saveGame.gameMode,
    );
  }
  
  /// Charge une partie (compatible avec l'ancien code)
  Future<SaveGame?> loadGame(String name) async {
    final data = await _saveService.loadGame(name);
    if (data == null) {
      return null;
    }
    
    return SaveGame(
      name: name,
      lastSaveTime: DateTime.now(),
      gameData: data,
      version: GameConstants.VERSION,
    );
  }
  
  /// Vérifie si une sauvegarde existe (compatible avec l'ancien code)
  Future<bool> saveExists(String name) async {
    return await _saveService.saveExists(name);
  }
  
  /// Supprime une sauvegarde (compatible avec l'ancien code)
  Future<void> deleteSave(String name) async {
    await _saveService.deleteSave(name);
  }
  
  /// Liste toutes les sauvegardes disponibles (compatible avec l'ancien code)
  Future<List<SaveGameInfo>> listSaves() async {
    final saves = await _saveService.listSaves();
    return saves.map((save) => SaveGameInfo(
      id: save.id,
      name: save.name,
      timestamp: save.timestamp,
      version: save.version,
      paperclips: save.paperclips,
      money: save.money,
      isSyncedWithCloud: save.isSyncedWithCloud,
      cloudId: save.cloudId,
      gameMode: save.gameMode,
    )).toList();
  }
  
  /// Récupère la dernière sauvegarde (compatible avec l'ancien code)
  Future<SaveGameInfo?> getLastSave() async {
    final save = await _saveService.getLastSave();
    if (save == null) {
      return null;
    }
    
    return SaveGameInfo(
      id: save.id,
      name: save.name,
      timestamp: save.timestamp,
      version: save.version,
      paperclips: save.paperclips,
      money: save.money,
      isSyncedWithCloud: save.isSyncedWithCloud,
      cloudId: save.cloudId,
      gameMode: save.gameMode,
    );
  }
  
  /// Crée une sauvegarde de secours (compatible avec l'ancien code)
  Future<bool> createBackup(String name, Map<String, dynamic> data) async {
    return await _saveService.createBackup(name, data);
  }
  
  /// Synchronise les sauvegardes (compatible avec l'ancien code)
  Future<bool> syncSaves() async {
    return await _saveService.syncSaves();
  }
}

/// Classe pour représenter une sauvegarde (compatible avec l'ancien code)
class SaveGame {
  final String id;
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

/// Classe pour représenter les informations d'une sauvegarde (compatible avec l'ancien code)
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