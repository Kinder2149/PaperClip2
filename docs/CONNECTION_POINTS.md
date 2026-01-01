# CONNECTION_POINTS

Ce document recense tous les points de connexion (variables d’environnement, fichiers et responsabilités) côté Frontend (Flutter) et Backend (FastAPI sur Fly.io) pour PaperClip.

## 1. Variables d’environnement attendues

Aucune variable sensible ne doit être commitée. Toutes les valeurs sont fournies par Firebase et Fly.io au runtime.

### Backend (Fly.io)
- FIREBASE_CREDENTIALS_JSON (secret)
  - Contenu JSON du compte de service Firebase Admin.
  - Alternative: GOOGLE_APPLICATION_CREDENTIALS.
  - Utilisation: server_fly/app/main.py (initialisation Firebase Admin) — lignes ~15–28.
- GOOGLE_APPLICATION_CREDENTIALS (secret)
  - Chemin absolu vers un fichier JSON de compte de service dans le conteneur.
  - Alternative à FIREBASE_CREDENTIALS_JSON.
  - Utilisation: server_fly/app/main.py — lignes ~21–28.
- DATABASE_URL (secret)
  - Chaîne de connexion Postgres injectée par `flyctl postgres attach`.
  - Utilisation: server_fly/app/main.py — lignes ~54–56 (création engine SQLAlchemy).
- PORT (optionnel; par défaut 8080)
  - Port d’écoute du conteneur Uvicorn.
  - Utilisation: server_fly/Dockerfile (ENV PORT=8080) et commande uvicorn.

### Frontend (Flutter)
- Aucune variable nécessaire pour l’auth Firebase côté app (configuration via google-services.json).
- .env n’est plus requis pour l’auth ni pour des backends legacy.

## 2. Ce qui est fourni par Firebase
- google-services.json (Android)
  - À placer dans android/app/ (non versionné, contient les identifiants publics du projet Firebase `paperclip-98294`).
- Compte de service (JSON) pour Firebase Admin
  - Valeur à injecter dans `FIREBASE_CREDENTIALS_JSON` (ou chemin via `GOOGLE_APPLICATION_CREDENTIALS`).
- ID Token Firebase
  - Émis côté client après connexion Google. Consommé par le backend via Firebase Admin.

## 3. Ce qui est fourni par Fly.io
- DATABASE_URL
  - Injecté par `flyctl postgres attach`.
- Gestion des secrets
  - `flyctl secrets set FIREBASE_CREDENTIALS_JSON=...`.
- Exécution / réseau
  - Décide de l’URL publique et du routage vers le conteneur (port 8080 exposé).

## 4. Où ces valeurs sont utilisées (références code)

### Backend
- Initialisation Firebase Admin: server_fly/app/main.py
  - Lignes ~15–28: choix de la source d’identifiants (FIREBASE_CREDENTIALS_JSON, GOOGLE_APPLICATION_CREDENTIALS, ADC).
- Vérification du token (toutes les routes protégées): server_fly/app/main.py
  - Lignes ~37–50: `verify_firebase_bearer()` décode l’ID Token via Firebase Admin, sinon 401.
- Connexion DB: server_fly/app/main.py
  - Lignes ~54–56: création du `engine` SQLAlchemy à partir de `DATABASE_URL`.
- Création schéma minimal: server_fly/app/main.py
  - Lignes ~85–90: `Base.metadata.create_all(bind=engine)`.

### Frontend
- Initialisation Firebase: lib/main.dart
  - Lignes ~129–133: `Firebase.initializeApp()`.
- Auth unique (Firebase): lib/services/auth/firebase_auth_service.dart
  - Méthodes `signInWithGoogle()`, `getIdToken()`, `authStateChanges()`.
- Client HTTP protégé (centralisation du token + gestion 401/403/erreurs réseau):
  - lib/services/backend/protected_http_client.dart

## 5. Actions humaines requises
- Firebase Console
  - Activer le provider Google (Auth > Méthode de connexion > Google).
  - Déclarer les empreintes SHA‑1/SHA‑256 de la clé de signature Android.
  - Télécharger `google-services.json` et le placer dans `android/app/` (non versionné).
  - Créer un compte de service et copier son JSON dans `FIREBASE_CREDENTIALS_JSON` (secret Fly.io) ou fournir un chemin via `GOOGLE_APPLICATION_CREDENTIALS`.
- Fly.io
  - Créer Postgres et attacher à l’app: `flyctl postgres create` puis `flyctl postgres attach` (injecte `DATABASE_URL`).
  - Injecter le secret Firebase Admin: `flyctl secrets set FIREBASE_CREDENTIALS_JSON=...`.
  - `flyctl deploy` puis tests: `/health`, `/health/auth`, `/db/health`, `/saves/*`, `/analytics/events`.

## 6. Points d’intégration côté Frontend
- Utiliser `FirebaseAuthService.getIdToken()` pour chaque appel backend protégé.
- Utiliser `ProtectedHttpClient` pour centraliser:
  - Ajout du header `Authorization: Bearer <ID_TOKEN>`.
  - Gestion 401 (session expirée) et 403 (interdit) via `NotificationManager`.
  - Gestion des erreurs réseau (notification utilisateur minimale).

## 7. Interdits vérifiés (architecture figée)
- Aucun JWT custom maison.
- Aucun fallback (pas de clé statique/API Key, pas de mode offline serveur).
- Aucun filesystem côté backend.
- Aucun Supabase / Render / legacy.
- Aucune logique métier dans le backend (seulement vérification d’auth et persistance brute).
