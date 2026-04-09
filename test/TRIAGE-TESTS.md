# Triage des Tests - Plan d'Action

**Date** : 9 avril 2026  
**Objectif** : Trier et organiser les 214 tests non-cloud

## 📊 Analyse Initiale

### Tests Validés ✅ (132 tests)
- `test/cloud/` - 87 tests ✅
- `test/integration/cloud_integration_test.dart` - 15 tests ✅
- `test/e2e_cloud/` - 30 tests ✅

### Tests à Trier ⚠️ (214 tests)

#### `test/unit/` (~200 tests)
- Tests qui passent → Garder
- Tests qui échouent → Analyser
  - Liés à chantier futur → Déplacer vers `test/chantiers/`
  - Obsolètes → Supprimer
  - À corriger → Corriger

#### `test/widget/` (~14 tests)
- Tests qui passent → Garder
- Tests qui échouent → Analyser

## 🎯 Plan de Triage

### Étape 1 : Identifier Tests Obsolètes

**Critères** :
- Fichier/classe n'existe plus
- Fonctionnalité supprimée (WorldsScreen, partieId, etc.)
- Architecture changée (gameMode, etc.)

**Action** :
- Supprimer immédiatement
- Documenter dans CHANGELOG

**Tests identifiés** :
- ✅ `world_state_helper_test.dart` - Supprimé
- 🔍 Tests `partieId` - À identifier
- 🔍 Tests `gameMode` - À identifier

### Étape 2 : Identifier Tests Chantiers Futurs

**Critères** :
- Liés à CHANTIER-02 (Ressources rares)
- Liés à CHANTIER-03 (Recherche)
- Liés à CHANTIER-04 (Agents)
- Liés à CHANTIER-05 (Reset)

**Action** :
- Déplacer vers `test/chantiers/CHANTIER-XX-[nom]/`
- Créer README par chantier

**Tests identifiés** :
- `rare_resources_*.dart` → CHANTIER-02
- `research_*.dart` → CHANTIER-03
- `agent_*.dart` → CHANTIER-04
- `reset_*.dart` → CHANTIER-05

### Étape 3 : Corriger Tests Validés

**Critères** :
- Fonctionnalité existe et stable
- Test échoue pour raison technique
- Peut être corrigé rapidement

**Action** :
- Corriger le test
- Vérifier qu'il passe
- Garder dans dossier actuel

### Étape 4 : Organiser Tests Validés

**Action** :
- Créer sous-dossiers par feature
- Mettre à jour README
- Ajouter liens vers doc

## 📋 Checklist de Triage

### Tests Obsolètes 🗑️
- [ ] Lister tous les tests obsolètes
- [ ] Supprimer fichiers
- [ ] Documenter dans CHANGELOG
- [ ] Commit

### Tests Chantiers 🚧
- [ ] Créer `test/chantiers/CHANTIER-02-ressources-rares/`
- [ ] Déplacer tests ressources rares
- [ ] Créer `test/chantiers/CHANTIER-03-recherche/`
- [ ] Déplacer tests recherche
- [ ] Créer `test/chantiers/CHANTIER-04-agents/`
- [ ] Déplacer tests agents
- [ ] Créer `test/chantiers/CHANTIER-05-reset/`
- [ ] Déplacer tests reset
- [ ] Créer README par chantier
- [ ] Commit

### Tests Validés ✅
- [ ] Corriger tests qui échouent
- [ ] Organiser par feature
- [ ] Mettre à jour README
- [ ] Vérifier couverture
- [ ] Commit

## 🔍 Analyse Détaillée par Fichier

### `test/unit/` - Tests à Analyser

#### Ressources Rares (CHANTIER-02)
- `rare_resources_calculator_test.dart` → `test/chantiers/CHANTIER-02-ressources-rares/`
- `rare_resources_display_test.dart` → `test/chantiers/CHANTIER-02-ressources-rares/`
- `rare_resources_manager_test.dart` → `test/chantiers/CHANTIER-02-ressources-rares/`

#### Recherche (CHANTIER-03)
- `research_manager_test.dart` → `test/chantiers/CHANTIER-03-recherche/`
- `research_meta_test.dart` → `test/chantiers/CHANTIER-03-recherche/`

#### Agents (CHANTIER-04)
- `agents/agent_card_test.dart` → `test/chantiers/CHANTIER-04-agents/`
- `agents/agent_manager_test.dart` → `test/chantiers/CHANTIER-04-agents/`
- `agents/production_optimizer_test.dart` → `test/chantiers/CHANTIER-04-agents/`
- `agent_persistence_test.dart` → `test/chantiers/CHANTIER-04-agents/`

#### Reset (CHANTIER-05)
- `reset_manager_refactored_test.dart.skip` → `test/chantiers/CHANTIER-05-reset/`
- `reset_manager_test.dart.skip` → `test/chantiers/CHANTIER-05-reset/`
- `reset_manager_simple_test.dart` → `test/chantiers/CHANTIER-05-reset/`
- `reset_history_entry_test.dart` → `test/chantiers/CHANTIER-05-reset/`

#### Tests Validés (À Garder)
- `enterprise_creation_test.dart` ✅
- `enterprise_persistence_test.dart` ✅
- `game_state_snapshot_test.dart` ✅
- `cloud_retry_policy_test.dart` ✅
- `protected_http_client_token_refresh_test.dart` ✅
- `audit_corrections_test.dart` ✅
- `managers_reset_test.dart` ✅

### `test/widget/` - Tests à Analyser

#### Dashboard/Statistics (CHANTIER-02 ou validés)
- `dashboard_panel_test.dart` - À analyser
- `statistics_panel_test.dart` - À analyser

### `test/integration/` - Tests à Analyser

#### Tests Chantiers
- `agents_test.dart` → CHANTIER-04
- `research_test.dart` → CHANTIER-03
- `reset_complete_test.dart` → CHANTIER-05
- `reset_serialization_test.dart` → CHANTIER-05

#### Tests Validés
- `auto_production_test.dart` ✅
- `market_manager_test.dart` ✅
- `gameplay_simulation_complete_test.dart` ✅
- `xp_combo_test.dart` ✅
- `save_load_test.dart` ✅

## 📊 Résumé Prévisionnel

### Après Triage

**Tests Validés** : ~160
- Cloud : 132 ✅
- Unit validés : ~20
- Integration validés : ~8

**Tests Chantiers** : ~50
- CHANTIER-02 : ~15
- CHANTIER-03 : ~12
- CHANTIER-04 : ~15
- CHANTIER-05 : ~8

**Tests Obsolètes** : ~4
- WorldsScreen
- partieId
- gameMode

## 🚀 Exécution

### Commandes

```bash
# 1. Analyser tous les tests
flutter test --reporter=compact > test_analysis.txt

# 2. Créer dossiers chantiers
mkdir -p test/chantiers/CHANTIER-02-ressources-rares
mkdir -p test/chantiers/CHANTIER-03-recherche
mkdir -p test/chantiers/CHANTIER-04-agents
mkdir -p test/chantiers/CHANTIER-05-reset

# 3. Déplacer tests (voir détail ci-dessus)

# 4. Supprimer tests obsolètes

# 5. Commit
git add -A
git commit -m "refactor: Triage et organisation des tests"
```

### Temps Estimé

- Analyse : 30 min
- Déplacement : 1h
- Correction : 1h
- Documentation : 30 min
- **Total** : ~3h

---

**Créé le** : 9 avril 2026  
**Statut** : 📋 Plan défini, prêt pour exécution
