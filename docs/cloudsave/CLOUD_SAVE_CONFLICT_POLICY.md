# CLOUD SAVE — Politique de Conflit (Paperclip)

Objectif: rendre contractuel le traitement des conflits entre l'état local et une révision cloud, sans merge serveur, avec décision côté client.

## Principes

- Core local maître.
- Append-only côté serveur (aucun UPDATE en place).
- Backend invisible (zéro jargon technique en UI).
- RLS obligatoire (isolation par utilisateur Supabase).
- Décision toujours côté client; aucune fusion serveur.

## Pré-requis contractuels

- `snapshot.meta.timestamps.lastSavedAt` est OBLIGATOIRE pour toute révision candidate à l'upload.
- Le format est ISO-8601 compatible `DateTime.parse`.

## Règles de recommandation (client)

- Comparer `lastSavedAt(local)` vs `lastSavedAt(cloud)` (fallback cloud: `meta.uploadedAt` si `lastSavedAt` absent en cloud).
- Si `local > cloud`: `keepLocalCreateNewRevision` (conserve le local et publie une nouvelle révision).
- Si `cloud > local`: `importCloudReplaceLocal` (importer la révision cloud, remplace l'état local après consentement explicite).
- Sinon: `undecided` (demander à l'utilisateur).

## UX minimale (proposée)

- Écran de comparaison succinct:
  - "Local: sauvegardé le …" vs "Cloud: publié le …".
  - Boutons: "Conserver local (et publier)" / "Importer cloud" / "Annuler".
- Jamais d'automatisme silencieux.

## Cas couverts

- Multi-device: décision basée sur timestamps; pas de merge.
- Offline → online: pas d'upload sans identité conforme; à la reconnexion, on réapplique les règles ci-dessus.
- Uploads multiples rapides: append-only, l'ordre temporel reste la source pour la recommandation.

## Non-objectifs

- Merge serveur des snapshots.
- Résolution automatique sans consentement.

## Tests requis

- Conflits multi-device (local plus récent vs cloud plus récent vs égalité).
- Offline returns (aucun upload offline, reprise côté client quand online).
- Uploads multiples rapides (ordre des révisions cohérent, aucune perte).
- RLS isolation (vérifié via tests d'intégration/e2e, non via unitaires).
