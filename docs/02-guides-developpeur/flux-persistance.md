# Flux de persistance — Client Flutter

## Invariants
- ID-first: une partie = un `partieId` (UUID v4 recommandé)
- Snapshot-first: source de vérité locale = `gameSnapshot`

## Composants
- Orchestrateur: `GamePersistenceOrchestrator`
- Local: `LocalSaveGameManager` (SharedPreferences)
- Cloud: `CloudPersistencePort`

## Sauvegarde locale
1) `saveGameById(state)` ou `requestManualSave(state)`
2) Snapshot normalisé (`_normalizeSnapshotContract`) puis écrit sous `gameSnapshot`
3) Sauvegarde via `LocalSaveGameManager.saveGame`

## Chargement par ID
1) `loadGameById(state, id)`
2) Si `gameSnapshot` présent → `applySnapshot` + sauvegarde post-lecture
3) Sinon, migration legacy (`gameData` → snapshot) et sauvegarde
4) Optionnel: `checkCloudAndPullIfNeeded` pour arbitre cloud

## Backups
- Nom: `<partieId>|<timestamp>`
- Restauration: `restoreFromBackup(state, backupName)`
  - Résolution nom→id → migration de sûreté → écriture locale sous `partieId`

## Post-login sync
1) `postLoginSync(playerId)`
2) Inventaire local (hors backups) ∪ cloud
3) Arbitrage fraîcheur par ID:
   - cloud > local → import cloud → matérialise local
   - local > cloud → push (si triggers/conditions réunies)
   - égal → no-op

## Matérialisation cloud-only
- `materializeFromCloud(partieId)`
- Tire l’objet cloud et écrit un snapshot local sous l’ID

## Retry des pushes
- Flags `pending_cloud_push_*` / `pending_identity_*`
- `retryPendingCloudPushes()` envoie les pushes en attente si `playerId` dispo

## États & diagnostic
- Voir `docs/runbook_persistence_sync.md`
