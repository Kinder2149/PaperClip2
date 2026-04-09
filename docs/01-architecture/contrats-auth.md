# Contrats Auth & Ownership

Ce document formalise les règles d’authentification et d’ownership applicables à PaperClip2.

## Auth — Source de vérité
- Firebase Auth est l’unique source d’authentification.
- Le backend accepte uniquement un Firebase ID Token via `Authorization: Bearer <idToken>` et vérifie le token (Admin SDK) pour obtenir le `uid`.

## Ownership des mondes
- L’ownership d’un monde est déterminée exclusivement par le backend à partir du `uid` extrait du token.
- Stockage: `players/{uid}/saves/{worldId}`.
- Interdictions côté client:
  - Ne jamais déduire/forcer l’ownership depuis des données locales.
  - Ne jamais utiliser `playerId` ou `worldId` comme critère de sécurité.

## Rôles des identifiants
- `uid Firebase`: identité racine (serveur-side).
- `worldId` (UUID v4): identifiant de ressource, identique dans l’URL et `snapshot.metadata.worldId`.
- `playerId`: contexte UX côté client (pré‑requis opérationnel pour déclencher le cloud), non sécuritaire.
- `saveId local`: strictement local.

## API canonique
- Côté client: `/worlds` pour créer/lire/lister/supprimer un monde.
- `/saves`: API technique backend (versions/restauration), non appelée par le client en usage fonctionnel.
