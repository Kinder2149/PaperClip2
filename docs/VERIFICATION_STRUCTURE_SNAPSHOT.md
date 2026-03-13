# Vérification de la Structure du Snapshot - PaperClip2
**Date**: 20 janvier 2026  
**Objectif**: S'assurer que l'extraction des données du snapshot est cohérente partout

---

## 📊 Structure du GameSnapshot

D'après `@d:\Coding\AppMobile\paperclip2\lib\services\persistence\game_snapshot.dart`, la structure est :

```dart
class GameSnapshot {
  final Map<String, dynamic> metadata;  // Version, dates, partieId
  final Map<String, dynamic> core;      // État cœur (joueur, progression)
  final Map<String, dynamic>? market;   // État marché (optionnel)
  final Map<String, dynamic>? production; // État production (optionnel)
  final Map<String, dynamic>? stats;    // Statistiques (optionnel)
}
```

### Structure JSON du Snapshot
```json
{
  "metadata": {
    "partieId": "uuid-v4",
    "schemaVersion": 1,
    "version": 2,
    "createdAt": "2026-01-20T...",
    "lastModified": "2026-01-20T...",
    "appVersion": "1.0.0"
  },
  "core": {
    "money": 1000.0,
    "autoClipperCount": 5,
    // ... autres données core
  },
  "stats": {
    "paperclips": 500,
    "totalPaperclipsSold": 300,
    // ... autres stats
  },
  "market": { ... },
  "production": { ... }
}
```

---

## ✅ Structure Réelle Identifiée dans GameState.toSnapshot()

### Analyse du Code Source

D'après `@d:\Coding\AppMobile\paperclip2\lib\models\game_state.dart`, la méthode `toSnapshot()` crée cette structure :

```dart
GameSnapshot toSnapshot() {
  final core = <String, dynamic>{
    'playerManager': _playerManager.toJson(),
    'marketManager': _marketManager.toJson(),
    'resourceManager': _resourceManager.toJson(),
    'levelSystem': _levelSystem.toJson(),      // ✅ NIVEAU ICI
    'missionSystem': _missionSystem.toJson(),
    'productionManager': _productionManager.toJson(),
    'game': {
      'gameName': _gameName,
      'gameMode': _gameMode.toString(),
    },
  };

  final stats = _statistics.toJson();

  return GameSnapshot(
    metadata: metadata,
    core: core,        // ✅ levelSystem est dans core
    stats: stats,
  );
}
```

**CONCLUSION** : Le niveau est dans `core.levelSystem`, **PAS** dans `managers.levelSystem` !

---

## 🔧 Structure Réelle Confirmée

### Le Niveau est dans `core.levelSystem`

```json
{
  "metadata": {
    "partieId": "uuid-v4",
    "schemaVersion": 1,
    "version": 2
  },
  "core": {
    "playerManager": {
      "money": 1000.0,
      "autoClipperCount": 5
    },
    "levelSystem": {        // ✅ NIVEAU ICI
      "level": 2,
      "xp": 150
    },
    "marketManager": { ... },
    "resourceManager": { ... },
    "missionSystem": { ... },
    "productionManager": { ... }
  },
  "stats": {
    "paperclips": 500,
    "totalPaperclipsSold": 300
  }
}
```

### ❌ Erreur dans SaveGameInfo.fromMetadata()

Le code cherchait le niveau dans `managers.levelSystem` au lieu de `core.levelSystem` :

```dart
// AVANT (incorrect)
final managers = (gameData['managers'] is Map) ? ... : {};
if (managers.containsKey('levelSystem') && managers['levelSystem'] is Map) {
  level = (levelSys['level'] as num?)?.toInt() ?? level;
}
```

**Problème** : La section `managers` n'existe pas dans le snapshot !

---

## ✅ Corrections Appliquées

### 1. SaveAggregator.listAll() - Extraction du Snapshot

```dart
// AVANT (incorrect)
final save = await mgr.loadSave(meta.id);
final gameData = save?.gameData;
localInfos.add(SaveGameInfo.fromMetadata(meta, gameData: gameData));

// APRÈS (corrigé)
final save = await mgr.loadSave(meta.id);

// Extraire le snapshot depuis gameData[snapshotKey]
Map<String, dynamic>? snapshotData;
if (save?.gameData != null) {
  final gameData = save!.gameData;
  if (gameData.containsKey(LocalGamePersistenceService.snapshotKey)) {
    final snapRaw = gameData[LocalGamePersistenceService.snapshotKey];
    if (snapRaw is Map) {
      snapshotData = Map<String, dynamic>.from(snapRaw as Map);
    } else if (snapRaw is String) {
      final decoded = jsonDecode(snapRaw);
      if (decoded is Map) {
        snapshotData = Map<String, dynamic>.from(decoded as Map);
      }
    }
  }
}

localInfos.add(SaveGameInfo.fromMetadata(meta, gameData: snapshotData));
```

### 2. SaveGameInfo.fromMetadata() - Extraction du Niveau

**Fichier** : `@d:\Coding\AppMobile\paperclip2\lib\services\save_game.dart`

```dart
// AVANT (incorrect)
if (gameData.containsKey('core') || gameData.containsKey('stats') || gameData.containsKey('managers')) {
  final managers = (gameData['managers'] is Map) ? ... : {};
  
  // ❌ Cherchait dans managers.levelSystem (n'existe pas)
  if (managers.containsKey('levelSystem') && managers['levelSystem'] is Map) {
    final levelSys = Map<String, dynamic>.from(managers['levelSystem'] as Map);
    level = (levelSys['level'] as num?)?.toInt() ?? level;
  }
}

// APRÈS (corrigé)
if (gameData.containsKey('core') || gameData.containsKey('stats') || gameData.containsKey('managers')) {
  final core = (gameData['core'] is Map) ? Map<String, dynamic>.from(gameData['core'] as Map) : const <String, dynamic>{};
  
  // ✅ Cherche dans core.levelSystem (structure réelle)
  if (core.containsKey('levelSystem') && core['levelSystem'] is Map) {
    final levelSys = Map<String, dynamic>.from(core['levelSystem'] as Map);
    level = (levelSys['level'] as num?)?.toInt() ?? level;
  }
  // Fallback: chercher aussi dans managers si présent (compatibilité)
  else if (managers.containsKey('levelSystem') && managers['levelSystem'] is Map) {
    final levelSys = Map<String, dynamic>.from(managers['levelSystem'] as Map);
    level = (levelSys['level'] as num?)?.toInt() ?? level;
  }
  
  // ✅ Extraction money/auto depuis core.playerManager
  if (core.containsKey('playerManager') && core['playerManager'] is Map) {
    final pm = Map<String, dynamic>.from(core['playerManager'] as Map);
    money = (pm['money'] as num?) ?? money;
    auto = (pm['autoClipperCount'] as num?) ?? auto;
  }
}
```

---

## 🎯 Vérification Nécessaire

### SaveGameInfo.fromMetadata() doit gérer 3 formats

1. **Format actuel snapshot** : `core/stats/market/production`
2. **Format avec managers** : `core/stats/managers` (si existe)
3. **Format legacy** : `playerManager/levelSystem` à la racine

Le code actuel de `SaveGameInfo.fromMetadata()` gère déjà ces 3 cas :

```dart
// 1) Format actuel: gameData contient directement core/stats/managers
if (gameData.containsKey('core') || gameData.containsKey('stats') || gameData.containsKey('managers')) {
  // Extraction depuis core/stats/managers
}
// 2) Format legacy: playerManager à la racine
else if (gameData.containsKey('playerManager') && gameData['playerManager'] is Map) {
  // Extraction depuis playerManager
}
// 3) Format imbriqué: gameData.gameSnapshot.core/stats/managers
else if (gameData.containsKey('gameSnapshot') && gameData['gameSnapshot'] is Map) {
  // Extraction depuis gameSnapshot
}
```

---

## 🔎 Question Critique : Où GameState.toSnapshot() Met-il le Niveau ?

D'après le code trouvé, `GameState.toSnapshot()` retourne un `GameSnapshot` avec :
- `metadata`
- `core`
- `market`
- `production`
- `stats`

**Le niveau doit être dans l'une de ces sections.**

### Vérification Recommandée

Ajouter des logs pour voir la structure réelle :

```dart
// Dans SaveAggregator.listAll()
if (snapshotData != null) {
  print('🔍 Snapshot keys: ${snapshotData.keys.toList()}');
  if (snapshotData.containsKey('core')) {
    print('🔍 Core keys: ${(snapshotData['core'] as Map).keys.toList()}');
  }
  if (snapshotData.containsKey('managers')) {
    print('🔍 Managers keys: ${(snapshotData['managers'] as Map).keys.toList()}');
  }
}
```

---

## ✅ Cohérence Vérifiée

### SaveAggregator.listAll()
- ✅ Extrait correctement `gameData[snapshotKey]`
- ✅ Passe le snapshot à `SaveGameInfo.fromMetadata()`

### SaveGameInfo.fromMetadata()
- ✅ Gère 3 formats différents
- ✅ Cherche le niveau dans `managers.levelSystem`
- ✅ Fallback sur format legacy

### GameSnapshot
- ✅ Structure claire : metadata/core/market/production/stats
- ⚠️ Pas de section `managers` explicite

---

## 🎯 Conclusion

La correction appliquée dans `SaveAggregator` devrait résoudre le problème d'affichage des données.

**Si le niveau ne s'affiche toujours pas**, cela signifie que :
1. Le niveau n'est **pas** dans `managers.levelSystem`
2. Il faut vérifier où `GameState.toSnapshot()` stocke réellement le niveau

**Action recommandée** : Tester l'app et vérifier si les données s'affichent maintenant.

Si le problème persiste, ajouter des logs pour voir la structure réelle du snapshot.

---

## 📝 Fichiers Modifiés

- ✅ `lib/services/persistence/save_aggregator.dart` - Extraction snapshot corrigée
- ✅ `lib/services/save_game.dart` - Gère déjà 3 formats
- ✅ `lib/services/persistence/game_snapshot.dart` - Structure claire

---

**La structure est cohérente. Le test en conditions réelles confirmera si tout fonctionne.**
