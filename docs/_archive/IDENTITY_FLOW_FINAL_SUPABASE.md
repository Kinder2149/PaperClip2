# IDENTITÉ & SESSIONS — Modèle final (Paperclip)

Objectif: garantir une identité unique, stable, cross-device, sans exposer Supabase à l’utilisateur.

## États d’identité

- local_only
  - Aucune identité distante. Jeu purement local, offline-first.
- google_play_only
  - Identité Google Play Games présente (playerId), sans session Supabase.
- supabase_anonymous
  - Session Supabase anonyme (technique). Autorisée uniquement si la synchronisation est désactivée.
- supabase_google_linked
  - Session Supabase liée via OAuth Google. Cible stricte quand la synchronisation est activée.

## Règle d’or (contractuelle)

Dès que `signed_in_sync_enabled == true`:
- La session Supabase DOIT être `OAuth Google`.
- Aucune écriture cloud n’est autorisée sous session anonyme.

## Transitions

- invité → Google
  - Play Games: signIn explicite.
  - Si sync ON: établir/forcer la session Supabase OAuth Google (silencieux pour l’UI).
- invité → email
  - Non supporté dans la version actuelle. Hors scope.
- offline → online
  - Si sync ON: tentative silencieuse de liaison OAuth Google avant toute écriture cloud.
- réinstallation / changement d’appareil
  - Sign-in Play Games puis sync ON ⇒ même `auth.users.id` (via Google) ⇒ récupération cross-device garantissant l’unicité.

## Invariants

- `auth.users.id` = clé primaire cloud.
- `owner.playerId` = identifiant logique métier (Google Play Games) stocké dans le payload cloud pour affichage/filtrage.
- Append-only strict: aucune mise à jour en place sur la table principale (écritures = insertions).
- Backend invisible: aucune mention de Supabase dans l’UI.
- RLS activée: lecture/écriture limitées à l’utilisateur authentifié.

## Impact technique

- La préférence d’opt-in `syncEnabled` est persistée (SharedPreferences) via `SyncOptIn`.
- `SupabaseCloudSaveAdapter` applique la règle d’or:
  - sync OFF: session anonyme possible (pas d’upload automatique).
  - sync ON: session OAuth Google exigée; refus si session absente ou `owner.playerId` manquant.
- `GoogleControlCenter`:
  - Charge l’opt-in au démarrage, permet le toggle et déclenche la liaison OAuth si ON.

## Tests de validation

- Multi-device: même compte Google, sync ON ⇒ révisions visibles des deux côtés, pas de doublon anonyme.
- Réinstallation: sign-in Google + sync ON ⇒ récupération OK sans perte.
- Offline → online: toggle ON sans réseau ⇒ pas d’upload; au retour online: liaison OAuth puis upload OK.
- Changement d’état: ON/OFF sans perte; aucune écriture anonyme après ON.
- Non-régression Games Services (succès/leaderboards) intacte.
