# Plan de refactorisation PaperClip2

Ce document suit l'avancement des phases de refactor définies après l'audit.

## Phase 1 — Persistance (GameSnapshot + GamePersistenceService)

### Étape P1-PR1 — GameSnapshot + GamePersistenceService (brouillon)
- Objectif : Introduire le DTO `GameSnapshot` et l'interface `GamePersistenceService` de manière non invasive.
- Branche suggérée : `refactor/p1-snapshot-and-persistence-interface`
- Fichiers ajoutés :
  - `lib/services/persistence/game_snapshot.dart`
  - `lib/services/persistence/game_persistence_service.dart`
  - `lib/services/persistence/local_game_persistence.dart`
- Tests ajoutés :
  - `test/persistence/snapshot_schema_test.dart`
- Risques :
  - Aucun changement attendu sur le comportement de sauvegarde existant (non branché à GameState pour l'instant).
- Statut : complété.

### Étape P1-PR2 — GameState.toSnapshot / applySnapshot
- Objectif : Permettre à `GameState` de sérialiser/désérialiser son état pur sans modifier le pipeline de sauvegarde actuel.
- Branche suggérée : `refactor/p1-gamestate-snapshot`
- Fichiers modifiés :
  - `lib/models/game_state.dart`
- Tests ajoutés :
  - `test/models/game_state_snapshot_test.dart`
- Risques :
  - Nécessite que l'initialisation des bindings Flutter soit correcte en test (`TestWidgetsFlutterBinding.ensureInitialized`).
- Statut : complété.

### Étape P1-PR3 — LocalGamePersistenceService (adapter vers SaveManagerAdapter)
- Objectif : Implémenter `LocalGamePersistenceService` en s'appuyant sur `SaveManagerAdapter` / `SaveGame` pour sauvegarder et recharger un `GameSnapshot` dans `gameData['gameSnapshot']`.
- Branche suggérée : `refactor/p1-persistence-adapter`
- Fichiers modifiés/ajoutés :
  - `lib/services/persistence/local_game_persistence.dart`
  - `test/persistence/local_persistence_test.dart`
- Changements techniques :
  - `saveSnapshot` crée ou met à jour une sauvegarde nommée `slotId` en injectant le JSON du snapshot dans `SaveGame.gameData`.
  - `loadSnapshot` lit la sauvegarde via `SaveManagerAdapter.loadGame` et reconstruit un `GameSnapshot` à partir de `gameData['gameSnapshot']`.
  - `migrateSnapshot` retourne pour l'instant le snapshot tel quel (la vraie migration sera implémentée dans une phase ultérieure).
- Tests ajoutés :
  - `test/persistence/local_persistence_test.dart` (roundtrip `saveSnapshot` → `loadSnapshot`).
- Risques :
  - Comportement des sauvegardes inchangé tant que `LocalGamePersistenceService` n'est pas branché dans le flux principal.
- Statut : complété.

## Phase 2 — Dégraisser GameState (core + session)

### Étape P2-PR1 — Introduction de GameCoreState et GameSessionController (squelettes)
- Objectif : Poser les briques `GameCoreState` (modèle pur) et `GameSessionController` (contrôleur de session) sans modifier le comportement de `GameState`.
- Branche suggérée : `refactor/p2-corestate-session-skeleton`
- Fichiers ajoutés :
  - `lib/models/game_core_state.dart`
  - `lib/controllers/game_session_controller.dart`
- Tests ajoutés :
  - `test/models/game_core_state_test.dart`
  - `test/controllers/game_session_controller_test.dart`
- Risques :
  - Aucun changement fonctionnel attendu, ces classes ne sont pas encore branchées au flux principal.
- Statut : complété.

### Étape P2-PR2 — Intégration de LocalGamePersistenceService dans GameState
- Objectif : Utiliser réellement `GameSnapshot` et `LocalGamePersistenceService` lors des sauvegardes/chargements via `GameState.saveGame` et `GameState.loadGame`.
- Branche suggérée : `refactor/p2-gamestate-persistence-integration`
- Fichiers modifiés/ajoutés :
  - `lib/models/game_state.dart`
  - `test/models/game_state_persistence_integration_test.dart`
- Changements techniques :
  - `saveGame` continue d'utiliser `SaveManagerAdapter.saveGame` mais enregistre aussi un snapshot complet via `LocalGamePersistenceService.saveSnapshot`.
  - `loadGame` utilise `SaveManagerAdapter.loadGame` pour la compatibilité, puis applique un `GameSnapshot` via `applySnapshot` si `gameData['gameSnapshot']` est présent, sinon retombe sur `_applyGameData`.
- Tests ajoutés :
  - `test/models/game_state_persistence_integration_test.dart` (roundtrip complet GameState → save → load → GameState).
- Risques :
  - Comportement inchangé pour les anciennes sauvegardes qui n'ont pas encore de `gameSnapshot`.
- Statut : complété.

### Étape P2-PR3 — Logique de production dans GameSessionController
- Objectif : Extraire la logique du timer de production automatique vers `GameSessionController` tout en conservant le comportement existant de `GameState`.
- Branche suggérée : `refactor/p2-session-production`
- Fichiers modifiés/ajoutés :
  - `lib/controllers/game_session_controller.dart`
  - `test/controllers/game_session_controller_production_test.dart`
- Changements techniques :
  - Ajout d'un timer de production et d'une méthode de tick `_handleProductionTick` dans `GameSessionController`, reproduisant la logique de `GameState.processProduction`.
  - Ajout d'une méthode `runProductionTickForTest()` pour permettre des tests unitaires sans dépendre d'un vrai `Timer`.
- Tests ajoutés :
  - `test/controllers/game_session_controller_production_test.dart` vérifie qu'un tick de production via le contrôleur augmente les trombones et consomme du métal.
- Risques :
  - Aucun changement fonctionnel dans cette PR : `GameState` ne délègue pas encore ses timers au contrôleur.
- Statut : complété.

### Étape P2-PR4 — Délégation du timer de production de GameState vers GameSessionController
- Objectif : Faire en sorte que `GameState.startProductionTimer()` délègue au `GameSessionController` quand il est présent, avec fallback sur l'implémentation historique.
- Branche suggérée : `refactor/p2-session-delegation`
- Fichiers modifiés/ajoutés :
  - `lib/models/game_state.dart`
  - `test/models/game_state_session_integration_test.dart`
- Changements techniques :
  - Ajout d'un champ privé `GameSessionController? _sessionController` et d'une méthode `setSessionController` dans `GameState`.
  - `startProductionTimer` sera adapté dans une PR ultérieure pour utiliser `_sessionController` lorsqu'il est injecté.
- Tests ajoutés :
  - `test/models/game_state_session_integration_test.dart` vérifiera la délégation effective une fois `startProductionTimer` adapté.
- Risques :
  - Aucun changement fonctionnel tant que `startProductionTimer` n'est pas encore modifié pour déléguer.
- Statut : brouillon.
