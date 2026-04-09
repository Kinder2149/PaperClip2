# 🔌 API BACKEND - FIREBASE FUNCTIONS

**Projet** : PaperClip2  
**Date** : 15 janvier 2026  
**Dernière mise à jour** : 20 janvier 2026  
**Statut** : ✅ Production

---

## 🎯 VUE D'ENSEMBLE

### Stack Technique
- **Firebase Functions v2** (2nd generation)
- **Node.js 20** LTS
- **Express 4.x** (framework HTTP)
- **Firebase Admin SDK** (Firestore, Auth)
- **Cloud Firestore** (base de données NoSQL)

### URL de base
```
Production: https://api-g3tpwosnaq-uc.a.run.app
Émulateurs: http://localhost:5001/paperclip-98294/us-central1/api
```

---

## 🔐 AUTHENTIFICATION

### Header requis
```
Authorization: Bearer <Firebase_ID_Token>
```

### Obtention du token
```dart
// Flutter
final token = await FirebaseAuthService.instance.getIdToken();
```

### Erreurs d'authentification
- **401** `missing_or_invalid_authorization` - Header absent/mal formé
- **401** `auth_failed` - Token invalide/expiré

---

## 📊 ENDPOINTS PRINCIPAUX

### 🏥 Health Check
```http
GET /health
```
**Réponse** : `{ "status": "ok" }`  
**Auth** : Non requise

---

### 🌍 Mondes (API Canonique)

#### Créer/Mettre à jour un monde
```http
PUT /worlds/{worldId}
Content-Type: application/json
Authorization: Bearer <token>

{
  "snapshot": {
    "metadata": { "worldId": "uuid-v4" },
    "core": { ... },
    "stats": { ... }
  },
  "name": "Mon monde",
  "game_version": "1.0.3"
}
```

**Réponse 200** :
```json
{
  "ok": true,
  "world_id": "uuid-v4",
  "updated_at": "2026-01-15T21:30:00Z",
  "size_bytes": 12345
}
```

**Erreurs** :
- **400** `invalid_world_id` - UUID invalide
- **400** `invalid_snapshot` - Snapshot manquant/invalide
- **422** `metadata_partie_id_mismatch` - worldId incohérent
- **429** `max_worlds_exceeded` - Limite de 10 mondes atteinte
- **500** `save_failed` - Erreur serveur

---

#### Récupérer un monde
```http
GET /worlds/{worldId}
Authorization: Bearer <token>
```

**Réponse 200** :
```json
{
  "world_id": "uuid-v4",
  "version": 5,
  "snapshot": { ... },
  "updated_at": "2026-01-15T21:30:00Z",
  "name": "Mon monde",
  "game_version": "1.0.3",
  "game_mode": "INFINITE"
}
```

**Erreurs** :
- **400** `invalid_world_id`
- **404** `not_found`
- **500** `load_failed`

---

#### Lister les mondes
```http
GET /worlds?page=1&limit=50
Authorization: Bearer <token>
```

**Réponse 200** :
```json
{
  "items": [
    {
      "world_id": "uuid-v4",
      "updated_at": "2026-01-15T21:30:00Z",
      "name": "Mon monde",
      "game_version": "1.0.3",
      "game_mode": "INFINITE"
    }
  ],
  "page": 1,
  "limit": 50,
  "total": null
}
```

---

#### Supprimer un monde
```http
DELETE /worlds/{worldId}
Authorization: Bearer <token>
```

**Réponse** : **204** (succès)  
**Erreurs** : **404** (déjà supprimé, idempotent)

---

### 📈 Analytics

#### Envoyer un événement
```http
POST /analytics/events
Content-Type: application/json
Authorization: Bearer <token>

{
  "name": "world_created",
  "properties": {
    "world_id": "uuid-v4",
    "mode": "infinite"
  },
  "timestamp": "2026-01-15T21:30:00Z"
}
```

**Réponse** : **202** (toujours, même en cas d'erreur interne)

---

## 🚦 RATE LIMITING

### Limites par utilisateur
- **100 requêtes/minute** par UID Firebase
- **Fenêtre** : 60 secondes glissantes
- **Réponse 429** :
```json
{
  "error": "RATE_LIMIT_EXCEEDED",
  "message": "Trop de requêtes. Veuillez réessayer dans 1 minute.",
  "retryAfter": 60
}
```

### Headers de réponse
- `RateLimit-Limit`: 100
- `RateLimit-Remaining`: Nombre restant
- `RateLimit-Reset`: Timestamp de réinitialisation

### Limites globales
- **300 requêtes/minute** par IP
- Exemption : `/health`

---

## 📦 MODÈLE DE DONNÉES FIRESTORE

```
players/{uid}/
  saves/{worldId}/
    state/
      current/     { version, snapshot, updatedAt, name, game_version }
      meta/        { lastVersion, nextVersion, updatedAt }
    versions/
      {n}/         { version, snapshot, createdAt }
  analytics/
    {autoId}/      { name, properties, timestamp, receivedAt }
```

---

## 🔑 CONTRAT D'AUTHENTIFICATION

### Identité racine : UID Firebase
- **Source de vérité** : Firebase ID Token
- **Ownership** : Déterminé exclusivement par le backend via `uid`
- **Partition** : `players/{uid}/`

### Identifiants et leurs rôles

| Identifiant | Rôle | Usage interdit |
|-------------|------|----------------|
| **uid Firebase** | Identité racine, ownership | Utilisation côté client pour autorisation |
| **playerId Google** | UX uniquement (affichage) | Authentification/autorisation backend |
| **worldId (UUID v4)** | Identifiant de ressource | Mécanisme d'auth, déduction d'ownership |
| **saveId local** | Gestion locale uniquement | Accès serveur, ownership |

### Règles strictes
- ✅ Ownership déterminé par le backend via `uid`
- ❌ Le client ne déduit JAMAIS l'ownership localement
- ❌ `playerId` n'a AUCUNE valeur d'ownership
- ❌ Aucune authentification alternative acceptée

---

## 🛠️ DÉVELOPPEMENT LOCAL

### Démarrer les émulateurs
```bash
cd functions
npm run serve
```

**Émulateurs disponibles** :
- Functions : http://localhost:5001
- Firestore : http://localhost:8080
- Auth : http://localhost:9099
- UI : http://localhost:4000

### Variables d'environnement
Créer `functions/.env` :
```env
FIREBASE_PROJECT_ID=paperclip-98294
FIRESTORE_EMULATOR_HOST=localhost:8080
FIREBASE_AUTH_EMULATOR_HOST=localhost:9099
```

---

## 🚀 DÉPLOIEMENT

### Build
```bash
cd functions
npm run build
```

### Déployer en production
```bash
npm run deploy
```

### Configuration production
```bash
firebase functions:config:set app.max_worlds=10
firebase functions:config:set app.max_snapshot_size_mb=5
```

---

## 📝 EXEMPLES D'UTILISATION

### Flutter - Sauvegarder un monde
```dart
final adapter = CloudPersistenceAdapter();
await adapter.pushById(
  partieId: worldId,
  snapshot: state.toSnapshot().toJson(),
  metadata: {
    'name': 'Mon monde',
    'game_version': GameConstants.VERSION,
  },
);
```

### cURL - Récupérer un monde
```bash
curl -H "Authorization: Bearer $TOKEN" \
  "https://api-g3tpwosnaq-uc.a.run.app/worlds/$WORLD_ID"
```

---

## ⚠️ CONTRAINTES IMPORTANTES

### UUID v4 requis
- `worldId` doit être un UUID v4 valide
- Cohérence entre URL et `snapshot.metadata.worldId`

### Limite de mondes
- **Maximum 10 mondes** par utilisateur
- Erreur 429 si dépassement

### Taille des snapshots
- **Maximum 5 MB** par snapshot
- Validation côté serveur

### Timestamps serveur
- Tous les timestamps sont générés côté serveur
- `serverTimestamp()` pour cohérence

---

## 🔍 CODES D'ERREUR COMPLETS

| Code | Description |
|------|-------------|
| **400** | `invalid_world_id`, `invalid_snapshot`, `invalid_snapshot_structure` |
| **401** | `missing_or_invalid_authorization`, `auth_failed` |
| **404** | `not_found` |
| **422** | `metadata_partie_id_mismatch` |
| **429** | `max_worlds_exceeded`, `RATE_LIMIT_EXCEEDED` |
| **500** | `save_failed`, `load_failed`, `delete_failed` |

---

## 📚 VOIR AUSSI

- **Architecture globale** : `01-architecture/architecture-globale.md`
- **Guide cloud sync** : `guide-cloud-sync.md`
- **Contrats auth** : `01-architecture/contrats-auth.md`

---

**Dernière mise à jour** : 20 janvier 2026  
**Version API** : 1.0  
**Région** : us-central1  
**Note** : Champ `game_mode` ajouté le 20/01/2026
