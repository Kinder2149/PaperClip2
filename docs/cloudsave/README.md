# Paperclip2 - Cloud Save (Supabase)

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

## Utilisation

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
