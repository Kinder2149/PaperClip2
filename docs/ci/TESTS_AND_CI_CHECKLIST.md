# CI & Tests — Checklist (PaperClip2)

## 1) Commandes locales
- Lint/analyse: `flutter analyze`
- Tests unitaires: `flutter test -r expanded`
- Tests ciblés: `flutter test -r expanded test/unit/services/persistence`

## 2) Portée des tests critiques
- Persistance locale (ID-first, snapshot-only): roundtrips de base
- Backups: rétention N=10, TTL=30j (quota + ancienneté)
- Intégrité: snapshot présent/lisible, doublons name→IDs, désalignements meta/save, format backups
- Cloud par partie: push/pull par `partieId`, statut enrichi
- UI (widgets): écrans Save/Load, Production, Upgrades (smoke tests)

## 3) Données de test & fakes
- `InMemorySaveGameManager` pour simuler le stockage local
- `FakeCloudPort` pour le cloud (push/pull/status)

## 4) Conseils de stabilité
- Isoler les singletons avant/after tests (`resetForTesting()`)
- Éviter les dépendances externes (dotenv, réseau) dans les tests unitaires
- Utiliser `pumpAndSettle` pour widgets avec animations

## 5) Pipeline CI (baseline)
- Étape 1: `flutter pub get`
- Étape 2: `flutter analyze`
- Étape 3: `flutter test -r expanded`
- Artifacts: rapport de couverture (optionnel)

## 6) Flags & Env
- `.env` versionnée avec `FEATURE_CLOUD_PER_PARTIE` par défaut à `false` sur CI
- Les tests cloud utilisent un fake et n’exigent pas de config réseau
