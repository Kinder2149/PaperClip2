# PHASE 3 — Politique de limitation des mondes (contractuelle)

Ce document clôture produit la PHASE 3 en formalisant une politique de limitation des mondes, sans modification backend, sans nouvelle fonctionnalité et sans refonte. Il s’appuie exclusivement sur les mécanismes existants (listing local, flags techniques, suppression) et sur les constantes déjà présentes dans le code.

Sources de référence (code existant, non exhaustif):
- `lib/constants/game_config.dart` — présence de constantes, dont `MAX_TOTAL_SAVES`
- `lib/services/saves/saves_facade.dart` — `listSaves`, suppression via adapter
- `lib/services/save_system/save_manager_adapter.dart` — `listSaves`, `deleteSaveById`
- `lib/services/persistence/game_persistence_orchestrator.dart` — états/flags techniques (pending)


## 1) Définition contractuelle: qu’est‑ce qu’un “monde” ?

- Monde: une sauvegarde principale locale représentant une partie identifiée par un `partieId`, non marquée comme backup.
- N’entrent pas dans la définition:
  - Backups: toute sauvegarde dont le nom contient le délimiteur de backup (`GameConstants.BACKUP_DELIMITER`).
  - États techniques: flags `pending_identity_<partieId>`, `pending_cloud_push_<partieId>` (prefs) qui ne constituent pas des mondes.
- Définition fermée: Monde = entrée locale listée par `SaveManagerAdapter.listSaves()` filtrée sur “non‑backup”.


## 2) Règle officielle de limite

- Nombre maximum de mondes (côté client): `MAX_TOTAL_SAVES` (défini dans `GameConstants`).
- La valeur contractuelle actuelle est celle déclarée dans le code au moment de la version (ex: 10 au jour de rédaction). Ce document ne crée pas de règle nouvelle: il formalise l’usage de la constante existante comme seuil produit.


## 3) Périmètre de comptage

- Comptés:
  - Sauvegardes locales “monde” (non‑backup) retournées par `listSaves()` après filtrage des backups.
- Non comptés:
  - Backups (noms contenant `BACKUP_DELIMITER`).
  - États `pending_*` (flags prefs) qui ne sont pas des entrées.
  - Objets cloud (le backend est volontairement sans limite; pas de comptage côté serveur).


## 4) Point d’application

- Où/Quand: vérification côté client juste avant la création d’un nouveau monde (au point d’entrée qui déclenche la création).
- Pourquoi côté client: le backend ne limite pas; la création est initiée par le client et celui‑ci dispose de l’inventaire local via `listSaves()`.
- Mécanisme: l’appelant obtient la liste via `SavesFacade.listSaves()` (ou `SaveManagerAdapter.listSaves()`), filtre les backups, compte les mondes et compare à `MAX_TOTAL_SAVES`.


## 5) Comportement en cas de limite atteinte

- Comportement attendu: blocage de la création d’un nouveau monde si le compte des mondes (non‑backup) est >= `MAX_TOTAL_SAVES`.
- Actions possibles pour l’utilisateur: utiliser la suppression existante d’un monde via `SaveManagerAdapter.deleteSaveById(worldId)` (ou les écrans de gestion existants) puis réessayer.
- Cette section formalise la politique produit sans introduire de nouvelle fonctionnalité: elle s’appuie sur les capacités actuelles (listing + suppression).


## 6) Feedback utilisateur minimal (sans nouvelle UI)

- Message explicite minimal: “Nombre maximum de mondes atteint. Supprimez un monde existant pour en créer un nouveau.”
- Action corrective: proposer la suppression d’un monde via les flux existants (écran/commande déjà en place) ou renvoyer l’utilisateur vers la liste des sauvegardes.
- Implémentation minimale autorisée: log applicatif et surface d’erreur standard existante (pas de nouvelle UI dédiée requise par cette politique).


## 7) Cohérence avec la PHASE 2

- Aucun conflit avec les états `pending_identity` ou `pending_cloud_push`: ces états sont des flags techniques et ne comptent pas comme mondes supplémentaires.
- Le push cloud (PHASE 2) reste orthogonal: la limite s’applique avant création locale; les états de synchronisation n’affectent pas le comptage.


## 8) Checklist de clôture PHASE 3 (binaire)

- [ ] Définition fermée du “monde” établie (non‑backup, local, par `partieId`).
- [ ] Règle de limite formalisée: `MAX_TOTAL_SAVES` de `GameConstants`.
- [ ] Périmètre de comptage précisé (comptés vs non comptés).
- [ ] Point d’application défini (vérification côté client avant création, via `listSaves()` + filtre).
- [ ] Comportement à la limite documenté (blocage + suppression via mécanismes existants).
- [ ] Feedback minimal décrit (message explicite + action corrective sans nouvelle UI).
- [ ] Cohérence avec PHASE 2 confirmée (pending_* exclus du comptage, pas de conflit).
- [ ] Document versionné dans le repo et communiqué à l’équipe produit/tech.

---
Document fondé exclusivement sur l’existant (constantes, capacités de listing/suppression, flags). Aucune modification backend, aucune nouvelle fonctionnalité ni refonte.
