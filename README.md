# 📎 PaperClip2

**Jeu de gestion incrémental (idle game)** développé avec Flutter et Firebase.

## 🎮 Description

PaperClip2 est un jeu de gestion où vous produisez et vendez des trombones pour développer votre empire industriel.

**Fonctionnalités principales :**
- 🏭 Production automatique et manuelle
- 📈 Système d'upgrades et de progression
- 💰 Marché dynamique avec fluctuations de prix
- ☁️ Sauvegarde cloud multi-appareils (Firebase)
- 🌍 Gestion multi-mondes (max 10 par utilisateur)
- 📱 Support Android, iOS, Web et Desktop

---

## 🚀 Démarrage Rapide

### Prérequis

- **Flutter SDK** ≥ 3.0.0 ([Installation](https://flutter.dev/docs/get-started/install))
- **Node.js** ≥ 18.x ([Installation](https://nodejs.org/))
- **Firebase CLI** : `npm install -g firebase-tools`
- **Compte Firebase** avec projet configuré

### Installation

```bash
# 1. Cloner le projet
git clone <repository-url>
cd PaperClip2

# 2. Installer les dépendances Flutter
flutter pub get

# 3. Créer le fichier de configuration
cp .env.example .env
# Éditer .env avec vos valeurs Firebase

# 4. Installer les dépendances backend
cd functions
npm install
cd ..
```

### Configuration Firebase

1. Créer un projet sur [Firebase Console](https://console.firebase.google.com/)
2. Télécharger `google-services.json` (Android) et placer dans `android/app/`
3. Télécharger `GoogleService-Info.plist` (iOS) et placer dans `ios/Runner/`
4. Éditer `.env` :
```env
APP_ENV=development
FUNCTIONS_API_BASE=https://us-central1-<your-project-id>.cloudfunctions.net/api
FEATURE_CLOUD_PER_PARTIE=true
```

---

## 🎯 Commandes Principales

### Développement

#### Lancer l'application

```bash
# Android (émulateur ou appareil connecté)
flutter run

# iOS (simulateur ou appareil connecté)
flutter run -d ios

# Web (Chrome)
flutter run -d chrome

# Windows Desktop
flutter run -d windows

# Spécifier un appareil
flutter devices                    # Lister les appareils
flutter run -d <device-id>        # Lancer sur un appareil spécifique
```

#### Backend (Émulateurs Firebase)

```bash
# Terminal séparé - Lancer les émulateurs
cd functions
firebase emulators:start

# Ou avec UI
firebase emulators:start --import=./emulator-data --export-on-exit
```

### Build Production

#### Android

```bash
# APK Release
flutter build apk --release

# APK de sortie : build/app/outputs/flutter-apk/app-release.apk

# App Bundle (pour Google Play Store)
flutter build appbundle --release

# Bundle de sortie : build/app/outputs/bundle/release/app-release.aab
```

#### iOS

```bash
# Build iOS
flutter build ios --release

# Ouvrir Xcode pour archiver et distribuer
open ios/Runner.xcworkspace
```

#### Web

```bash
# Build Web
flutter build web --release

# Fichiers de sortie : build/web/
```

#### Windows

```bash
# Build Windows
flutter build windows --release

# Exécutable : build/windows/runner/Release/
```

### Tests

```bash
# Tous les tests
flutter test

# Tests avec rapport détaillé
flutter test -r expanded

# Tests unitaires uniquement
flutter test test/unit/

# Tests d'intégration
flutter test test/integration_test/

# Tests backend
cd functions
npm test
```

### Déploiement

#### Backend Firebase Functions

```bash
cd functions

# Build
npm run build

# Déployer toutes les fonctions
firebase deploy --only functions

# Déployer une fonction spécifique
firebase deploy --only functions:api

# Déployer avec les règles Firestore
firebase deploy --only functions,firestore:rules
```

#### Application Mobile

**Android (Google Play Store) :**
1. Générer le bundle : `flutter build appbundle --release`
2. Uploader sur [Google Play Console](https://play.google.com/console)

**iOS (App Store) :**
1. Ouvrir Xcode : `open ios/Runner.xcworkspace`
2. Product → Archive
3. Distribuer via App Store Connect

### Maintenance

```bash
# Nettoyer le build
flutter clean
flutter pub get

# Nettoyer complètement (avec script)
.\clean-build.ps1

# Mettre à jour les dépendances
flutter pub upgrade

# Analyser le code
flutter analyze

# Formater le code
dart format lib/
```

---

## 📁 Structure du Projet

```
PaperClip2/
├── lib/                          # Code source Flutter
│   ├── constants/               # Constantes et configuration
│   ├── controllers/             # Contrôleurs de session
│   ├── domain/                  # Logique métier (DDD)
│   ├── gameplay/                # Mécanique de jeu
│   ├── models/                  # Modèles de données
│   ├── screens/                 # Écrans UI
│   ├── services/                # Services (persistance, auth, cloud)
│   │   ├── persistence/        # Gestion sauvegarde/sync
│   │   ├── auth/               # Authentification Firebase
│   │   └── cloud/              # Synchronisation cloud
│   ├── widgets/                 # Widgets réutilisables
│   └── main.dart                # Point d'entrée
│
├── functions/                    # Backend Firebase Functions
│   ├── src/                     # Code TypeScript
│   │   ├── index.ts            # Endpoints API
│   │   └── routes/             # Routes Express
│   └── test/                    # Tests backend
│
├── test/                         # Tests Flutter
│   ├── unit/                    # Tests unitaires
│   ├── integration_test/        # Tests d'intégration
│   └── e2e/                     # Tests end-to-end
│
├── docs/                         # Documentation
│   ├── 01-architecture/         # Architecture technique
│   ├── 02-guides-developpeur/   # Guides développeur
│   └── 03-guides-utilisateur/   # Guides utilisateur
│
├── android/                      # Configuration Android
├── ios/                          # Configuration iOS
├── web/                          # Configuration Web
├── windows/                      # Configuration Windows
│
├── assets/                       # Ressources (images, audio)
├── scripts/                      # Scripts utilitaires
└── archive/                      # Fichiers obsolètes
```

---

## 🏗️ Architecture Technique

### Stack Frontend
- **Framework** : Flutter 3.x (Dart)
- **State Management** : Provider
- **Stockage Local** : SharedPreferences
- **Navigation** : Flutter Navigator 2.0
- **Auth** : Firebase Auth

### Stack Backend
- **Runtime** : Firebase Functions v2 (Node.js 20)
- **Framework** : Express 4.x
- **Database** : Cloud Firestore
- **Auth** : Firebase Auth (JWT tokens)

### Persistance
- **ID-first** : Chaque monde identifié par UUID v4 (`partieId`)
- **Snapshot-first** : Source de vérité locale = `gameSnapshot`
- **Cloud-first** : Sync automatique au login
- **Multi-device** : Synchronisation cross-device via Firestore

---

## 📚 Documentation

### Pour Développeurs
- [Architecture Globale](docs/01-architecture/architecture-globale.md)
- [Guide Persistance](docs/02-guides-developpeur/guide-persistance.md)
- [API Backend](docs/02-guides-developpeur/api-backend.md)
- [Guide Déploiement](docs/02-guides-developpeur/guide-deployment.md)

### Pour Utilisateurs
- [Guide Sauvegarde Cloud](docs/03-guides-utilisateur/guide-sauvegarde-cloud.md)
- [FAQ](docs/03-guides-utilisateur/faq.md)

### Index Complet
- [Documentation Index](docs/INDEX.md)

---

## 🔧 Configuration

### Variables d'Environnement

#### Client Flutter (`.env`)
```env
APP_ENV=development                    # development | production
FUNCTIONS_API_BASE=https://...        # URL Firebase Functions
FEATURE_CLOUD_PER_PARTIE=true         # Activer sync cloud
```

#### Backend Functions (`functions/.env`)
```env
FIREBASE_PROJECT_ID=your-project-id
FIRESTORE_EMULATOR_HOST=localhost:8080  # Dev uniquement
```

---

## 🧪 Tests et Qualité

### Couverture de Tests
```bash
# Générer rapport de couverture
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### Analyse Statique
```bash
# Analyser le code
flutter analyze

# Vérifier le formatage
dart format --set-exit-if-changed lib/
```

---

## 🐛 Debugging

### Logs
```bash
# Logs Flutter en temps réel
flutter logs

# Logs Firebase Functions
firebase functions:log

# Logs Firestore (émulateur)
firebase emulators:start --inspect-functions
```

### DevTools
```bash
# Ouvrir Flutter DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

---

## 🚢 Déploiement sur Mobile

### Tester sur Appareil Physique

#### Android
```bash
# Activer le mode développeur sur l'appareil
# Connecter via USB
# Autoriser le débogage USB

flutter devices              # Vérifier que l'appareil est détecté
flutter run                  # Lancer l'app
```

#### iOS
```bash
# Connecter l'iPhone via USB
# Faire confiance à l'ordinateur sur l'iPhone

flutter devices              # Vérifier que l'appareil est détecté
flutter run                  # Lancer l'app
```

### Installer l'APK Manuellement

```bash
# 1. Build l'APK
flutter build apk --release

# 2. Installer via ADB
adb install build/app/outputs/flutter-apk/app-release.apk

# 3. Ou transférer l'APK sur l'appareil et installer
```

---

## 🤝 Contribution

### Workflow Git
```bash
# Créer une branche
git checkout -b feature/ma-fonctionnalite

# Commit
git add .
git commit -m "feat: description de la fonctionnalité"

# Push
git push origin feature/ma-fonctionnalite
```

### Conventions de Commit
- `feat:` Nouvelle fonctionnalité
- `fix:` Correction de bug
- `docs:` Documentation
- `refactor:` Refactoring
- `test:` Ajout/modification de tests
- `chore:` Tâches de maintenance

---

## 📄 Licence

Propriétaire - Tous droits réservés

---

## 📞 Support

Pour toute question ou problème :
- Consulter la [FAQ](docs/03-guides-utilisateur/faq.md)
- Ouvrir une issue sur GitHub
- Consulter la [documentation complète](docs/INDEX.md)

---

**Version** : 1.0.3  
**Dernière mise à jour** : Mars 2026
