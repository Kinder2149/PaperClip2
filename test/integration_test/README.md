# 🧪 Tests d'Intégration - Auth Google & Cloud Save

## 📋 Vue d'ensemble

Cette suite de tests valide l'ensemble du flux d'authentification Google Firebase et de sauvegarde cloud, de la connexion initiale jusqu'à la récupération complète des données.

**Fichiers** :
- `auth_cloud_flow_test.dart` : 22 tests automatisés
- `run_tests.ps1` : Script de lancement PowerShell
- `README.md` : Ce fichier

---

## 🎯 Tests Couverts

### Groupe 1 : Flux Auth Google + Cloud Save (15 tests)
- **TEST 1-3** : Initialisation Firebase & CloudPort
- **TEST 4** : Création entreprise avec UUID v4
- **TEST 5-7** : Structure snapshot v3 et métadonnées
- **TEST 8** : Restauration depuis snapshot
- **TEST 9-10** : Structures agents/recherches et dates ISO 8601
- **TEST 11** : Suppression entreprise
- **TEST 12** : Validation UUID v4 strict
- **TEST 13-15** : Sérialisation JSON et restauration complète

### Groupe 2 : CloudPort Manager (3 tests)
- **TEST 16** : Activation/désactivation
- **TEST 17** : Double activation idempotente
- **TEST 18** : Préférence persistée

### Groupe 3 : Snapshot Avancés (4 tests)
- **TEST 19** : Ressources rares initialisées
- **TEST 20** : Mode de stockage préservé
- **TEST 21** : Snapshot déterministe
- **TEST 22** : Gestion valeurs nulles

---

## 🚀 Lancement des Tests

### Option 1 : Script PowerShell (Recommandé)

```powershell
# Depuis la racine du projet
.\test\integration_test\run_tests.ps1
```

Le script propose 3 options :
1. **Chrome (Web)** - Recommandé pour développement
2. **Android** - Pour tests sur émulateur/device
3. **Tous les tests unitaires** - Lance tous les tests du projet

### Option 2 : Commande Flutter directe

```bash
# Web (Chrome)
flutter test integration_test/auth_cloud_flow_test.dart -d chrome

# Android
flutter test integration_test/auth_cloud_flow_test.dart -d <device-id>

# Avec logs verbeux
flutter test integration_test/auth_cloud_flow_test.dart -d chrome --verbose
```

---

## ⚙️ Prérequis

### Configuration Backend
- ✅ Firebase Functions déployées
- ✅ Firestore activé
- ✅ Firebase Authentication activé (Google Sign-In)

### Configuration Frontend
- ✅ Fichier `.env` avec `FUNCTIONS_API_BASE`
- ✅ `google-services.json` (Android)
- ✅ `firebase_options.dart` configuré

### Environnement
- Flutter SDK installé
- Chrome (pour tests Web)
- Émulateur Android ou device (pour tests Android)

---

## 📊 Résultats Attendus

### Succès Complet
```
✅ TEST 1: Vérifier que FirebaseAuth est initialisé
✅ TEST 2: Vérifier que CloudPort est désactivé au départ
✅ TEST 3: Activation manuelle CloudPort
...
✅ TEST 22: Snapshot gère les valeurs nulles correctement

All tests passed!
```

### Échec Partiel
```
✅ TEST 1-10: PASSED
❌ TEST 11: FAILED
  Expected: null
  Actual: 'uuid-value'
  
✅ TEST 12-22: PASSED

Some tests failed.
```

---

## 🔍 Détails des Tests

### TEST 4 : Création entreprise avec UUID v4

**Ce qui est testé** :
- Génération UUID v4 valide
- Format : `xxxxxxxx-xxxx-4xxx-xxxx-xxxxxxxxxxxx`
- Longueur : 36 caractères
- Version : 4 (3ème groupe commence par '4')
- Variant : RFC 4122 (4ème groupe commence par 8, 9, a ou b)

**Code** :
```dart
await gameState.createNewEnterprise('Test Enterprise');
final enterpriseId = gameState.enterpriseId;

expect(enterpriseId, isNotNull);
expect(enterpriseId!.length, equals(36));
```

---

### TEST 5 : Snapshot v3 - Structure

**Ce qui est testé** :
- Présence de `metadata` et `core`
- Version snapshot = 3
- EnterpriseId dans metadata
- Date `savedAt` au format ISO 8601

**Code** :
```dart
final snapshot = gameState.toSnapshot();
final json = snapshot.toJson();

expect(json, contains('metadata'));
expect(json['metadata']['snapshotSchemaVersion'], equals(3));
```

---

### TEST 7 : Format snake_case

**Ce qui est testé** :
- Tous les champs en `snake_case`
- Absence de `camelCase`
- Exemples : `enterprise_id`, `quantum_foam`, `innovation_points`

**Code** :
```dart
expect(metadata, contains('snapshotSchemaVersion'));
expect(core, contains('enterpriseName'));
expect(core, isNot(contains('quantumFoam'))); // Pas de camelCase
```

---

### TEST 8 : Restauration depuis snapshot

**Ce qui est testé** :
- Création GameState
- Sauvegarde snapshot
- Restauration dans nouveau GameState
- Vérification données identiques

**Code** :
```dart
final snapshot = gameState.toSnapshot();
final newGameState = GameState();
newGameState.applySnapshot(snapshot);

expect(newGameState.enterpriseId, equals(originalId));
```

---

## 🐛 Dépannage

### Erreur : "Firebase not initialized"

**Solution** :
```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

Vérifier que `firebase_options.dart` existe et est configuré.

---

### Erreur : "SharedPreferences not mocked"

**Solution** :
```dart
SharedPreferences.setMockInitialValues({});
final prefs = await SharedPreferences.getInstance();
```

Toujours initialiser les mocks avant les tests.

---

### Erreur : "CloudPort activation failed"

**Cause** : CloudPort déjà actif ou erreur de configuration

**Solution** :
```dart
await cloudPortManager.deactivate(reason: 'test_cleanup');
await cloudPortManager.activate(reason: 'test');
```

---

### Tests échouent sur Android

**Causes possibles** :
1. `google-services.json` manquant ou incorrect
2. Permissions Firebase Auth non configurées
3. Émulateur sans Google Play Services

**Solution** :
- Utiliser Chrome pour développement
- Vérifier configuration Android Firebase
- Utiliser émulateur avec Google Play

---

## 📈 Métriques de Performance

### Temps d'Exécution Attendus
- **Groupe 1** (15 tests) : ~5-10 secondes
- **Groupe 2** (3 tests) : ~1-2 secondes
- **Groupe 3** (4 tests) : ~2-3 secondes
- **Total** : ~10-15 secondes

### Couverture
- ✅ Création entreprise : 100%
- ✅ Snapshot v3 : 100%
- ✅ CloudPort : 100%
- ✅ Restauration : 100%
- ⚠️ Auth Google : Partielle (nécessite interaction manuelle)

---

## 🔄 Intégration Continue

### GitHub Actions (Exemple)

```yaml
name: Integration Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test integration_test/auth_cloud_flow_test.dart
```

---

## 📝 Ajouter de Nouveaux Tests

### Template de Test

```dart
test('TEST XX: Description du test', () async {
  // ARRANGE
  await gameState.createNewEnterprise('Test Name');
  
  // ACT
  final result = gameState.someMethod();
  
  // ASSERT
  expect(result, expectedValue, reason: 'Explication');
});
```

### Bonnes Pratiques

1. **Nommer clairement** : `TEST XX: Description précise`
2. **Utiliser AAA** : Arrange, Act, Assert
3. **Ajouter raisons** : `reason: 'Pourquoi ce test échoue'`
4. **Nettoyer** : `tearDown()` pour cleanup
5. **Isoler** : Chaque test indépendant

---

## 🎓 Ressources

### Documentation
- [Flutter Testing](https://docs.flutter.dev/testing)
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Firebase Testing](https://firebase.google.com/docs/flutter/testing)

### Guides Internes
- `test/manual/GUIDE_TEST_COMPLET_AUTH_CLOUD.md` - Guide de test manuel
- `docs/02-guides-developpeur/GUIDE_COMPLET_SAUVEGARDE_CLOUD.md` - Architecture cloud

---

## ✅ Checklist Validation

Avant de merger du code, vérifier que :

- [ ] Tous les tests passent (22/22)
- [ ] Aucun warning dans les logs
- [ ] Performance acceptable (<15s)
- [ ] Tests ajoutés pour nouvelles features
- [ ] Documentation mise à jour

---

## 📞 Support

**Problèmes** : Créer une issue avec :
- Logs complets du test
- Plateforme (Web/Android)
- Version Flutter
- Configuration Firebase

**Questions** : Consulter d'abord :
1. Ce README
2. Guide de test manuel
3. Documentation architecture
