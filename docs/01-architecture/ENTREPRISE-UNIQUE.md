# Architecture Entreprise Unique - Référence Complète

**Projet** : PaperClip2  
**Date création** : 7 avril 2026  
**Statut** : ✅ Implémenté (traces à nettoyer)  
**Autorité** : Document de référence technique

---

## 🎯 DÉCISION ARCHITECTURALE FIGÉE

### Principe fondamental
**1 utilisateur = 1 entreprise persistante**

Cette décision remplace l'ancienne architecture multi-mondes (multi-save) par un système simplifié et contrôlé.

### Justification
- **Simplicité** : Élimine la complexité de gestion multi-save
- **UX cohérente** : Pas de confusion entre "mondes" ou "parties"
- **Performance** : Moins de requêtes cloud, moins de stockage local
- **Gameplay** : Focus sur une seule entreprise à développer

---

## 🏗️ ARCHITECTURE TECHNIQUE

### Identifiant Unique

**`enterpriseId`** : UUID v4 généré une fois à la création de l'entreprise

```dart
// Exemple
final enterpriseId = "f4edf80a-139e-48b0-a32b-b4902a0ccdf5";
```

**Propriétés** :
- Généré côté client avec `Uuid().v4()`
- Immuable (ne change jamais)
- Stocké dans `GameState.enterpriseId`
- Présent dans `snapshot.metadata.enterpriseId`
- Validation stricte format UUID v4 côté backend

### Nom d'Entreprise

**`enterpriseName`** : Chaîne personnalisable

```dart
// Exemple
final enterpriseName = "Mon Entreprise";
```

**Propriétés** :
- Personnalisable à la création (IntroductionScreen page 4)
- Modifiable après création
- Stocké dans `GameState.enterpriseName`
- Présent dans `snapshot.metadata.enterpriseName`
- Validation : 1-50 caractères

### Format Snapshot v3

```json
{
  "metadata": {
    "enterpriseId": "f4edf80a-139e-48b0-a32b-b4902a0ccdf5",
    "enterpriseName": "Mon Entreprise",
    "createdAt": "2026-04-07T10:30:00.000Z",
    "updatedAt": "2026-04-07T12:45:00.000Z",
    "gameVersion": "1.0.0",
    "snapshotVersion": 3
  },
  "core": {
    "clips": 1000,
    "funds": 500.50,
    "wire": 100,
    "trust": 50,
    "operations": 10,
    "creativity": 5,
    "yomi": 0,
    "processors": 1,
    "memory": 1
  },
  "stats": {
    "totalClipsProduced": 5000,
    "totalFundsEarned": 2500.00,
    "sessionDuration": 3600
  }
}
```

**Champs obligatoires** :
- `metadata.enterpriseId` (UUID v4)
- `metadata.enterpriseName` (string)
- `metadata.snapshotVersion` (3)

---

## 🌐 API BACKEND

### Endpoint Principal

**Base URL** : `https://[region]-[project-id].cloudfunctions.net/api`

### Routes

#### GET /enterprise/{uid}
Récupère l'entreprise de l'utilisateur authentifié.

**Paramètres** :
- `uid` : Firebase Auth UID (extrait du token)

**Réponse 200** :
```json
{
  "enterprise_id": "f4edf80a-139e-48b0-a32b-b4902a0ccdf5",
  "name": "Mon Entreprise",
  "snapshot": { /* snapshot v3 */ },
  "updated_at": "2026-04-07T12:45:00.000Z"
}
```

**Réponse 404** : Aucune entreprise trouvée

#### PUT /enterprise/{uid}
Sauvegarde l'entreprise de l'utilisateur authentifié.

**Paramètres** :
- `uid` : Firebase Auth UID (extrait du token)

**Body** :
```json
{
  "enterpriseId": "f4edf80a-139e-48b0-a32b-b4902a0ccdf5",
  "snapshot": { /* snapshot v3 */ }
}
```

**Validation** :
- `enterpriseId` doit être UUID v4 valide
- `snapshot.metadata.enterpriseId` doit correspondre à `enterpriseId`
- `snapshot.metadata.snapshotVersion` doit être 3

**Réponse 200** :
```json
{
  "ok": true,
  "enterprise_id": "f4edf80a-139e-48b0-a32b-b4902a0ccdf5",
  "updated_at": "2026-04-07T12:45:00.000Z"
}
```

#### DELETE /enterprise/{uid}
Supprime l'entreprise de l'utilisateur (testeurs uniquement).

**Paramètres** :
- `uid` : Firebase Auth UID (extrait du token)

**Réponse 204** : Suppression réussie

---

## 💾 PERSISTANCE CLIENT

### LocalSaveGameManager

Stockage local via SharedPreferences.

**Clé de stockage** : `enterpriseId`

```dart
// Sauvegarde
await LocalSaveGameManager.instance.saveSnapshot(
  snapshot,
  slotId: enterpriseId,
);

// Chargement
final snapshot = await LocalSaveGameManager.instance.loadSnapshot(
  slotId: enterpriseId,
);
```

### GamePersistenceOrchestrator

Orchestration save/load + cloud sync.

```dart
// Sauvegarde locale + push cloud
await GamePersistenceOrchestrator.instance.requestLifecycleSave(gameState);

// Chargement
await GamePersistenceOrchestrator.instance.loadGameById(
  gameState,
  enterpriseId,
);
```

### CloudPersistenceAdapter

Communication HTTP avec `/enterprise/{uid}`.

```dart
// Push cloud
await CloudPersistenceAdapter.instance.pushById(
  enterpriseId: enterpriseId,
  snapshot: snapshot.toJson(),
  metadata: metadata,
);

// Pull cloud
final detail = await CloudPersistenceAdapter.instance.pullById(
  enterpriseId: enterpriseId,
);
```

---

## 🔄 SYNCHRONISATION CLOUD

### Stratégie "Cloud Always Wins"

Au login, le cloud écrase toujours le local.

```dart
// AppBootstrapController.bootstrap()
if (cloudExists) {
  // Pull cloud et écrase local
  await orchestrator.pullFromCloud(enterpriseId);
} else if (localExists) {
  // Push local vers cloud
  await orchestrator.pushCloudForState(gameState);
}
```

### Flux de Synchronisation

#### Création d'entreprise
```
1. Utilisateur crée "Mon Entreprise"
   ↓
2. UUID généré : f4edf80a-139e-48b0-a32b-b4902a0ccdf5
   ↓
3. Sauvegarde locale (cache)
   ↓
4. Push cloud automatique (si Firebase connecté)
   ↓
5. Données dans Firestore : enterprises/{uid}
```

#### Login utilisateur
```
1. Utilisateur se connecte avec Firebase
   ↓
2. Pull cloud automatique
   ↓
3. Écrasement du cache local (cloud always wins)
   ↓
4. Chargement dans MainScreen
```

#### Sauvegarde en jeu
```
1. GameState.save() appelé
   ↓
2. Écriture locale (cache)
   ↓
3. Push cloud automatique
   ↓
4. Retry automatique si échec (backoff: 1s, 2s, 4s)
```

---

## 🎮 WORKFLOWS DÉVELOPPEUR

### Créer une Nouvelle Entreprise

```dart
// 1. Créer via GameState
await gameState.createNewEnterprise(name: "Mon Entreprise");

// 2. Sauvegarder localement
await GamePersistenceOrchestrator.instance.requestLifecycleSave(gameState);

// 3. Push cloud automatique (si Firebase connecté)
await GamePersistenceOrchestrator.instance.pushCloudForState(gameState);
```

### Charger l'Entreprise Existante

```dart
// 1. Récupérer enterpriseId
final enterpriseId = gameState.enterpriseId;

// 2. Charger depuis local ou cloud
await GamePersistenceOrchestrator.instance.loadGameById(
  gameState,
  enterpriseId,
);

// 3. Démarrer session
runtimeActions.startSession();
```

### Supprimer l'Entreprise

```dart
// 1. Supprimer via GameState
await gameState.deleteEnterprise();

// 2. Supprimer du cloud
await CloudPersistenceAdapter.instance.deleteById(
  enterpriseId: enterpriseId,
);
```

---

## ⚠️ TRACES À NETTOYER

### Alias `worldId` (80+ occurrences)

**Fichiers impactés** :
- `lib/services/persistence/local_game_persistence.dart`
- `lib/services/persistence/game_persistence_orchestrator.dart`
- `lib/services/persistence/world_model.dart`
- `lib/services/persistence/sync_result.dart`
- `lib/services/persistence/save_manager.dart`

**Action requise** : Renommer `worldId` → `enterpriseId`

### Backend Endpoints Obsolètes

**Endpoints à supprimer** :
- `PUT /worlds/:worldId`
- `GET /worlds/:worldId`
- `GET /worlds`
- `DELETE /worlds/:worldId`
- `PUT /saves/:partieId`
- `GET /saves/:partieId/latest`
- `GET /saves`
- `DELETE /saves/:partieId`

**Action requise** : Supprimer ces endpoints de `functions/src/index.ts`

### Validation Backend Hybride

**Actuel** :
```typescript
const metaPid = metadata.partieId ?? metadata.worldId ?? metadata.enterpriseId;
```

**Devrait être** :
```typescript
const enterpriseId = metadata.enterpriseId;
if (!enterpriseId || typeof enterpriseId !== 'string') {
  return res.status(422).json({ error: 'metadata_enterprise_id_missing' });
}
```

**Voir** : `docs/TODO-NETTOYAGE-CODE.md` pour la roadmap complète

---

## ✅ VALIDATION

### Tests Fonctionnels

- [x] Création entreprise fonctionne
- [x] Sauvegarde locale fonctionne
- [x] Push cloud fonctionne
- [x] Pull cloud fonctionne
- [x] Sync "cloud always wins" au login
- [x] Retry automatique après échec
- [x] Validation UUID v4 stricte
- [x] Format snapshot v3 valide

### Tests à Effectuer Après Nettoyage

- [ ] Aucune référence `worldId` dans logs
- [ ] Endpoints `/worlds` retournent 404
- [ ] Endpoints `/saves` retournent 404
- [ ] Backend rejette `metadata.worldId`
- [ ] Backend accepte uniquement `metadata.enterpriseId`

---

## 🔗 RÉFÉRENCES

### Documentation
- `architecture-globale.md` : Vue d'ensemble système
- `persistance-cloud.md` : Synchronisation cloud
- `DECISIONS_PERSISTANCE.md` : Décisions techniques
- `../INDEX.md` : Index documentation complète

### Code
- `lib/models/game_state.dart` : État entreprise
- `lib/services/persistence/game_persistence_orchestrator.dart` : Orchestration
- `lib/services/cloud/cloud_persistence_adapter.dart` : API client
- `functions/src/index.ts` : API backend

### Audit et Nettoyage
- `../AUDIT-CODE-ETAT-REEL.md` : État actuel du code
- `../TODO-NETTOYAGE-CODE.md` : Roadmap nettoyage

---

**FIN DU DOCUMENT — SOURCE DE VÉRITÉ POUR ARCHITECTURE ENTREPRISE UNIQUE**
