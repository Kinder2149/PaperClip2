# PHASE 2 — Politique de création & push cloud des mondes (contractuelle)

Ce document formalise, sans refonte ni nouvelles fonctionnalités, la politique actuelle telle qu’implémentée dans le client Flutter. Il élimine l’ambiguïté produit et sert de référence contractuelle.

Sources de référence (code existant, non exhaustif):
- `lib/services/game_runtime_coordinator.dart` — `startNewGameAndStartAutoSave`
- `lib/services/persistence/save_manager.dart` — `saveCloud`, `saveCloudById`
- `lib/services/persistence/game_persistence_orchestrator.dart` — `saveGame`, `_pump`, `pushCloudFromSaveId`, `materializeFromCloud`


## 1) Règle officielle de push post‑création

- Déclencheur: juste après la création d’un monde via `startNewGameAndStartAutoSave`, l’app lit la préférence `SharedPreferences['cloud_enabled']`.
- Condition: si `cloud_enabled == true`, l’app tente immédiatement un push cloud de la partie courante via `SaveManager.instance.saveCloud(state, reason: 'world_creation')`.
- Préconditions nécessaires:
  - **Identité de partie**: `state.partieId` doit être présent (création invalide sinon, exception bloquante). 
  - **Port cloud configuré** et **playerId disponible** pour attacher la partie côté cloud (si playerId manquant, le push ne s’exécute pas, voir états). 
- Cas où aucun push n’est garanti:
  - `cloud_enabled == false` (ou non défini).
  - `cloud_enabled == true` mais identité joueur indisponible au moment du push (l’opération sort proprement en “pending_identity”).
  - Échec d’appel réseau/serveur (l’opération est marquée en “pending_cloud_push” sans garantie de retry immédiat).


## 2) États post‑création (existants uniquement)

- local_only
  - Cause: `cloud_enabled == false` (ou non défini). Aucun push tenté.
  - Flags techniques existants: aucun flag spécifique. La partie existe localement sous son `partieId`.
  - Visibilité actuelle: visible localement (monde jouable). Pas d’indicateur cloud dédié identifié.
  - Caractère: acceptable et stable (peut rester local).

- cloud_ok
  - Cause: `cloud_enabled == true` + identité joueur disponible + push réussi.
  - Flags techniques existants: nettoyage de flags éventuels `pending_identity_<partieId>` et `pending_cloud_push_<partieId>`.
  - Visibilité actuelle: aucune UI spécifique; observable indirectement (ex: disponibilité via un pull ultérieur).
  - Caractère: acceptable et stable.

- pending_identity
  - Cause: `cloud_enabled == true` mais `playerId` absent au moment du push.
  - Flags techniques existants: `SharedPreferences['pending_identity_<partieId>'] = true`, `syncState = 'pending_identity'`.
  - Visibilité actuelle: non exposé à l’utilisateur final (état interne + préférences).
  - Caractère: transitoire (en attente d’identité). Aucun engagement de retry automatique.

- pending_cloud_push
  - Cause: push tenté mais échec réseau/serveur (exception lors de `pushById`).
  - Flags techniques existants: `SharedPreferences['pending_cloud_push_<partieId>'] = true`.
  - Visibilité actuelle: non exposé à l’utilisateur final; erreur avalée au point d’appel post‑création.
  - Caractère: transitoire. Aucun engagement de retry automatique.


## 3) Définition contractuelle de `cloud_enabled`

- Définition: préférence utilisateur (clé `cloud_enabled` dans `SharedPreferences`) utilisée exclusivement comme **garde‑fou** pour tenter un push cloud initial immédiatement après la création d’un monde.
- Ce que `cloud_enabled` n’est PAS:
  - Ce n’est pas un statut de synchronisation d’un monde.
  - Ce n’est pas une garantie de présence cloud.
  - Ce n’est pas un indicateur de connectivité, ni un commutateur de synchronisation continue.
- Divergences connues possibles:
  - `cloud_enabled == true` mais pas d’identité joueur → monde non poussé (etat `pending_identity`).
  - `cloud_enabled == false` alors que le monde existe déjà côté cloud (créé/poussé antérieurement) → la préférence ne reflète pas l’état réel du monde.


## 4) Visibilité minimale produit (sans nouvelle UI)

- Cas à informer (au minimum via canaux existants: logs, états internes, surfaces d’état):
  - `pending_identity`: au moment du push post‑création si `playerId` absent.
  - `pending_cloud_push`: en cas d’échec réseau/serveur lors du push post‑création.
- Minimum requis (non intrusif):
  - Loggage avec les codes déjà utilisés par le logger (exemples observés: `pump_start`, `save_error`) et/ou exposition de `syncState` (`'pending_identity'`, `'ready'`, `'syncing'`).
  - Conservation des flags `SharedPreferences` existants (`pending_identity_*`, `pending_cloud_push_*`) comme source de vérité technique.
  - Aucun nouvel élément d’UI n’est exigé par ce document.


## 5) Responsabilité de retry (existante uniquement)

- Mécanismes observés:
  - Un push peut être relancé via les points d’entrée existants:
    - `SaveManager.saveCloud(state, reason: ...)` pour la partie courante.
    - `SaveManager.saveCloudById(partieId: ...)` sans charger l’UI.
  - L’orchestrateur effectue un arbitrage après certaines sauvegardes locales (`saveGame` appelle un arbitrage de fraicheur/sync) mais sans garantie de timing.
- Qui déclenche et quand:
  - Le client (application) via ses flux existants (sauvegardes, actions explicites) peut décider d’appeler ces entrées.
  - Aucune promesse de synchronisation automatique n’est faite par ce document.


## 6) Checklist de clôture PHASE 2 (binaire)

- [ ] La règle de push post‑création est décrite (déclencheur, condition, préconditions, non‑garanties).
- [ ] Les 4 états post‑création existants sont formalisés (cause, flags techniques, visibilité, caractère).
- [ ] `cloud_enabled` est défini contractuellement, avec ses non‑sens et divergences connues.
- [ ] La visibilité minimale produit est énoncée (logs/états/flags) sans exiger de nouvelle UI.
- [ ] La responsabilité de retry est clarifiée, sans promettre de synchronisation automatique.
- [ ] Ce document est versionné dans le repo et référencé par l’équipe produit/tech.


---
Document fondé exclusivement sur le comportement existant du client Flutter (sans modification backend, sans refonte, sans ajout de fonctionnalités).
