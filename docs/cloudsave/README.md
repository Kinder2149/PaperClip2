# Paperclip2 - Cloud Save (Supabase / FastAPI HTTP)

Objectif: sauvegarde cloud append-only avec RLS Supabase, invisible pour l'utilisateur.

## Schéma SQL

Voir `supabase_migration.sql` dans ce dossier. Il crée:
- `cloud_saves` (append-only)
- `friends` (append-only)
- RLS activée et policies `select/insert` avec `auth.uid() = user_id`

Exécuter le script avec un rôle service dans votre projet Supabase.

## Variables d'environnement (.env)

```
SUPABASE_URL=https://YOUR-PROJECT.supabase.co
SUPABASE_ANON_KEY=eyJ...

# Cloud par partie (POC/HTTP)
FEATURE_CLOUD_PER_PARTIE=true
# POC local (SnapshotsCloudPersistencePort) = false, HTTP FastAPI = true
FEATURE_CLOUD_PER_PARTIE_HTTP=true
CLOUD_BACKEND_BASE_URL=https://your-cloud-backend.example.com
CLOUD_API_BEARER=Bearer your-token
```

`pubspec.yaml` inclut déjà `flutter_dotenv` et `supabase_flutter`.

## Wiring côté Flutter

```dart
import 'services/google/google_bootstrap.dart';
import 'services/google/cloudsave/cloud_save_bootstrap.dart';

final google = createGoogleServices(enableOnAndroid: true);
final cloud = createCloudSaveService(identity: google.identity);
```

Passez `cloud` à votre `GoogleControlCenter`.

## Utilisation (Supabase)

- Construire un `CloudSaveRecord` depuis l'état local (SAVE_SCHEMA_V1) via `CloudSaveService.buildRecord(...)`.
- `upload(record)` insère une nouvelle révision (append-only).
- `listByOwner(playerId)` retourne les révisions filtrées par `owner.playerId` côté client (RLS limite aux lignes du user courant).
- `getById(id)` récupère une révision précise (RLS exigée).

## Identité invisible et unique

- RLS s'appuie sur `auth.uid()` Supabase (UUID GoTrue). Une session anonyme est initialisée automatiquement.
- Le `playerId` Google est stocké dans le payload (`CloudSaveRecord.owner.playerId`) et utilisé côté client pour filtrer.
- Pour un partage cross-device automatique, envisager l'auth Google Supabase (en option, hors périmètre minimal).

## Offline

- Le cœur de jeu reste local; les actions cloud sont opt-in et explicites.
- Aucune écriture automatique; pas de logique métier côté serveur.

---

## Adapter HTTP (FastAPI) — Contrat minimal

Endpoints attendus (côté serveur):

- PUT `/api/cloud/parties/{partieId}`
  - Body JSON:
    ```json
    {
      "snapshot": { /* GameSnapshot JSON */ },
      "metadata": {
        "partieId": "...",
        "playerId": "optional-if-known",
        "gameMode": "INFINITE|COMPETITIVE",
        "gameVersion": "...",
        "savedAt": "ISO-8601",
        "name": "..."
      }
    }
    ```
  - Auth: header `Authorization: Bearer ...`
  - Réponse: 2xx si OK

- GET `/api/cloud/parties/{partieId}`
  - Réponse 200:
    ```json
    { "snapshot": { ... }, "metadata": { ... } }
    ```
  - 404 si aucune révision

- GET `/api/cloud/parties/{partieId}/status`
  - Réponse 200:
    ```json
    {
      "partieId": "...",
      "syncState": "in_sync|ahead_remote|unknown",
      "remoteVersion": 1,
      "lastPushAt": "ISO-8601",
      "lastPullAt": "ISO-8601",
      "playerId": "optional-if-known"
    }
    ```
  - 404 si aucune révision

Notes:
- Le client inclut `playerId` dans `metadata` si une identité Google est disponible; sinon champ omis.
- `HttpCloudPersistencePort` parse `playerId` depuis `status` pour l’UI (traçabilité).
