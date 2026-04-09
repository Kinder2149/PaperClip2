# PaperClip2 — Architecture Globale

Ce document consolide l’architecture du projet (client Flutter + backend Firebase Functions) et sert d’entrée unique.

## Vue d’ensemble
- Client: Flutter (mobile/desktop/web)
- Backend: Firebase Functions (Production)

**Stack technique confirmée :**
- Firebase Functions v2 (2nd gen)
- Node.js 20 LTS
- Express 4.x
- Firebase Admin SDK
- Cloud Firestore (base de données)
- Firebase Auth (authentification)

**Endpoints exposés :**
- Base URL : `https://[region]-[project-id].cloudfunctions.net/api`
- Configuration client : Variable d'environnement `FUNCTIONS_API_BASE`

⚠️ **Clarification** : Le projet utilise exclusivement Firebase Functions.
Toute mention de FastAPI, Render, ou autres backends est erronée et obsolète.

### Architecture Backend (Firebase Functions + Firestore)
- Auth: Firebase Auth (ID Token) — unique source de vérité
- Stockage cloud: Firestore, partitionné par `uid` → `enterprises/{uid}`
- **Architecture entreprise unique** : 1 utilisateur = 1 entreprise persistante

## Décisions contractuelles (source)
- Auth & Ownership
  - Firebase Auth est l'unique source d'identité; `uid` extrait serveur-side depuis l'ID Token
  - Ownership de l'entreprise déterminé exclusivement par le serveur (interdiction de filtrage client par sécurité)
- API canonique (client)
  - `/enterprise/{uid}` pour toutes les opérations (GET/PUT/DELETE)
  - **DEPRECATED** : `/worlds` et `/saves` (ancienne architecture multi-mondes)
- Identité entreprise
  - `enterpriseId` = UUID v4, généré une fois à la création
  - Identité technique immuable, stockée dans `snapshot.metadata.enterpriseId`
  - 1 utilisateur = 1 entreprise unique (pas de multi-save)
- Modèle de données
  - `SaveGame` est le modèle de persistance principal unifié
  - `enterpriseId` comme identifiant unique (UUID v4 obligatoire)

## Couches côté client
- UI
  - IntroductionScreen (création entreprise avec nom personnalisable)
  - MainScreen (dashboard entreprise unique)
- Services de persistance
  - `GamePersistenceOrchestrator` (orchestration save/push/pull)
  - `LocalSaveGameManager` (stockage local)
  - `CloudPersistenceAdapter` (HTTP vers `/enterprise/{uid}`)
- Identité
  - `FirebaseAuthService` (ID Token pour appels protégés; écoute des changements d'auth)
- Utilitaires
  - `Logger` (logs structurés)

## Flux de données (sauvegarde/push)
1) L'UI déclenche une sauvegarde locale via `GamePersistenceOrchestrator`
2) Si utilisateur Firebase connecté, push automatique vers `/enterprise/{uid}` (garanti à la création)
3) En cas de succès: nettoyage des flags; en cas d'échec: flags `pending_cloud_push_*` + `syncState='error'`
4) Retry automatique sur changement d'auth et au resume (backoff exponentiel: 1s, 2s, 4s)

## Synchronisation automatique au login
- Listener Firebase Auth dans `main.dart` déclenche sync au login
- Stratégie "cloud always wins" : le cloud écrase toujours le local au login
- Si cloud n'existe pas et local existe : push local vers cloud
- Désactivation cloud automatique au logout

## États de synchronisation (UX)
- Synchronisé, En attente, Erreur, Cloud uniquement
- Détermination: `SavesFacade.canonicalStateFor` (priorité Erreur > En attente > Synchronisé)

## Observabilité
- Logs structurés côté client: `enterprise_put_attempt/success/failure` avec `enterpriseId`, `latency_ms`, `http_code`, `cause_category`

## Backend (résumé)
- Express + Admin SDK
- Middleware d'auth: vérifie l'ID Token, extrait `uid`
- Endpoint principal: `/enterprise/{uid}` (GET, PUT, DELETE)
- Format snapshot v3 avec `metadata.enterpriseId` (UUID v4 obligatoire)
- Résolution conflits: "Last write wins" (pas de versioning)

Pour les détails d'API, voir `docs/02-guides-developpeur/api-backend.md`.
