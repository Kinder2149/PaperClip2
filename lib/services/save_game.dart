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
    num money = 0;
    num paperclips = 0;
    num totalSold = 0;
    num auto = 0;

    if (gameData != null) {
      // 1) Format legacy: playerManager à la racine
      if (gameData.containsKey('playerManager') && gameData['playerManager'] is Map) {
        final pm = Map<dynamic, dynamic>.from(gameData['playerManager'] as Map);
        money = (pm['money'] as num?) ?? money;
        paperclips = (pm['paperclips'] as num?) ?? paperclips;
        totalSold = (pm['totalPaperclipsSold'] as num?) ?? totalSold;
        auto = (pm['autoClipperCount'] as num?) ?? auto;
      }
      // 2) Nouveau format snapshot-only: gameSnapshot.core/stats
      else if (gameData.containsKey('gameSnapshot') && gameData['gameSnapshot'] is Map) {
        final snap = Map<String, dynamic>.from(gameData['gameSnapshot'] as Map);
        final core = (snap['core'] is Map) ? Map<String, dynamic>.from(snap['core'] as Map) : const <String, dynamic>{};
        final stats = (snap['stats'] is Map) ? Map<String, dynamic>.from(snap['stats'] as Map) : const <String, dynamic>{};
        money = (core['money'] as num?) ?? money;
        paperclips = (stats['paperclips'] as num?) ?? paperclips;
        totalSold = (stats['totalPaperclipsSold'] as num?) ?? totalSold;
        auto = (core['autoClipperCount'] as num?) ?? auto;
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
      paperclips: paperclips,
      money: money,
      totalPaperclipsSold: totalSold,
      autoClipperCount: auto,
    );
  }
  
  @override
  String toString() => 'SaveGameInfo(id: $id, name: $name, lastModified: $timestamp)';
}
