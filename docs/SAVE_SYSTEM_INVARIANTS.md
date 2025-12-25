# Système de Sauvegardes — Invariants, Schéma, Do/Don't (PaperClip2)

Document canonique — fait foi
Dernière mise à jour: 2025-12-25
Voir aussi: `identity/INVARIANTS_IDENTITE_PERSISTENCE.md` (identité canonique `player_uid`, règles cloud append-only) • `Glossaire.md`

Ce document est la source de vérité UNIQUE et FINALE du système de sauvegardes (local + cloud). Il remplace toutes les approches legacy et clarifie le rôle de chaque composant. 

Documents antérieurs (ex: dossiers `docs/cloud`, `docs/cloudsave`, notes de conception historiques) sont considérés comme ARCHIVÉS et NON-AUTORITATIFS. Toute contradiction doit être tranchée par le présent document.

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

### 2.a) Invariants Identité (playerId)

- `playerId` (Google Play Games) est une identité UTILISATEUR, distincte de `partieId`.
- Le client persiste un `lastKnownPlayerId` localement pour robustesse redémarrage; il est validé/invalidé par un `refresh()` silencieux.
- Aucune dépendance gameplay ↔ identité: le jeu ne bloque jamais si `playerId` est indisponible.
- Lors d’un push cloud, si un `playerId` est disponible et confirmé, il est inclus dans les métadonnées côté cloud (traçabilité).

### 2.b) Invariants Multi-parties

- Un utilisateur peut posséder plusieurs parties simultanément (cardinalité 1→N via `partieId`).
- `partieId` est un UUID v4, immuable, clé technique unique d’une partie.
- Aucune clé métier basée sur le nom: `name` est strictement cosmétique.
- Aucun « slot global » cloud: le cloud est par partie (indexé par `partieId`).

Note d'application (exécution): au moment de la création d'une partie, l'identité doit exister immédiatement.
Toute tentative de démarrer autosave/sync sans `partieId` est interdite par le runtime et provoque une erreur explicite
afin d'éviter toute progression sans identité. Cet invariant est vérifié juste après `startNewGame()`.

### 2.c) Règles Cloud vs Local (Cloud-first)

- Local = cache temporaire matérialisant des snapshots par `partieId`.
- La synchronisation est best-effort, non bloquante, et déterministe par ID.
- Post-connexion, `postLoginSync()` arbitre par union des IDs: 
  - local ∧ cloud → importer cloud (cloud gagne)
  - local seul → push de création cloud
  - cloud seul → matérialiser local
- Pas de création automatique de partie en dehors de l’action utilisateur « Nouvelle partie ».
- Les pushes/pulls cloud sont effectués par `CloudPersistencePort` (HTTP/mock), jamais via un slot global.

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

## 8) UX Synchronisation (visibilité minimale)

- Un indicateur discret d’état de sync est affiché dans l’UI (pas de modal, pas d’action requise).
- Mapping `syncState` → UI:
  - `ready` → icône cloud validée + libellé « À jour » (teinte verte)
  - `syncing` → indicateur de progression + libellé « Synchronisation… » (teinte bleue)
  - `error` → icône d’alerte + libellé « Erreur de sync » (teinte ambre)
- Aucune interruption de jeu. Les erreurs de sync sont non bloquantes et re-tentées par la pompe.

## 9) Ce que le système NE FAIT PAS

- Pas de slot cloud global (Google Play Games Snapshots) et pas de boutons cloud sans `partieId`.
- Pas de création automatique de partie en arrière-plan (uniquement via l’action « Nouvelle partie »).
- Pas de dépendance du gameplay aux états d’identité (le jeu fonctionne anonymement).
- Pas de renommage silencieux des parties.
- Pas de décision par `name` (jamais utilisé comme clé technique).

---

Système clôturé — cette documentation est figée et opposable. Toute évolution future devra partir de ce document et expliciter les invariants modifiés.
