# Cloud Security & Ownership — Règles minimales

Objectif: garantir que seul le propriétaire réel d’une partie cloud peut la modifier, sans introduire de logique de conflit ni de versioning.

## Invariants
- L’identité souveraine est `player_uid` (UUID v4), portée par le JWT (`sub`).
- Chaque fichier de partie cloud peut contenir un champ `owner_uid`.
- Les métadonnées doivent inclure: `name`, `gameMode`, `gameVersion`, `playerId` (héritage provider).
- Taille maximale du snapshot: `MAX_SNAPSHOT_BYTES` (par défaut 256 KiB).
- Optionnel: `GAME_MODE_ENUM` permet de restreindre `gameMode` à une liste fermée.

## Avant / Après

- Auth sur routes cloud
  - Avant: JWT accepté mais non exploité; fallback `API_KEY`.
  - Après: JWT décodé et renvoyé aux handlers (claims). Fallback `API_KEY` conservé en mode DEV/tests.

- Association partie → propriétaire
  - Avant: aucune (seulement `metadata.playerId`).
  - Après: champ `owner_uid` écrit à la création si JWT présent. Contrôle strict ensuite.

- Écriture (PUT /api/cloud/parties/{partie_id})
  - Avant: autorisée si token/API_KEY ok.
  - Après: si JWT →
    - Création: `owner_uid = sub`.
    - Mise à jour: 403 si `owner_uid` ≠ `sub`.
    - Legacy (sans owner): revendication auto possible seulement si `playerId` → `sub` via identité ou via `claims.providers`.

- Listing (GET /api/cloud/parties?playerId=...)
  - Avant: filtrage par `metadata.playerId` uniquement.
  - Après: si JWT → filtrage additionnel par `owner_uid == sub`. Legacy: si pas d’owner, autorisé seulement si `playerId` mappe vers `sub`.

- Suppression (DELETE /api/cloud/parties/{partie_id})
  - Avant: suppression si token/API_KEY ok.
  - Après: si JWT et `owner_uid` présent → 403 si requester ≠ owner.

## Cas refusés (erreurs)
- 401 Missing/Invalid Authorization, 401 Token expired
- 403 Forbidden: not the owner of this partie
- 413 Snapshot too large (dépasse `MAX_SNAPSHOT_BYTES`)
- 422 Missing or empty metadata fields: `name`, `gameMode`, `gameVersion`, `playerId`
- 422 Invalid gameMode (si `GAME_MODE_ENUM` activée)
- 422 Metadata fields too long (name>100, gameMode>50, gameVersion>20)

## Notes de compatibilité
- Le mode `API_KEY` (DEV/tests) ne fournit pas de claims JWT: dans ce cas, les contrôles d’ownership ne s’appliquent pas.
- Les fichiers legacy sans `owner_uid` peuvent être revendiqués par un utilisateur si et seulement si la résolution `(provider=google, provider_user_id=playerId)` retourne le même `player_uid` que le `sub`, ou si `claims.providers` contient `{provider: google, id: playerId}`.

## Paramètres d’environnement
- `MAX_SNAPSHOT_BYTES` (int): taille max du snapshot (défaut 262144).
- `GAME_MODE_ENUM` (CSV): liste d’enums autorisées pour `gameMode`.

## Tests négatifs (extraits)
- Écriture non propriétaire: PUT par un autre `sub` → 403.
- Suppression non propriétaire: DELETE par un autre `sub` → 403.
- Listing restreint: un utilisateur ne voit pas les parties dont il n’est pas owner.
- Revendication legacy refusée: fichier sans owner et `playerId` mappant vers un autre `sub` → 403.
- Snapshot trop volumineux → 413.
- `gameMode` hors enum (si activée) → 422.
