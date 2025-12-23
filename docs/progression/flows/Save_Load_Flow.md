# Flux Save / Load (PaperClip2)

Ce document détaille les séquences opérationnelles pour la persistance locale et le cloud par partie.

## 1) Sauvegarde (autosave, manual, lifecycle)

- Orchestrateur: `GamePersistenceOrchestrator`
- Entrées: `requestAutoSave`, `requestManualSave`, `requestLifecycleSave`, `saveOnImportantEvent`
- Étapes:
  1. `GameState.toSnapshot()` (migration éventuelle intégrée au service local)
  2. Écriture snapshot-only via `LocalGamePersistenceService.saveSnapshotById(partieId)`
  3. Backups automatiques nommés `partieId|timestamp` (cooldown pour lifecycle)
  4. Rétention centralisée `SaveManagerAdapter.applyBackupRetention(partieId)` (N=10, TTL=30j)

Notes:
- Aucune écriture de champs hors snapshot.
- Les métadonnées (version, mode) sont alignées lors de l’enrichissement UI via les métas stockés.

## 2) Chargement (ID-first)

- API: `loadGameById(partieId)` via orchestrateur → `LocalGamePersistenceService.loadSnapshotById`
- Étapes:
  1. Lecture snapshot (clé `gameSnapshot`)
  2. Migration snapshot si nécessaire
  3. Application au `GameState`
  4. Écriture snapshot-only pour normalisation
- Fallback restauration:
  - Si snapshot invalide: recherche de backups par `partieId`; sinon fallback compat par `baseName|timestamp`.
  - Restauration dans la sauvegarde cible puis rechargement.

## 3) Cloud par partie

- Port: `CloudPersistencePort` (pushById, pullById, statusById)
- Push:
  - Extraction du snapshot local (par `partieId`)
  - Métadonnées minimales (`partieId`, `gameMode`, `gameVersion`, `savedAt`, `name`)
  - `pushCloudFromSaveId(partieId)` pour push sans UI
- Pull:
  - `pullCloudById(partieId)` → snapshot+metadata
  - Écriture locale immédiate (overwrite strict ID-first)
- Statut:
  - `statusById(partieId)` expose un état simplifié (mock: `unknown | in_sync | ahead_remote`)

## 4) UI SaveLoadScreen

- Liste principale sans backups.
- Filtre “Sauvegardes locales uniquement”: masque les entrées avec `remoteVersion != null`.
- Badges cloud: affichage selon `cloudSyncState` + info-bulle d’aide.
- Actions par entrée: Push/Pull cloud, Restore dernier backup, Supprimer, Charger.

## 5) Feature flag

- `.env`: `FEATURE_CLOUD_PER_PARTIE=true` pour afficher filtres/boutons cloud par partie.

## 6) Sécurité & intégrité

- `runIntegrityChecks()` (debug-only):
  - Doublons de nom → IDs distincts.
  - Snapshot présent et lisible.
  - Désalignement meta/save (name, version, mode).
  - Backups conformes (format, orphelins, rétention).
