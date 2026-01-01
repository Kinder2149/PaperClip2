# Contrat API — Identité Joueur Canonique (JWT sub = player_uid)

Ce document formalise le contrat d’identité côté backend pour PaperClip2.
Objectif: dissocier l’identité métier des providers externes et stabiliser un identifiant souverain `player_uid` (UUID v4).

## Invariants
- `player_uid` est un UUID v4 généré côté backend et constitue l’identité métier souveraine.
- Le JWT émis par `/api/auth/login` a `sub = player_uid`.
- Les informations provider (ex: Google) sont conservées comme métadonnées indépendantes.
- Compat héritée: l’endpoint accepte encore `playerId` (Google id historique) et peut inclure `legacy_playerId` dans le JWT.
- Aucun flux UI n’est requis pour cette couche.

## Endpoint d’authentification
- Route: `POST /api/auth/login`
- Body (nouveau schéma recommandé):
  ```json
  { "provider": "google", "provider_user_id": "<idGoogle>" }
  ```
- Body (compat héritée):
  ```json
  { "playerId": "<idGoogle>" }
  ```
- Comportement:
  1. Normalisation des entrées. Si `playerId` est fourni, il est traité comme `(provider="google", provider_user_id=playerId)`.
  2. Résolution/Création de l’identité via `(provider, provider_user_id)` → `player_uid` (UUID v4).
  3. Émission du JWT avec:
     - `sub`: `player_uid`
     - `providers`: liste des liens connus `{ provider, id }`
     - `iat`, `exp`: standard JWT (TTL via `JWT_TTL_SECONDS`)
     - `legacy_playerId`: uniquement si le champ héritage a été fourni

## Schéma JWT (réponse `/api/auth/login`)
- En-tête HTTP: `Authorization: Bearer <jwt>` pour les appels protégés
- Claims:
  - `sub` (string): `player_uid` (UUID v4 souverain)
  - `providers` (array): `[{ "provider": "google", "id": "<provider_user_id>" }, ...]`
  - `iat` (number): epoch secondes
  - `exp` (number): epoch secondes
  - `legacy_playerId` (string, optionnel): valeur héritée si fournie au login

## Vérification JWT (serveur)
- Décodage standard HS256 avec `SECRET_KEY`.
- Cas nominal: si `sub` est un UUID v4 → accepté tel quel.
- Compat héritée: si l’ancien token encode `sub` ou `playerId` comme id Google non-UUID:
  - le backend résout dynamiquement un `player_uid` via `(provider="google", provider_user_id=<valeur>)`.
  - la vérification expose un champ "normalisé" `claims.player_uid` utilisable par les routes.

## Store d’identité (développement)
- Implémentation simple par fichier JSON listant les liens:
  ```json
  { "links": [ {"provider": "google", "provider_user_id": "g123", "player_uid": "<uuid>", "created_at": "<iso>"} ] }
  ```
- En production, migrer vers une table SQL avec contrainte d’unicité `(provider, provider_user_id)`.

## Compatibilité et migration
- Aucune suppression brutale: les anciens clients peuvent encore envoyer `playerId`.
- Les anciens JWT (non-UUID `sub`) sont acceptés via résolution dynamique.
- Plan de dépréciation: annoncer et retirer `legacy_playerId` quand l’écosystème client sera entièrement migré.

## Sécurité
- `SECRET_KEY` doit être géré par variables d’environnement.
- TTL configurable via `JWT_TTL_SECONDS`.
- La taille du JWT peut croître si plusieurs providers sont liés; surveiller les limites si besoin.

## Exemples
- Requête:
  ```http
  POST /api/auth/login
  Content-Type: application/json
  
  { "provider": "google", "provider_user_id": "g123" }
  ```
- Réponse (exemple):
  ```json
  {
    "access_token": "<jwt>",
    "token_type": "bearer",
    "expires_at": "2025-01-01T12:00:00+00:00"
  }
  ```
- Claim décodé (exemple):
  ```json
  {
    "sub": "c8f6d2e1-8b31-4b76-b28b-3d6afc18b8a7",
    "providers": [ { "provider": "google", "id": "g123" } ],
    "iat": 1735120000,
    "exp": 1735123600
  }
  ```
