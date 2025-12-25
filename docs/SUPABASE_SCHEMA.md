# PaperClip2 — SUPABASE_SCHEMA (Postgres)

Objectif: documenter le schéma minimal requis côté Supabase/Postgres pour l’identité (player_uid souverain) et la gestion des liaisons providers. Le cloud de sauvegarde reste filesystem (cloud_data) — pas de table pour les snapshots.

## 1) Principes
- player_uid est la clé canonique (UUID v4) utilisée dans les JWT (`sub`).
- Les identités providers (ex: Google, Apple) se lient à `player_uid` via une table de mapping.
- Option A (clean absolu): aucune compat legacy par `playerId` pour l’ownership des saves.

## 2) Tables

### 2.1 players
- Rôle: registre souverain des joueurs.
- Clé: `id` (UUID v4), identique au `player_uid` exposé au client via JWT.

DDL recommandé:
```sql
create table if not exists players (
  id uuid primary key,
  created_at timestamptz not null default now()
);
```

Index:
- PK implicite sur `id`.

### 2.2 identity_provider_links
- Rôle: lier un `player_uid` à un provider et un identifiant provider spécifique.
- Contrainte d’unicité: un couple `(provider, provider_user_id)` ne peut appartenir qu’à un seul `player_uid`.

DDL recommandé:
```sql
create table if not exists identity_provider_links (
  player_uid uuid not null references players(id) on delete cascade,
  provider text not null,
  provider_user_id text not null,
  created_at timestamptz not null default now(),
  primary key (player_uid, provider, provider_user_id)
);

-- Assure l’unicité transversale des identifiants providers
create unique index if not exists identity_provider_links_provider_user_unique
  on identity_provider_links (provider, provider_user_id);
```

Notes:
- `provider` valeurs usuelles: `google`, `apple`, `email`, etc.
- `provider_user_id` doit être stable côté provider.

## 3) Droits et sécurité
- API backend FastAPI signe les JWT avec `sub = player_uid`.
- Les routes cloud exigent un JWT valide; aucune API_KEY n’est acceptée.
- Supabase RLS: si utilisées, aligner les politiques pour ne permettre que la lecture/écriture des liens appartenant à `player_uid` courant (si l’accès direct à Supabase est nécessaire; sinon exclusivement via backend).

Exemple de politique (indicatif):
```sql
-- Exemple si l’app interroge Supabase directement (sinon non requis)
alter table identity_provider_links enable row level security;
create policy read_own_links on identity_provider_links
  for select using (auth.uid()::uuid = player_uid);
create policy write_own_links on identity_provider_links
  for insert with check (auth.uid()::uuid = player_uid);
```

## 4) Synchronisation et migrations
- Le backend contient déjà la logique de résolution/création dans `server/app/services/identity.py`.
- Aucune migration snapshot en base: les snapshots sont versionnés dans les fichiers JSON (cloud passif).

## 5) Références
- Backend: `server/app/services/identity.py`, `server/app/routes/auth.py`
- Conformité: `docs/FINAL_SAVE_SYSTEM_COMPLIANCE.md` (Option A, ownership strict)
- Architecture: `docs/ARCHITECTURE.md`
