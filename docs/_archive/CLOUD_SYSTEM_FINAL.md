# Système Local + Cloud + Google — Document final (gel)

## Fonctionnement global
- Local: exécution et sauvegarde snapshot-only, clé d'identité = `partieId`.
- Cloud: stockage asynchrone non bloquant, source de vérité lors des conflits.
- Google: identification du joueur uniquement (`playerId`).
- Synchronisation: arrière-plan, déterministe, tolérante aux indisponibilités (retry différé).

## Rôle des composants
- Local: cache persistant, backups, aucun blocage gameplay.
- Cloud: sauvegarde distante par `partieId` (métadonnées: `playerId`, `name`, `gameMode`, `gameVersion`, `savedAt`).
- Google: fournit `playerId`; déclenche la sync post-connexion.
- Orchestrateur: file de sauvegardes, pompe asynchrone, `syncState` ('ready'|'syncing'|'error'), `onPlayerConnected` → sync + retry, flags `pending_cloud_push_<id>`.

## Cycle de vie d’une partie
1. Création: génération `partieId` unique, snapshot local.
2. Sauvegarde locale: autosave/lifecycle/important/backup (ID-first, backups: `partieId|timestamp`).
3. Connexion joueur: injection `playerId`, `onPlayerConnected(playerId)`.
4. Synchronisation cloud (union ID-first):
   - local ∧ cloud → matérialiser du cloud (cloud gagne).
   - local seul → push (requiert `playerId`, sinon pending).
   - cloud seul → matérialiser localement.
5. Reprise autre appareil: connexion Google → postLoginSync → matérialisation cloud.

## Invariants garantis
- Gameplay jamais bloqué par le cloud.
- Conflit: cloud écrase local.
- `partieId` = unique et stable; aucun couplage par nom.
- Push cloud interdit sans `playerId` (rejet propre); sauvegarde locale intacte.

## Points d’attention assumés
- Unicité du `partieId` = fondation anti-doublons.
- Backend Render (gratuit) potentiellement lent/HS: géré par retry, sans impacter le gameplay.
- Cas non couverts volontairement: tests UI d’état `syncState`, scénarios massifs d’anti-doublons.

## Décisions figées
- Cloud = source de vérité; Local = cache.
- ID-first par `partieId` (nom non clé).
- Sync automatique sans choix utilisateur.
- Opérations cloud non bloquantes + retry.
- Push cloud strictement lié à `playerId`.

## État final (gel)
- Fonctionnalité figée. Les évolutions suivantes nécessitent une nouvelle version/refonte:
  - Fusion/merge de parties.
  - Changement de source de vérité.
  - Changement d’identité (abandon `partieId` ID-first).
  - UI de gestion avancée des états de sync.
  - Évolution majeure du modèle cloud.

## Validation
- Suites de tests ciblées OK (syncState, playerId requis, post-connexion, anti-doublons). 
- Suites Google OK.
- Un test d’intégrité local (legacy) hors périmètre cloud signale un cas non bloquant.
