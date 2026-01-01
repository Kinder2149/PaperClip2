# Tests backend – 2026-01-01

Ce dossier contient des tests minimaux pour valider la sécurité et la connectivité du backend déployé sur Fly.io.

## Pré-requis
- Python 3.11+
- Dans un environnement local (pas dans le conteneur Fly), installer les dépendances de tests:

```
pip install -r ..\requirements.txt
```

Contenu de `..\\requirements.txt`:
- pytest
- requests

## Exécuter les tests Pytest

Depuis `server_fly/`:

```
pytest -q tests/2026-01-01
```

Les tests vérifient notamment:
- /health → 200
- /health/auth sans Authorization → 401
- /db/health sans Authorization → 401
- /saves et /analytics sans Authorization → 401

Pour tester les endpoints protégés avec un vrai ID Token Firebase, voir la section suivante.

## Tests manuels (REST) avec ID Token

1) Récupérer un ID Token via l’app Flutter (FirebaseAuthService.getIdToken())
2) Appeler:

```
curl -H "Authorization: Bearer <ID_TOKEN>" https://server-fly-paperclip.fly.dev/health/auth
curl -H "Authorization: Bearer <ID_TOKEN>" https://server-fly-paperclip.fly.dev/db/health
```

Sauvegardes:

```
PARTIE_ID=<uuid-v4>
curl -X PUT -H "Authorization: Bearer <ID_TOKEN>" -H "Content-Type: application/json" \
  -d '{"snapshot": {"ok": true}}' \
  https://server-fly-paperclip.fly.dev/saves/$PARTIE_ID

curl -H "Authorization: Bearer <ID_TOKEN>" \
  https://server-fly-paperclip.fly.dev/saves/$PARTIE_ID/latest
```

Analytics (best-effort 202):

```
curl -X POST -H "Authorization: Bearer <ID_TOKEN>" -H "Content-Type: application/json" \
  -d '{"name": "test", "properties": {"k": "v"}}' \
  https://server-fly-paperclip.fly.dev/analytics/events
```
