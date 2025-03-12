import 'package:paperclip2/models/game_config.dart';

/// Interface pour les différentes stratégies de sauvegarde
abstract class SaveStrategy {
  /// Sauvegarde les données du jeu
  Future<bool> save(String name, Map<String, dynamic> data, {GameMode gameMode = GameMode.INFINITE});
  
  /// Charge les données du jeu
  Future<Map<String, dynamic>?> load(String name);
  
  /// Vérifie si une sauvegarde existe
  Future<bool> exists(String name);
  
  /// Supprime une sauvegarde
  Future<bool> delete(String name);
  
  /// Liste toutes les sauvegardes disponibles
  Future<List<SaveInfo>> listSaves();
}

/// Informations sur une sauvegarde
class SaveInfo {
  final String id;
  final String name;
  final DateTime timestamp;
  final String version;
  final double paperclips;
  final double money;
  final bool isSyncedWithCloud;
  final String? cloudId;
  final GameMode gameMode;

  SaveInfo({
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
  
  /// Crée une instance à partir d'un Map
  factory SaveInfo.fromJson(Map<String, dynamic> json) {
    return SaveInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      version: json['version'] as String,
      paperclips: (json['paperclips'] as num).toDouble(),
      money: (json['money'] as num).toDouble(),
      isSyncedWithCloud: json['isSyncedWithCloud'] as bool? ?? false,
      cloudId: json['cloudId'] as String?,
      gameMode: json['gameMode'] != null 
          ? GameMode.values[json['gameMode'] as int] 
          : GameMode.INFINITE,
    );
  }
  
  /// Convertit l'instance en Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'timestamp': timestamp.toIso8601String(),
      'version': version,
      'paperclips': paperclips,
      'money': money,
      'isSyncedWithCloud': isSyncedWithCloud,
      'cloudId': cloudId,
      'gameMode': gameMode.index,
    };
  }
} 