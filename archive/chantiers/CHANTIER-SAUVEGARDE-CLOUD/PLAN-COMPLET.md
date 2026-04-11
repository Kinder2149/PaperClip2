# CHANTIER - SAUVEGARDE CLOUD : Plan Complet

## 🎯 Objectif

Vérifier et corriger le système de sauvegarde cloud pour garantir la synchronisation bidirectionnelle, la résolution de conflits avec choix utilisateur, et l'intégrité complète des données.

## 📊 État Actuel - Ce qui Fonctionne

### ✅ Firebase Auth
- Connexion Google opérationnelle
- Token Firebase disponible
- Connexion silencieuse fonctionnelle
- Vérification auth centralisée

### ✅ Cloud API
- Endpoints REST `/enterprise/{uid}` fonctionnels
- Push/Pull/Delete opérationnels
- Retry automatique avec timeouts
- Validation UUID v4

### ✅ Synchronisation Basique
- Sync au login fonctionnelle
- Push local → cloud si cloud vide
- Pull cloud → local si local vide
- Détection de conflits (diff timestamps)

## ❌ Problèmes Critiques Identifiés

### 1. Pas de Résolution de Conflits Utilisateur

**Situation** : Local niveau 20, Cloud niveau 50

**Comportement actuel** :
```dart
// _syncFromCloudAtLogin() ligne 1975
if (diff.inMinutes > 5) {
  // ⚠️ Notification seulement
  NotificationManager.instance.showNotification(
    message: '⚠️ Conflit détecté: cloud appliqué',
  );
  // ❌ Cloud wins automatiquement
  // ❌ Perte données locales sans confirmation
}
```

**Comportement attendu** :
- Afficher écran avec stats des deux versions
- Bouton "Garder Local" → Supprime cloud + push local
- Bouton "Garder Cloud" → Supprime local + pull cloud
- Suppression réelle de la version non choisie

### 2. Pas de Vérification Intégrité Complète

**À vérifier** :
- Toutes les propriétés GameState sont-elles sauvegardées ?
- Missions, recherches, agents, ressources rares ?
- Métadonnées entreprise complètes ?

## 🛠️ Corrections à Implémenter

### Correction 1 : Écran de Résolution de Conflits

**Fichier** : `lib/screens/conflict_resolution_screen.dart`

**Statut** : ✅ Créé

**Fonctionnalités** :
- Affichage stats comparatives (niveau, paperclips, money, temps de jeu, date)
- Bouton "Garder Local" (bleu)
- Bouton "Garder Cloud" (vert)
- Empêche retour arrière sans choix
- Retourne `ConflictChoice` enum

**Problème identifié** : Erreur `shade50` et `shade900` sur `Color`
- **Solution** : Changer paramètre `color` de `Color` à `MaterialColor`

### Correction 2 : Ajouter Méthodes dans GamePersistenceOrchestrator

**Fichier** : `lib/services/persistence/game_persistence_orchestrator.dart`

**Méthodes à ajouter** :

```dart
// 1. Setter pour BuildContext
BuildContext? _navigationContext;

void setNavigationContext(BuildContext? context) {
  _navigationContext = context;
}

// 2. Afficher écran de résolution
Future<ConflictChoice?> _showConflictResolution({
  required GameSnapshot localSnapshot,
  required GameSnapshot cloudSnapshot,
  required String enterpriseId,
}) async {
  final context = _navigationContext;
  if (context == null || !context.mounted) {
    _logger.warn('[CONFLICT] Pas de contexte de navigation');
    return null;
  }

  final choice = await Navigator.of(context).push<ConflictChoice>(
    MaterialPageRoute(
      builder: (context) => ConflictResolutionScreen(
        data: ConflictResolutionData(
          localSnapshot: localSnapshot,
          cloudSnapshot: cloudSnapshot,
          enterpriseId: enterpriseId,
        ),
      ),
    ),
  );
  
  return choice;
}

// 3. Extraire snapshot depuis SaveGame
GameSnapshot _extractSnapshot(SaveGame save) {
  final data = save.gameData;
  final snapshotKey = LocalGamePersistenceService.snapshotKey;
  final rawSnapshot = data[snapshotKey];
  
  if (rawSnapshot is Map<String, dynamic>) {
    return GameSnapshot.fromJson(rawSnapshot);
  } else if (rawSnapshot is Map) {
    return GameSnapshot.fromJson(Map<String, dynamic>.from(rawSnapshot));
  } else if (rawSnapshot is String) {
    return GameSnapshot.fromJsonString(rawSnapshot);
  }
  
  throw StateError('Snapshot format invalide');
}
```

### Correction 3 : Modifier `_syncFromCloudAtLogin()`

**Fichier** : `lib/services/persistence/game_persistence_orchestrator.dart:1975`

**Changement** :

```dart
// AVANT
if (diff.inMinutes > 5) {
  NotificationManager.instance.showNotification(...);
  // Continue avec cloud wins
}

// APRÈS
if (diff.inMinutes > 5) {
  _logger.info('[CONFLICT] Conflit détecté', code: 'conflict_detected', ctx: {
    'enterpriseId': enterpriseId,
    'diffMinutes': diff.inMinutes,
  });
  
  // Charger snapshot local
  final localSave = await _loadSaveByIdViaLocalManager(enterpriseId);
  if (localSave == null) {
    // Si local n'existe plus, appliquer cloud
    await _importCloudObject(...);
    return;
  }
  
  final localSnapshot = _extractSnapshot(localSave);
  final cloudSnapshot = GameSnapshot.fromJson(cloudObj);
  
  // Afficher écran de choix
  final choice = await _showConflictResolution(
    localSnapshot: localSnapshot,
    cloudSnapshot: cloudSnapshot,
    enterpriseId: enterpriseId,
  );
  
  if (choice == ConflictChoice.keepLocal) {
    _logger.info('[CONFLICT] Choix: garder local', code: 'conflict_keep_local');
    
    // Supprimer cloud
    await port.deleteById(enterpriseId: enterpriseId);
    
    // Push local vers cloud
    await pushCloudFromSaveId(
      enterpriseId: enterpriseId,
      uid: playerId!,
      reason: 'conflict_resolution_keep_local',
    );
    
    NotificationManager.instance.showNotification(
      message: '✅ Version locale conservée et synchronisée',
      level: NotificationLevel.SUCCESS,
    );
  } else if (choice == ConflictChoice.keepCloud) {
    _logger.info('[CONFLICT] Choix: garder cloud', code: 'conflict_keep_cloud');
    
    // Supprimer local
    await _deleteSaveByIdViaLocalManager(enterpriseId);
    
    // Appliquer cloud
    await _importCloudObject(
      enterpriseId: enterpriseId,
      obj: cloudObj,
      cloudName: cloudName,
    );
    
    NotificationManager.instance.showNotification(
      message: '✅ Version cloud conservée et appliquée',
      level: NotificationLevel.SUCCESS,
    );
  } else {
    // Cancel ou null → ne rien faire
    _logger.warn('[CONFLICT] Choix annulé', code: 'conflict_cancelled');
    NotificationManager.instance.showNotification(
      message: '⚠️ Résolution de conflit annulée',
      level: NotificationLevel.WARNING,
    );
  }
  
  return;
}
```

### Correction 4 : Injecter BuildContext

**Fichier** : `lib/services/app_bootstrap_controller.dart`

**Localisation** : Méthode `_installFirebaseAuthListener()` ou `_onAuthStateChanged()`

**Changement** :

```dart
// Après connexion Firebase réussie
if (user != null) {
  final uid = user.uid;
  
  // Injecter contexte de navigation
  final context = _navigationContext; // À obtenir depuis le widget
  GamePersistenceOrchestrator.instance.setNavigationContext(context);
  
  // Lancer sync
  await GamePersistenceOrchestrator.instance.syncAllWorldsFromCloud(
    playerId: uid,
  );
}
```

**Note** : Le `BuildContext` doit être passé au `AppBootstrapController` depuis le widget racine.

## 📝 Tests à Créer

### Tests Backend Cloud (8 tests)

**Fichier** : `test/cloud/cloud_backend_test.dart`

```dart
group('Cloud Backend Tests', () {
  test('Connexion Google retourne token valide', () async {
    // Test Firebase Auth
  });
  
  test('Push cloud envoie données correctement', () async {
    // Test CloudPersistenceAdapter.pushById()
  });
  
  test('Pull cloud reçoit données correctement', () async {
    // Test CloudPersistenceAdapter.pullById()
  });
  
  test('Liste entreprises retourne entreprise utilisateur', () async {
    // Test CloudPersistenceAdapter.listParties()
  });
  
  test('Suppression cloud supprime entreprise', () async {
    // Test CloudPersistenceAdapter.deleteById()
  });
  
  test('Retry automatique fonctionne', () async {
    // Test CloudRetryPolicy
  });
  
  test('Timeout respecté (60s push, 30s pull)', () async {
    // Test timeouts
  });
  
  test('Validation UUID rejette IDs invalides', () async {
    // Test _validateEnterpriseId()
  });
});
```

### Tests Synchronisation (6 tests)

**Fichier** : `test/cloud/cloud_sync_test.dart`

```dart
group('Cloud Sync Tests', () {
  test('Sync bidirectionnelle Local ↔ Cloud', () async {
    // Test push puis pull
  });
  
  test('Connexion tardive - Cloud vide → Push local', () async {
    // Scénario 3
  });
  
  test('Connexion tardive - Local vide → Pull cloud', () async {
    // Scénario 2
  });
  
  test('Connexion tardive - Conflit → Affiche fenêtre', () async {
    // Scénario 4 - Vérifier que ConflictResolutionScreen s'affiche
  });
  
  test('Résolution conflit - Garder local → Supprime cloud', () async {
    // Vérifier que cloud est supprimé et local poussé
  });
  
  test('Résolution conflit - Garder cloud → Supprime local', () async {
    // Vérifier que local est supprimé et cloud appliqué
  });
});
```

### Tests Intégrité Données (10 tests)

**Fichier** : `test/cloud/cloud_data_integrity_test.dart`

```dart
group('Cloud Data Integrity Tests', () {
  test('PlayerManager - Toutes propriétés sauvegardées', () async {
    // Vérifier paperclips, money, metal, etc.
  });
  
  test('MarketManager - Toutes propriétés sauvegardées', () async {
    // Vérifier prix, auto-sell, etc.
  });
  
  test('LevelSystem - Niveau + XP sauvegardés', () async {
    // Vérifier level, experience
  });
  
  test('MissionSystem - Missions sauvegardées', () async {
    // Vérifier missions actives, complétées
  });
  
  test('RareResourcesManager - Quantum + PI sauvegardés', () async {
    // Vérifier quantum, pointsInnovation
  });
  
  test('ResearchManager - Recherches sauvegardées', () async {
    // Vérifier recherches débloquées
  });
  
  test('AgentManager - Agents sauvegardés', () async {
    // Vérifier agents IA
  });
  
  test('ResetManager - Historique sauvegardé', () async {
    // Vérifier historique resets
  });
  
  test('ProductionManager - Production sauvegardée', () async {
    // Vérifier production, upgrades
  });
  
  test('Métadonnées - Nom, ID, dates sauvegardés', () async {
    // Vérifier enterpriseName, enterpriseId, createdAt, lastModified
  });
});
```

### Tests Gestion Erreurs (5 tests)

**Fichier** : `test/cloud/cloud_error_handling_test.dart`

```dart
group('Cloud Error Handling Tests', () {
  test('Erreur réseau → Retry automatique', () async {
    // Simuler erreur réseau
  });
  
  test('Erreur auth → Message utilisateur', () async {
    // Simuler token expiré
  });
  
  test('Erreur backend → Gestion 500/503', () async {
    // Simuler erreur serveur
  });
  
  test('Timeout → Annulation après délai', () async {
    // Simuler timeout
  });
  
  test('Offline → Sauvegarde locale continue', () async {
    // Vérifier que local fonctionne sans cloud
  });
});
```

### Tests Widget (3 tests)

**Fichier** : `test/cloud/conflict_resolution_widget_test.dart`

```dart
group('ConflictResolutionScreen Tests', () {
  testWidgets('Affiche stats correctement', (tester) async {
    // Vérifier affichage niveau, paperclips, money, etc.
  });
  
  testWidgets('Bouton Garder Local fonctionne', (tester) async {
    // Tap sur bouton, vérifier retour ConflictChoice.keepLocal
  });
  
  testWidgets('Bouton Garder Cloud fonctionne', (tester) async {
    // Tap sur bouton, vérifier retour ConflictChoice.keepCloud
  });
});
```

## 🚀 Plan d'Exécution

### Phase 1 : Corrections Critiques (4h)

**Priorité HAUTE**

1. ✅ Créer `ConflictResolutionScreen` (FAIT)
2. ❌ Corriger erreur `MaterialColor` dans `ConflictResolutionScreen`
3. ❌ Ajouter méthodes dans `GamePersistenceOrchestrator` :
   - `setNavigationContext()`
   - `_showConflictResolution()`
   - `_extractSnapshot()`
4. ❌ Modifier `_syncFromCloudAtLogin()` pour résolution conflits
5. ❌ Injecter `BuildContext` depuis `AppBootstrapController`
6. ❌ Tester manuellement le flux de résolution de conflits

### Phase 2 : Tests Automatisés (4h)

**Priorité MOYENNE**

1. ❌ Créer `test/cloud/cloud_backend_test.dart` (8 tests)
2. ❌ Créer `test/cloud/cloud_sync_test.dart` (6 tests)
3. ❌ Créer `test/cloud/cloud_data_integrity_test.dart` (10 tests)
4. ❌ Créer `test/cloud/cloud_error_handling_test.dart` (5 tests)
5. ❌ Créer `test/cloud/conflict_resolution_widget_test.dart` (3 tests)

### Phase 3 : Validation (2h)

**Priorité HAUTE**

1. ❌ Exécuter tous les tests (32 tests minimum)
2. ❌ Corriger les échecs
3. ❌ Build APK et test manuel complet
4. ❌ Vérifier tous les scénarios :
   - Première connexion Google
   - Connexion avec cloud existant
   - Connexion tardive (local avancé, cloud vide)
   - Connexion tardive (local avancé, cloud avancé) → **CRITIQUE**
5. ❌ Documentation finale

## ✅ Critères de Validation

La mission sera validée quand :

1. ✅ Connexion Google fonctionne
2. ✅ Utilisateur créé automatiquement dans backend
3. ✅ Entreprise associée à l'UID Firebase
4. ✅ Sync bidirectionnelle fonctionne (local ↔ cloud)
5. ❌ **Fenêtre de choix affichée en cas de conflit**
6. ❌ **Suppression réelle de la partie non choisie**
7. ❌ **Toutes les données sauvegardées** (ressources, missions, recherches)
8. ✅ Gestion erreurs robuste (réseau, auth, backend)
9. ❌ **Tous les tests passent** (32 tests minimum)
10. ❌ **Build APK réussi** et test manuel validé

## 📊 Statut Global

| Composant | Statut | Commentaire |
|-----------|--------|-------------|
| Firebase Auth | ✅ | Fonctionnel |
| Cloud API | ✅ | Fonctionnel |
| Sync basique | ✅ | Fonctionnel |
| **Résolution conflits** | ❌ | **À implémenter** |
| Tests backend | ❌ | À créer (8 tests) |
| Tests sync | ❌ | À créer (6 tests) |
| Tests intégrité | ❌ | À créer (10 tests) |
| Tests erreurs | ❌ | À créer (5 tests) |
| Tests widget | ❌ | À créer (3 tests) |

**Estimation totale** : 10h de travail

**Prochaine action** : Corriger `ConflictResolutionScreen` puis ajouter méthodes dans `GamePersistenceOrchestrator`
