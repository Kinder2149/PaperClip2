# 🎯 Plan Complet de Correction et Unification - PaperClip2

## 📋 Vue d'Ensemble

Ce plan détaille toutes les corrections nécessaires pour résoudre le bug de confusion des mondes et unifier l'architecture du projet selon les principes **Cloud-First** et **ID-First**.

---

## 🔴 PHASE 1 : Corrections Critiques - Identité des Parties (P0)

### **1.1 Corriger `GameState.setPartieId()` avec logs et validation stricte**

**Fichier** : `lib/models/game_state.dart`

**Objectif** : Tracer tous les changements d'identité et détecter les tentatives d'assignation d'ID invalides.

**Actions** :
```dart
void setPartieId(String id) {
  final uuidV4 = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12} ?$');
  if (uuidV4.hasMatch(id)) {
    // AJOUT: Logger le changement d'identité
    if (kDebugMode && _partieId != null && _partieId != id) {
      print('[GameState] ⚠️ Changement de partieId détecté: $_partieId → $id');
    }
    _partieId = id;
  } else {
    // AJOUT: Logger l'erreur au lieu d'ignorer silencieusement
    if (kDebugMode) {
      print('[GameState] ❌ Tentative d\'assignation d\'un partieId invalide (non UUID v4): "$id"');
      print('[GameState] Stack trace:');
      print(StackTrace.current);
    }
    // AJOUT: Lever une exception pour détecter les bugs
    throw ArgumentError('[GameState] partieId doit être un UUID v4 valide, reçu: "$id"');
  }
}
```

**Validation** : Tester avec un ID invalide et vérifier que l'exception est levée.

---

### **1.2 Corriger `GameState.applySnapshot()` pour utiliser `setPartieId()`**

**Fichier** : `lib/models/game_state.dart`

**Objectif** : Garantir que le `partieId` est toujours validé et mis à jour lors du chargement d'un snapshot.

**Actions** :
```dart
// AVANT (BUGUÉ)
final metaPartieId = metadata['partieId'] as String?;
if (_partieId == null && metaPartieId != null && metaPartieId.isNotEmpty) {
  _partieId = metaPartieId;  // Assignation directe sans validation
}

// APRÈS (CORRIGÉ)
final metaPartieId = metadata['partieId'] as String?;
if (metaPartieId != null && metaPartieId.isNotEmpty) {
  try {
    setPartieId(metaPartieId);  // Utilise la validation
  } catch (e) {
    if (kDebugMode) {
      print('[GameState] ⚠️ Snapshot contient un partieId invalide: "$metaPartieId"');
      print('[GameState] Erreur: $e');
    }
    // Ne pas bloquer le chargement, mais signaler le problème
  }
}
```

**Validation** : Charger une partie, puis une autre, et vérifier que le `partieId` change correctement.

---

### **1.3 Ajouter vérification d'intégrité dans `loadGameById()`**

**Fichier** : `lib/services/persistence/game_persistence_orchestrator.dart`

**Objectif** : S'assurer que l'identité de la partie chargée correspond à l'ID demandé.

**Actions** : Ajouter à la fin de `loadGameById()` (ligne ~1485) :
```dart
// AJOUT: Vérification d'intégrité post-chargement
final loadedId = state.partieId;
if (loadedId != id) {
  _logger.error('[LOAD] ⚠️ INCOHÉRENCE CRITIQUE: partieId ne correspond pas', 
    code: 'load_id_mismatch', ctx: {
      'expected': id,
      'actual': loadedId,
    });
  throw StateError(
    'LOAD_ID_MISMATCH: L\'identité de la partie chargée ne correspond pas.\n'
    'Attendu: $id\n'
    'Obtenu: $loadedId\n'
    'Cela indique une corruption des données ou un bug dans le système de sauvegarde.'
  );
}

_logger.info('[LOAD] ✅ Vérification d\'intégrité réussie', code: 'load_integrity_ok', ctx: {
  'partieId': id,
  'gameName': state.gameName,
});
```

**Validation** : Charger plusieurs parties successivement et vérifier les logs.

---

### **1.4 Ajouter logs de traçabilité dans `startNewGame()`**

**Fichier** : `lib/services/game_runtime_coordinator.dart`

**Objectif** : Tracer la création de nouvelles parties et détecter les problèmes d'identité.

**Actions** : Améliorer les logs existants (ligne ~226-232) :
```dart
// AMÉLIORATION: Logs plus détaillés
final newPartieId = _gameState.partieId;
if (newPartieId == null || newPartieId.isEmpty) {
  _logger.error('[WORLD-CREATE] ❌ IDENTITÉ MANQUANTE après startNewGame', 
    code: 'identity_missing', ctx: {
      'gameName': name,
      'gameMode': mode.toString(),
    });
  throw StateError('[IdentityInvariant] partieId manquant après startNewGame("$name"): création invalide');
}

_logger.info('[WORLD-CREATE] ✅ Nouvelle partie créée avec succès', 
  code: 'world_create_success', ctx: {
    'partieId': newPartieId,
    'gameName': name,
    'gameMode': mode.toString(),
  });
```

**Validation** : Créer une nouvelle partie et vérifier les logs.

---

## 🟡 PHASE 2 : Renforcement de la Persistance (P1)

### **2.1 Auditer `LocalSaveGameManager.activeSaveId` et sa synchronisation**

**Fichier** : `lib/services/save_system/local_save_game_manager.dart`

**Objectif** : S'assurer que `activeSaveId` est toujours synchronisé avec `GameState.partieId`.

**Actions** :
1. Ajouter un log dans le setter `activeSaveId` pour tracer les changements
2. Vérifier que `loadSave()` met bien à jour `activeSaveId` (ligne ~254)
3. Vérifier que `saveGame()` utilise bien le `save.id` fourni (ligne ~394)

**Code à ajouter** :
```dart
@override
set activeSaveId(String? id) {
  if (kDebugMode && _activeSaveId != null && _activeSaveId != id) {
    _logger.info('Changement activeSaveId: $_activeSaveId → $id');
  }
  _activeSaveId = id;
  _logger.info('Sauvegarde active définie: $id');
}
```

**Validation** : Charger plusieurs parties et vérifier que `activeSaveId` suit correctement.

---

### **2.2 Vérifier la cohérence des métadonnées lors des sauvegardes**

**Fichier** : `lib/services/persistence/game_persistence_orchestrator.dart`

**Objectif** : Garantir que les métadonnées du snapshot correspondent toujours à l'état actuel.

**Actions** : Dans `saveGame()` (ligne ~688), renforcer la vérification :
```dart
// RENFORCEMENT: Vérification stricte de cohérence
if (!isBackupName) {
  final snapPartieId = snapshot.metadata['partieId'];
  final snapGameName = snapshot.metadata['gameId'];
  
  if (snapPartieId is! String || snapPartieId.isEmpty) {
    throw SaveError('PARTIE_ID_MISSING', 'Snapshot sans metadata.partieId');
  }
  
  if (state.partieId != null && state.partieId!.isNotEmpty && snapPartieId != state.partieId) {
    _logger.error('[SAVE] ⚠️ INCOHÉRENCE: metadata.partieId ne correspond pas', 
      code: 'save_id_mismatch', ctx: {
        'statePartieId': state.partieId,
        'snapPartieId': snapPartieId,
        'saveName': name,
      });
    throw SaveError('PARTIE_ID_MISMATCH', 
      'metadata.partieId ($snapPartieId) ne correspond pas à state.partieId (${state.partieId})');
  }
  
  // AJOUT: Vérifier aussi le nom du jeu
  if (snapGameName != state.gameName) {
    _logger.warn('[SAVE] ⚠️ Nom de jeu différent', code: 'save_name_mismatch', ctx: {
      'stateGameName': state.gameName,
      'snapGameName': snapGameName,
    });
  }
}
```

**Validation** : Sauvegarder plusieurs parties et vérifier les logs.

---

### **2.3 Renforcer `SnapshotValidator` avec vérifications `partieId`**

**Fichier** : `lib/services/persistence/snapshot_validator.dart`

**Objectif** : Valider le format UUID v4 du `partieId` dans les snapshots.

**Actions** : Ajouter une validation UUID v4 :
```dart
// AJOUT: Validation UUID v4 pour partieId
static bool _isValidUuidV4(String? value) {
  if (value == null || value.isEmpty) return false;
  final uuidV4 = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$');
  return uuidV4.hasMatch(value);
}

// Dans validateSnapshot(), ajouter :
final partieId = metadata['partieId'] as String?;
if (partieId == null || partieId.isEmpty) {
  errors.add('metadata.partieId manquant');
} else if (!_isValidUuidV4(partieId)) {
  errors.add('metadata.partieId n\'est pas un UUID v4 valide: "$partieId"');
}
```

**Validation** : Créer un snapshot avec un `partieId` invalide et vérifier que la validation échoue.

---

## 🟢 PHASE 3 : Amélioration SaveAggregator et UI (P2)

### **3.1 Ajouter logs détaillés dans `SaveAggregator.listAll()`**

**Fichier** : `lib/services/persistence/save_aggregator.dart`

**Objectif** : Tracer la construction de la liste des mondes pour détecter les doublons.

**Actions** : Ajouter des logs dans `listAll()` :
```dart
// AJOUT: Logs de traçabilité
_logger.info('[AGGREGATOR] Construction liste mondes', code: 'list_start', ctx: {
  'cloudCount': cloudIndex.length,
  'localCount': localIndex.length,
});

// Dans la boucle cloud (ligne ~146)
for (final cloudEntry in cloudIndex.values) {
  final localInfo = localIndex[cloudEntry.partieId];
  
  if (localInfo != null) {
    _logger.debug('[AGGREGATOR] Monde cloud+local: ${cloudEntry.partieId}');
    // ... reste du code
  } else {
    _logger.debug('[AGGREGATOR] Monde cloud-only: ${cloudEntry.partieId}');
    // ... reste du code
  }
}

// Dans la boucle local (ligne ~210)
for (final localInfo in localInfos) {
  if (localInfo.isBackup) continue;
  if (cloudIndex.containsKey(localInfo.id)) continue;
  
  _logger.debug('[AGGREGATOR] Monde local-only: ${localInfo.id}');
  // ... reste du code
}

// À la fin
_logger.info('[AGGREGATOR] Liste construite', code: 'list_complete', ctx: {
  'totalEntries': result.length,
  'cloudSynced': result.where((e) => e.cloudSyncState == 'in_sync').length,
  'localOnly': result.where((e) => e.source == SaveSource.local).length,
});
```

**Validation** : Charger la liste des mondes et vérifier les logs.

---

### **3.2 Améliorer gestion des erreurs dans `WorldsScreen._load()`**

**Fichier** : `lib/screens/worlds_screen.dart`

**Objectif** : Afficher des messages d'erreur clairs à l'utilisateur.

**Actions** : Remplacer le catch silencieux (ligne ~665) :
```dart
// AVANT (SILENCIEUX)
} catch (_) {
  if (!mounted) return;
  setState(() => _loading = false);
  // Erreurs silencieuses pour un premier squelette
}

// APRÈS (INFORMATIF)
} catch (e, stack) {
  _logger.error('[WORLDS] Erreur chargement liste mondes', 
    code: 'worlds_load_error', ctx: {
      'error': e.toString(),
    });
  
  if (!mounted) return;
  setState(() => _loading = false);
  
  // Afficher un message à l'utilisateur
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Erreur lors du chargement des mondes: ${e.toString()}'),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: 'Réessayer',
        textColor: Colors.white,
        onPressed: () => _load(forceRefresh: true),
      ),
    ),
  );
}
```

**Validation** : Simuler une erreur et vérifier l'affichage du message.

---

## 🔵 PHASE 4 : Tests et Validation (P2)

### **4.1 Créer tests unitaires pour `setPartieId` et `applySnapshot`**

**Fichier** : `test/unit/game_state_identity_test.dart` (à créer)

**Objectif** : Valider le comportement de gestion de l'identité.

**Actions** :
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/models/game_state.dart';

void main() {
  group('GameState Identity Management', () {
    late GameState gameState;
    
    setUp(() {
      gameState = GameState();
    });
    
    test('setPartieId accepte un UUID v4 valide', () {
      const validUuid = '550e8400-e29b-41d4-a716-446655440000';
      expect(() => gameState.setPartieId(validUuid), returnsNormally);
      expect(gameState.partieId, equals(validUuid));
    });
    
    test('setPartieId rejette un UUID invalide', () {
      const invalidUuid = 'not-a-valid-uuid';
      expect(() => gameState.setPartieId(invalidUuid), throwsArgumentError);
    });
    
    test('applySnapshot met à jour le partieId correctement', () {
      const uuid1 = '550e8400-e29b-41d4-a716-446655440000';
      const uuid2 = '660e8400-e29b-41d4-a716-446655440001';
      
      gameState.setPartieId(uuid1);
      expect(gameState.partieId, equals(uuid1));
      
      // Créer un snapshot avec un nouveau partieId
      final snapshot = GameSnapshot(
        metadata: {'partieId': uuid2, 'gameId': 'Test'},
        core: {},
        stats: {},
      );
      
      gameState.applySnapshot(snapshot);
      expect(gameState.partieId, equals(uuid2));
    });
  });
}
```

**Validation** : Exécuter `flutter test test/unit/game_state_identity_test.dart`

---

### **4.2 Créer tests d'intégration multi-mondes**

**Fichier** : `integration_test/multi_world_test.dart` (à créer)

**Objectif** : Valider le scénario complet de gestion multi-mondes.

**Actions** :
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paperclip2/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Multi-World Management', () {
    testWidgets('Créer et alterner entre deux mondes sans perte de données', 
      (WidgetTester tester) async {
      // Lancer l'app
      app.main();
      await tester.pumpAndSettle();
      
      // 1. Créer monde 1
      await tester.tap(find.text('Créer un monde'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Monde 1');
      await tester.tap(find.text('Créer'));
      await tester.pumpAndSettle();
      
      // 2. Jouer jusqu'au niveau 3
      // ... (actions de jeu)
      
      // 3. Retour à la liste des mondes
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      
      // 4. Vérifier que Monde 1 est présent
      expect(find.text('Monde 1'), findsOneWidget);
      
      // 5. Créer monde 2
      await tester.tap(find.text('Créer un monde'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Monde 2');
      await tester.tap(find.text('Créer'));
      await tester.pumpAndSettle();
      
      // 6. Retour à la liste
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      
      // 7. VÉRIFICATION CRITIQUE: Les deux mondes doivent être présents
      expect(find.text('Monde 1'), findsOneWidget);
      expect(find.text('Monde 2'), findsOneWidget);
      
      // 8. Charger Monde 1
      await tester.tap(find.text('Monde 1'));
      await tester.pumpAndSettle();
      
      // 9. Retour à la liste
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      
      // 10. VÉRIFICATION FINALE: Aucune perte de données
      expect(find.text('Monde 1'), findsOneWidget);
      expect(find.text('Monde 2'), findsOneWidget);
    });
  });
}
```

**Validation** : Exécuter `flutter test integration_test/multi_world_test.dart`

---

### **4.3 Valider le scénario utilisateur complet**

**Objectif** : Reproduire exactement le scénario du bug rapporté.

**Actions** :
1. Connexion utilisateur
2. Créer partie 1
3. Récupérer partie 2 depuis le cloud
4. Jouer partie 1 jusqu'au niveau 3, sauvegarder
5. Retour page mondes → **Vérifier affichage correct**
6. Charger partie 2, jouer, sauvegarder
7. Retour page mondes → **Vérifier : pas de perte de partie 1**
8. Alterner entre les parties 3-4 fois
9. **Vérifier les logs** : Tracer tous les changements de `partieId`

**Critères de succès** :
- ✅ Les deux parties restent distinctes
- ✅ Aucune perte de données
- ✅ Aucune duplication
- ✅ Logs clairs et traçables

---

## 📊 Checklist de Validation Finale

### **Corrections Critiques (P0)**
- [ ] `GameState.setPartieId()` lève une exception pour ID invalide
- [ ] `GameState.applySnapshot()` utilise `setPartieId()` au lieu d'assignation directe
- [ ] `loadGameById()` vérifie l'intégrité post-chargement
- [ ] `startNewGame()` trace la création avec logs détaillés

### **Renforcement Persistance (P1)**
- [ ] `LocalSaveGameManager.activeSaveId` est synchronisé avec `GameState.partieId`
- [ ] Métadonnées de sauvegarde vérifiées pour cohérence
- [ ] `SnapshotValidator` valide le format UUID v4 du `partieId`

### **Amélioration UI (P2)**
- [ ] `SaveAggregator.listAll()` trace la construction de la liste
- [ ] `WorldsScreen._load()` affiche des messages d'erreur clairs

### **Tests (P2)**
- [ ] Tests unitaires pour `setPartieId` et `applySnapshot` passent
- [ ] Tests d'intégration multi-mondes passent
- [ ] Scénario utilisateur complet validé sans bug

---

## 🚀 Ordre d'Exécution Recommandé

1. **Nettoyer `game_state.dart`** : Exécuter `python scripts/fix_game_state_nullbytes.py`
2. **Appliquer Phase 1** : Corrections critiques (1.1 à 1.4)
3. **Tester manuellement** : Reproduire le scénario du bug
4. **Appliquer Phase 2** : Renforcement persistance (2.1 à 2.3)
5. **Appliquer Phase 3** : Amélioration UI (3.1 à 3.2)
6. **Appliquer Phase 4** : Tests automatisés (4.1 à 4.3)
7. **Validation finale** : Checklist complète

---

## 📝 Notes Importantes

- **Sauvegarde** : Créer une branche Git avant toute modification
- **Tests continus** : Tester après chaque phase
- **Logs** : Activer le mode debug pour voir tous les logs
- **Documentation** : Mettre à jour `docs/` avec les changements

---

## 🎯 Résultat Attendu

Après l'application complète de ce plan :
- ✅ **Zéro perte de données** lors des changements de monde
- ✅ **Identité stricte** : Chaque partie a un `partieId` UUID v4 unique et immuable
- ✅ **Traçabilité complète** : Tous les changements d'identité sont loggés
- ✅ **Validation robuste** : Les snapshots corrompus sont détectés et rejetés
- ✅ **Tests automatisés** : Le bug ne peut plus réapparaître
- ✅ **Conformité Cloud-First** : Architecture unifiée selon les invariants système
