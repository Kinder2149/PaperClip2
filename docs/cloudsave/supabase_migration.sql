-- Paperclip2 - Supabase Cloud Save & Friends
-- Idempotent migration for tables, RLS, and append-only policies

-- 1) Extensions (optional, for gen_random_uuid)
create extension if not exists pgcrypto;

-- 2) Tables
create table if not exists public.cloud_saves (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  schema_version text not null,
  payload jsonb not null,
  device_id text,
  created_at timestamptz not null default now()
);

create table if not exists public.friends (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  friend_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  constraint friends_no_self check (user_id <> friend_id),
  constraint friends_unique_one_way unique (user_id, friend_id)
);

-- Optional: a symmetric uniqueness to avoid duplicates in reverse
-- This is enforced in application code; alternatively you can add a deferred
-- constraint via trigger to reject (friend_id, user_id) if (user_id, friend_id) exists.

-- 3) Row Level Security (RLS)
alter table public.cloud_saves enable row level security;
alter table public.friends enable row level security;

-- 4) Policies (append-only)
-- Cloud saves: owner can insert and select only their rows
create policy if not exists cloud_saves_select on public.cloud_saves
  for select using ( auth.uid() = user_id );

create policy if not exists cloud_saves_insert on public.cloud_saves
  for insert with check ( auth.uid() = user_id );

-- No update/delete policy (append-only)

-- Friends: a user can see their outgoing friendships and insert new ones
create policy if not exists friends_select on public.friends
  for select using ( auth.uid() = user_id );

create policy if not exists friends_insert on public.friends
  for insert with check ( auth.uid() = user_id );

-- 5) Indexes
create index if not exists idx_cloud_saves_user_created_at
  on public.cloud_saves (user_id, created_at desc);

create index if not exists idx_friends_user_created_at
  on public.friends (user_id, created_at desc);

-- 6) Helpers (optional): ensure schema_version is present and payload is JSON object
alter table public.cloud_saves
  add constraint if not exists cloud_saves_payload_object
  check (jsonb_typeof(payload) = 'object');

-- 7) Minimum grants: rely on RLS + Supabase Auth; no extra grants required
-- Execute with the project service role to create objects, then interact via client SDK with user sessions.

-- 8) Identity governance notes (documentation)
-- - Canonical identity is auth.users.id (UUID).
-- - Client stores provider links in auth.users.user_metadata.linked_provider_ids (JSON map),
--   e.g. { "google_play_games": "GPGS_PLAYER_ID", "email": "user@example.com" }.
-- - Client marks one-time migration with user_metadata.migration_done_at (ISO timestamp) when
--   the first OAuth session occurs, by uploading a fresh cloud revision (append-only) under the
--   new auth.users.id. Historical anonymous rows are left untouched and will remain inaccessible
--   to the new user_id by RLS (by design), avoiding server-side UPDATEs.
-- - Friends/social features must always use the canonical user_id. Provider IDs are not sources of truth.

-- 9) Optional hardening ideas (not enforced here)
-- - Add a server-side function to validate payload schema_version values and basic payload shape.
-- - Add a trigger to reject UPDATE/DELETE on cloud_saves to enforce append-only at DB level.
-- - Add monitoring on insert rates and payload sizes to prevent abuse.
