import 'package:uuid/uuid.dart';
import 'game_snapshot.dart';

/// Migre les snapshots de v2 vers v3
/// v3 : Migration Multi-Parties → Entreprise Unique
class SnapshotMigrator {
  /// Migre un snapshot v2 vers v3
  static GameSnapshot migrateToV3(GameSnapshot oldSnapshot) {
    final oldMetadata = oldSnapshot.metadata;
    final version = oldMetadata['version'] as int? ?? 1;
    
    if (version >= 3) {
      return oldSnapshot; // Déjà v3
    }
    
    // Migration v2 → v3
    final newMetadata = {
      'version': 3,
      'enterpriseId': oldMetadata['enterpriseId'] ?? const Uuid().v4(),
      'enterpriseName': oldMetadata['gameId'] ?? oldMetadata['gameName'] ?? 'Mon Entreprise',
      'createdAt': oldMetadata['createdAt'] ?? DateTime.now().toUtc().toIso8601String(),
      'lastModified': oldMetadata['savedAt'] ?? DateTime.now().toUtc().toIso8601String(),
      'gameMode': oldMetadata['gameMode'] ?? 'infinite',
      'quantum': 0, // Nouveau
      'pointsInnovation': 0, // Nouveau
      'totalResets': 0, // Nouveau
    };
    
    // Ajouter sections agents et recherche vides
    final newCore = Map<String, dynamic>.from(oldSnapshot.core);
    newCore['agents'] = {
      'unlocked': [],
      'active': [],
      'levels': {},
      'config': {},
    };
    newCore['research'] = {
      'completed': [],
      'available': [],
    };
    
    return GameSnapshot(
      metadata: newMetadata,
      core: newCore,
      market: oldSnapshot.market,
      production: oldSnapshot.production,
      stats: oldSnapshot.stats,
    );
  }
}
