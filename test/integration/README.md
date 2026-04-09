# Tests d'Intégration Cloud

Ce dossier contient les tests d'intégration pour le système de sauvegarde cloud.

## 📋 Vue d'Ensemble

Les tests d'intégration valident le fonctionnement complet du système en testant l'interaction entre les différents composants :
- `GamePersistenceOrchestrator` (orchestrateur principal)
- `LocalSaveGameManager` (gestionnaire local)
- `CloudPersistencePort` (adaptateur cloud)

## 🧪 Tests Disponibles

### `cloud_integration_test.dart` - 15 tests

**Phase 3.2** : Tests d'intégration créés pour valider le système complet.

#### Groupe 1 : Orchestrator + LocalManager (5 tests)
Tests de l'interaction entre l'orchestrateur et le gestionnaire local.

1. **1.1 - Sauvegarde locale puis push cloud fonctionne**
   - Valide que les données sauvegardées localement peuvent être poussées au cloud
   - Vérifie l'extraction du snapshot depuis SaveGame

2. **1.2 - Pull cloud puis restauration locale fonctionne**
   - Valide que les données cloud peuvent être matérialisées localement
   - Vérifie la création de SaveGame depuis CloudWorldDetail

3. **1.3 - Suppression locale + cloud synchronisée**
   - Valide que la suppression locale déclenche suppression cloud
   - Vérifie l'appel à CloudAdapter.deleteById

4. **1.4 - Extraction snapshot depuis SaveGame correcte**
   - Valide l'extraction du snapshot depuis gameData
   - Vérifie la structure GameSnapshot

5. **1.5 - Métadonnées cohérentes entre local et cloud**
   - Valide la cohérence des métadonnées (name, version, enterpriseId)
   - Vérifie la préservation lors du push/pull

#### Groupe 2 : Orchestrator + CloudAdapter (5 tests)
Tests de l'interaction entre l'orchestrateur et l'adaptateur cloud.

1. **2.1 - Retry policy appliquée sur erreurs réseau**
   - Valide que les erreurs réseau déclenchent des retries
   - Vérifie le nombre de tentatives (3 max)

2. **2.2 - Timeout respecté sur opérations longues**
   - Valide que les timeouts sont appliqués
   - Vérifie TimeoutException après délai

3. **2.3 - Auth token injecté dans toutes les requêtes**
   - Valide que l'uid Firebase est toujours présent
   - Vérifie metadata['uid'] dans les appels

4. **2.4 - UUID validation avant opérations cloud**
   - Valide que les enterpriseId sont des UUID v4
   - Vérifie le format avec regex

5. **2.5 - Erreurs cloud propagées correctement**
   - Valide que les erreurs cloud remontent
   - Vérifie la propagation des exceptions

#### Groupe 3 : Flux Complet Sync (5 tests)
Tests des scénarios de synchronisation complets.

1. **3.1 - Login → Sync → Local vide → Pull cloud**
   - Scénario nouveau device avec données cloud
   - Valide pull automatique

2. **3.2 - Login → Sync → Cloud vide → Push local**
   - Scénario premier device avec données locales
   - Valide push automatique

3. **3.3 - Login → Sync → Conflit → Données préparées**
   - Scénario conflit détecté
   - Valide détection sans modification automatique

4. **3.4 - Résolution keepLocal → Cloud supprimé + Local poussé**
   - Résolution en faveur du local
   - Valide suppression cloud + push local

5. **3.5 - Résolution keepCloud → Local supprimé + Cloud appliqué**
   - Résolution en faveur du cloud
   - Valide matérialisation locale depuis cloud

## 🚀 Exécution des Tests

### Tous les tests d'intégration
```bash
flutter test test/integration/cloud_integration_test.dart --no-pub
```

### Un groupe spécifique
```bash
flutter test test/integration/cloud_integration_test.dart --no-pub --name "Groupe 1"
```

### Un test spécifique
```bash
flutter test test/integration/cloud_integration_test.dart --no-pub --name "1.1"
```

## 🔧 Mocks Utilisés

Les tests utilisent **Mockito** pour créer des mocks des dépendances :

### `MockCloudPersistencePort`
Mock de l'adaptateur cloud pour simuler les opérations cloud sans réseau réel.

**Méthodes mockées** :
- `pushById()` : Simuler push vers cloud
- `pullById()` : Simuler pull depuis cloud
- `deleteById()` : Simuler suppression cloud
- `statusById()` : Simuler récupération statut

### Génération des Mocks

Les mocks sont générés automatiquement avec `build_runner` :

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Le fichier généré : `cloud_integration_test.mocks.dart`

## 📊 Résultats Attendus

**Tous les tests doivent passer** :
```
00:05 +15: All tests passed!
```

**Temps d'exécution** : ~5 secondes

## 🎯 Objectifs des Tests

1. **Validation de l'intégration** : Vérifier que les composants fonctionnent ensemble
2. **Détection de régressions** : S'assurer qu'aucune modification ne casse le système
3. **Documentation vivante** : Les tests servent de documentation du comportement attendu
4. **Confiance dans le code** : Permettre des refactorings en toute sécurité

## 📝 Maintenance

### Ajouter un nouveau test

1. Identifier le groupe approprié (Groupe 1, 2 ou 3)
2. Ajouter le test dans le groupe avec un numéro séquentiel
3. Suivre le pattern Arrange-Act-Assert
4. Utiliser des mocks pour les dépendances externes
5. Vérifier que le test passe

### Modifier un test existant

1. Comprendre l'objectif du test
2. Modifier uniquement ce qui est nécessaire
3. Vérifier que tous les tests passent après modification
4. Mettre à jour la documentation si nécessaire

## 🔗 Liens Connexes

- **Tests Phase 2** : `test/cloud/` - Tests unitaires des composants cloud
- **Documentation principale** : `docs/chantiers/CHANTIER-SAUVEGARDE-CLOUD/`
- **Plan de validation** : `C:\Users\vcout\.windsurf\plans\validation-cloud-phases-3-4-7e6aec.md`

## ✅ Critères de Succès

- [ ] 15/15 tests passent
- [ ] Temps d'exécution < 10 secondes
- [ ] Aucun test flaky (résultats stables)
- [ ] Code coverage > 80% pour orchestrator
- [ ] Pas de dépendances externes réelles (tout mocké)

---

**Créé le** : 8 avril 2026  
**Phase** : 3.2 - Tests d'Intégration  
**Statut** : ✅ Terminé
