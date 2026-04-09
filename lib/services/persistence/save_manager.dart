import 'dart:async';

import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/services/persistence/game_persistence_orchestrator.dart';

/// SaveManager centralise toutes les décisions de sauvegarde (locale + cloud)
/// en déléguant l'exécution à GamePersistenceOrchestrator, afin d'éviter toute
/// duplication de logique et d'imposer un point d'entrée unique.
class SaveManager {
  SaveManager._();
  static final SaveManager instance = SaveManager._();

  /// Sauvegarde locale immédiate de l'état courant (ID-first).
  Future<void> saveLocal(GameState state, {String? reason}) {
    // Utilise la file et les règles internes de l'orchestrateur (pump + coalesce)
    return GamePersistenceOrchestrator.instance.requestManualSave(state, reason: reason);
  }

  /// Déclenche un push cloud pour la partie courante (via playerId provider de l'orchestrateur).
  Future<void> saveCloud(GameState state, {String? reason}) async {
    final pid = state.enterpriseId;
    if (pid == null || pid.isEmpty) return;
    // L'orchestrateur gère la récupération du playerId via son provider configuré.
    await GamePersistenceOrchestrator.instance.pushCloudForState(state, reason: reason);
  }

  /// Déclenche un push cloud à partir d'un identifiant de sauvegarde (sans charger l'UI).
  Future<void> saveCloudById({required String enterpriseId, required String uid}) async {
    await GamePersistenceOrchestrator.instance.pushCloudFromSaveId(
      enterpriseId: enterpriseId,
      uid: uid,
    );
  }

  /// Charge une entreprise par identifiant technique.
  Future<void> loadEnterprise(GameState state, {required String enterpriseId}) {
    return GamePersistenceOrchestrator.instance.loadGameById(state, enterpriseId);
  }
}
