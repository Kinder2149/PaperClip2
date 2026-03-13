# Flux Complet de Création et Sauvegarde d'un Monde - PaperClip2
**Date**: 21 janvier 2026  
**Objectif**: Vérifier la cohérence, complétude et unification des chemins de création et sauvegarde

---

## 📋 Vue d'Ensemble

### Points d'Entrée de Création
1. **WorldsScreen** → Bouton "Créer un monde" (point d'entrée principal)
2. **StartScreen** → Neutralisé (redirige vers WorldsScreen)

### Chemins de Sauvegarde
1. **AutoSave** → Sauvegarde automatique périodique
2. **Lifecycle Save** → Sauvegarde lors d'événements importants
3. **Manual Save** → Sauvegarde manuelle via bouton
4. **Cloud Push** → Synchronisation cloud (automatique si connecté)

---

## 🔄 Flux de Création d'un Monde

### 1. Point d'Entrée : WorldsScreen._createNewWorld()

**Fichier** : `@d:\Coding\AppMobile\paperclip2\lib\screens\worlds_screen.dart:140-191`

```dart
Future<void> _createNewWorld() async {
  try {
    // ✅ VÉRIFICATION: Limite de mondes (MAX_WORLDS)
    final entries = await SaveAggregator().listAll(context);
    final worldCount = entries.where((e) => !e.isBackup).length;
    
    if (worldCount >= GameConstants.MAX_WORLDS) {
      // ✅ NOTIFICATION: Snackbar avec message clair
      ScaffoldMessenger.of(context).showSnackBar(...);
      return;
    }
    
    // ✅ DIALOGUE: Validation nom + mode de jeu
    final result = await showNewGameDialog(context: context);
    if (result == null) return; // Annulation
    final (name, mode) = result;
    
    // ✅ CRÉATION: Via RuntimeActions (façade)
    await context.read<RuntimeActions>()
        .startNewGameAndStartAutoSave(name, mode: mode);
    
    // ✅ SESSION: Démarrage session runtime
    context.read<RuntimeActions>().startSession();
    
    // ✅ NAVIGATION: Introduction → MainScreen
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IntroductionScreen(
          showSkipButton: true,
          isCompetitiveMode: mode == GameMode.COMPETITIVE,
          onStart: () {
            Navigator.of(_).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainScreen()),
            );
          },
        ),
      ),
    );
  } catch (err) {
    // ✅ GESTION ERREUR: Snackbar avec message d'erreur
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Impossible de créer le monde: $err')),
    );
  }
}
```

**Points Positifs** :
- ✅ Vérification limite de mondes
- ✅ Validation du nom (min 3 caractères)
- ✅ Gestion d'erreur avec notification utilisateur
- ✅ Navigation cohérente

---

### 2. Façade RuntimeActions

**Fichier** : `@d:\Coding\AppMobile\paperclip2\lib\services\runtime\runtime_actions.dart:34-35`

```dart
Future<void> startNewGameAndStartAutoSave(String name, {GameMode mode = GameMode.INFINITE}) =>
    _runtime.startNewGameAndStartAutoSave(name, mode: mode);
```

**Rôle** : Façade légère qui délègue au `GameRuntimeCoordinator`

---

### 3. Orchestration : GameRuntimeCoordinator.startNewGameAndStartAutoSave()

**Fichier** : `@d:\Coding\AppMobile\paperclip2\lib\services\game_runtime_coordinator.dart:199-268`

```dart
Future<void> startNewGameAndStartAutoSave(
  String name, {
  GameMode mode = GameMode.INFINITE,
}) async {
  // ✅ ARRÊT AUTOSAVE: Stopper l'autosave précédent
  _autoSaveService.stop();
  
  // ✅ SNAPSHOT MONDES: Logger les mondes existants avant création
  try {
    final saves = await GamePersistenceOrchestrator.instance.listSaves();
    final ids = saves
        .where((m) => !m.name.contains(GameConstants.BACKUP_DELIMITER))
        .map((m) => m.id)
        .toList();
    _logger.info('📃 WORLDS-SNAPSHOT', code: 'worlds_snapshot_before', ctx: {
      'count': ids.length,
      'ids': ids.join(','),
    });
  } catch (_) {}
  
  // ✅ LOG AVANT CRÉATION
  try {
    final beforeId = _gameState.partieId ?? '';
    _logger.info('[WORLD-CREATE] before', code: 'world_create_before', ctx: {
      'prev_worldId': beforeId,
      'origin': 'new_game',
      'name': name,
      'mode': mode.toString(),
    });
  } catch (_) {}
  
  // ✅ CRÉATION GAMESTATE: Appel à GameState.startNewGame()
  await _gameState.startNewGame(name, mode: mode);
  
  // ✅ INVARIANT IDENTITÉ: Vérification partieId obligatoire
  final newPartieId = _gameState.partieId;
  if (newPartieId == null || newPartieId.isEmpty) {
    throw StateError('[IdentityInvariant] partieId manquant après startNewGame("'+name+'"): création invalide');
  }
  
  // ✅ LOG APRÈS CRÉATION
  try {
    _logger.info('[WORLD-CREATE] after', code: 'world_create_after', ctx: {
      'worldId': newPartieId,
      'origin': 'new_game',
      'name': name,
      'mode': mode.toString(),
    });
  } catch (_) {}
  
  // ✅ DÉMARRAGE AUTOSAVE
  await _autoSaveService.start();
  
  // ✅ AUDIO: Chargement musique (optionnel)
  final audio = _audioPort;
  if (audio != null) {
    unawaited(audio.loadGameMusicState(name));
  }

  // ✅ CLOUD PUSH: Push obligatoire si utilisateur connecté
  try {
    final firebaseUser = FirebaseAuthService.instance.currentUser;
    if (firebaseUser != null) {
      if (kDebugMode) {
        _logger.debug('[Runtime] User authenticated (uid=${firebaseUser.uid}) - pushing new world to cloud');
      }
      // PUSH IMMÉDIAT pour création de monde (événement critique)
      await GamePersistenceOrchestrator.instance.pushCloudForState(_gameState, reason: 'world_creation');
    } else {
      if (kDebugMode) {
        _logger.debug('[Runtime] User not authenticated - skipping cloud push for new world');
      }
    }
  } catch (e) {
    // ✅ GESTION ERREUR: Logger mais ne pas bloquer
    _logger.warn('[Runtime] Failed to push new world to cloud: $e', code: 'world_creation_push_failed');
  }
}
```

**Points Positifs** :
- ✅ Arrêt autosave précédent
- ✅ Logs détaillés (avant/après création)
- ✅ **Invariant identité strict** : Exception si partieId manquant
- ✅ Push cloud immédiat si connecté
- ✅ Gestion erreur cloud non bloquante

**Points d'Attention** :
- ⚠️ Le push cloud est immédiat (hors queue) - **Intentionnel** pour événement critique
- ⚠️ Pas de sauvegarde locale explicite ici - **Déléguée à AutoSave**

---

### 4. Création GameState : GameState.startNewGame()

**Fichier** : `@d:\Coding\AppMobile\paperclip2\lib\models\game_state.dart` (tail:500)

```dart
Future<void> startNewGame(String name, {GameMode mode = GameMode.INFINITE}) async {
  try {
    _gameName = name;
    
    // ✅ GÉNÉRATION UUID: Toujours générer un nouveau UUID v4
    _partieId = const Uuid().v4();
    
    // ✅ RESET: Réinitialiser l'état de jeu
    reset();

    _gameMode = mode;

    // ✅ MODE COMPÉTITIF: Définir le temps de début
    if (mode == GameMode.COMPETITIVE) {
      _competitiveStartTime = _clock.now();
    } else {
      _competitiveStartTime = null;
    }

    // ✅ NOTIFICATION: notifyListeners()
    notifyListeners();

    print('Nouvelle partie créée: $name, mode: $mode');

    return;
  } catch (e, stackTrace) {
    print('Erreur lors de la création d\'une nouvelle partie: $e');
    print(stackTrace);
    // ✅ EXCEPTION: Lever une SaveError
    throw SaveError('CREATE_ERROR', 'Impossible de créer une nouvelle partie: $e');
  }
}
```

**Points Positifs** :
- ✅ **UUID v4 toujours généré** (ID-first)
- ✅ Reset complet de l'état
- ✅ Mode compétitif géré
- ✅ Exception levée en cas d'erreur

**Points d'Attention** :
- ⚠️ Pas de sauvegarde locale ici - **Intentionnel** (orchestré par Coordinator)
- ⚠️ `print()` au lieu de logger - **À améliorer**

---

## 💾 Flux de Sauvegarde

### 1. AutoSave (Sauvegarde Automatique)

**Déclencheur** : Timer périodique (AutoSaveService)

**Fichier** : `@d:\Coding\AppMobile\paperclip2\lib\services\auto_save_service.dart`

```dart
// Sauvegarde automatique toutes les X secondes
final snapshot = _gameState.toSnapshot();
final validation = SnapshotValidator.validate(snapshot);
if (!validation.isValid) {
  // ❌ ERREUR: Snapshot invalide
  final msg = validation.errors.map((e) => e.toString()).join('; ');
  _logger.error('[AutoSave] Snapshot invalide: $msg');
  return;
}

// ✅ SAUVEGARDE: Via GamePersistenceOrchestrator
await GamePersistenceOrchestrator.instance.requestAutoSave(_gameState);
```

**Points Positifs** :
- ✅ Validation snapshot avant sauvegarde
- ✅ Logs d'erreur si snapshot invalide
- ✅ Utilise l'orchestrateur

---

### 2. Lifecycle Save (Sauvegarde Événementielle)

**Déclencheur** : Événements importants (achat upgrade, choix progression, etc.)

**Fichier** : `@d:\Coding\AppMobile\paperclip2\lib\models\game_state.dart`

```dart
Future<void> saveOnImportantEvent() async {
  try {
    // ✅ ÉVÉNEMENT: Émission pour orchestration externe
    _eventBus.emit(
      GameEvent(
        type: GameEventType.importantEventOccurred,
        source: 'GameState',
        severity: GameEventSeverity.info,
        data: {
          'reason': 'game_state_saveOnImportantEvent',
        },
      ),
    );
  } catch (e) {
    print('Erreur lors de la sauvegarde événementielle: $e');
  }
}
```

**Appelé par** :
- `chooseProgressionPath()` → Choix chemin progression
- `purchaseUpgrade()` → Achat upgrade

**Points Positifs** :
- ✅ Découplage via EventBus
- ✅ Gestion erreur

**Points d'Attention** :
- ⚠️ `print()` au lieu de logger - **À améliorer**

---

### 3. Manual Save (Sauvegarde Manuelle)

**Déclencheur** : Bouton "Sauvegarder" (SaveButton widget)

**Fichier** : `@d:\Coding\AppMobile\paperclip2\lib\widgets\save_button.dart`

```dart
// Sauvegarde manuelle via bouton
await GamePersistenceOrchestrator.instance.requestManualSave(_gameState);

// ✅ NOTIFICATION: Snackbar succès/échec
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Sauvegarde réussie')),
);
```

**Points Positifs** :
- ✅ Notification utilisateur
- ✅ Gestion erreur avec snackbar

---

### 4. Cloud Push (Synchronisation Cloud)

**Déclencheur** : Après sauvegarde locale (si utilisateur connecté)

**Fichier** : `@d:\Coding\AppMobile\paperclip2\lib\services\persistence\game_persistence_orchestrator.dart`

```dart
// Push cloud après sauvegarde locale
final firebaseUser = FirebaseAuthService.instance.currentUser;
if (firebaseUser != null) {
  // ✅ PUSH CLOUD: Via CloudPersistencePort
  await pushCloudForState(state, reason: 'auto_save');
}
```

**Points Positifs** :
- ✅ Vérification utilisateur connecté
- ✅ Raison du push loggée
- ✅ Gestion erreur non bloquante

---

## 🔍 Analyse de Cohérence

### ✅ Points Forts

1. **ID-First Strict**
   - ✅ UUID v4 généré à la création
   - ✅ Invariant vérifié (exception si manquant)
   - ✅ partieId utilisé partout

2. **Validation Snapshot**
   - ✅ SnapshotValidator avant sauvegarde
   - ✅ Logs d'erreur si invalide

3. **Gestion Erreurs**
   - ✅ Exceptions levées (SaveError)
   - ✅ Notifications utilisateur (Snackbar)
   - ✅ Logs détaillés

4. **Cloud-First**
   - ✅ Push immédiat à la création si connecté
   - ✅ Push automatique après sauvegarde
   - ✅ Gestion erreur non bloquante

5. **Logs Complets**
   - ✅ Logs avant/après création
   - ✅ Logs snapshot mondes
   - ✅ Logs push cloud

---

### ⚠️ Points d'Attention

1. **Sauvegarde Locale Initiale**
   - ⚠️ Pas de sauvegarde locale explicite après `startNewGame()`
   - ⚠️ Déléguée à AutoSave (premier cycle)
   - **Risque** : Si crash avant premier autosave, monde perdu
   - **Recommandation** : Ajouter sauvegarde locale immédiate après création

2. **Logs avec `print()`**
   - ⚠️ `GameState.startNewGame()` utilise `print()` au lieu de logger
   - ⚠️ `GameState.saveOnImportantEvent()` utilise `print()` pour erreurs
   - **Recommandation** : Utiliser `_logger` partout

3. **Push Cloud Immédiat**
   - ⚠️ Push hors queue pour création monde
   - **Intentionnel** mais peut échouer si réseau lent
   - **Recommandation** : Ajouter retry automatique

4. **Validation Nom**
   - ✅ Validation min 3 caractères dans dialogue
   - ⚠️ Pas de validation côté GameState
   - **Recommandation** : Ajouter validation dans `startNewGame()`

---

## 🚨 Problèmes Critiques Identifiés

### ❌ CRITIQUE #1 : Pas de Sauvegarde Locale Immédiate

**Problème** :
```dart
// GameRuntimeCoordinator.startNewGameAndStartAutoSave()
await _gameState.startNewGame(name, mode: mode);
// ❌ PAS DE SAUVEGARDE LOCALE ICI
await _autoSaveService.start(); // Premier autosave dans X secondes
```

**Conséquence** : Si l'app crash avant le premier autosave, le monde est perdu

**Solution** :
```dart
await _gameState.startNewGame(name, mode: mode);

// ✅ SAUVEGARDE LOCALE IMMÉDIATE
await GamePersistenceOrchestrator.instance.requestLifecycleSave(
  _gameState,
  reason: 'world_creation_initial',
);

await _autoSaveService.start();
```

---

### ⚠️ ATTENTION #2 : Push Cloud Peut Échouer Silencieusement

**Problème** :
```dart
try {
  await GamePersistenceOrchestrator.instance.pushCloudForState(_gameState, reason: 'world_creation');
} catch (e) {
  // ⚠️ Logger mais ne pas bloquer
  _logger.warn('[Runtime] Failed to push new world to cloud: $e');
}
```

**Conséquence** : Monde créé localement mais pas dans le cloud

**Solution** : Ajouter un flag `pending_cloud_push` et retry automatique

---

### ⚠️ ATTENTION #3 : Validation Nom Manquante dans GameState

**Problème** :
```dart
Future<void> startNewGame(String name, {GameMode mode = GameMode.INFINITE}) async {
  _gameName = name; // ❌ Pas de validation
  // ...
}
```

**Conséquence** : Nom vide ou invalide peut passer

**Solution** :
```dart
Future<void> startNewGame(String name, {GameMode mode = GameMode.INFINITE}) async {
  // ✅ VALIDATION
  if (name.trim().length < 3) {
    throw SaveError('INVALID_NAME', 'Le nom doit contenir au moins 3 caractères');
  }
  _gameName = name.trim();
  // ...
}
```

---

## 📊 Diagramme de Flux

```
┌─────────────────────────────────────────────────────────────┐
│                    CRÉATION D'UN MONDE                       │
└─────────────────────────────────────────────────────────────┘

1. WorldsScreen._createNewWorld()
   │
   ├─→ Vérifier limite MAX_WORLDS
   │   └─→ Si dépassé: Snackbar + return
   │
   ├─→ showNewGameDialog()
   │   ├─→ Validation nom (min 3 car)
   │   └─→ Choix mode (INFINITE/COMPETITIVE)
   │
   ├─→ RuntimeActions.startNewGameAndStartAutoSave()
   │   │
   │   └─→ GameRuntimeCoordinator.startNewGameAndStartAutoSave()
   │       │
   │       ├─→ _autoSaveService.stop()
   │       │
   │       ├─→ Logger snapshot mondes existants
   │       │
   │       ├─→ GameState.startNewGame()
   │       │   ├─→ Générer UUID v4
   │       │   ├─→ reset()
   │       │   ├─→ Définir mode
   │       │   └─→ notifyListeners()
   │       │
   │       ├─→ ❌ CRITIQUE: Pas de sauvegarde locale ici
   │       │
   │       ├─→ Vérifier invariant partieId
   │       │   └─→ Si manquant: throw StateError
   │       │
   │       ├─→ _autoSaveService.start()
   │       │
   │       └─→ Push cloud si connecté
   │           ├─→ Si succès: Log
   │           └─→ Si échec: Warn (non bloquant)
   │
   ├─→ RuntimeActions.startSession()
   │
   └─→ Navigation: IntroductionScreen → MainScreen

┌─────────────────────────────────────────────────────────────┐
│                    SAUVEGARDE D'UN MONDE                     │
└─────────────────────────────────────────────────────────────┘

1. AutoSave (Timer périodique)
   │
   ├─→ GameState.toSnapshot()
   ├─→ SnapshotValidator.validate()
   │   └─→ Si invalide: Log erreur + return
   │
   └─→ GamePersistenceOrchestrator.requestAutoSave()
       ├─→ Sauvegarde locale
       └─→ Push cloud si connecté

2. Lifecycle Save (Événements importants)
   │
   ├─→ GameState.saveOnImportantEvent()
   │   └─→ EventBus.emit()
   │
   └─→ GameRuntimeCoordinator (listener)
       └─→ GamePersistenceOrchestrator.requestLifecycleSave()

3. Manual Save (Bouton utilisateur)
   │
   └─→ GamePersistenceOrchestrator.requestManualSave()
       ├─→ Sauvegarde locale
       ├─→ Push cloud si connecté
       └─→ Snackbar succès/échec
```

---

## 🎯 Recommandations

### Priorité Haute

1. **Ajouter Sauvegarde Locale Immédiate**
   ```dart
   // Dans GameRuntimeCoordinator.startNewGameAndStartAutoSave()
   await _gameState.startNewGame(name, mode: mode);
   
   // ✅ AJOUT: Sauvegarde locale immédiate
   await GamePersistenceOrchestrator.instance.requestLifecycleSave(
     _gameState,
     reason: 'world_creation_initial',
   );
   
   await _autoSaveService.start();
   ```

2. **Ajouter Validation Nom dans GameState**
   ```dart
   Future<void> startNewGame(String name, {GameMode mode = GameMode.INFINITE}) async {
     if (name.trim().length < 3) {
       throw SaveError('INVALID_NAME', 'Le nom doit contenir au moins 3 caractères');
     }
     _gameName = name.trim();
     // ...
   }
   ```

3. **Remplacer `print()` par Logger**
   ```dart
   // AVANT
   print('Nouvelle partie créée: $name, mode: $mode');
   
   // APRÈS
   _logger.info('[GameState] Nouvelle partie créée', code: 'game_created', ctx: {
     'name': name,
     'mode': mode.toString(),
     'partieId': _partieId,
   });
   ```

### Priorité Moyenne

4. **Ajouter Retry Cloud Push**
   - Implémenter retry automatique avec backoff exponentiel
   - Stocker flag `pending_cloud_push` si échec
   - Retry au prochain login

5. **Améliorer Logs**
   - Ajouter contexte (partieId, userId) dans tous les logs
   - Utiliser codes d'erreur standardisés

---

## ✅ Conclusion

### Points Forts
- ✅ Architecture claire et découplée
- ✅ ID-first strict avec invariant
- ✅ Validation snapshot
- ✅ Gestion erreur complète
- ✅ Logs détaillés

### Points Critiques à Corriger
- ❌ **Pas de sauvegarde locale immédiate** après création
- ⚠️ Push cloud peut échouer silencieusement
- ⚠️ Validation nom manquante dans GameState
- ⚠️ `print()` au lieu de logger

### Cohérence Globale
Le flux est **cohérent et complet** mais nécessite **3 corrections critiques** pour être **robuste et sans perte de données**.
