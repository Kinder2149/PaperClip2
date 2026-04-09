# Architecture des Tests - PaperClip2

**Date** : 9 avril 2026  
**Version** : 1.0

## 📋 Principe Général

Les tests suivent la même logique que la documentation :
- **Tests validés** → Figés et stables dans dossiers principaux
- **Tests en chantier** → En développement dans `test/chantiers/`
- **Tests obsolètes** → Supprimés

## 🗂️ Structure des Dossiers

```
test/
├── README.md                          # Ce fichier
├── ARCHITECTURE.md                    # Architecture détaillée
│
├── cloud/                             # ✅ Tests cloud VALIDÉS (87 tests)
│   ├── README.md                      # → docs/chantiers/CHANTIER-SAUVEGARDE-CLOUD/
│   ├── cloud_backend_test.dart
│   ├── cloud_sync_test.dart
│   └── ...
│
├── integration/                       # ✅ Tests intégration VALIDÉS (15 tests)
│   ├── README.md                      # → docs/chantiers/CHANTIER-SAUVEGARDE-CLOUD/
│   ├── cloud_integration_test.dart
│   └── ...
│
├── e2e_cloud/                         # ✅ Tests E2E cloud VALIDÉS (30 tests)
│   ├── README.md                      # → docs/chantiers/CHANTIER-SAUVEGARDE-CLOUD/
│   ├── cloud_e2e_test.dart
│   ├── helpers/
│   └── mocks/
│
├── unit/                              # ⚠️ Tests unitaires (MIXTE)
│   ├── README.md
│   ├── ✅ Tests validés (à trier)
│   └── 🚧 Tests en chantier (à déplacer)
│
├── widget/                            # ⚠️ Tests widgets (MIXTE)
│   ├── README.md
│   └── Tests à trier
│
├── chantiers/                         # 🚧 Tests EN DÉVELOPPEMENT
│   ├── README.md
│   ├── CHANTIER-02-ressources-rares/
│   │   ├── rare_resources_test.dart
│   │   └── reset_rewards_test.dart
│   ├── CHANTIER-03-recherche/
│   │   └── research_tree_test.dart
│   ├── CHANTIER-04-agents/
│   │   └── agents_ai_test.dart
│   └── CHANTIER-05-reset/
│       └── reset_progression_test.dart
│
└── obsoletes/                         # 🗑️ Tests OBSOLÈTES (à supprimer)
    ├── README.md
    └── world_state_helper_test.dart (supprimé)
```

## 🎯 Règles de Gestion des Tests

### 1. Tests Validés (Figés)

**Critères** :
- ✅ Tous les tests passent (100%)
- ✅ Liés à un chantier terminé
- ✅ Documentation figée existe
- ✅ Code stable et en production

**Emplacement** :
- `test/cloud/` - Tests backend cloud
- `test/integration/` - Tests intégration
- `test/e2e_cloud/` - Tests E2E cloud
- `test/unit/[feature]/` - Tests unitaires validés
- `test/widget/[feature]/` - Tests widgets validés

**Règles** :
- ❌ NE JAMAIS modifier sans validation
- ✅ Lien vers doc figée dans README
- ✅ Exécution dans CI/CD
- ✅ Couverture > 85%

### 2. Tests en Chantier

**Critères** :
- 🚧 Tests en développement
- 🚧 Liés à un chantier actif
- 🚧 Peuvent échouer temporairement
- 🚧 Documentation en cours

**Emplacement** :
- `test/chantiers/CHANTIER-XX-[nom]/`

**Règles** :
- ✅ Peuvent être modifiés librement
- ✅ Organisés par chantier
- ✅ Préfixe `CHANTIER-XX-`
- ⚠️ Non exécutés dans CI/CD

### 3. Tests Obsolètes

**Critères** :
- ❌ Fonctionnalité supprimée
- ❌ Architecture changée
- ❌ Remplacés par nouveaux tests

**Action** :
- 🗑️ Supprimer immédiatement
- 📝 Documenter dans CHANGELOG

**Exemples** :
- `world_state_helper_test.dart` (WorldsScreen supprimé)
- Tests `partieId` (migration vers `enterpriseId`)
- Tests `gameMode` (architecture changée)

## 🔄 Workflow de Gestion

### Démarrage d'un Chantier

1. **Créer dossier chantier**
   ```
   test/chantiers/CHANTIER-XX-[nom]/
   ```

2. **Créer README.md**
   ```markdown
   # Tests CHANTIER-XX : [Nom]
   
   **Statut** : 🚧 En développement
   **Doc** : docs/chantiers/CHANTIER-XX-[nom]/
   
   ## Tests
   - [ ] Test 1
   - [ ] Test 2
   ```

3. **Développer tests**
   - Tests peuvent échouer
   - Itération rapide
   - Pas de contrainte de couverture

### Fin d'un Chantier

1. **Valider tests**
   - ✅ Tous les tests passent
   - ✅ Couverture > 85%
   - ✅ Documentation figée

2. **Déplacer tests validés**
   ```bash
   # Exemple : CHANTIER-02 terminé
   mv test/chantiers/CHANTIER-02-ressources-rares/*.dart test/unit/rare_resources/
   ```

3. **Mettre à jour README**
   - Lien vers doc figée
   - Nombre de tests
   - Couverture

4. **Nettoyer chantier**
   ```bash
   rm -rf test/chantiers/CHANTIER-02-ressources-rares/
   ```

5. **Commit**
   ```bash
   git commit -m "test: CHANTIER-02 validé - Tests ressources rares (15 tests)"
   ```

### Détection d'Obsolescence

1. **Identifier tests obsolètes**
   - Fonctionnalité supprimée
   - Erreur de compilation
   - Architecture changée

2. **Documenter**
   ```markdown
   # CHANGELOG Tests
   
   ## Supprimés - 9 avril 2026
   - world_state_helper_test.dart - WorldsScreen supprimé (CHANTIER-01)
   ```

3. **Supprimer**
   ```bash
   rm test/unit/world_state_helper_test.dart
   ```

## 📊 État Actuel (9 avril 2026)

### Tests Validés ✅

| Dossier | Tests | Statut | Doc |
|---------|-------|--------|-----|
| `cloud/` | 87 | ✅ 100% | CHANTIER-SAUVEGARDE-CLOUD |
| `integration/` | 15 | ✅ 100% | CHANTIER-SAUVEGARDE-CLOUD |
| `e2e_cloud/` | 30 | ✅ 100% | CHANTIER-SAUVEGARDE-CLOUD |
| **Total** | **132** | **✅ 100%** | - |

### Tests à Trier ⚠️

| Dossier | Tests | Passent | À Trier |
|---------|-------|---------|---------|
| `unit/` | ~200 | ~150 | 50 |
| `widget/` | ~14 | ~2 | 12 |
| **Total** | **~214** | **~152** | **62** |

### Tests en Chantier 🚧

| Chantier | Tests | Statut |
|----------|-------|--------|
| CHANTIER-02 (Ressources rares) | ~15 | 🚧 À créer |
| CHANTIER-03 (Recherche) | ~10 | 🚧 À créer |
| CHANTIER-04 (Agents) | ~8 | 🚧 À créer |
| CHANTIER-05 (Reset) | ~7 | 🚧 À créer |

### Tests Obsolètes 🗑️

| Fichier | Raison | Action |
|---------|--------|--------|
| `world_state_helper_test.dart` | WorldsScreen supprimé | ✅ Supprimé |
| Tests `partieId` | Migration `enterpriseId` | 🚧 À identifier |
| Tests `gameMode` | Architecture changée | 🚧 À identifier |

## 🎯 Mission Actuelle

**Objectif** : Trier et organiser les 214 tests non-cloud

**Actions** :
1. ✅ Créer architecture et règles
2. 🚧 Analyser chaque test
3. 🚧 Déplacer tests validés
4. 🚧 Déplacer tests chantiers
5. 🚧 Supprimer tests obsolètes
6. 🚧 Mettre à jour README

**Temps estimé** : 2-3h

## 📝 Conventions de Nommage

### Fichiers de Test

```
[feature]_test.dart              # Test unitaire
[feature]_integration_test.dart  # Test intégration
[feature]_e2e_test.dart         # Test E2E
[feature]_widget_test.dart      # Test widget
```

### Dossiers

```
test/[category]/[feature]/       # Tests validés
test/chantiers/CHANTIER-XX-[nom]/ # Tests en chantier
```

### README

Chaque dossier de tests doit avoir un `README.md` avec :
- Lien vers documentation figée
- Nombre de tests
- Couverture
- Instructions d'exécution

## 🚀 Commandes Utiles

### Exécuter tests validés
```bash
flutter test test/cloud/
flutter test test/integration/
flutter test test/e2e_cloud/
```

### Exécuter tests d'un chantier
```bash
flutter test test/chantiers/CHANTIER-02-ressources-rares/
```

### Vérifier couverture
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### Analyser tests
```bash
flutter test --reporter=compact > test_report.txt
```

## 📚 Références

- **Documentation** : `docs/chantiers/`
- **Architecture Tests** : `test/ARCHITECTURE.md`
- **Règles Documentation** : Voir mémoires système
- **Changelog Tests** : `test/CHANGELOG.md`

---

**Créé le** : 9 avril 2026  
**Dernière mise à jour** : 9 avril 2026  
**Statut** : ✅ Architecture définie
