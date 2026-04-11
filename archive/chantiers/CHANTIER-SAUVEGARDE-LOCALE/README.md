# CHANTIER - SAUVEGARDE LOCALE

## 🎯 Objectif

Vérifier et corriger le système de sauvegarde locale pour garantir qu'un joueur qui ne se connecte pas à Google puisse :

1. ✅ Sauvegarder son entreprise et ses données en local
2. ✅ Retrouver automatiquement son entreprise au redémarrage
3. ✅ Atterrir directement sur les panels (pas sur l'écran de connexion)

## 📁 Structure du Chantier

```
CHANTIER-SAUVEGARDE-LOCALE/
├── README.md                          # Ce fichier
├── PLAN-COMPLET.md                    # Plan détaillé d'analyse et tests
└── SYNTHESE.md                        # Synthèse des résultats
```

## 📊 Résultats de l'Analyse

### ✅ Points Fonctionnels Vérifiés

#### Backend
- **LocalSaveGameManager** : Gestionnaire de sauvegardes locales opérationnel
- **LocalGamePersistenceService** : Sauvegarde/chargement snapshots par `enterpriseId`
- **GamePersistenceOrchestrator** : Orchestration complète fonctionnelle
- **AutoSaveService** : Auto-sauvegarde avec timer périodique
- **Validation & Migration** : Snapshots validés et migrés automatiquement

#### Frontend
- **BootstrapScreen** : Détection et chargement automatique de l'entreprise ✅
- **IntroductionScreen** : Création entreprise avec validation complète ✅
- **SaveButton** : Widget de sauvegarde manuelle opérationnel ✅
- **Navigation** : Flux correct vers MainScreen si entreprise existe ✅

### ⚠️ Corrections Identifiées

#### 1. Filtre Backup (CRITIQUE)
**Fichier** : `lib/screens/bootstrap_screen.dart:148`

```dart
// AVANT (incorrect)
.where((meta) => !meta.name.contains('_backup_'))

// APRÈS (correct)
.where((meta) => !meta.name.contains(GameConstants.BACKUP_DELIMITER))
```

**Impact** : Risque de ne pas filtrer correctement les backups lors du chargement automatique.

#### 2. Tests à Corriger
Les 3 tests créés ont des erreurs de compilation à résoudre :
- Propriétés inexistantes dans GameState (`paperclips`, `money`)
- Méthodes à adapter (`fromSnapshot()`, `saveGameById()`, `listSaves()`)

## 📝 Tests Créés

### ✅ Tests Implémentés (à corriger)

1. **`test/local_save/local_save_complete_test.dart`**
   - Sauvegarde snapshot avec enterpriseId
   - Intégrité des données
   - Validation snapshot

2. **`test/local_save/local_load_enterprise_test.dart`**
   - Chargement entreprise depuis sauvegarde locale
   - Vérification enterpriseId correct
   - Test retour null si inexistant

3. **`test/local_save/cycle_complet_offline_test.dart`**
   - Cycle complet : Créer → Sauvegarder → Fermer → Rouvrir
   - Navigation automatique vers MainScreen

### 📋 Tests Manquants

- Auto-save périodique
- Lifecycle save (pause/exit)
- Backup automatique
- Tests widgets (navigation, boutons)
- Persistance multi-session

## 🔧 Actions Requises

### Priorité 1 : Corrections Critiques

1. **Corriger filtre backup dans BootstrapScreen** (ligne 148)
2. **Corriger les tests** pour qu'ils compilent

### Priorité 2 : Vérifications

1. Vérifier SaveButton visible dans MainScreen
2. Vérifier auto-save démarre correctement
3. Vérifier lifecycle save fonctionne

### Priorité 3 : Tests Complémentaires

1. Créer tests manquants
2. Exécuter tous les tests
3. Validation finale

## ✅ Critères de Validation

La mission sera validée quand :

1. ✅ Filtre backup corrigé
2. ✅ Tests compilent sans erreur
3. ✅ Tous les tests passent au vert
4. ✅ Un joueur local peut créer une entreprise
5. ✅ Les données sont sauvegardées automatiquement
6. ✅ Au redémarrage, l'entreprise est chargée automatiquement
7. ✅ Navigation directe vers panels (pas d'écran connexion)
8. ✅ Aucune perte de données sur plusieurs sessions

## 📚 Documentation

- **PLAN-COMPLET.md** : Analyse détaillée backend/frontend, flux de données, tests
- **SYNTHESE.md** : Synthèse complète avec flux de navigation et actions requises

## 🎯 Prochaines Étapes

1. Corriger le filtre backup
2. Corriger les tests pour compilation
3. Exécuter les tests
4. Vérifications manuelles (SaveButton, auto-save, lifecycle)
5. Créer tests manquants si nécessaire
6. Validation finale

---

**Status** : 🟡 En cours - Corrections requises
**Dernière mise à jour** : 2026-04-08
