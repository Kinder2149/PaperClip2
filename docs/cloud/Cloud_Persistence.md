# Persistance Cloud par Partie (PaperClip2)

Ce document précise l’architecture et l’usage de la persistance cloud par `partieId`.

## 1) Port d’abstraction

Interface: `CloudPersistencePort`
- `pushById({ required String partieId, required Map<String, dynamic> snapshot, required Map<String, dynamic> metadata })`
- `pullById({ required String partieId }) -> Map<String,dynamic>?`
- `statusById({ required String partieId }) -> CloudStatus`

Contrats:
- Indexation stricte par `partieId` (ID-first).
- `metadata` est informative (name, mode, version, timestamps), le snapshot reste source de vérité.

## 2) Orchestrateur — appels

- `pushCloudFromSaveId(partieId)`
  - Lit la sauvegarde locale par ID.
  - Extrait `gameSnapshot`.
  - Construit les métadonnées minimales.
  - Appelle `CloudPersistencePort.pushById`.
- `pullCloudById(partieId)`
  - Récupère `snapshot`+`metadata`.
  - L’UI applique localement (overwrite strict) via `SaveManagerAdapter.saveGame`.

## 3) Statuts Cloud & UI

- Mock local/HTTP: `unknown | in_sync | ahead_remote`.
- Agrégation côté client: `SaveAggregator` enrichit les entrées (remoteVersion, cloudSyncState).
- UI:
  - Badge dynamique selon `cloudSyncState`.
  - Filtre “local only”: masque les entrées avec `remoteVersion != null`.

## 4) Auto-push à la création

- `GameRuntimeCoordinator.startNewGameAndStartAutoSave(...)`:
  - Si `FEATURE_CLOUD_PER_PARTIE=true` et `partieId` connu, sauvegarde locale initiale puis `pushCloudFromSaveId` (best-effort, non bloquant).

## 5) Paramétrage & Flags

- `.env` → `FEATURE_CLOUD_PER_PARTIE=true`.

## 6) Sécurité

- Pas de secrets dans le client.
- Ne jamais hardcoder de clés API.
- Les erreurs cloud ne bloquent pas le jeu (best-effort, notifications UI).
