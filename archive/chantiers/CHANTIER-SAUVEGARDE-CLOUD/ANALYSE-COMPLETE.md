# ANALYSE COMPLÈTE - SAUVEGARDE CLOUD

## 📊 Architecture Actuelle

### 1. Firebase Auth (`firebase_auth_service.dart`)

**✅ Fonctionnel**
- Connexion Google via `signInWithGoogle()`
- Token Firebase via `getIdToken()`
- Connexion silencieuse via `ensureSignedInSilently()`
- Vérification auth via `ensureAuthenticatedForCloud()`

**Flux de connexion** :
```
User clique "Se connecter avec Google"
  → signInWithGoogle()
  → GoogleSignIn.authenticate()
  → Firebase.signInWithCredential()
  → Token Firebase disponible
  → currentUser.uid disponible
```

### 2. Cloud Persistence (`cloud_persistence_adapter.dart`)

**✅ Fonctionnel**
- API REST `/enterprise/{uid}` (CHANTIER-01)
- Push cloud via `pushById()`
- Pull cloud via `pullById()`
- Liste entreprises via `listParties()`
- Suppression via `deleteById()`
- Validation UUID v4
- Retry policy avec timeouts (60s push, 30s pull)

**Endpoints** :
```
PUT    /enterprise/{uid}  → Sauvegarde entreprise
GET    /enterprise/{uid}  → Récupération entreprise
DELETE /enterprise/{uid}  → Suppression entreprise
```

### 3. Game Persistence Orchestrator

**✅ Fonctionnel**
- Orchestration local + cloud
- Queue de sauvegarde avec priorités
- Backup automatique
- Sync au login via `syncAllWorldsFromCloud()`

**⚠️ Problème Identifié : Pas de résolution de conflits utilisateur**

#### Comportement Actuel (ligne 1925-2007)
```dart
Future<void> _syncFromCloudAtLogin({
  required String enterpriseId,
  String? playerId,
}) async {
  // Récupérer cloud
  final cloudStatus = await port.statusById(enterpriseId: enterpriseId);
  final cloudExists = cloudStatus.exists;
  
  if (cloudExists && cloudObj != null) {
    // Détection conflit (ligne 1975)
    if (diff.inMinutes > 5) {
      // ⚠️ NOTIFICATION SEULEMENT, PAS DE CHOIX
      NotificationManager.instance.showNotification(
        message: '⚠️ Conflit détecté: cloud appliqué',
      );
    }
    
    // ⚠️ TOUJOURS APPLIQUER CLOUD (cloud wins)
    await _importCloudObject(...);
    return;
  }
  
  // Si cloud n'existe pas → push local
  if (localMeta != null) {
    await pushCloudFromSaveId(...);
  }
}
```

**Problèmes** :
1. ❌ Pas d'interface de choix utilisateur
2. ❌ "Cloud always wins" sans demander
3. ❌ Notification mais pas de suppression de la version non choisie

### 4. App Bootstrap (`app_bootstrap_controller.dart`)

**✅ Fonctionnel**
- Installe listener Firebase Auth (ligne 132)
- Déclenche sync cloud au login
- Gère le cycle de vie de l'app

**Flux au démarrage** :
```
App démarre
  → _installFirebaseAuthListener()
  → authStateChanges().listen()
  → Si user connecté → syncAllWorldsFromCloud()
  → Navigation vers écran approprié
```

## 🔍 Analyse des Scénarios

### Scénario 1 : Première Connexion Google

**État** : Local vide, Cloud vide

**Flux actuel** :
```
1. User se connecte à Google
2. Firebase Auth → uid disponible
3. syncAllWorldsFromCloud()
   → listParties() retourne []
   → Aucune entreprise cloud
4. Si local existe → push vers cloud
5. Sinon → Création nouvelle entreprise
```

**✅ Fonctionne correctement**

### Scénario 2 : Connexion Google avec Cloud Existant

**État** : Local vide, Cloud avec entreprise

**Flux actuel** :
```
1. User se connecte à Google
2. syncAllWorldsFromCloud()
   → listParties() retourne [entreprise]
   → _syncFromCloudAtLogin()
   → Cloud exists → pull cloud
   → _importCloudObject()
3. Entreprise restaurée localement
```

**✅ Fonctionne correctement**

### Scénario 3 : Connexion Tardive (Local Avancé, Cloud Vide)

**État** : Local niveau 20, Cloud vide

**Flux actuel** :
```
1. User joue offline → niveau 20
2. User se connecte à Google
3. syncAllWorldsFromCloud()
   → listParties() retourne []
   → Détecte local orphelin
   → pushCloudFromSaveId()
4. Local poussé vers cloud
```

**✅ Fonctionne correctement**

### Scénario 4 : Connexion Tardive (Local Avancé, Cloud Avancé)

**État** : Local niveau 20, Cloud niveau 50

**Flux actuel** :
```
1. User joue offline → niveau 20
2. User se connecte à Google (autre appareil avait niveau 50)
3. syncAllWorldsFromCloud()
   → _syncFromCloudAtLogin()
   → Cloud exists (niveau 50)
   → Détecte conflit (diff > 5 min)
   → ⚠️ NOTIFICATION SEULEMENT
   → ⚠️ CLOUD WINS (niveau 50 appliqué)
   → ❌ LOCAL NIVEAU 20 PERDU
```

**❌ PROBLÈME CRITIQUE**
- Pas de choix utilisateur
- Perte de données locale sans confirmation
- Pas de suppression explicite

## 🛠️ Corrections Nécessaires

### Correction 1 : Écran de Résolution de Conflits

**Fichier créé** : `lib/screens/conflict_resolution_screen.dart`

**Fonctionnalités** :
- ✅ Affichage stats comparatives (niveau, paperclips, money, temps de jeu)
- ✅ Bouton "Garder Local"
- ✅ Bouton "Garder Cloud"
- ✅ Empêche retour arrière sans choix
- ✅ Retourne `ConflictChoice` enum

### Correction 2 : Modifier `_syncFromCloudAtLogin()`

**Fichier** : `lib/services/persistence/game_persistence_orchestrator.dart:1925`

**Changements requis** :
```dart
// AVANT (ligne 1975)
if (diff.inMinutes > 5) {
  NotificationManager.instance.showNotification(...);
  // Continue avec cloud wins
}

// APRÈS
if (diff.inMinutes > 5) {
  // Charger snapshot local
  final localSave = await _loadSaveByIdViaLocalManager(enterpriseId);
  final localSnapshot = _extractSnapshot(localSave);
  
  // Afficher écran de choix
  final choice = await _showConflictResolution(
    localSnapshot: localSnapshot,
    cloudSnapshot: GameSnapshot.fromJson(cloudObj),
    enterpriseId: enterpriseId,
  );
  
  if (choice == ConflictChoice.keepLocal) {
    // Supprimer cloud + push local
    await port.deleteById(enterpriseId: enterpriseId);
    await pushCloudFromSaveId(
      enterpriseId: enterpriseId,
      uid: playerId!,
      reason: 'conflict_keep_local',
    );
  } else if (choice == ConflictChoice.keepCloud) {
    // Supprimer local + pull cloud
    await _deleteSaveByIdViaLocalManager(enterpriseId);
    await _importCloudObject(...);
  }
  // Si cancel → ne rien faire
  return;
}
```

**Méthodes à ajouter** :
1. `setNavigationContext(BuildContext? context)` - Pour accéder au Navigator
2. `_showConflictResolution()` - Affiche l'écran et retourne le choix
3. `_extractSnapshot()` - Extrait GameSnapshot depuis SaveGame

### Correction 3 : Injecter BuildContext

**Fichier** : `lib/services/app_bootstrap_controller.dart`

**Changement** :
```dart
// Après connexion Firebase réussie
GamePersistenceOrchestrator.instance.setNavigationContext(context);
await GamePersistenceOrchestrator.instance.syncAllWorldsFromCloud(
  playerId: uid,
);
```

## 📝 Tests à Créer

### Tests Backend Cloud (8 tests)

**Fichier** : `test/cloud/cloud_backend_test.dart`

1. ✅ Connexion Google → Token valide
2. ✅ Push cloud → Données envoyées
3. ✅ Pull cloud → Données reçues
4. ✅ Liste entreprises → Retourne entreprise utilisateur
5. ✅ Suppression cloud → Entreprise supprimée
6. ✅ Retry automatique → Fonctionne
7. ✅ Timeout → Respecté
8. ✅ Validation UUID → Rejette invalides

### Tests Synchronisation (6 tests)

**Fichier** : `test/cloud/cloud_sync_test.dart`

1. ✅ Sync bidirectionnelle → Local ↔ Cloud
2. ✅ Connexion tardive - Cloud vide → Push local
3. ✅ Connexion tardive - Local vide → Pull cloud
4. ❌ **Connexion tardive - Conflit** → Affiche fenêtre de choix
5. ❌ **Résolution conflit - Garder local** → Supprime cloud
6. ❌ **Résolution conflit - Garder cloud** → Supprime local

### Tests Intégrité Données (10 tests)

**Fichier** : `test/cloud/cloud_data_integrity_test.dart`

1. ✅ PlayerManager → Toutes propriétés sauvegardées
2. ✅ MarketManager → Toutes propriétés sauvegardées
3. ✅ LevelSystem → Niveau + XP sauvegardés
4. ✅ MissionSystem → Missions sauvegardées
5. ✅ RareResourcesManager → Quantum + PI sauvegardés
6. ✅ ResearchManager → Recherches sauvegardées
7. ✅ AgentManager → Agents sauvegardés
8. ✅ ResetManager → Historique sauvegardé
9. ✅ ProductionManager → Production sauvegardée
10. ✅ Métadonnées → Nom, ID, dates sauvegardés

### Tests Gestion Erreurs (5 tests)

**Fichier** : `test/cloud/cloud_error_handling_test.dart`

1. ✅ Erreur réseau → Retry automatique
2. ✅ Erreur auth → Message utilisateur
3. ✅ Erreur backend → Gestion 500/503
4. ✅ Timeout → Annulation après délai
5. ✅ Offline → Sauvegarde locale continue

### Tests Widget (3 tests)

**Fichier** : `test/cloud/conflict_resolution_widget_test.dart`

1. ❌ ConflictResolutionScreen → Affichage stats
2. ❌ ConflictResolutionScreen → Choix local
3. ❌ ConflictResolutionScreen → Choix cloud

## 🎯 Prochaines Étapes

### Phase 1 : Corrections Critiques (PRIORITÉ)

1. ✅ Créer `ConflictResolutionScreen` (FAIT)
2. ❌ Ajouter méthodes dans `GamePersistenceOrchestrator` :
   - `setNavigationContext(BuildContext? context)`
   - `_showConflictResolution()`
   - `_extractSnapshot()`
3. ❌ Modifier `_syncFromCloudAtLogin()` pour afficher le choix
4. ❌ Injecter BuildContext depuis `AppBootstrapController`

### Phase 2 : Tests Automatisés

1. ❌ Créer tests backend cloud (8 tests)
2. ❌ Créer tests synchronisation (6 tests)
3. ❌ Créer tests intégrité données (10 tests)
4. ❌ Créer tests gestion erreurs (5 tests)
5. ❌ Créer tests widget (3 tests)

### Phase 3 : Validation

1. ❌ Exécuter tous les tests
2. ❌ Corriger les échecs
3. ❌ Build APK et test manuel
4. ❌ Documentation finale

## 📊 Statut Global

- **Architecture** : ✅ Bien conçue
- **Firebase Auth** : ✅ Fonctionnel
- **Cloud API** : ✅ Fonctionnel
- **Sync basique** : ✅ Fonctionnel
- **Résolution conflits** : ❌ À implémenter
- **Tests** : ❌ À créer (32 tests minimum)

**Estimation** : 6-8h de travail restant
