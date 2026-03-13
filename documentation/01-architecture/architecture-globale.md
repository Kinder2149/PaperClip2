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
- Stockage cloud: Firestore, partitionné par `uid` → `players/{uid}/saves/{worldId}`

## Décisions contractuelles (source)
- Auth & Ownership (ex-Phase 0)
  - Firebase Auth est l’unique source d’identité; `uid` extrait serveur-side depuis l’ID Token
  - Ownership d’un monde déterminé exclusivement par le serveur (interdiction de filtrage client par sécurité)
- API canonique (client)
  - `/worlds` pour toutes les opérations fonctionnelles (PUT/GET/LIST/DELETE)
  - `/saves` réservé au backend (versions/restauration)
- Identité monde
  - `worldId` = UUID v4, identique dans le path et `snapshot.metadata.worldId`
  - 1 monde = 1 sauvegarde principale (backups exclus)
- Limite de mondes
  - Maximum 10 mondes par utilisateur (`GameConstants.MAX_WORLDS`)
  - Validation côté client (UI) et backend (HTTP 429)
- Modèle de données
  - `SaveGame` est le modèle de persistance principal unifié
  - `World` existe comme wrapper utilitaire dans les services de persistance

## Couches côté client
- UI
  - WorldsScreen, composants réutilisables (WorldCard, badges d’état)
- Services de persistance
  - `GamePersistenceOrchestrator` (orchestration save/push/pull, arbitrage fraîcheur)
  - `SaveManagerAdapter` + `LocalSaveGameManager` (stockage local)
  - `CloudPersistenceAdapter` (HTTP vers `/worlds`)
  - `SavesFacade` (API simple pour l’UI; mapping d’états)
- Identité
  - `FirebaseAuthService` (ID Token pour appels protégés; écoute des changements d’auth)
- Utilitaires
  - `Logger` (logs structurés)

## Flux de données (sauvegarde/push)
1) L'UI déclenche une sauvegarde locale (write-through) via `SavesFacade` → `SaveManagerAdapter`
2) Si utilisateur Firebase connecté, push automatique vers `/worlds/:worldId` (garanti à la création de monde)
3) En cas de succès: nettoyage des flags; en cas d'échec: flags `pending_cloud_push_*` et `last_push_error_*` + `syncState='error'`
4) Retry automatique sur changement d'auth et au resume (et retry manuel par monde)

## Synchronisation automatique au login
- Listener Firebase Auth dans `main.dart` déclenche `SavesFacade.onPlayerConnected()` au login
- `postLoginSync()` compare fraîcheur local vs cloud pour chaque monde
- Import automatique des mondes cloud-only
- Désactivation cloud automatique au logout

## États de synchronisation (UX)
- Synchronisé, En attente, Erreur, Cloud uniquement
- Détermination: `SavesFacade.canonicalStateFor` (priorité Erreur > En attente > Synchronisé)

## Observabilité
- Logs structurés côté client: `worlds_put_attempt/success/failure` avec `worldId`, `latency_ms`, `http_code` (si connu), `cause_category`

## Backend (résumé)
- Express + Admin SDK
- Middleware d’auth: vérifie l’ID Token, extrait `uid`
- Endpoints principaux: `/worlds` (canonique), `/saves` (technique), `/analytics/events`

Pour les détails d’API, voir `docs/backend/firebase_functions_api.md`.
