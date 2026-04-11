# CHANTIER - SAUVEGARDE LOCALE

## 🎯 Objectif
Vérifier et corriger le système de sauvegarde locale pour garantir qu'un joueur qui ne se connecte pas à Google puisse :
1. Sauvegarder son entreprise et ses données en local
2. Retrouver automatiquement son entreprise au redémarrage
3. Atterrir directement sur les panels (pas sur l'écran de connexion)

## 📋 Phase 1 : ANALYSE BACKEND (Sauvegarde Locale)

### 1.1 Services de Persistance Identifiés

#### LocalSaveGameManager
- **Fichier** : `lib/services/save_system/local_save_game_manager.dart`
- **Rôle** : Gestionnaire bas-niveau utilisant SharedPreferences
- **Méthodes clés** :
  - `saveGame(SaveGame save)` : Sauvegarde complète
  - `loadSave(String saveId)` : Chargement par ID
  - `listSaves()` : Liste toutes les sauvegardes
  - `deleteSave(String saveId)` : Suppression
- **Stockage** : 
  - Métadonnées : `save_metadata_` + saveId
  - Données : `save_data_` + saveId

#### LocalGamePersistenceService
- **Fichier** : `lib/services/persistence/local_game_persistence.dart`
- **Rôle** : Service de persistance pour GameSnapshot
- **Méthodes clés** :
  - `saveSnapshot(GameSnapshot snapshot, {required String slotId})`
  - `loadSnapshot({required String slotId})`
  - `saveSnapshotById(GameSnapshot snapshot, {required String enterpriseId})`
  - `loadSnapshotById({required String enterpriseId})`
- **Format** : Snapshot stocké dans `gameData['gameSnapshot']`

#### GamePersistenceOrchestrator
- **Fichier** : `lib/services/persistence/game_persistence_orchestrator.dart`
- **Rôle** : Orchestrateur principal (couche haute)
- **Responsabilités** :
  - Coordination sauvegarde/chargement
  - Gestion auto-save
  - Gestion backups
  - Migration de données

#### AutoSaveService
- **Fichier** : `lib/services/auto_save_service.dart`
- **Rôle** : Gestion automatique des sauvegardes
- **Fonctionnalités** :
  - Timer périodique (AUTO_SAVE_INTERVAL)
  - Sauvegarde lifecycle (pause/exit)
  - Création backups automatiques
  - Nettoyage backups anciens

### 1.2 Points à Vérifier Backend

- [ ] Vérifier que `saveSnapshot` utilise bien `enterpriseId` comme `slotId`
- [ ] Vérifier que `loadSnapshot` charge bien par `enterpriseId`
- [ ] Vérifier la validation des snapshots avant sauvegarde
- [ ] Vérifier la migration automatique des snapshots
- [ ] Vérifier la gestion des erreurs de sauvegarde
- [ ] Vérifier le système de backup automatique
- [ ] Vérifier le nettoyage des anciennes sauvegardes

## 📋 Phase 2 : ANALYSE FRONTEND (UI & Navigation)

### 2.1 Écrans Analysés

#### BootstrapScreen ✅
- **Fichier** : `lib/screens/bootstrap_screen.dart`
- **Rôle** : Écran de démarrage et orchestration navigation
- **Logique actuelle** :
  1. Vérifie si entreprise chargée en mémoire (`gameState.enterpriseId`)
  2. Si oui → `MainScreen` directement
  3. Sinon, liste les sauvegardes locales via `GamePersistenceOrchestrator.listSaves()`
  4. Si entreprise trouvée → Charge via `loadEnterpriseAndStartAutoSave()` → `MainScreen`
  5. Si aucune entreprise → `WelcomeScreen`
- **Points à vérifier** :
  - [x] Détection entreprise existante ✅ (lignes 126-139)
  - [x] Chargement automatique ✅ (lignes 141-166)
  - [x] Navigation vers MainScreen ✅ (lignes 135-137, 162-164)
  - [ ] **PROBLÈME** : Filtre backups utilise `_backup_` au lieu de `BACKUP_DELIMITER` (ligne 148)

#### IntroductionScreen ✅
- **Fichier** : `lib/screens/introduction_screen.dart`
- **Rôle** : Écran de création entreprise (4 pages)
- **Fonctionnalités** :
  - Page 4 : Formulaire nom entreprise avec validation
  - Callback `onCreateEnterprise(String enterpriseName)` (ligne 94-96)
  - Validation : 3-30 caractères, caractères alphanumériques
- **Points à vérifier** :
  - [x] Formulaire création entreprise ✅ (lignes 101-196)
  - [x] Validation nom entreprise ✅ (lignes 61-91)
  - [x] Callback création ✅ (ligne 94-96)
  - [x] Navigation après création ✅ (ligne 98)

#### MainScreen ✅
- **Fichier** : `lib/screens/main_screen.dart`
- **Rôle** : Écran principal avec 8 panels
- **Fonctionnalités** :
  - Utilise `SaveButton` widget (ligne 34)
  - Démarre session runtime au montage (ligne 91)
  - Gère lifecycle avec `WidgetsBindingObserver`
- **Points à vérifier** :
  - [x] Import SaveButton ✅ (ligne 34)
  - [x] Démarrage session ✅ (ligne 91)
  - [ ] Vérifier présence SaveButton dans l'UI
  - [ ] Vérifier auto-save actif

#### SaveButton Widget ✅
- **Fichier** : `lib/widgets/save_button.dart`
- **Rôle** : Widget réutilisable pour sauvegarde manuelle
- **Méthodes** :
  - `saveGame(BuildContext)` : Sauvegarde via `requestManualSave()`
  - `saveGameWithName(BuildContext, String)` : Sauvegarde avec nom (deprecated ID-first)
- **Logique** :
  - Vérifie `gameState.isInitialized` et `enterpriseId`
  - Appelle `GamePersistenceOrchestrator.requestManualSave()`
  - Affiche notification succès/erreur
- **Points à vérifier** :
  - [x] Utilise bien `requestManualSave()` ✅ (lignes 64, 103, 171)
  - [x] Vérifie `enterpriseId` ✅ (lignes 55, 93)
  - [x] Notifications utilisateur ✅ (lignes 69-80, 177-192)
  - [x] États de chargement ✅ (lignes 159-203)

### 2.2 Navigation Analysée

#### Flux Actuel (BootstrapScreen)
```
main.dart
    ↓
BootstrapScreen (AppBootstrapController.bootstrap())
    ↓
Sync cloud terminée ?
    ↓
    ├─ gameState.enterpriseId existe ?
    │   └─ OUI → startSession() → MainScreen ✅
    │
    ├─ listSaves() non vide ?
    │   └─ OUI → loadEnterpriseAndStartAutoSave() → startSession() → MainScreen ✅
    │
    └─ Aucune entreprise → WelcomeScreen → IntroductionScreen
```

#### Flux Création Entreprise
```
WelcomeScreen
    ↓
Bouton "Créer une entreprise"
    ↓
IntroductionScreen (4 pages)
    ↓
Page 4 : Formulaire nom
    ↓
onCreateEnterprise(name) → RuntimeActions.createNewEnterpriseAndStartAutoSave()
    ↓
GameState.createNewEnterprise() + saveGameById()
    ↓
onStart() → Navigation MainScreen
```

### 2.3 Points Critiques Identifiés

#### ✅ Points Fonctionnels
1. **Détection entreprise** : BootstrapScreen vérifie bien l'existence
2. **Chargement automatique** : `loadEnterpriseAndStartAutoSave()` appelé
3. **Sauvegarde manuelle** : SaveButton utilise `requestManualSave()`
4. **Validation création** : IntroductionScreen valide le nom

#### ⚠️ Points à Corriger
1. **Filtre backup** : Utilise `_backup_` au lieu de `GameConstants.BACKUP_DELIMITER`
2. **Présence SaveButton** : À vérifier dans MainScreen UI
3. **Auto-save** : À vérifier qu'il démarre bien
4. **Lifecycle save** : À vérifier pause/exit

## 📋 Phase 3 : FLUX DE DONNÉES

### 3.1 Flux de Sauvegarde

```
GameState.toSnapshot()
    ↓
AutoSaveService._performAutoSave()
    ↓
GamePersistenceOrchestrator.requestAutoSave()
    ↓
LocalGamePersistenceService.saveSnapshot()
    ↓
LocalSaveGameManager.saveGame()
    ↓
SharedPreferences (stockage)
```

### 3.2 Flux de Chargement

```
App Start
    ↓
Vérification entreprise locale
    ↓
LocalSaveGameManager.listSaves()
    ↓
LocalGamePersistenceService.loadSnapshot(enterpriseId)
    ↓
GameState.fromSnapshot()
    ↓
Navigation vers MainGameScreen
```

## 📋 Phase 4 : TESTS À CRÉER

### 4.1 Tests Backend

#### Test 1 : Sauvegarde Locale Complète
```dart
test('Sauvegarde locale d\'une entreprise', () async {
  // Créer GameState avec entreprise
  // Sauvegarder via LocalGamePersistenceService
  // Vérifier présence dans SharedPreferences
  // Vérifier intégrité des données
});
```

#### Test 2 : Chargement Entreprise
```dart
test('Chargement entreprise depuis sauvegarde locale', () async {
  // Créer et sauvegarder entreprise
  // Charger via loadSnapshotById
  // Vérifier données chargées
  // Vérifier enterpriseId correct
});
```

#### Test 3 : Auto-Save
```dart
test('Auto-save périodique fonctionne', () async {
  // Initialiser AutoSaveService
  // Modifier GameState
  // Attendre timer auto-save
  // Vérifier sauvegarde effectuée
});
```

#### Test 4 : Lifecycle Save
```dart
test('Sauvegarde au lifecycle (pause/exit)', () async {
  // Simuler pause app
  // Vérifier sauvegarde déclenchée
  // Simuler exit app
  // Vérifier sauvegarde finale
});
```

#### Test 5 : Backup Automatique
```dart
test('Création backup automatique', () async {
  // Déclencher création backup
  // Vérifier backup créé avec bon format
  // Vérifier nettoyage anciens backups
});
```

### 4.2 Tests Frontend

#### Test 6 : Détection Entreprise au Démarrage
```dart
testWidgets('Détection entreprise existante au démarrage', (tester) async {
  // Créer entreprise en local
  // Démarrer app
  // Vérifier navigation vers MainGameScreen
  // Vérifier pas d'écran de connexion
});
```

#### Test 7 : Redirection Automatique
```dart
testWidgets('Redirection automatique vers panels', (tester) async {
  // Sauvegarder entreprise
  // Redémarrer app
  // Vérifier atterrissage sur panels
  // Vérifier données chargées
});
```

#### Test 8 : Sauvegarde Manuelle
```dart
testWidgets('Bouton sauvegarde manuelle fonctionne', (tester) async {
  // Afficher MainGameScreen
  // Trouver bouton sauvegarde
  // Taper bouton
  // Vérifier sauvegarde effectuée
});
```

### 4.3 Tests d'Intégration

#### Test 9 : Cycle Complet Offline
```dart
testWidgets('Cycle complet sans connexion Google', (tester) async {
  // 1. Créer entreprise
  // 2. Jouer (modifier données)
  // 3. Sauvegarder
  // 4. Fermer app
  // 5. Rouvrir app
  // 6. Vérifier données restaurées
  // 7. Vérifier navigation correcte
});
```

#### Test 10 : Persistance Multi-Session
```dart
testWidgets('Persistance sur plusieurs sessions', (tester) async {
  // Session 1 : Créer et jouer
  // Session 2 : Charger et continuer
  // Session 3 : Vérifier continuité
});
```

## 📋 Phase 5 : CHECKLIST DE VÉRIFICATION

### Backend
- [ ] LocalSaveGameManager initialisé correctement
- [ ] SharedPreferences accessible
- [ ] Sauvegarde snapshot avec enterpriseId
- [ ] Chargement snapshot par enterpriseId
- [ ] Validation snapshot avant sauvegarde
- [ ] Migration automatique fonctionnelle
- [ ] Auto-save timer actif
- [ ] Lifecycle save (pause/exit)
- [ ] Backup automatique
- [ ] Nettoyage backups anciens
- [ ] Gestion erreurs robuste

### Frontend
- [ ] Détection entreprise au démarrage
- [ ] Redirection automatique si entreprise existe
- [ ] Pas d'écran connexion si local
- [ ] Boutons sauvegarde présents
- [ ] Indicateur dernière sauvegarde
- [ ] Chargement données au démarrage
- [ ] Navigation correcte vers panels

### Intégration
- [ ] Cycle complet création → sauvegarde → chargement
- [ ] Persistance multi-session
- [ ] Pas de perte de données
- [ ] Performance acceptable
- [ ] Gestion erreurs utilisateur

## 📋 Phase 6 : CORRECTIONS IDENTIFIÉES

### Corrections Backend

#### ✅ Corrections Nécessaires
1. **Filtre backup dans BootstrapScreen** (ligne 148)
   - **Problème** : Utilise `_backup_` au lieu de `GameConstants.BACKUP_DELIMITER`
   - **Impact** : Risque de ne pas filtrer correctement les backups
   - **Solution** : Remplacer par `GameConstants.BACKUP_DELIMITER`

### Corrections Frontend

#### ⚠️ Points à Vérifier
1. **Présence SaveButton dans MainScreen UI**
   - Vérifier que le bouton est bien affiché dans l'interface
   - Vérifier son emplacement (AppBar, FAB, ou panel)

2. **Auto-save démarrage**
   - Vérifier que `AutoSaveService.start()` est bien appelé
   - Vérifier le timer périodique actif

3. **Lifecycle save**
   - Vérifier sauvegarde sur pause app
   - Vérifier sauvegarde sur exit app

### Tests Créés

#### ✅ Tests Implémentés
1. **`local_save_complete_test.dart`** - Sauvegarde locale complète
   - Test sauvegarde snapshot avec enterpriseId
   - Test intégrité des données
   - Test validation snapshot

2. **`local_load_enterprise_test.dart`** - Chargement entreprise
   - Test chargement depuis sauvegarde locale
   - Test avec enterpriseId correct
   - Test retour null si inexistant
   - Test via GamePersistenceOrchestrator

3. **`cycle_complet_offline_test.dart`** - Cycle complet offline
   - Test création → sauvegarde → fermeture → réouverture
   - Test navigation automatique vers MainScreen

#### ⚠️ Erreurs de Compilation à Corriger
Les tests utilisent des propriétés qui n'existent pas dans GameState:
- `gameState.paperclips` → Utiliser snapshot ou méthodes appropriées
- `gameState.money` → Utiliser snapshot ou méthodes appropriées
- `gameState.fromSnapshot()` → Vérifier méthode correcte
- `coordinator.saveGameById()` → Utiliser `GamePersistenceOrchestrator`
- `coordinator.listSaves()` → Utiliser `GamePersistenceOrchestrator`

### Tests Manquants à Créer

- [ ] Test 3 : Auto-save périodique
- [ ] Test 4 : Lifecycle save (pause/exit)
- [ ] Test 5 : Backup automatique
- [ ] Test 6 : Détection entreprise au démarrage (widget)
- [ ] Test 7 : Redirection automatique vers panels (widget)
- [ ] Test 8 : Sauvegarde manuelle (widget)
- [ ] Test 10 : Persistance multi-session

## 📊 État d'Avancement

- [ ] Phase 1 : Analyse Backend
- [ ] Phase 2 : Analyse Frontend
- [ ] Phase 3 : Flux de Données
- [ ] Phase 4 : Création Tests
- [ ] Phase 5 : Exécution Tests
- [ ] Phase 6 : Corrections
- [ ] Phase 7 : Validation Finale

## 🎯 Critères de Validation

La mission sera validée quand :
1. ✅ Tous les tests créés passent au vert
2. ✅ Un joueur local peut créer une entreprise
3. ✅ Les données sont sauvegardées automatiquement
4. ✅ Au redémarrage, l'entreprise est chargée automatiquement
5. ✅ Navigation directe vers panels (pas d'écran connexion)
6. ✅ Aucune perte de données sur plusieurs sessions
