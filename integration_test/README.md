# Tests E2E (End-to-End) - Phase 4

Tests automatisés end-to-end pour valider le système de sauvegarde cloud complet.

## 📋 Vue d'Ensemble

Les tests E2E simulent des parcours utilisateur complets, du login à la résolution de conflits, en passant par la synchronisation multi-device et l'intégrité des données.

**Total** : 30 tests E2E automatisés

## 🎯 Objectifs

- Valider les scénarios critiques utilisateur
- Tester l'intégration complète du système
- Détecter les régressions rapidement
- Garantir la robustesse du système cloud

## 🧪 Structure des Tests

### Fichier Principal
**`integration_test/cloud_e2e_test.dart`** - 30 tests organisés en 6 groupes

### Groupes de Tests

#### Groupe 1 : Login & Bootstrap (5 tests)
- Premier login nouveau utilisateur
- Login utilisateur existant avec restauration
- Gestion erreurs réseau au login
- Re-authentification automatique (token expiré)
- Backend indisponible

#### Groupe 2 : Synchronisation Bidirectionnelle (5 tests)
- Sauvegarde locale → Push cloud
- Pull cloud → Restauration locale
- Sync périodique automatique
- Retry sur échec
- Suppression locale + cloud

#### Groupe 3 : Multi-Device Sync (5 tests)
- Device A avance → Device B sync
- Détection conflit multi-device
- Résolution conflit - Keep Local
- Résolution conflit - Keep Cloud
- Fallback cloud wins sans context

#### Groupe 4 : Intégrité Données (5 tests)
- PlayerManager - Toutes propriétés
- MarketManager - Toutes propriétés
- Missions, Recherches, Agents
- Ressources rares (Quantum, PI)
- Historique resets

#### Groupe 5 : Gestion Erreurs (5 tests)
- Retry automatique sur erreur réseau
- Timeout respecté
- JSON cloud invalide
- UUID validation
- Auth token injecté

#### Groupe 6 : Performance & Stabilité (5 tests)
- Snapshot large (10MB)
- 100 sync rapides - Pas de memory leak
- Sync concurrent - Thread safe
- Sync périodique - UI responsive
- Déconnexion propre - Cleanup

## 🛠️ Infrastructure

### Helpers
**`helpers/test_helpers.dart`** - Fonctions utilitaires
- `loginAndWait()` - Setup login
- `logout()` - Setup logout
- `setupConflict()` - Créer conflit
- `saveAndRestore()` - Save/restore GameState
- `expectGameStateEquals()` - Assertions
- `expectSnapshotValid()` - Validation snapshot

### Mocks
**`mocks/simple_mocks.dart`** - Mocks simples
- `MockFirebaseAuth` - Mock Firebase Auth
- `MockHttpClient` - Mock HTTP cloud
- `TestSnapshotFactory` - Factory snapshots

## 🚀 Exécution des Tests

### Tous les Tests E2E
```bash
flutter test integration_test/
```

### Un Groupe Spécifique
```bash
flutter test integration_test/cloud_e2e_test.dart --name "Groupe 1"
```

### Un Test Spécifique
```bash
flutter test integration_test/cloud_e2e_test.dart --name "1.1"
```

### Avec Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## ✅ Critères de Succès

### Tests
- [ ] 30 tests E2E créés
- [ ] 30/30 tests passent ✅
- [ ] Temps d'exécution < 5 min
- [ ] Aucun test flaky

### Code
- [ ] Mocks complets
- [ ] Helpers réutilisables
- [ ] Code coverage > 85%
- [ ] Pas de duplication

### Validation Finale
- [ ] **Total : 132 tests passent** (87 Phase 2 + 15 Phase 3 + 30 Phase 4)
- [ ] `flutter build apk --debug` réussit
- [ ] Aucune régression détectée

## 📊 Résultats Attendus

**Temps d'exécution** : ~3-5 minutes pour 30 tests

**Exemple de sortie** :
```
00:03 +30: All tests passed!
```

## 🔧 Dépendances

**`pubspec.yaml`** :
```yaml
dev_dependencies:
  integration_test:
    sdk: flutter
  test: ^1.24.0
```

## 📝 Maintenance

### Ajouter un Nouveau Test

1. Identifier le groupe approprié
2. Ajouter le test dans le groupe
3. Utiliser les helpers existants
4. Configurer les mocks nécessaires
5. Vérifier que le test passe

### Modifier un Test Existant

1. Comprendre l'objectif du test
2. Modifier uniquement ce qui est nécessaire
3. Vérifier que tous les tests passent
4. Mettre à jour la documentation si nécessaire

## 🐛 Troubleshooting

### Tests Flaky
- Utiliser `await tester.pumpAndSettle()` après actions UI
- Éviter `pump(Duration(...))` trop longs
- Vérifier états avec `expect()` plutôt que timing

### Erreurs de Compilation
- Vérifier imports
- Régénérer mocks si nécessaire
- Nettoyer avec `flutter clean`

### Tests Lents
- Réduire taille snapshots de test
- Optimiser delays dans mocks
- Paralléliser tests indépendants

## 🔗 Liens Connexes

- **Tests Phase 2** : `test/cloud/` - Tests unitaires cloud
- **Tests Phase 3** : `test/integration/` - Tests d'intégration
- **Documentation** : `docs/chantiers/CHANTIER-SAUVEGARDE-CLOUD/`
- **Plan Phase 4** : `C:\Users\vcout\.windsurf\plans\phase-4-tests-e2e-cloud-68be56.md`

## 📈 Métriques

| Métrique | Valeur |
|----------|--------|
| **Tests E2E** | 30 |
| **Groupes** | 6 |
| **Temps exécution** | ~3-5 min |
| **Coverage** | >85% |

---

**Créé le** : 9 avril 2026  
**Phase** : 4 - Tests E2E  
**Statut** : 🚧 En cours d'implémentation
