import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:paperclip2/constants/game_config.dart'; // Importé depuis constants au lieu de models
import 'package:paperclip2/utils/logger.dart';

/// Modèle principal de sauvegarde pour PaperClip2.
/// 
/// Ce modèle représente une sauvegarde complète d'un monde/partie, incluant :
/// - Un identifiant technique unique (UUID v4) utilisé pour le stockage local et cloud
/// - Un nom affichable pour l'utilisateur
/// - Les données de jeu complètes (incluant le GameSnapshot)
/// - Les métadonnées de sauvegarde (mode de jeu, version, timestamps)
/// 
/// **Architecture :**
/// - `SaveGame` est le modèle de persistance unifié utilisé par tous les services
/// - Le modèle `World` existe comme wrapper utilitaire mais `SaveGame` reste la source de vérité
/// - L'identifiant `id` correspond au `worldId`/`partieId` dans l'architecture cloud
/// 
/// **Identité stricte (ID-first) :**
/// - Chaque sauvegarde possède un `id` UUID v4 unique généré à la création
/// - Cet ID est utilisé comme clé de stockage local et cloud (`/worlds/:worldId`)
/// - Le `name` est purement affichable et peut être modifié sans impact sur l'identité
/// 
/// **Limite :** Un utilisateur peut créer jusqu'à `GameConstants.MAX_WORLDS` mondes.
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
      appLogger.error('[SAVE] Erreur lors de la création de SaveGame à partir de JSON: '+e.toString());
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
      appLogger.warn('[STATE] Mode de jeu inconnu: '+modeString+', utilisation du mode infini par défaut');
      return GameMode.INFINITE;
    }
  }
}
