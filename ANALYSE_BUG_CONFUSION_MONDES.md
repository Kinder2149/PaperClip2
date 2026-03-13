# 🔥 ANALYSE CRITIQUE : Bug de Confusion des Mondes

## 📋 Symptômes Rapportés

**Scénario utilisateur :**
1. ✅ Connexion + création partie 1 + récupération partie 2 depuis cloud → **OK**
2. ✅ Jouer partie 1 jusqu'au niveau 3, sauvegarder → **OK**
3. ✅ Retour page mondes → affichage correct (partie 1 niv 3, partie 2 niv 1) → **OK**
4. ✅ Charger partie 2 → affichage correct → **OK**
5. ❌ **Retour page mondes → PERTE de la partie 1, DUPLICATION de la partie 2**

## 🔍 Analyse Approfondie du Code

### 1. **PROBLÈME CRITIQUE IDENTIFIÉ : Gestion du `partieId` dans GameState**

#### 📍 Localisation : `lib/models/game_state.dart`

```dart
// Ligne 73 : Champ privé _partieId
String? _partieId; // ID technique unique (UUID v4)

// Ligne 88-96 : Méthode setPartieId avec validation UUID v4
void setPartieId(String id) {
  // Enforce UUID v4 format (cloud-first invariant: identité technique stricte)
  final uuidV4 = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12} ?$');
  if (uuidV4.hasMatch(id)) {
    _partieId = id;
  } else {
    // 🔥 PROBLÈME : Ignorer silencieusement les IDs non conformes
    // Aucun log, aucune exception, aucune notification
  }
}
```

**⚠️ PROBLÈME MAJEUR :** La méthode `setPartieId()` **ignore silencieusement** les identifiants qui ne correspondent pas au format UUID v4, sans aucun log ni exception.

#### 📍 Impact sur le chargement : `lib/services/persistence/game_persistence_orchestrator.dart`

```dart
// Ligne 1443-1445 : Chargement avec snapshot
state.applyLoadedGameDataWithoutSnapshot(name, <String, dynamic>{});
state.applySnapshot(snapshot);
await state.finishLoadGameAfterSnapshot(name, <String, dynamic>{});
```

**🔥 SCÉNARIO DE BUG :**

1. **Chargement partie 1 (UUID valide)** :
   - `loadGameById(state, "abc-123-uuid-v4")` → ✅ `_partieId` = "abc-123-uuid-v4"
   
2. **Sauvegarde partie 1** :
   - Snapshot créé avec `partieId` = "abc-123-uuid-v4" → ✅ OK
   
3. **Chargement partie 2 (UUID valide)** :
   - `loadGameById(state, "def-456-uuid-v4")` → ✅ `_partieId` = "def-456-uuid-v4"
   - **MAIS** : Si le snapshot contient un `partieId` mal formaté ou si `applySnapshot()` tente de définir un ID invalide...

#### 📍 Vérification dans `applySnapshot()` : `lib/models/game_state.dart` (fin du fichier)

```dart
// Application du snapshot
void applySnapshot(GameSnapshot snapshot) {
  final metadata = snapshot.metadata;
  
  // ID technique (UUID) si présent dans les métadonnées du snapshot
  final metaPartieId = metadata['partieId'] as String?;
  if (_partieId == null && metaPartieId != null && metaPartieId.isNotEmpty) {
    _partieId = metaPartieId; // 🔥 ASSIGNATION DIRECTE sans validation !
  }
}
```

**🚨 BUG CONFIRMÉ :** `applySnapshot()` assigne **directement** `_partieId` sans passer par `setPartieId()`, **contournant la validation UUID v4** !

### 2. **PROBLÈME SECONDAIRE : Confusion dans SaveAggregator**

#### 📍 Localisation : `lib/services/persistence/save_aggregator.dart`

```dart
// Lignes 145-207 : Construction des entrées depuis le cloud
for (final cloudEntry in cloudIndex.values) {
  final localInfo = localIndex[cloudEntry.partieId];
  
  if (localInfo != null) {
    // Monde cloud + local
    result.add(SaveEntry(
      source: SaveSource.cloud,
      id: cloudEntry.partieId, // ✅ ID du cloud
      name: cloudEntry.name ?? localInfo.name,
      // ... stats locales
    ));
  }
}

// Lignes 209-248 : Ajout des mondes locaux orphelins
for (final localInfo in localInfos) {
  if (localInfo.isBackup) continue;
  if (cloudIndex.containsKey(localInfo.id)) continue; // Déjà traité
  
  result.add(SaveEntry(
    source: SaveSource.local,
    id: localInfo.id, // ✅ ID local
    // ...
  ));
}
```

**Logique correcte** : Le `SaveAggregator` utilise bien les IDs techniques pour l'indexation.

### 3. **PROBLÈME TERTIAIRE : Chargement des données locales**

#### 📍 Localisation : `lib/services/save_system/local_save_game_manager.dart`

```dart
// Ligne 254-339 : Méthode loadSave
Future<SaveGame?> loadSave(String saveId) async {
  await _ensureInitialized();
  
  try {
    final String? jsonData = _prefs.getString('$_saveDataPrefix$saveId');
    if (jsonData == null) {
      return null;
    }
    
    final Map<String, dynamic> data = jsonDecode(jsonData);
    
    // ... validation et extraction
    
    return SaveGame(
      id: saveId, // ✅ Utilise bien le saveId fourni
      name: name,
      lastSaveTime: lastModifiedTime,
      gameData: gameData,
      version: version,
      gameMode: gameMode,
    );
  } catch (e) {
    _logger.severe('Erreur lors du chargement de la sauvegarde $saveId: $e');
    return null;
  }
}
```

**Logique correcte** : Le `LocalSaveGameManager` charge bien par ID technique.

## 🎯 CAUSES RACINES IDENTIFIÉES

### **Cause #1 : Contournement de validation dans `applySnapshot()`**

```dart
// ❌ MAUVAIS : Assignation directe sans validation
final metaPartieId = metadata['partieId'] as String?;
if (_partieId == null && metaPartieId != null && metaPartieId.isNotEmpty) {
  _partieId = metaPartieId; // Contourne setPartieId()
}
```

**Conséquence :** Si un snapshot contient un `partieId` corrompu, mal formaté, ou appartenant à une autre partie, il écrase silencieusement l'identité du `GameState`.

### **Cause #2 : Validation UUID v4 trop stricte avec échec silencieux**

```dart
// ❌ MAUVAIS : Échec silencieux sans log ni exception
void setPartieId(String id) {
  final uuidV4 = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12} ?$');
  if (uuidV4.hasMatch(id)) {
    _partieId = id;
  } else {
    // Silence total = bug invisible
  }
}
```

**Conséquence :** Les tentatives d'assignation d'ID invalides passent inaperçues, rendant le debugging impossible.

### **Cause #3 : Condition `_partieId == null` dans `applySnapshot()`**

```dart
// ❌ PROBLÉMATIQUE : N'écrase pas si déjà défini
if (_partieId == null && metaPartieId != null && metaPartieId.isNotEmpty) {
  _partieId = metaPartieId;
}
```

**Scénario problématique :**
1. Chargement partie 1 → `_partieId` = "uuid-partie-1"
2. Sauvegarde partie 1 → Snapshot avec `partieId` = "uuid-partie-1"
3. Chargement partie 2 → `loadGameById()` tente de charger "uuid-partie-2"
4. **MAIS** si `applySnapshot()` est appelé avec un snapshot de la partie 1 (cache, erreur de chargement, etc.), la condition `_partieId == null` est **fausse**, donc l'ID n'est pas mis à jour
5. Le `GameState` garde `_partieId` = "uuid-partie-1" alors qu'il affiche les données de la partie 2

## 🔧 CORRECTIONS NÉCESSAIRES

### **Correction #1 : Utiliser `setPartieId()` dans `applySnapshot()`**

```dart
// ✅ BON : Utiliser la méthode de validation
final metaPartieId = metadata['partieId'] as String?;
if (metaPartieId != null && metaPartieId.isNotEmpty) {
  setPartieId(metaPartieId); // Passe par la validation
}
```

### **Correction #2 : Logger les échecs de validation dans `setPartieId()`**

```dart
void setPartieId(String id) {
  final uuidV4 = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12} ?$');
  if (uuidV4.hasMatch(id)) {
    _partieId = id;
  } else {
    // ✅ Logger l'erreur pour debugging
    if (kDebugMode) {
      print('[GameState] ⚠️ Tentative d\'assignation d\'un partieId invalide (non UUID v4): $id');
    }
    // ✅ Option : Lever une exception en mode debug
    throw ArgumentError('[GameState] partieId doit être un UUID v4 valide, reçu: $id');
  }
}
```

### **Correction #3 : Forcer l'écrasement du `partieId` lors du chargement**

```dart
// ✅ BON : Toujours écraser lors du chargement d'un snapshot
final metaPartieId = metadata['partieId'] as String?;
if (metaPartieId != null && metaPartieId.isNotEmpty) {
  // Forcer l'écrasement même si _partieId est déjà défini
  setPartieId(metaPartieId);
}
```

### **Correction #4 : Ajouter des logs de traçabilité dans `loadGameById()`**

```dart
Future<void> loadGameById(GameState state, String id, {bool allowRestore = true}) async {
  // ✅ Log avant chargement
  final prevId = state.partieId;
  _logger.info('[LOAD] Chargement monde', code: 'load_start', ctx: {
    'targetId': id,
    'currentId': prevId,
  });
  
  // ... chargement ...
  
  // ✅ Log après chargement
  final newId = state.partieId;
  _logger.info('[LOAD] Chargement terminé', code: 'load_complete', ctx: {
    'targetId': id,
    'resultId': newId,
    'success': newId == id,
  });
  
  // ✅ Vérification d'intégrité
  if (newId != id) {
    _logger.error('[LOAD] ⚠️ INCOHÉRENCE : partieId ne correspond pas à l\'ID chargé', code: 'load_id_mismatch', ctx: {
      'expected': id,
      'actual': newId,
    });
    throw StateError('LOAD_ID_MISMATCH: L\'identité de la partie chargée ne correspond pas (attendu: $id, obtenu: $newId)');
  }
}
```

## 📊 Scénario de Bug Reconstruit

### **Étape 1 : Chargement partie 1**
```
loadGameById(state, "uuid-partie-1")
→ state._partieId = "uuid-partie-1" ✅
→ Affichage correct
```

### **Étape 2 : Sauvegarde partie 1**
```
saveGame(state, "uuid-partie-1")
→ Snapshot créé avec metadata.partieId = "uuid-partie-1" ✅
→ Sauvegarde locale + cloud OK
```

### **Étape 3 : Chargement partie 2**
```
loadGameById(state, "uuid-partie-2")
→ Chargement snapshot partie 2
→ applySnapshot() appelé
→ metadata['partieId'] = "uuid-partie-2"
→ Condition: _partieId == null ? NON (déjà "uuid-partie-1")
→ _partieId reste "uuid-partie-1" ❌
→ GameState affiche données partie 2 mais identité partie 1
```

### **Étape 4 : Retour page mondes**
```
SaveAggregator.listAll()
→ Charge métadonnées locales par ID
→ Trouve "uuid-partie-1" (GameState actif)
→ Trouve "uuid-partie-2" (fichier local)
→ MAIS GameState._partieId = "uuid-partie-1" alors que données = partie 2
→ Confusion : deux entrées pointent vers des données incohérentes
```

### **Étape 5 : Sauvegarde automatique partie 2**
```
AutoSave déclenché
→ state.partieId = "uuid-partie-1" (MAUVAIS)
→ Sauvegarde écrase la partie 1 avec les données de la partie 2 ❌
→ Perte de la partie 1 originale
→ Duplication de la partie 2 sous deux IDs différents
```

## ✅ Plan de Correction

1. **Corriger `applySnapshot()`** : Utiliser `setPartieId()` et supprimer la condition `_partieId == null`
2. **Renforcer `setPartieId()`** : Ajouter logs et exceptions en cas d'ID invalide
3. **Ajouter vérification post-chargement** : S'assurer que `state.partieId == id` après `loadGameById()`
4. **Ajouter logs de traçabilité** : Suivre les changements d'identité du GameState
5. **Tests de non-régression** : Vérifier le scénario multi-mondes avec changements de contexte

## 🎯 Priorité : **CRITIQUE P0**

Ce bug provoque une **perte de données utilisateur** et une **corruption silencieuse** des sauvegardes.
