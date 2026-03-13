# 🔥 BACKEND FIREBASE FUNCTIONS - PAPERCLIP2

**Stack** : Firebase Functions v2 + Node.js 20 + Express 4  
**Région** : us-central1  
**Statut** : ✅ Production

---

## 🚀 DÉMARRAGE RAPIDE

### Installation
```bash
npm install
```

### Développement local (émulateurs)
```bash
npm run serve
```

### Build
```bash
npm run build
```

### Déploiement production
```bash
npm run deploy
```

### Tests
```bash
npm test              # Tests unitaires
npm run test:e2e      # Tests E2E
```

---

## 📁 STRUCTURE

```
functions/
├── src/
│   └── index.ts          # Point d'entrée principal
├── lib/                  # Code compilé (généré)
├── test/
│   └── e2e/             # Tests E2E
├── package.json
├── tsconfig.json
└── .env                 # Variables locales (non versionné)
```

---

## 🔧 CONFIGURATION

### Variables d'environnement locales
Créer `functions/.env` :
```env
FIREBASE_PROJECT_ID=paperclip-98294
FIRESTORE_EMULATOR_HOST=localhost:8080
FIREBASE_AUTH_EMULATOR_HOST=localhost:9099
```

### Configuration production
```bash
firebase functions:config:set app.max_worlds=10
firebase functions:config:set app.max_snapshot_size_mb=5
```

---

## 🌐 ÉMULATEURS

### Démarrer
```bash
npm run serve
```

### URLs
- **Functions** : http://localhost:5001
- **Firestore** : http://localhost:8080
- **Auth** : http://localhost:9099
- **UI** : http://localhost:4000

---

## 📚 DOCUMENTATION COMPLÈTE

**Voir** : `../documentation/02-guides-developpeur/api-backend.md`

### Endpoints principaux
- `GET /health` - Health check
- `PUT /worlds/{worldId}` - Créer/mettre à jour un monde
- `GET /worlds/{worldId}` - Récupérer un monde
- `GET /worlds` - Lister les mondes
- `DELETE /worlds/{worldId}` - Supprimer un monde
- `POST /analytics/events` - Envoyer un événement analytics

---

## 🔐 AUTHENTIFICATION

Tous les endpoints (sauf `/health`) requièrent :
```
Authorization: Bearer <Firebase_ID_Token>
```

---

## 🚦 LIMITES

- **100 requêtes/minute** par utilisateur
- **10 mondes maximum** par utilisateur
- **5 MB maximum** par snapshot

---

## 📊 SCRIPTS NPM

| Script | Description |
|--------|-------------|
| `build` | Compile TypeScript → `lib/` |
| `serve` | Démarre les émulateurs |
| `deploy` | Déploie en production |
| `test` | Lance les tests unitaires |
| `test:e2e` | Lance les tests E2E |
| `lint` | Vérifie le code |

---

## 🔗 LIENS UTILES

- **Documentation API** : `../documentation/02-guides-developpeur/api-backend.md`
- **Architecture** : `../documentation/01-architecture/architecture-globale.md`
- **Firebase Console** : https://console.firebase.google.com/project/paperclip-98294

---

**Dernière mise à jour** : 15 janvier 2026
