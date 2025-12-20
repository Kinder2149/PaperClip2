# Contributing — Gouvernance GameState et Règles de Revue

Ce document encadre les contributions pour éviter tout retour vers un God Object et sécuriser l’évolution du projet.

## Périmètre GameState

- Autorisé
  - Exposer/mettre à jour l’état métier (getters/setters simples), sans logique UI.
  - Déléguer les actions au `GameEngine`/managers/services.
  - Sérialiser/désérialiser via snapshot (`toSnapshot`/`applySnapshot`).
  - Appeler des services transverses (offline/persistance/social/pricing) de façon orchestrée, sans afficher.
- Interdit
  - Timers, boucles, scheduling (tick déclenché par un contrôleur externe).
  - Formatage UI, textes d’affichage, navigation, dialogs.
  - I/O direct de persistance (hors orchestrateur) ou accès stockage.
  - Réimplanter des règles métier (logique à déplacer dans engine/managers/services).

## Ports UI (notification/navigation/audio)

- Usage
  - GameState peut émettre des signaux via ports (ex: notification d’unlock) mais ne décide pas du rendu.
  - Les services UI (ex: SocialUiService/PricingAdviceService) doivent rester des façades UI. GameState ne doit pas contenir de textes de présentation.
- Bonnes pratiques
  - Toujours vérifier la présence du port (null-safe) côté service UI.
  - Préférer des messages métier neutres si nécessaire, le wording final vit côté UI.

## Persistance — Snapshot-first

- Le snapshot est la source de vérité.
- `GamePersistenceOrchestrator` est l’unique point d’entrée save/load/backup.
- `prepareGameData` et alias legacy sont tolérés pour compat/migration, ne pas les réintroduire dans de nouveaux flux.

## API publique de GameState

- Stable (exemples)
  - Accès aux managers (`playerManager`, `marketManager`, `resourceManager`, `levelSystem`, `productionManager`, `statistics`).
  - Actions déléguées (`producePaperclip`, `buyAutoclipper`, `purchaseUpgrade`, `chooseProgressionPath`).
  - Offline (`applyOfflineProgressV2`), session (`startNewGame`, `reset`, `togglePause`).
  - Persistance (passe-plat orchestrateur: `saveGame`, `loadGame`, `saveOnImportantEvent`, `checkAndRestoreFromBackup`).
- Compat/legacy (à éviter dans du nouveau code)
  - `totalTimePlayedInSeconds`, `isCrisisTransitionComplete`, `gameId`, `autocliperCost`, `purchaseMetal`, `prepareGameData`, `formattedPlayTime`.

## Checklist PR (copier-coller)

- [ ] Aucune importation d’outils UI/formatage dans `GameState`.
- [ ] Aucune logique de timers/scheduling dans `GameState`.
- [ ] Toute nouvelle méthode de `GameState` délègue au `GameEngine`/service/manager approprié.
- [ ] Persistance uniquement via `GamePersistenceOrchestrator` (aucun I/O direct dans `GameState`).
- [ ] Offline appliqué via `applyOfflineProgressV2` uniquement.
- [ ] Les interactions UI passent par des ports; pas de navigation/affichage direct.
- [ ] Si le snapshot évolue, la doc `docs/persistence.md` est mise à jour et un test roundtrip est prévu.

## Tests recommandés

- Roundtrip snapshot: `toSnapshot`/`applySnapshot` conserve l’état métier.
- Offline idempotent: absence de double-application.
- Délégation tick: pas d’effet quand paused/non-initialisé; passage des bons paramètres à `GameEngine`.
- Orchestrateur: chemin save/load/backup testé avec mocks (sans I/O réel).

## Exemple d’ajout acceptable

- Ajouter une méthode `canPurchaseUpgrade(id)` qui délègue à `GameEngine` et ne modifie pas l’état UI.

## Exemple d’ajout non acceptable

- Ajouter une méthode qui formate la durée de jeu en texte ou qui pousse une navigation.
