# PaperClip2 — Save System: Conformité Finale (ID-first, Snapshot-first, Cloud passif)

Ce document consolide les invariants, APIs autorisées/dépréciées, politiques de backups, modèle cloud et la checklist de non-régression. Il sert de contrat d’architecture pour éviter toute régression future.

## 1) Invariants non négociables
- Identité
  - Toute partie est identifiée par un identifiant technique immuable `partieId` (UUID v4).
  - Le `gameName` est un label purement visuel. Aucune opération technique par nom.
- Persistance
  - Snapshot-first: la vérité métier persistée est le `GameSnapshot`.
  - ID-first: tous les flux (save, load, delete, sync cloud, backups) s’indexent par `partieId`.
  - Aucune duplication lors des sauvegardes standard: une sauvegarde met à jour la même partie (`id` constant).
- Backups
  - Un backup n’est pas une partie: il est un artefact technique de sécurité attaché à une partie.
  - Convention de nommage: `backupName = "<partieId>|<timestamp_ms>"` (préfixe ID-first).
  - Restauration: écrase la cible (même `partieId`), ne crée jamais une nouvelle partie.
- Cloud
  - Le cloud est un support passif, pas une entité. Pas de “partie cloud”.
  - Opérations cloud uniquement par `partieId`.

## 2) APIs autorisées (exemples représentatifs)
- Orchestrateur (autorité)
  - `saveGameById(GameState state)` — snapshot-only, ID-first
  - `loadGameById(GameState state, String id)` — ID-first
  - `deleteSaveById(String id)` — ID-first
  - `pushCloudById({ required String partieId, required GameState state })` — Cloud passif
  - `pullCloudById({ required String partieId })` — Cloud passif
  - `cloudStatusById({ required String partieId })` — Lecture état cloud par partie
- LocalGamePersistenceService
  - `saveSnapshotById(GameSnapshot snapshot, { required String partieId })`
  - `loadSnapshotById({ required String partieId })`
- SaveManagerAdapter (compat couchée derrière Orchestrator)
  - `listSaves()` — méta enrichies, `isBackup` pour filtrer
  - `deleteSaveById(String id)` — suppression stricte par ID
  - `loadGameById(String id)` — chargement par ID
  - `applyBackupRetention({ required String partieId, int? max, Duration? ttl })`

## 3) APIs dépréciées (ne pas utiliser)
- Toute API “par nom” (exemples) — dépréciées via `@Deprecated`
  - `deleteSave(String name)` / `deleteSaveByName(String name)`
  - `loadGame(String name)` / `manualSave(String name)` / `loadGameAndStartAutoSave(String name)`
  - Toute variante `saveExists(String name)`

## 4) Backups — Politique et comportements
- Création
  - Interdite sans `partieId`. Nommage: `partieId|timestamp`.
- Restauration
  - Résolution `backupName -> backupId` puis overwrite de la cible (ID existant).
  - Refus si la cible n’existe pas ou `partieId` absent.
- Rétention
  - TTL: 30 jours (`BACKUP_RETENTION_TTL`)
  - Quota: 10 derniers par partie (`BACKUP_RETENTION_MAX`)
  - Nettoyage complémentaire legacy (MAX_BACKUPS=3) conservé pour compat locale mais non bloquant.
- Visibilité UI
  - Jamais listés dans la liste principale des parties (`isBackup` filtré).
  - Affichage optionnel dans un écran dédié (historique backups), groupés par `partieId`.

## 5) Cloud — Modèle passif par partie
- Ports et flux
  - `CloudPersistencePort`: `pushById`, `pullById`, `statusById` (tous par `partieId`).
  - Orchestrateur: `pushCloudById`, `pullCloudById`, `cloudStatusById`.
  - Pas d’API pour lister/créer des “parties cloud”.
- UI
  - Pas de “slot global” GPG: désactivé (`enableGpg=false`).
  - L’état cloud (badge) est interrogeable par partie (feature flag), sans effet sur le core.

## 6) Vérifications anti-régression (checklist)
- ID-first
  - [ ] Toute suppression passe par `deleteSaveById`
  - [ ] Tout chargement de partie par ID (`loadGameById` en UI runtime)
  - [ ] Toute écriture snapshot standard nécessite `state.partieId` non vide
- Snapshot-first
  - [ ] Les writes passent par snapshot-only (clé `gameSnapshot`)
  - [ ] La migration snapshot est appliquée à la lecture si nécessaire
- Backups
  - [ ] Nommage strict `partieId|timestamp`
  - [ ] Restauration n’entraîne aucune création de partie
  - [ ] TTL=30j et N=10 appliqués par `applyBackupRetention`
  - [ ] Jamais listés comme parties
- Cloud
  - [ ] Opérations par `partieId` exclusivement
  - [ ] Aucune dépendance du gameplay sur le cloud
  - [ ] Aucune entité “partie cloud” listée ou chargée

## 7) Notes d’implémentation (Phase 2–5)
- AutoSaveService
  - Nettoyage par ID (`GamePersistenceOrchestrator.deleteSaveById`) pour backups et vieux saves
  - Backups nommés avec `partieId|timestamp` (plus `gameName|...`)
- SaveManagerAdapter
  - Rétention par ID: TTL + quota; nettoyage legacy converti en suppression par ID
  - Restauration depuis backup: overwrite strict de la cible par ID
- GamePersistenceOrchestrator
  - Files d’attente (autosave, events, lifecycle) envoient des requêtes ID-first
  - Cloud par `partieId` (port configurable), aucune création locale
- UI
  - SaveLoadScreen: actions techniques par ID, backups filtrés
  - BackupsHistoryScreen: suppression par ID, restauration sûre

---
Ce document est la référence officielle. Tout nouveau code lié aux sauvegardes doit s’y conformer. Toute API ou flux contredisant ces invariants doit être refusé en revue.
