// lib/services/save/save_types.dart

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../models/game_config.dart';

/// Interface pour les classes qui fournissent des données à sauvegarder
abstract class SaveDataProvider {
  Map<String, dynamic> prepareGameData();
  void loadGameData(Map<String, dynamic> data);
  String? get gameName;
  GameMode get gameMode;
}

/// Représente une sauvegarde complète du jeu
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
    return {
      'id': id,
      'name': name,
      'timestamp': lastSaveTime.toIso8601String(),
      'version': version,
      'isSyncedWithCloud': isSyncedWithCloud,
      'cloudId': cloudId,
      'gameMode': gameMode.index,
      'gameData': gameData,
    };
  }

  factory SaveGame.fromJson(Map<String, dynamic> json) {
    try {
      final gameData = json['gameData'] as Map<String, dynamic>? ?? {};

      // Si les données sont à la racine, les copier dans gameData
      for (final key in ['playerManager', 'marketManager', 'levelSystem']) {
        if (json.containsKey(key)) {
          gameData[key] = json[key];
        }
      }

      return SaveGame(
        id: json['id'] as String? ?? const Uuid().v4(),
        name: json['name'] as String,
        lastSaveTime: DateTime.parse(json['timestamp'] as String),
        gameData: gameData,
        version: json['version'] as String? ?? GameConstants.VERSION,
        isSyncedWithCloud: json['isSyncedWithCloud'] as bool? ?? false,
        cloudId: json['cloudId'] as String?,
        gameMode: json['gameMode'] != null
            ? GameMode.values[json['gameMode'] as int]
            : null,
      );
    } catch (e) {
      print('Error creating SaveGame from JSON: $e');
      rethrow;
    }
  }
}

/// Version légère de SaveGame avec uniquement les métadonnées
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

  // Création à partir d'un SaveGame
  factory SaveGameInfo.fromSaveGame(SaveGame save) {
    final gameData = save.gameData;
    final playerData = gameData['playerManager'] as Map<String, dynamic>?;

    return SaveGameInfo(
      id: save.id,
      name: save.name,
      timestamp: save.lastSaveTime,
      version: save.version,
      paperclips: _extractDouble(playerData, 'paperclips') ??
          _extractDouble(gameData['productionManager'], 'paperclips') ?? 0.0,
      money: _extractDouble(playerData, 'money') ?? 0.0,
      isSyncedWithCloud: save.isSyncedWithCloud,
      cloudId: save.cloudId,
      gameMode: save.gameMode,
    );
  }

  static double? _extractDouble(Map<String, dynamic>? data, String key) {
    if (data == null || !data.containsKey(key)) return null;
    final value = data[key];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try { return double.parse(value); } catch (_) { return null; }
    }
    return null;
  }
}

/// Exception pour les erreurs de sauvegarde
class SaveError implements Exception {
  final String code;
  final String message;
  SaveError(this.code, this.message);

  @override
  String toString() => '$code: $message';
}