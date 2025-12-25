# Invariants Système – Identité & Persistance

Document normatif. Applicabilité immédiate et permanente. Toute dérogation est interdite sans révision formelle de ce document.

## 1. Portée et objectifs
- Définir l’identité interne canonique du joueur et ses relations avec les entités de jeu.
- Établir la vérité métier persistée et son cycle de vie.
- Poser les règles d’ownership du cloud et les contraintes d’écriture.
- Rendre obligatoire le versioning des snapshots.
- Interdire explicitement les pratiques contraires à ces invariants.

Contexte certain: jeu local-first (jouable sans réseau). Cloud facultatif, asynchrone et non bloquant. Google est un fournisseur d’authentification, pas l’identité de jeu.

## 2. Définitions
- player_uid: identifiant interne canonique d’un joueur. Stable, unique, opaque (UUID v4 ou équivalent).
- partie_id: identifiant unique d’une partie. Stable, unique, opaque (UUID v4). Une partie = un partie_id.
- snapshot: représentation complète, immuable et auto-suffisante de l’état métier d’une partie à un instant t.
- ownership: relation exclusive entre un owner (player_uid) et une ressource cloud.

## 3. Invariants
1. Identité
   - 3.1. player_uid est l’identité canonique unique d’un joueur au sein du système.
   - 3.2. Aucune autre identité externe (Google, Apple, etc.) n’est considérée comme identité de jeu.
2. Vérité métier
   - 3.3. snapshots constituent la vérité métier persistée de l’état de jeu.
   - 3.4. Les snapshots sont immuables une fois écrits (append-only).
3. Local-first
   - 3.5. L’intégralité du jeu est fonctionnelle hors-ligne. Le cloud est facultatif et non bloquant.
4. Ownership cloud
   - 3.6. Toute ressource cloud (snapshots, métadonnées associées) possède un owner unique: un player_uid.
   - 3.7. Écriture cloud non propriétaire interdite: seul l’owner peut créer/modifier/retirer ses propres ressources.
5. Versioning obligatoire
   - 3.8. Chaque snapshot est versionné. Le versioning est strictement monotone par couple (player_uid, partie_id).
   - 3.9. Un snapshot référence exactement: player_uid, partie_id, version, horodatage, et l’état complet sérialisé.
6. Absence de logique métier serveur
   - 3.10. Aucun calcul métier ne doit être requis côté serveur pour déterminer l’état d’une partie. Le serveur est un stockage et une validation d’ownership.
7. Non-ambiguïté et traçabilité
   - 3.11. Aucune clé métier ne dépend d’un nom ou d’un affichage. Seuls des identifiants opaques sont autorisés.
   - 3.12. Toute opération persistante est traçable par identifiants et horodatages.

## 4. Modèle relationnel minimal (identité ↔ parties ↔ snapshots)
- Un player_uid possède zéro ou plusieurs partie_id.
- Un partie_id appartient à exactement un player_uid.
- Un snapshot appartient à exactement un couple (player_uid, partie_id) et à une version unique dans ce couple.
- Les snapshots forment une chaîne temporelle immuable pour un couple (player_uid, partie_id): version 1 < version 2 < …

Implications:
- Pas de partage de partie entre player_uid.
- Pas d’écriture ou d’écrasement trans-parties. Une version identifie de manière unique un état dans la chronologie d’une partie.

## 5. Règles d’ownership cloud
- Le serveur n’accepte l’écriture d’un snapshot que si le jeton d’authentification correspond au player_uid owner.
- Le serveur refuse toute écriture, mise à jour ou suppression pour un player_uid ≠ owner.
- Les lectures peuvent être restreintes à l’owner par défaut. Toute exposition publique doit faire l’objet d’un contrat séparé (hors scope de ce document) et ne modifie pas l’ownership.

## 6. Versioning des snapshots
- Chaque snapshot doit porter:
  - player_uid
  - partie_id
  - version (entier strictement croissant par couple player_uid + partie_id)
  - timestamp de création (UTC)
  - charge utile de l’état de jeu (complète)
- Les versions ne régressent jamais. Il est interdit d’insérer un snapshot avec une version ≤ à la dernière version existante pour le même couple.
- Les snapshots sont immuables: aucune modification en place. Toute évolution de l’état crée une nouvelle version.

## 7. Opérations autorisées
- Création de partie: génération d’un nouveau partie_id associé au player_uid courant.
- Émission de snapshot: création d’un nouveau snapshot immuable avec version suivante pour le couple courant.
- Synchronisation cloud: upload/download asynchrones, sans bloquer le jeu local.
- Restauration locale: remplacement de l’état local à partir d’un snapshot choisi (sans altérer le snapshot source).

## 8. Opérations interdites
- Écriture cloud non propriétaire (toute écriture par un player_uid différent de l’owner).
- Modification in-place d’un snapshot (toute mutation post-création).
- Régression de version (insertion d’une version non strictement supérieure).
- Couplage de logique métier au serveur (toute décision serveur qui altère l’état de jeu).
- Dépendance à une identité non canonique (utiliser un identifiant autre que player_uid comme clé primaire de données de jeu).

## 9. Sécurité et validation
- Authentification obligatoire pour toute écriture.
- Validation stricte des identifiants opaques et de l’ownership avant persistance.
- Rejet de toute requête ambiguë, incomplète ou non conforme aux champs obligatoires.

## 10. Décisions irréversibles
- player_uid est et reste l’identité canonique du joueur.
- snapshots sont et restent la vérité métier persistée.
- Le cloud est un stockage sous ownership strict; aucune écriture non propriétaire n’est tolérée.
- Versioning snapshot obligatoire et strictement monotone par partie.
- Aucune logique métier côté serveur n’est permise.
- Le système demeure local-first, le cloud restant facultatif et asynchrone.

## 11. Priorité des invariants
En cas de conflit, la priorité est: Identité canonique > Ownership cloud > Immutabilité et versioning des snapshots > Local-first. Toute implémentation technique doit se conformer à cet ordre sans exception.
