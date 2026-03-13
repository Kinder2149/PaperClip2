import 'game_snapshot.dart';

/// Interface de service de persistance pour l'état du jeu.
///
/// Cette abstraction permet de brancher différentes implémentations
/// (stockage local, cloud, etc.) tout en gardant un contrat unique.
abstract class GamePersistenceService {
  /// Sauvegarde un instantané de jeu dans un "slot" identifié.
  Future<void> saveSnapshot(GameSnapshot snapshot, {required String slotId});

  /// Charge un instantané de jeu depuis un slot.
  /// Retourne `null` si aucun snapshot n'est disponible.
  Future<GameSnapshot?> loadSnapshot({required String slotId});

  /// Applique les migrations nécessaires pour amener le snapshot
  /// au dernier format supporté par l'application.
  Future<GameSnapshot> migrateSnapshot(GameSnapshot snapshot);
}
