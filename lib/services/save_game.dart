// lib/services/save_game.dart
// Ce fichier sert de point d'entrée unifié pour le système de sauvegarde

// Exporter les classes du modèle pour la sauvegarde
export '../models/save_game.dart' show SaveGame;
export '../models/save_metadata.dart' show SaveMetadata;

// SaveManagerAdapter supprimé - utiliser LocalSaveGameManager directement
export 'save_system/save_error.dart' show SaveError;

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
  final num totalPaperclipsSold;
  final num autoClipperCount;
  final int level;
  final bool isBackup;
  final bool isRestored;

  SaveGameInfo({
    required this.id,
    required this.name,
    required this.timestamp,
    required this.version,
    this.paperclips = 0,
    this.money = 0,
    this.totalPaperclipsSold = 0,
    this.autoClipperCount = 0,
    this.level = 1,
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
    int level = 1;

    if (gameData != null) {
      // CORRECTION CRITIQUE: gameData contient DIRECTEMENT le snapshot (core/stats/managers)
      // Pas besoin de chercher dans gameData['gameSnapshot']
      
      // 1) Format actuel: gameData contient directement core/stats/managers
      if (gameData.containsKey('core') || gameData.containsKey('stats') || gameData.containsKey('managers')) {
        final core = (gameData['core'] is Map) ? Map<String, dynamic>.from(gameData['core'] as Map) : const <String, dynamic>{};
        final stats = (gameData['stats'] is Map) ? Map<String, dynamic>.from(gameData['stats'] as Map) : const <String, dynamic>{};
        final managers = (gameData['managers'] is Map) ? Map<String, dynamic>.from(gameData['managers'] as Map) : const <String, dynamic>{};
        
        // Extraire money depuis playerManager dans core
        if (core.containsKey('playerManager') && core['playerManager'] is Map) {
          final pm = Map<String, dynamic>.from(core['playerManager'] as Map);
          money = (pm['money'] as num?) ?? money;
          auto = (pm['autoClipperCount'] as num?) ?? auto;
        }
        
        paperclips = (stats['paperclips'] as num?) ?? paperclips;
        totalSold = (stats['totalPaperclipsSold'] as num?) ?? totalSold;
        
        // CORRECTION CRITIQUE: Le niveau est dans core.levelSystem, pas dans managers.levelSystem
        if (core.containsKey('levelSystem') && core['levelSystem'] is Map) {
          final levelSys = Map<String, dynamic>.from(core['levelSystem'] as Map);
          level = (levelSys['level'] as num?)?.toInt() ?? level;
        }
        // Fallback: chercher aussi dans managers si présent (compatibilité)
        else if (managers.containsKey('levelSystem') && managers['levelSystem'] is Map) {
          final levelSys = Map<String, dynamic>.from(managers['levelSystem'] as Map);
          level = (levelSys['level'] as num?)?.toInt() ?? level;
        }
      }
      // 2) Format legacy: playerManager à la racine
      else if (gameData.containsKey('playerManager') && gameData['playerManager'] is Map) {
        final pm = Map<dynamic, dynamic>.from(gameData['playerManager'] as Map);
        money = (pm['money'] as num?) ?? money;
        paperclips = (pm['paperclips'] as num?) ?? paperclips;
        totalSold = (pm['totalPaperclipsSold'] as num?) ?? totalSold;
        auto = (pm['autoClipperCount'] as num?) ?? auto;
      }
      // 3) Format imbriqué: gameData.gameSnapshot.core/stats/managers
      else if (gameData.containsKey('gameSnapshot') && gameData['gameSnapshot'] is Map) {
        final snap = Map<String, dynamic>.from(gameData['gameSnapshot'] as Map);
        final core = (snap['core'] is Map) ? Map<String, dynamic>.from(snap['core'] as Map) : const <String, dynamic>{};
        final stats = (snap['stats'] is Map) ? Map<String, dynamic>.from(snap['stats'] as Map) : const <String, dynamic>{};
        final managers = (snap['managers'] is Map) ? Map<String, dynamic>.from(snap['managers'] as Map) : const <String, dynamic>{};
        
        // Extraire money depuis playerManager dans core
        if (core.containsKey('playerManager') && core['playerManager'] is Map) {
          final pm = Map<String, dynamic>.from(core['playerManager'] as Map);
          money = (pm['money'] as num?) ?? money;
          auto = (pm['autoClipperCount'] as num?) ?? auto;
        }
        
        paperclips = (stats['paperclips'] as num?) ?? paperclips;
        totalSold = (stats['totalPaperclipsSold'] as num?) ?? totalSold;
        
        // CORRECTION CRITIQUE: Le niveau est dans core.levelSystem, pas dans managers.levelSystem
        if (core.containsKey('levelSystem') && core['levelSystem'] is Map) {
          final levelSys = Map<String, dynamic>.from(core['levelSystem'] as Map);
          level = (levelSys['level'] as num?)?.toInt() ?? level;
        }
        // Fallback: chercher aussi dans managers si présent (compatibilité)
        else if (managers.containsKey('levelSystem') && managers['levelSystem'] is Map) {
          final levelSys = Map<String, dynamic>.from(managers['levelSystem'] as Map);
          level = (levelSys['level'] as num?)?.toInt() ?? level;
        }
      }
    }

    return SaveGameInfo(
      id: metadata.id,
      name: metadata.name,
      timestamp: metadata.lastModified,
      version: metadata.version,
      isRestored: metadata.isRestored,
      isBackup: isBackup,
      paperclips: paperclips,
      money: money,
      totalPaperclipsSold: totalSold,
      autoClipperCount: auto,
      level: level,
    );
  }
  
  @override
  String toString() => 'SaveGameInfo(id: $id, name: $name, lastModified: $timestamp)';
}
