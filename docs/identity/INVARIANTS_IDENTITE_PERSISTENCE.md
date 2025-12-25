# Invariants Système – Identité & Persistance

Document canonique — fait foi
Dernière mise à jour: 2025-12-25
Voir aussi: `../Glossaire.md` • `../SAVE_SYSTEM_INVARIANTS.md` • `../persistence.md`

## Objet et portée
- Définir les invariants non négociables concernant l’identité joueur et la persistance des données.
- S’applique à tout client (mobile/desktop/web) et au backend.
- Normatif, opposable, sans impact de code immédiat.

## Définitions
- `player_uid`: identifiant interne canonique, opaque, stable, unique (UUID v4), généré localement au premier lancement.
- `partie_id`: identifiant unique (UUID v4) d’une partie. Une partie est un univers de progression isolé.
- `snapshot`: capture complète, i.e. sérialisation intégrale d’une partie à un instant t, autosuffisante pour un restore.
- `rev`: numéro de version séquentiel d’un snapshot dans l’historique d’une même `partie_id`.
- Provider OAuth (ex: Google): moyen d’authentifier un acteur réseau. N’EST PAS l’identité de jeu.

## Modèle d’identité (canon interne)
- `player_uid` DOIT être:
  - généré localement à la première exécution,
  - persistant localement,
  - indépendant de tout provider réseau,
  - utilisé comme clé primaire logique côté client pour toutes données locales.
- Le backend NE DOIT PAS imposer ni déduire `player_uid` à partir d’un provider.
- La présence/absence de session réseau NE DOIT PAS modifier ou régénérer `player_uid`.

## Relation identité ↔ parties ↔ snapshots
- Un `player_uid` PEUT posséder N `partie_id`.
- Une `partie_id` APPARTIENT à un unique `player_uid` (ownership fort).
- Un `snapshot` appartient à exactement une `partie_id`.
- Les snapshots forment une suite ordonnée par `rev` strictement croissant par `partie_id`.
- Les opérations autorisées:
  - créer une nouvelle `partie_id` (initial snapshot `rev=0`),
  - émettre un nouveau snapshot (rev+1) pour une `partie_id`,
  - restaurer une `partie_id` à partir d’un snapshot antérieur (en créant un nouveau snapshot fils avec `rev` suivant, jamais en réécrivant l’historique).

## Persistance locale-first
- Le jeu DOIT être pleinement jouable hors-ligne.
- Le stockage local est l’autorité de vérité pour l’exécution locale.
- Toute fonctionnalité cloud est facultative, asynchrone, non bloquante, et ne DOIT PAS empêcher la sauvegarde ni le chargement local.

## Cloud (ownership, accès, synchronisation)
- Ownership:
  - Les données cloud d’une `partie_id` sont détenues par le `player_uid` qui l’a créée.
  - Le lien `player_uid ↔ compte réseau` est une association d’accès, pas d’identité.
- Accès:
  - L’accès cloud DOIT vérifier que l’acteur réseau est autorisé à agir au nom du `player_uid` ciblé.
  - Les opérations cloud (push/pull) DOIVENT s’opérer au niveau `partie_id` et `rev`.
- Synchronisation:
  - Push cloud: ajoute un snapshot avec `rev` suivant côté cloud. NE DOIT PAS écraser d’historique existant.
  - Pull cloud: récupère l’historique des snapshots d’une `partie_id`. La fusion est explicite, jamais implicite.
  - Conflits: résolus par politique explicite (ex. arbitrage par `rev` + horodatage + confirmation utilisateur). Aucune résolution silencieuse.

## Versioning des snapshots (obligation)
- Chaque snapshot DOIT porter:
  - `partie_id` (UUID v4),
  - `rev` (entier >=0, strictement croissant),
  - `player_uid` propriétaire,
  - `timestamp_utc` ISO8601,
  - `schema_version` (version du format de snapshot),
  - `hash` de contenu (intégrité),
  - métadonnées minimales (plateforme/app_version).
- Le format de snapshot DOIT être strictement versionné via `schema_version`. Toute évolution de schéma nécessite une stratégie d’upgrade claire et non destructive.

## Interdictions explicites
- Écriture libre côté client vers le cloud INTERDITE. Toute écriture passe par une API versionnée et contrôlée.
- Écrasement d’un snapshot existant INTERDIT. Seul l’ajout en fin d’historique est permis.
- Déduction de l’identité de jeu (`player_uid`) à partir d’un provider OAuth INTERDITE.
- Fusion implicite ou silencieuse de snapshots INTERDITE.
- Utilisation d’attributs non stables (email, display name) comme clés d’identité INTERDITE.
- Modification rétroactive de l’historique (réécriture de `rev`) INTERDITE.
- Partage de `partie_id` entre plusieurs `player_uid` INTERDIT.

## Invariants (liste opposable)
- `player_uid` est l’identité canonique de jeu; il est local, stable, opaque, indépendant du réseau.
- `partie_id` identifie une partie unique, appartenant à un seul `player_uid`.
- Un snapshot est complet, autosuffisant, immuable; toute nouvelle sauvegarde est un nouveau `rev`.
- Le jeu est local-first; le cloud est optionnel, asynchrone et non bloquant.
- Toute écriture cloud est append-only, contrôlée, auditée et versionnée.
- Le versioning (`rev`, `schema_version`) est obligatoire et vérifié.
- Les résolutions de conflit sont explicites, jamais implicites.
- Les providers d’authentification n’influencent ni la génération ni la stabilité du `player_uid`.

## Décisions irréversibles
- Standard d’identité: `player_uid` (UUID v4) devient la seule identité interne canonique. Aucune autre source (provider, email) ne pourra la supplanter.
- Append-only pour la persistance: interdiction définitive d’écraser/modifier un snapshot existant. Historique inviolable par conception.
- Versioning obligatoire et permanent: tout snapshot sans `schema_version` ou sans `rev` est invalide.
- Séparation identité/auth: les providers réseau n’incarneront jamais l’identité de jeu. Seul lier/délier des moyens d’accès est permis.
- Local-first invariant: aucune dépendance dure au réseau ne pourra être introduite pour jouer, sauvegarder ou restaurer.

## Validation et conformité
- Toute API ou fonctionnalité nouvelle DOIT démontrer sa conformité à ces invariants (checklist d’acceptation).
- Toute migration de schéma DOIT inclure un plan d’upgrade non destructif et test de rétrocompatibilité ou de conversion.
- Des audits périodiques DOIVENT vérifier:
  - unicité/stabilité de `player_uid`,
  - monotonie de `rev`,
  - intégrité (`hash`) des snapshots,
  - absence d’overwrite côté cloud,
  - traçabilité des opérations (horodatage/audit).

---

Référence croisée:
- Voir également: `../SAVE_SYSTEM_INVARIANTS.md` (invariants détaillés du système de sauvegarde)
- Voir également: `../persistence.md` (stratégie snapshot-first)
