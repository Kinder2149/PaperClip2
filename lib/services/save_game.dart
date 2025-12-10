// lib/services/save_game.dart
// Ce fichier sert de point d'entrée unifié pour le système de sauvegarde

// Exporter les classes du modèle pour la sauvegarde
export '../models/save_game.dart' show SaveGame;
export '../models/save_metadata.dart' show SaveMetadata;

// Exporter l'adaptateur comme point d'entrée principal pour le système de sauvegarde
export 'save_system/save_manager_adapter.dart' show SaveManagerAdapter, SaveError;
// L'alias 'as' n'est pas permis dans une directive export, utiliser import + export séparé
import 'save_system/save_manager_adapter.dart' show SaveManagerAdapter;

// Import des dépendances nécessaires pour la réutilisation des classes
import '../constants/game_config.dart';
import 'save_system/local_save_game_manager.dart';
import '../models/save_metadata.dart'; // Import direct de SaveMetadata pour l'utilisation interne

/// Classe SaveGameInfo pour compatibilité avec le code existant
/// 
/// Assure une compatibilité robuste avec SaveMetadata et fournit des valeurs par défaut
/// sécurisées pour éviter les problèmes de nullité.
class SaveGameInfo {
  final String id;
  final String name;
  
  /// Date de dernière modification de la sauvegarde
  /// Également disponible via le getter lastModified pour compatibilité
  final DateTime timestamp;
  
  /// Getter pour standardiser avec le reste du système de sauvegarde
  /// Retourne toujours une valeur non-null
  DateTime get lastModified => timestamp;
  
  final String version;
  final num paperclips;
  final num money;
  final GameMode gameMode;
  final num totalPaperclipsSold;
  final num autoClipperCount;
  final bool isBackup;
  final bool isRestored;

  SaveGameInfo({
    required this.id,
    required this.name,
    required this.timestamp,
    required this.version,
    this.paperclips = 0,
    this.money = 0,
    required this.gameMode,
    this.totalPaperclipsSold = 0,
    this.autoClipperCount = 0,
    this.isBackup = false,
    this.isRestored = false,
  });
  
  /// Crée une instance à partir d'un objet SaveMetadata
  /// Cette méthode facilite la conversion entre les deux modèles
  factory SaveGameInfo.fromMetadata(SaveMetadata metadata, {
    Map<dynamic, dynamic>? gameData,
    bool isBackup = false,
  }) {
    // Cast sécurisé qui accepte Map<dynamic, dynamic>
    Map<dynamic, dynamic> playerManager = {};
    if (gameData != null && gameData.containsKey('playerManager')) {
      var pm = gameData['playerManager'];
      if (pm is Map) {
        playerManager = pm;
      }
    }
    
    return SaveGameInfo(
      id: metadata.id,
      name: metadata.name,
      timestamp: metadata.lastModified,
      version: metadata.version,
      gameMode: metadata.gameMode,
      isRestored: metadata.isRestored,
      isBackup: isBackup,
      // Extraire les données de jeu avec des valeurs par défaut sécurisées
      paperclips: playerManager['paperclips'] ?? 0,
      money: playerManager['money'] ?? 0,
      totalPaperclipsSold: playerManager['totalPaperclipsSold'] ?? 0,
      autoClipperCount: playerManager['autoClipperCount'] ?? 0,
    );
  }
  
  @override
  String toString() => 'SaveGameInfo(id: $id, name: $name, lastModified: $timestamp)';
}
