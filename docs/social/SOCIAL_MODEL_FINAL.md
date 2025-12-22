# SOCIAL & AMIS — Modèle final (Option A — Minimaliste)

Objectif: clarifier et stabiliser le modèle Social court terme, sans ambiguïté avec Google.

## Décision figée

- Option A (recommandée court terme):
  - Amis Supabase = ajout manuel (UUID Supabase d’un ami).
  - Amis Google = uniquement pour Leaderboards (pas de mapping automatique vers Supabase).
  - Deux mondes séparés; aucun mécanisme de découverte/synchronisation croisée.

## Modèle de données (Supabase)

- Table `friends` (append-only, one-way):
  - `user_id` (uuid, référence auth.users.id)
  - `friend_id` (uuid, référence auth.users.id)
  - `created_at` (timestamp)
- Pas de réciprocité intrinsèque (A→B n’implique pas B→A).
- RLS: chaque utilisateur ne lit que ses propres liens (`user_id = auth.uid()`).

## Flux UX minimal

- Ajout: saisir/coller un UUID ami → insertion `friends(user_id, friend_id)`.
- Liste: lister `friends` de l’utilisateur.
- Aucun affichage d’identité Supabase en clair; l’UI reste générique et non-technique.

## Identité requise

- Pour toute opération amis, une session Supabase OAuth Google est requise (pas d’anonyme).
- L’UI invite à la connexion Google si nécessaire.

## Non-objectifs (hors scope)

- Réciprocité automatique.
- Discovery/contacts.
- Mapping automatique des amis Google vers Supabase.

## Tests requis

- Ajout et listage (pass-through client) avec un repository mock.
- Cas limites: doublon silencieux côté client (côté serveur, contrainte d’unicité si désirée), UUID invalide → erreur.
- RLS: vérifié par tests d’intégration/e2e, non en unitaire.
