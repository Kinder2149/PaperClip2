# 📚 Documentation PaperClip2

Index complet de la documentation du projet.

---

## 🚀 Démarrage Rapide

- [Guide Rapide](GUIDE_RAPIDE.md) - Commencer en 5 minutes
- [README Principal](../README.md) - Vue d'ensemble et commandes

---

## 🏗️ Architecture

### Documents Principaux
- [Architecture Globale](01-architecture/architecture-globale.md) - Vue d'ensemble du système
- [Persistance Cloud](01-architecture/persistance-cloud.md) - Système de sauvegarde et synchronisation
- [Décisions Persistance](01-architecture/DECISIONS_PERSISTANCE.md) - Choix techniques et justifications
- [Contrats Auth](01-architecture/contrats-auth.md) - Authentification et sécurité
- [Conventions Nommage](01-architecture/conventions-nommage.md) - Standards de code

### Concepts Clés
- **Entreprise unique** : 1 utilisateur = 1 entreprise persistante
- **ID-first** : Entreprise identifiée par UUID v4 (`enterpriseId`)
- **Snapshot-first** : Source de vérité locale = `gameSnapshot`
- **Cloud always wins** : Le cloud écrase le local au login
- **Multi-device** : Support cross-device via Firestore

---

## 👨‍💻 Guides Développeur

### Persistance et Synchronisation
- [Guide Persistance](02-guides-developpeur/guide-persistance.md) - Gestion des sauvegardes
- [Flux Persistance](02-guides-developpeur/flux-persistance.md) - Diagrammes et workflows
- [Guide Complet Sauvegarde Cloud](02-guides-developpeur/GUIDE_COMPLET_SAUVEGARDE_CLOUD.md) - Documentation exhaustive

### API et Backend
- [API Backend](02-guides-developpeur/api-backend.md) - Endpoints Firebase Functions
- [Guide Déploiement](02-guides-developpeur/guide-deployment.md) - Déploiement production

### Workflows Courants

#### Créer une Nouvelle Entreprise
```dart
// 1. Créer via GameState
await gameState.createNewEnterprise(name: "Mon Entreprise");

// 2. Sauvegarder localement
await GamePersistenceOrchestrator.instance.requestLifecycleSave(gameState);

// 3. Push cloud automatique (si Firebase connecté)
await GamePersistenceOrchestrator.instance.pushCloudForState(gameState);
```

#### Charger l'Entreprise Existante
```dart
// 1. Charger depuis local ou cloud
final enterpriseId = gameState.enterpriseId;
await GamePersistenceOrchestrator.instance.loadGameById(gameState, enterpriseId);

// 2. Sync cloud automatique au login (cloud always wins)
// Géré automatiquement par AppBootstrapController

// 3. Démarrer session
runtimeActions.startSession();
```

#### Synchroniser avec le Cloud
```dart
// Sync automatique au login (cloud always wins)
// Géré par AppBootstrapController.bootstrap()

// Push manuel si nécessaire
await GamePersistenceOrchestrator.instance.pushCloudForState(gameState);
```

---

## 👥 Guides Utilisateur

- [Guide Sauvegarde Cloud](03-guides-utilisateur/guide-sauvegarde-cloud.md) - Utiliser la sauvegarde cloud
- [FAQ](03-guides-utilisateur/faq.md) - Questions fréquentes

### Fonctionnalités Utilisateur

#### Entreprise Unique
- **1 entreprise** par utilisateur
- Nom personnalisable et modifiable
- Synchronisation cloud automatique
- Accès depuis n'importe quel appareil

#### Progression Offline
- Production continue pendant **2h maximum** en arrière-plan
- Simulation au retour de l'application
- Popup récapitulative des gains

#### Smart Routing
- Chargement automatique de la dernière partie jouée
- Navigation fluide entre les mondes
- Pas besoin de repasser par l'écran de sélection

---

## 🔧 Configuration

### Variables d'Environnement

#### Client (`.env`)
```env
APP_ENV=development
FUNCTIONS_API_BASE=https://us-central1-<project-id>.cloudfunctions.net/api
FEATURE_CLOUD_PER_PARTIE=true
MISSION_LOG=off
```

#### Backend (`functions/.env`)
```env
FIREBASE_PROJECT_ID=your-project-id
FIRESTORE_EMULATOR_HOST=localhost:8080
```

### Firebase Setup
1. Créer projet sur [Firebase Console](https://console.firebase.google.com/)
2. Activer Authentication (Google, Email/Password)
3. Activer Firestore Database
4. Activer Functions
5. Télécharger fichiers de config :
   - `google-services.json` → `android/app/`
   - `GoogleService-Info.plist` → `ios/Runner/`

---

## 🧪 Tests

### Structure des Tests
```
test/
├── unit/                    # Tests unitaires
│   ├── models/             # Tests des modèles
│   ├── services/           # Tests des services
│   └── gameplay/           # Tests logique métier
│
├── integration_test/        # Tests d'intégration
│   ├── persistence/        # Tests sauvegarde/sync
│   ├── auth/               # Tests authentification
│   └── gameplay/           # Tests gameplay complet
│
└── e2e/                     # Tests end-to-end
    └── scenarios/          # Scénarios utilisateur
```

### Commandes
```bash
# Tests unitaires
flutter test test/unit/

# Tests d'intégration
flutter test test/integration_test/

# Tests backend
cd functions && npm test

# Couverture
flutter test --coverage
```

---

## 🐛 Debugging et Diagnostic

### Logs
```bash
# Logs Flutter
flutter logs

# Logs Firebase Functions
firebase functions:log

# Logs avec filtre
flutter logs | grep "WORLD-SWITCH"
```

### Outils de Diagnostic
- **DevTools** : `flutter pub global run devtools`
- **Firebase Console** : Monitoring temps réel
- **Firestore Emulator UI** : `http://localhost:4000`

### Problèmes Courants

#### Sync Cloud Échoue
1. Vérifier connexion internet
2. Vérifier authentification Firebase
3. Consulter `syncState` dans l'UI
4. Vérifier logs : `[cloud][error]`

#### Partie Non Chargée
1. Vérifier que `partieId` est valide (UUID v4)
2. Vérifier existence locale : SharedPreferences
3. Vérifier existence cloud : Firestore `/worlds/{partieId}`
4. Consulter `LastPlayedTracker`

#### Progression Offline Incorrecte
1. Vérifier `lastActiveAt` dans les métadonnées
2. Vérifier limite 2h (`OFFLINE_MAX_DURATION`)
3. Consulter logs : `[Runtime] recoverOffline()`

---

## 📦 Build et Déploiement

### Android
```bash
# Debug
flutter build apk --debug

# Release
flutter build apk --release

# App Bundle (Play Store)
flutter build appbundle --release
```

### iOS
```bash
# Build
flutter build ios --release

# Archive (Xcode)
open ios/Runner.xcworkspace
# Product → Archive
```

### Web
```bash
flutter build web --release
```

### Backend
```bash
cd functions
npm run build
firebase deploy --only functions
```

---

## 🔐 Sécurité

### Authentification
- Firebase Auth comme source unique de vérité
- JWT tokens pour API calls
- Header : `Authorization: Bearer <token>`

### Ownership
- Strict via `uid` Firebase Auth
- Validation serveur-side (Firestore Rules)
- Pas de confiance client-side

### Validation
- UUID v4 obligatoire pour `partieId`
- Snapshot validation avant persistance
- Limite 10 mondes par utilisateur (serveur-side)

---

## 📊 Métriques et Monitoring

### Métriques Clés
- Taux de réussite sync cloud
- Temps de chargement des mondes
- Fréquence des sauvegardes
- Erreurs de persistance

### Outils
- Firebase Analytics
- Firebase Performance Monitoring
- Custom logs (`Logger.forComponent()`)

---

## 🗺️ Roadmap

### Fonctionnalités Futures
- [ ] Achievements cross-device
- [ ] Leaderboards globaux
- [ ] Mode compétitif amélioré
- [ ] Partage de mondes
- [ ] Import/Export manuel

### Améliorations Techniques
- [ ] Rate limiting API
- [ ] Cache intelligent sync
- [ ] Compression snapshots
- [ ] Migration automatique versions

---

## 📞 Support

### Ressources
- [README Principal](../README.md)
- [FAQ Utilisateur](03-guides-utilisateur/faq.md)
- [Guide Rapide](GUIDE_RAPIDE.md)

### Contact
- Issues GitHub
- Documentation inline (code)
- Logs de debug

---

**Dernière mise à jour** : Mars 2026  
**Version documentation** : 2.0
