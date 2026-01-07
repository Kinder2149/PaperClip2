# Release Notes — 2026-01-07

## Modifications principales
- Durcissement validation backend Cloud Functions (Functions API `PUT /saves/:partieId`):
  - `snapshot` doit être un objet.
  - `snapshot.metadata`, `snapshot.core`, `snapshot.stats` doivent être des objets.
  - `snapshot.metadata.partieId` (ou `partie_id`) est requis, doit être un UUID v4 et égal au `:partieId` du chemin.
  - Codes d’erreur: `400` (structure invalide), `422` (erreurs sémantiques: missing/invalid/mismatch).
- Tests de vérification prod (Cloud Functions):
  - Scénario A (User A): PUT v1/v2, GET latest, LIST, RESTORE, DELETE → OK.
  - Isolation (User B): lecture croisée refusée → 404.
  - Limites: snapshot incomplet → 422 (corrigé), partie inexistante → 404.
- Nettoyage legacy:
  - Test d’intégration FastAPI archivé: `test/_archive/api_e2e_test.fastapi_legacy.dart`.

## Fichiers modifiés/ajoutés
- `functions/src/index.ts`: validation renforcée + helper `isPlainObject`.
- `scripts/cloud_ab_tests.ps1`: script de tests A/B + limites en prod (Cloud Functions).
- `test/_archive/api_e2e_test.fastapi_legacy.dart`: ancien test FastAPI déplacé dans `_archive`.

## Commandes de déploiement utilisées
```bash
cd functions
npm ci
npm run build
npm run deploy
```

## Points d’attention
- `firebase-functions` est signalé comme < 5.1.0 (warnings). Planifier une montée de version ultérieurement (tests émulateur recommandés avant).
- Le test Dart `api_e2e_test.dart` ciblait FastAPI (JWT custom). Il a été archivé pour éviter toute confusion avec l’API Cloud Functions.

## Validation
- Conformité Option C (Cloud Functions) confirmée pour le flux Cloud Save minimal.
- Snapshot incomplet désormais rejeté (HTTP 422).
