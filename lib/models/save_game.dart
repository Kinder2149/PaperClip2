import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:paperclip2/constants/game_config.dart'; // Importé depuis constants au lieu de models

class SaveGame {
  final String id;
  final String name;
  final Map<String, dynamic> gameData;
  final GameMode gameMode;
  final DateTime lastSaveTime;
  final String version;
  final bool isRestored;
  
  SaveGame({
    String? id,
    required this.name,
    required this.gameData,
    required this.gameMode,
    required this.lastSaveTime,
    String? version,
    bool isRestored = false,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.version = version ?? GameConstants.VERSION,
    this.isRestored = isRestored;
  
  // Factory pour créer une sauvegarde à partir d'un JSON
  factory SaveGame.fromJson(Map<String, dynamic> json) {
    try {
      return SaveGame(
        id: json['id'] as String?,
        name: json['name'] as String,
        gameData: json['gameData'] as Map<String, dynamic>,
        gameMode: _gameModefromString(json['gameMode'] as String),
        lastSaveTime: DateTime.parse(json['lastSaveTime'] as String),
        version: json['version'] as String?,
        isRestored: json['isRestored'] as bool? ?? false,
      );
    } catch (e) {
      print('Erreur lors de la création de SaveGame à partir de JSON: $e');
      throw Exception('Impossible de charger la sauvegarde');
    }
  }
  
  // Méthode pour convertir en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'gameData': gameData,
      'gameMode': gameMode.toString().split('.').last,
      'lastSaveTime': lastSaveTime.toIso8601String(),
      'version': version,
      'isRestored': isRestored,
    };
  }
  
  // Méthode pour convertir en chaîne JSON
  String toJsonString() {
    return jsonEncode(toJson());
  }
  
  // Méthode pour créer une copie avec des modifications
  SaveGame copyWith({
    String? id,
    String? name,
    Map<String, dynamic>? gameData,
    GameMode? gameMode,
    DateTime? lastSaveTime,
    String? version,
    bool? isRestored,
  }) {
    return SaveGame(
      id: id ?? this.id,
      name: name ?? this.name,
      gameData: gameData ?? this.gameData,
      gameMode: gameMode ?? this.gameMode,
      lastSaveTime: lastSaveTime ?? this.lastSaveTime,
      version: version ?? this.version,
      isRestored: isRestored ?? this.isRestored,
    );
  }
  
  // Méthode privée pour convertir une chaîne en GameMode
  static GameMode _gameModefromString(String modeString) {
    try {
      if (modeString == 'COMPETITIVE') {
        return GameMode.COMPETITIVE;
      } else {
        return GameMode.INFINITE;
      }
    } catch (e) {
      print('Mode de jeu inconnu: $modeString, utilisation du mode infini par défaut');
      return GameMode.INFINITE;
    }
  }
}
