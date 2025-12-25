# PaperClip2 — PROD_ENV_CHECKLIST

But: valider qu’un déploiement de production est conforme à l’Option A (clean absolu), aux invariants d’identité/persistance, et aux politiques de sécurité et de concurrence.

Dernière mise à jour: 2025-12-25

## 1) Backend FastAPI (Render)
- [ ] URL backend: `https://paperclip2-api.onrender.com`
- [ ] API base: `https://paperclip2-api.onrender.com/api`
- [ ] Démarrage OK (logs Render sans erreurs)

### 1.1 Variables d’environnement (obligatoires)
- [ ] `SECRET_KEY` (forte entropie, non commitée)
- [ ] `JWT_TTL_SECONDS=3600` (ou valeur souhaitée)
- [ ] `CLOUD_STORAGE_DIR=cloud_data` (ou dossier persistant monté)
- [ ] `SNAPSHOT_SCHEMA_VERSION=1`
- [ ] `REQUIRE_CONDITIONAL_WRITES=1` (ETag requis)
- [ ] `MAX_SNAPSHOT_BYTES=262144` (256 KiB par défaut)
- [ ] `GAME_MODE_ENUM` vide ou liste fermée (ex: `classic,zen`)
- [ ] `API_KEY` non défini (Option A: JWT-only)

### 1.2 Réseau et sécurité
- [ ] HTTPS forcé
- [ ] CORS: domaines autorisés (app mobile/web si applicable)
- [ ] Rate limiting (niveau plateforme / proxy) recommandé
- [ ] Logs structurés activés et retenus (erreurs 4xx/5xx, 412/428)

### 1.3 Santé applicative
- [ ] Endpoint de santé ou ping (ex: `/` ou `/docs`) accessible
- [ ] Erreurs d’import au boot: aucune
- [ ] ETag présent dans réponses `GET /api/cloud/parties/{id}` et `.../status`

## 2) Identité & JWT
- [ ] `POST /api/auth/login` accepte `{ provider, provider_user_id }`
- [ ] Tokens émis: `sub` = `player_uid` (UUID v4), `providers` listés
- [ ] `verify_jwt` rejette tout `sub` non-UUID
- [ ] Pas de compat legacy `playerId` (rejetée au login)

## 3) Cloud — Option A (clean absolu)
- [ ] Toutes les routes cloud exigent JWT (aucun fallback `API_KEY`)
- [ ] `PUT /api/cloud/parties/{partieId}`
  - [ ] `If-None-Match: *` en création; `If-Match: "<etag>"` en update
  - [ ] 412/428 renvoyés conformément aux préconditions
  - [ ] Ownership: `owner_uid` = `player_uid` JWT (premier writer si manquant)
- [ ] `GET /api/cloud/parties?playerId=...` ne retourne que `owner_uid` = requester
- [ ] `DELETE /api/cloud/parties/{partieId}` refuse non-propriétaire (403)

## 4) Supabase/Postgres (si activé)
- [ ] Schéma appliqué: voir `docs/SUPABASE_SCHEMA.md`
- [ ] Tables `players` et `identity_provider_links` présentes
- [ ] Unicité `(provider, provider_user_id)` assurée
- [ ] (Facultatif) RLS aligné si accès direct par client; sinon accès exclusivement via backend

## 5) Client (Flutter)
- [ ] Envoi JWT dans `Authorization: Bearer <token>`
- [ ] ETag géré: cache par `partieId`, 412/428 remontés au contrôleur pour UX
- [ ] `snapshotSchemaVersion=1` produit à l’écriture
- [ ] Pas d’appel `/auth/refresh` (stratégie de re-login silencieux côté `AuthService`)

## 6) Données & sauvegardes
- [ ] Sauvegardes locales: quotas N=10, TTL=30j appliqués
- [ ] Pas de “slot global” ni logique par nom
- [ ] Backups non listés comme parties, UI dédiée pour restauration

## 7) Runbook validation rapide
- [ ] Login → obtenir JWT
- [ ] PUT nouvelle partie avec `If-None-Match: *` → 200
- [ ] GET partie → ETag renvoyé
- [ ] PUT update avec `If-Match` invalide → 412
- [ ] DELETE avec autre compte → 403
- [ ] LIST parties avec JWT → seules les siennes

## 8) Références
- Conformité: `docs/FINAL_SAVE_SYSTEM_COMPLIANCE.md`
- Schéma Supabase: `docs/SUPABASE_SCHEMA.md`
- Architecture: `docs/ARCHITECTURE.md`
