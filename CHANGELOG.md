# CHANGELOG — PaperClip2

> Une ligne par mission terminée. Format : `[date] | [type] | [description]`

---

| Date | Type | Description |
|---|---|---|
| 2026-04-10 | Reprise projet | Nettoyage et alignement sur METHODO — création PROJET_CONTEXTE.md, archivage documentation |
| 2026-04-10 | Nettoyage worldId | 0 occurrence `worldId` dans lib/ — 30 occurrences remplacées par `enterpriseId` dans `game_persistence_orchestrator.dart` |
| 2026-04-10 | Auth & Cloud | Fiabilisation flux auth/cloud — suppression `cloud_enabled` (cloud automatique si Firebase connecté), centralisation appels auth via `AppBootstrapController.requestGoogleSignIn()`, déclencheur sync unique (listener Firebase Auth), 9 fichiers modifiés |
| 2026-04-10 | Bug fix Android | AUTH-ANDROID-FIX — Google Sign-In `clientConfigurationError` corrigé : `GoogleSignIn.instance` → instance statique avec `serverClientId` explicite (google_sign_in v7+ ne lit plus google-services.json automatiquement), 1 fichier modifié |

