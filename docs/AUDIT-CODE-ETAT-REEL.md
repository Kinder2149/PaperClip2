# Audit Code : État Réel de l'Implémentation

**Date** : 7 avril 2026  
**Objectif** : Établir la vérité technique sur l'architecture entreprise unique

---

## 🎯 VERDICT : Architecture HYBRIDE (Non Conforme)

Le code utilise un **système hybride** entre multi-worlds et entreprise unique pure.

### ✅ Implémenté Correctement

**Frontend** :
- `enterpriseId` (UUID v4) dans `GameState`
- Méthodes `createNewEnterprise()`, `deleteEnterprise()`, `setEnterpriseId()`
- API client utilise `/enterprise/{uid}` (CloudPersistenceAdapter)
- Validation UUID v4 stricte côté client

**Backend** :
- Endpoints `/enterprise/{uid}` (GET, PUT, DELETE) fonctionnels
- Validation `enterpriseId` format UUID v4
- Snapshot v3 avec `metadata.enterpriseId`

### ❌ Traces Multi-Worlds à Nettoyer

#### 1. Alias `worldId` (80+ occurrences)

**Fichiers impactés** :
- `lib/services/persistence/local_game_persistence.dart` (18 occurrences)
- `lib/services/persistence/game_persistence_orchestrator.dart` (46 occurrences)
- `lib/services/persistence/world_model.dart` (5 occurrences)
- `lib/services/persistence/sync_result.dart` (5 occurrences)
- `lib/services/persistence/save_manager.dart` (2 occurrences)
- `lib/models/save_game.dart` (2 occurrences)
- `lib/services/game_runtime_coordinator.dart` (2 occurrences)

**Détails** :

`local_game_persistence.dart` :
```dart
// Ligne 46 : Commentaire obsolète
// ID-first strict: l'identifiant persistant doit être le worldId (slotId)

// Ligne 63-64 : Méthode obsolète
Future<void> saveSnapshotByWorldId(GameSnapshot snapshot, {required String worldId})

// Ligne 118-119 : Méthode obsolète
Future<void> loadSnapshotByWorldId({required String worldId})

// Ligne 188 : Méthode obsolète
Future<World?> loadWorld(String worldId)

// Ligne 220 : Métadonnée obsolète
md['worldId'] ??= slotId;
```

`game_persistence_orchestrator.dart` :
```dart
// Logs utilisant 'worldId' au lieu de 'enterpriseId'
// Lignes 590, 623, 635, 636, 681, 707, 709, 743, 745, etc.
'worldId': request.slotId
'worldId': next.slotId
```

`world_model.dart` :
```dart
// Classe World avec worldId au lieu de enterpriseId
class World {
  final String worldId;  // DEVRAIT ÊTRE enterpriseId
  // ...
}
```

`save_manager.dart` :
```dart
// Ligne 36-37 : Méthode obsolète
Future<void> loadWorld(GameState state, {required String worldId})
```

#### 2. Backend : Endpoints `/worlds` Obsolètes

**Fichier** : `functions/src/index.ts`

**Endpoints à supprimer** :
- `PUT /worlds/:worldId` (ligne 155)
- `GET /worlds/:worldId` (ligne 314)
- `GET /worlds` (ligne 357)
- `DELETE /worlds/:worldId` (ligne 424)
- `PUT /saves/:partieId` (ligne 471)
- `GET /saves/:partieId/latest` (ligne 520)
- `GET /saves` (ligne 563)
- `DELETE /saves/:partieId` (ligne 608)

**Validation obsolète** :
```typescript
// Ligne 175 : Accepte worldId/partieId au lieu de enterpriseId uniquement
const metaPid = metadata.partieId ?? metadata.partie_id ?? metadata.worldId ?? metadata.world_id;
```

**DEVRAIT ÊTRE** :
```typescript
const enterpriseId = metadata.enterpriseId;
if (!enterpriseId || typeof enterpriseId !== 'string') {
  return res.status(422).json({ error: 'metadata_enterprise_id_missing' });
}
```

#### 3. Logique Multi-Worlds Résiduelle

**Limite 10 mondes** (ligne 203-207) :
```typescript
const MAX_WORLDS = 10;
if (existingWorlds.length >= MAX_WORLDS) {
  logger.warn('max_worlds_exceeded', { uid, worldId, count: existingWorlds.length, limit: MAX_WORLDS });
  return res.status(429).json({ error: 'max_worlds_exceeded', limit: MAX_WORLDS, current: existingWorlds.length });
}
```
**DEVRAIT ÊTRE** : Supprimer (1 seule entreprise = pas de limite)

**Liste de mondes** (ligne 357-421) :
```typescript
app.get('/worlds', verifyFirebaseIdToken, async (req: Request, res: Response) => {
  // Retourne liste de mondes
});
```
**DEVRAIT ÊTRE** : Supprimer endpoint (pas de liste pour entreprise unique)

#### 4. Métadonnées Snapshot Hybrides

**Backend valide** :
- `metadata.partieId` (obsolète)
- `metadata.worldId` (obsolète)
- `metadata.enterpriseId` (correct)

**DEVRAIT VALIDER** : Uniquement `metadata.enterpriseId`

---

## 📊 Statistiques

### Occurrences à Nettoyer

| Terme | Occurrences | Fichiers |
|-------|-------------|----------|
| `worldId` | 80+ | 7 fichiers Dart |
| `partieId` | 0 | 0 fichiers Dart (✅ nettoyé) |
| `/worlds` endpoints | 4 | 1 fichier TypeScript |
| `/saves` endpoints | 4 | 1 fichier TypeScript |

### Fichiers à Modifier

**Frontend (Dart)** :
1. `lib/services/persistence/local_game_persistence.dart` (18 modifications)
2. `lib/services/persistence/game_persistence_orchestrator.dart` (46 modifications)
3. `lib/services/persistence/world_model.dart` (5 modifications)
4. `lib/services/persistence/sync_result.dart` (5 modifications)
5. `lib/services/persistence/save_manager.dart` (2 modifications)
6. `lib/models/save_game.dart` (2 modifications)
7. `lib/services/game_runtime_coordinator.dart` (2 modifications)

**Backend (TypeScript)** :
1. `functions/src/index.ts` (supprimer 8 endpoints, modifier validation)
2. `functions/src/utils/logger.ts` (1 modification)

---

## 🎯 Actions Requises

### Priorité P0 : Backend

1. **Supprimer endpoints obsolètes** :
   - `/worlds/*` (4 endpoints)
   - `/saves/*` (4 endpoints)

2. **Modifier validation snapshot** :
   - Accepter UNIQUEMENT `metadata.enterpriseId`
   - Rejeter `metadata.worldId`, `metadata.partieId`

3. **Supprimer logique multi-worlds** :
   - Limite 10 mondes
   - Liste de mondes

### Priorité P1 : Frontend

1. **Renommer `worldId` → `enterpriseId`** :
   - Classe `World` → `Enterprise`
   - Propriété `worldId` → `enterpriseId`
   - Méthodes `*ByWorldId()` → `*ByEnterpriseId()`

2. **Supprimer méthodes obsolètes** :
   - `saveSnapshotByWorldId()`
   - `loadSnapshotByWorldId()`
   - `loadWorld()`

3. **Nettoyer logs** :
   - Remplacer `'worldId':` par `'enterpriseId':`

### Priorité P2 : Documentation

1. **Mettre à jour docs statiques** (voir Phase 2 du plan)
2. **Archiver docs chantiers obsolètes** (voir Phase 3 du plan)
3. **Créer doc référence** (voir Phase 4 du plan)

---

## 🔍 Validation

### Tests à Effectuer Après Nettoyage

1. **Backend** :
   - ✅ `/enterprise/{uid}` fonctionne (GET, PUT, DELETE)
   - ❌ `/worlds/*` retourne 404
   - ❌ `/saves/*` retourne 404
   - ✅ Validation rejette `metadata.worldId`

2. **Frontend** :
   - ✅ Création entreprise fonctionne
   - ✅ Sauvegarde/chargement fonctionne
   - ✅ Sync cloud fonctionne
   - ❌ Aucune référence `worldId` dans logs

3. **Documentation** :
   - ✅ Docs statiques mentionnent "entreprise unique"
   - ❌ Docs statiques ne mentionnent pas "multi-worlds"
   - ✅ Un seul document de référence existe

---

## 📝 Notes

- ✅ `partieId` complètement nettoyé du code Dart
- ⚠️ `worldId` encore utilisé comme alias de `enterpriseId`
- ⚠️ Backend expose encore API legacy `/worlds` et `/saves`
- ✅ Frontend utilise déjà `/enterprise` exclusivement
