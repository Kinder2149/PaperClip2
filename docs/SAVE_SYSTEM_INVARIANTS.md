# Système de Sauvegardes — Invariants, Schéma, Do/Don't (PaperClip2)

Ce document formalise la cible après refonte Local + Cloud. Il remplace les approches legacy et clarifie le rôle de chaque composant.

## 1) Schéma conceptuel

- Partie (entité centrale)
  - Identité: `partieId` (UUID v4, stable)
  - Nom: `name` (cosmétique, affichage uniquement)
  - Mode de jeu: `gameMode` (INFINITE | COMPETITIVE)
  - Snapshot: `gameSnapshot` (source de vérité unique)
- Local
  - Sauvegarde: snapshot-only écrit via `GamePersistenceOrchestrator.saveGame()`
  - Backups: entrées internes nommées `partieId#<timestamp>` avec rétention (N=10, TTL=30j)
  - Restauration: orchestrée automatiquement si snapshot invalide
- Cloud (support par partie)
  - Port: `CloudPersistencePort` (push/pull/status) indexé par `partieId`
  - HTTP/Local mock: implémentations injectables
  - Statuts: `in_sync | ahead_remote | unknown` (local mock), extensible
  - Métadonnées: incluent `playerId` si disponible (identité Google), pour traçabilité
- Google
  - Identité utilisateur (connexion, profil, playerId)
  - Aucune persistance; plus de slot cloud global GPG

## 2) Invariants (non négociables)

- ID-first: toute opération technique s’appuie sur `partieId` (chargement, backups, cloud)
- Snapshot-only: `gameSnapshot` est la seule source durable de l’état
- Cloud = support: jamais entité autonome; API strictement par `partieId`
- Traçabilité identité: si un `playerId` est disponible au moment du push, il DOIT être inclus dans les métadonnées cloud
- Pas de renommage implicite: `name` n’est pas harmonisé silencieusement à l’écriture
- Backups internes uniquement: non listés dans la vue principale des parties

## 3) Do / Don’t

- Do
  - Charger par `id` (`loadGameById`) et afficher via `name`
  - Extraire les stats UI depuis `gameSnapshot` (core/stats)
  - Utiliser `CloudPersistencePort` par `partieId` pour push/pull/status
  - Conserver Google pour l’identité (connexion/profil), pas pour la persistance
- Don’t
  - Réintroduire un slot cloud global (GPG) ou des boutons cloud sans `partieId`
  - Lire des managers runtime pour l’UI persistance (toujours snapshot)
  - Effectuer un renommage de sauvegarde sans action explicite utilisateur

## 4) Statuts Cloud (implémentation locale/mock)

- unknown: aucune donnée cloud connue pour `partieId`
- ahead_remote: `lastPushAt > lastPullAt` (le cloud semble plus récent que le dernier pull local)
- in_sync: `lastPullAt != null` et (`lastPushAt == null` ou `lastPullAt >= lastPushAt`)

Note: l’implémentation HTTP pourra enrichir (ex: `ahead_local`, `diverged`) selon la stratégie serveur.

## 5) Flux clés (résumé)

- Save (autosave/manual/lifecycle)
  - Orchestrateur -> `toSnapshot()` -> écrit `gameSnapshot` uniquement
  - Backups automatiques `partieId#timestamp` sur évènements lifecycle (cooldown)
- Load
  - `loadGameById` (ID-first) -> snapshot-first + migration + offline + réécriture snapshot-only
  - Restauration depuis backups si snapshot invalide
- Cloud par partie
  - Push: `pushCloudById(partieId, state)`
  - Pull: `pullCloudById(partieId)` puis application locale du snapshot
  - Status: `cloudStatusById(partieId)` pour l’UI (retourne aussi `playerId` si connu côté cloud)

## 6) Paramétrage

- Activer l’UI Cloud par partie: `FEATURE_CLOUD_PER_PARTIE=true` (dotenv)
- Le cloud global GPG est désactivé et ne doit pas être réactivé

## 7) Glossaire

- `partieId`: identifiant technique unique de la partie (UUID v4)
- `name`: libellé affiché à l’utilisateur, non technique
- `gameSnapshot`: payload persistant, sections `metadata/core/production/market/stats`
- backup: entrée locale interne `partieId#timestamp` utilisée pour restauration et rétention
