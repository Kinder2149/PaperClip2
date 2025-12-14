# PaperClip2 - Dossier Services

## Objectif

Le dossier `services` contient les services qui interagissent avec des systèmes externes ou fournissent des fonctionnalités transversales à l'application. Ces services sont généralement des singletons qui peuvent être accédés depuis différents points de l'application.

## Composants Principaux

- **auto_save_service.dart** : Service responsable de la sauvegarde automatique périodique de l'état du jeu (timer) et du déclenchement des sauvegardes.
- **persistence/game_persistence_orchestrator.dart** : Orchestrateur de persistance (save/load/backup + snapshot). Centralise la logique hors de `GameState`.
- **save_system/save_manager_adapter.dart** : Façade/adapter utilisée par le code legacy pour accéder au nouveau système de sauvegarde.
- **save_system/local_save_game_manager.dart** : Stockage local (SharedPreferences), métadonnées, opérations primitives (save/load/list/delete).
- **save_migration_service.dart** : Migration des sauvegardes legacy vers le format actuel (inclut une stratégie lazy/progressive).
- **ui/game_ui_port.dart** + **ui/flutter_game_ui_facade.dart** : Port UI (interface) + implémentation Flutter (notifications, navigation, etc.).
- **audio/game_audio_port.dart** + **audio/flutter_game_audio_facade.dart** : Port audio (interface) + implémentation Flutter.
- **lifecycle/app_lifecycle_handler.dart** : Branche le cycle de vie Flutter et déclenche des sauvegardes/backup via l’orchestrateur.
- **notification_manager.dart** + **notification_storage_service.dart** : Notifications in-app et persistance associée.
- **navigation_service.dart** : Service de navigation (wrapper autour du `Navigator`).
- **theme_service.dart** : Gestion du thème clair/sombre.
- **progression/progression_rules_service.dart** : Règles de progression (service transverse).
- **upgrades/upgrade_effects_calculator.dart** : Calcul des effets d’améliorations.

## Persistance & auto-save (doctrine)

### Principes

- **Auto-save périodique (Timer)** : exclusivement géré par `AutoSaveService`.
- **Orchestration de persistance** (save/load/snapshot) : centralisée dans `GamePersistenceOrchestrator`.
- **SaveSystem** (`LocalSaveGameManager`) : responsable uniquement du stockage local (IO) et des opérations primitives (save/load/list/delete). Il ne doit pas porter de logique d'auto-save périodique.

### Schéma (flux)

`UI / GameState` → `GamePersistenceOrchestrator` → `SaveManagerAdapter` → `LocalSaveGameManager` (+ snapshots via `GamePersistenceService`)

## Ports (UI / Audio)

Objectif : découpler la logique métier (`GameState`, managers) de Flutter.

- **UI**
  - **Port** : `ui/game_ui_port.dart`
  - **Impl Flutter** : `ui/flutter_game_ui_facade.dart`
- **Audio**
  - **Port** : `audio/game_audio_port.dart`
  - **Impl Flutter** : `audio/flutter_game_audio_facade.dart`

`main.dart` branche les implémentations Flutter sur `GameState` au boot.

## Événements & notifications (EventManager)

### Point d'entrée canonique

- **Canonique** : `models/event_system.dart` (classe `EventManager`, `NotificationEvent`, `GameEvent`).
- **Ré-exports** :
  - `managers/event_manager.dart` ré-exporte le canonique.
  - `services/event_manager.dart` est gelé et ré-exporte également le canonique afin d'éviter toute double implémentation.
 - **notification_storage_service.dart** : Persistance des messages/notifications in-app.
 - **notification_manager.dart** : Affichage des notifications (UI).

## Migration des sauvegardes (legacy)

La migration des anciennes sauvegardes (clés legacy en `SharedPreferences`) est gérée par `save_migration_service.dart`.

- Stratégie recommandée : **migration lazy/progressive** déclenchée lors de l’accès à l’écran des sauvegardes.
- Objectif : éviter de bloquer le boot.
- La migration crée des backups pré-migration **idempotents** (une seule copie stable) et purge les backups legacy timestampés.
