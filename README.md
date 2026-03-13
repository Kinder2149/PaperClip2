# 📎 PaperClip2

**Jeu de gestion incrémental (idle game)** développé avec Flutter et Firebase.

## 🎮 Description

PaperClip2 est un jeu de gestion où vous produisez et vendez des trombones pour développer votre empire industriel. Le jeu propose :
- Production automatique et manuelle
- Système d'upgrades et de progression
- Marché dynamique avec fluctuations de prix
- Sauvegarde cloud multi-appareils
- Limite de 10 mondes par utilisateur

## 📚 Documentation

**Documentation complète** : [`documentation/README.md`](documentation/README.md)

### Accès rapide
- **Architecture** : [`documentation/01-architecture/`](documentation/01-architecture/)
- **Guides développeur** : [`documentation/02-guides-developpeur/`](documentation/02-guides-developpeur/)
- **Guides utilisateur** : [`documentation/03-guides-utilisateur/`](documentation/03-guides-utilisateur/)
- **Rapports missions** : [`documentation/04-rapports-missions/`](documentation/04-rapports-missions/)

## 🏗️ Architecture

### Backend : Firebase Functions (Production)

**Stack technique confirmée :**
- **Firebase Functions v2** (2nd generation)
- **Node.js 20** LTS
- **Express 4.x** (framework HTTP)
- **Firebase Admin SDK** (Firestore, Auth)
- **Cloud Firestore** (base de données NoSQL)
- **Firebase Auth** (authentification utilisateur)

**Endpoints exposés :**
- Base URL : `https://[region]-[project-id].cloudfunctions.net/api`
- Configuration client : Variable d'environnement `FUNCTIONS_API_BASE`

⚠️ **Note importante** : Le projet utilise **exclusivement Firebase Functions** comme backend.
Toute mention de FastAPI, Render, ou autres backends dans d'anciennes notes est obsolète et doit être ignorée.

### Frontend
- **Flutter** (Dart)
- **Provider** (gestion d'état)
- **SharedPreferences** (stockage local)

### Authentification
- En-tête HTTP : `Authorization: Bearer <Firebase ID Token>`
- Firebase Auth comme source unique de vérité
- Documentation : `docs/backend/firebase_functions_api.md`

### Synthèse persistance & identité (client)

- Orchestrateur client: `GamePersistenceOrchestrator` (ID-first, snapshot-first)
- Stockage local: `LocalSaveGameManager` (SharedPreferences), clé snapshot: `gameSnapshot`
- API canonique côté client: `/worlds` (création, mise à jour, lecture, listing, suppression). Détails: `docs/backend/firebase_functions_api.md` (section "API canonique de persistance côté client").
- API technique backend: `/saves` (versions/restauration legacy). Le client ne l’appelle pas directement. Détails: même document.
- Rôle de `playerId`: prérequis opérationnel côté client (gating) et métadonnée de contexte; ni ownership ni sécurité. Détails: `docs/backend/firebase_functions_api.md` (section "Rôle et statut contractuel de playerId").
- Cycle de vie d’un monde (client): états et transitions réelles (`local_only`, `pending_identity`, `cloud_pending`, `cloud_synced`, `cloud_error`, `cloud-only`). Détails: `docs/backend/firebase_functions_api.md` (section "Cycle de vie d’un monde – Client").

## 🚀 Getting Started

### Prérequis

- **Flutter SDK** ≥ 3.0.0
- **Node.js** ≥ 18.x (pour Firebase Functions)
- **Firebase CLI** : `npm install -g firebase-tools`
- **Compte Firebase** avec projet configuré

### Installation

#### 1. Clone le projet
```bash
git clone <repository-url>
cd paperclip2
```

#### 2. Configuration Flutter
```bash
# Installer les dépendances
flutter pub get

# Créer le fichier .env
cp .env.example .env
```

Éditer `.env` avec vos valeurs :
```env
APP_ENV=development
FUNCTIONS_API_BASE=https://us-central1-<your-project-id>.cloudfunctions.net/api
```

**Note :** Les clés Firebase sont gérées par `google-services.json` (Android) et `GoogleService-Info.plist` (iOS).

#### 3. Configuration Backend
```bash
cd functions
npm install

# Créer le fichier .env (optionnel pour développement local)
cp .env.example .env
```

#### 4. Lancer en développement

**Terminal 1 - Backend (émulateurs Firebase) :**
```bash
cd functions
firebase emulators:start
```

**Terminal 2 - Flutter :**
```bash
flutter run
```

### Variables d'Environnement

#### Client Flutter (`.env`)
- `APP_ENV` : Environnement (`development` | `production`)
- `FUNCTIONS_API_BASE` : URL de base des Firebase Functions

#### Backend Functions (`functions/.env`)
- `FIREBASE_PROJECT_ID` : ID du projet Firebase
- `FIRESTORE_EMULATOR_HOST` : Host de l'émulateur Firestore (dev uniquement)

## 📦 Build et Déploiement

### Build Production

**Android :**
```bash
flutter build apk --release
# APK disponible dans : build/app/outputs/flutter-apk/app-release.apk
```

**iOS :**
```bash
flutter build ios --release
```

### Déploiement Backend

```bash
cd functions
npm ci
npm run build
firebase deploy --only functions:api
```

Voir aussi : `functions/package.json` et `docs/backend/firebase_functions_api.md`

## Démarrage de l’app

1. Configurer le fichier `.env` (voir section Configuration).
2. Lancer l’application Flutter (Android / iOS / Web / Desktop).
3. Les services cloud utilisent les endpoints HTTP onRequest exposés par Functions.
4. Au démarrage, l’application vérifie la présence de `FUNCTIONS_API_BASE` (échec immédiat si absent).

## Observabilité & diagnostic

- Runbook diagnostic persistance/synchro: `docs/runbook_persistence_sync.md`
  - États `syncState`, flags SharedPreferences (`pending_cloud_push_*`, `pending_identity_*`, `last_push_error_*`)
  - Erreurs transport `push_failed_<code>` et arbitrage fraîcheur
  - Procédures push/import/restore et invariants (ID-first, snapshot-first)

## 📚 Documentation

### Documentation Technique
- [Architecture Globale](docs/ARCHITECTURE_GLOBALE.md) - Vue d'ensemble du système
- [Guide Persistance Client](docs/CLIENT_PERSISTENCE_GUIDE.md) - Sauvegarde et synchronisation
- [API Backend](docs/backend/firebase_functions_api.md) - Endpoints et contrats
- [Audit Pré-Production](docs/AUDIT_COMPLET_PRE_PROD.md) - État du projet et checklist

### Documentation Utilisateur
- [Guide Cloud Save](docs/USER_GUIDE_CLOUD_SAVE.md) - Utilisation de la sauvegarde cloud

### Documentation Développeur
- [Plan Nettoyage Legacy](docs/PLAN_NETTOYAGE_LEGACY.md) - Refactoring en cours
- [Runbook Diagnostic](docs/runbook_persistence_sync.md) - Diagnostic et résolution de problèmes

## Documentation produit (PHASE 5)

- Cycle de vie d’un monde: `docs/PHASE5_CYCLE_VIE_MONDE.md`
- Garanties de persistance: `docs/PHASE5_GARANTIES_PERSISTENCE.md`
- Récupérabilité cross‑device: `docs/PHASE5_RECUPERABILITE_CROSS_DEVICE.md`

Notes d’alignement:
- ID-first strict: chaque monde est identifié par un `partieId` (UUID v4 recommandé).
- Snapshot-first: la source de vérité locale est `gameSnapshot`.
- Ownership et sécurité: serveur‑side via Firebase Auth uid (backend Functions).

## 🧪 Tests

### Tests Flutter
```bash
# Tous les tests
flutter test

# Tests avec rapport détaillé
flutter test -r expanded

# Tests unitaires spécifiques
flutter test test/unit/
```

### Tests Backend
```bash
cd functions
npm test

# Tests E2E spécifiques
npm test -- worlds_limit.test.ts
```

## 🏛️ Structure du Projet

```bash
paperclip2/
├── lib/                      # Code Flutter
│   ├── constants/           # Constantes et configuration
│   ├── controllers/         # Contrôleurs de session
│   ├── managers/            # Managers métier (Market, Production, etc.)
│   ├── models/              # Modèles de données
│   ├── screens/             # Écrans UI
│   ├── services/            # Services (persistance, auth, cloud)
│   ├── widgets/             # Widgets réutilisables
│   └── main.dart            # Point d'entrée
├── functions/               # Backend Firebase Functions
│   ├── src/                # Code TypeScript
│   │   └── index.ts        # Endpoints API
│   └── test/               # Tests backend
├── docs/                    # Documentation
├── test/                    # Tests Flutter
└── .env                     # Configuration (non versionné)
```

## 🔑 Concepts Clés

### Persistance
- **ID-first** : Chaque monde est identifié par un `worldId` (UUID v4)
- **Snapshot-first** : Source de vérité locale = `gameSnapshot`
- **Cloud-first** : Synchronisation automatique au login
- **Limite** : Maximum 10 mondes par utilisateur

### Synchronisation
- **États** : `local_only`, `cloud_pending`, `cloud_synced`, `cloud_error`, `cloud-only`
- **Push automatique** : À la création de monde (si connecté)
- **Sync automatique** : Au login Firebase Auth
- **Retry** : Automatique sur changement d'auth et au resume

### Sécurité
- **Ownership** : Strict via Firebase Auth `uid`
- **Validation** : UUID v4 obligatoire pour `worldId`
- **Rate limiting** : À implémenter (recommandé : 100 req/min)

## 🤝 Contribution

Voir [CONTRIBUTING.md](CONTRIBUTING.md) (à créer)

## 📄 Licence

Voir [LICENSE]

---
