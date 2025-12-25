# Persistance — Stratégie Snapshot-First

Document canonique — fait foi
Dernière mise à jour: 2025-12-25
Voir aussi: `identity/INVARIANTS_IDENTITE_PERSISTENCE.md` • `Glossaire.md`

Ce document décrit la stratégie de persistance adoptée pour PaperClip2 après la refonte de `GameState`.

## Objectifs

- Avoir une source de vérité unique et stable pour l’état du jeu: le GameSnapshot.
- Simplifier les migrations de schéma et réduire les divergences de données.
- Encapsuler toute l’I/O de persistance hors de `GameState`.

## Principes

- Snapshot-first: `GameSnapshot` est la source de vérité. Il est produit par `GameState.toSnapshot()` et appliqué avec `GameState.applySnapshot()`.
- Orchestration hors `GameState`: `GamePersistenceOrchestrator` est l’unique point d’entrée pour save/load/backup.
- Legacy en lecture seule: lorsque aucun snapshot n’existe, un chargement legacy peut être migré une fois vers snapshot, puis snapshot devient la source unique.
- En cas de snapshot présent mais invalide: pas de fallback legacy. On tente une restauration depuis les backups.

## Flux

- Écriture (save manuelle)
  - `GameRuntimeCoordinator.manualSave(name)` → `GamePersistenceOrchestrator.requestManualSave` → `saveGame(state, name)` → écrit un payload contenant uniquement le snapshot.
- Écriture (autosave)
  - Domaine émet `importantEventOccurred` → `GameRuntimeCoordinator` déclenche `saveOnImportantEvent(state)` en fire-and-forget (métriques + watchdog).
- Lecture (load)
  - `GameRuntimeCoordinator.loadGameAndStartAutoSave(name)` → `GamePersistenceOrchestrator.loadGame`
    - Si snapshot présent: migration éventuelle + `state.applySnapshot(snapshot)` → `finishLoadGameAfterSnapshot`
    - Sinon: migration legacy → `state.applyLoadedGameDataWithoutSnapshot(...)` → écriture snapshot-only
  - Après load: le Coordinator applique l'Offline Progress (simulation bornée) puis best-effort autosave.
- Backups
  - Déclenchés via orchestrateur (cooldown), nommés `baseName__BACKUP__timestamp`.
  - Restauration utilisée si la sauvegarde principale est invalide.

## Invariants & Tests recommandés

- Roundtrip: `state -> toSnapshot -> applySnapshot -> state'` conserve l’équivalence métier (managers, stats, mode de jeu).
- Offline idempotent: `applyOfflineProgressV2` ne double-applique pas sur des intervalles déjà traités; les timestamps `_lastActiveAt/_lastOfflineAppliedAt/_offlineSpecVersion` sont persistés.
- Pas de fallback legacy si snapshot existe et est invalide; restauration depuis backup tentée, sinon erreur explicite.

## Responsabilités

- `GameState`
  - Sérialisation/désérialisation (snapshot).
  - Aucune I/O; aucun format de stockage ne doit être géré ici.
- `GameRuntimeCoordinator`
  - Orchestration save/autosave/load; application Offline Progress post-load et au resume.
  - Maintien des métadonnées runtime (`RuntimeMetaRegistry`) et propagation vers `GameState` avant persistance.
- `GamePersistenceOrchestrator`
  - Save/load/backup; migration de snapshot; contrôle des priorités de save et coalescing.
- `SaveManagerAdapter`
  - Backend de stockage.
- `GamePersistenceMapper`
  - Migration legacy → runtime, et finalisation post-snapshot (si nécessaire).

## Évolutions de schéma

- Ajouter les nouvelles clés sous `metadata/core/stats` avec valeurs par défaut robustes.
- Documenter l’impact dans cette page et ajouter un test de backward-compat lecture.

## Politique d’erreur

- Snapshot invalide: FormatException remontée et tentative de restauration depuis backups par l’orchestrateur.
- Les erreurs de save lors d’événements importants sont best-effort (journalisées).
