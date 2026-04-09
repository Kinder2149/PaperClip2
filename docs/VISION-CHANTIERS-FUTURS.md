# Vision Stratégique - Chantiers Futurs

**Date** : 9 avril 2026  
**Horizon** : 2-3 mois

## 🎯 Vue d'Ensemble

### Chantiers Implémentés (3/7) ✅

```
✅ CHANTIER-01 : Migration Multi→Unique (100%)
✅ SAUVEGARDE-CLOUD : Système cloud complet (100%)
✅ SAUVEGARDE-LOCALE : Système local robuste (100%)
```

**Base solide** : Architecture propre, tests validés, documentation complète

### Chantiers à Implémenter (4/7) 🚧

```
🚧 CHANTIER-02 : Ressources Rares (20% préparé)
🚧 CHANTIER-05 : Reset Progression (25% préparé)
🚧 CHANTIER-03 : Arbre de Recherche (15% préparé)
🚧 CHANTIER-04 : Agents IA (20% préparé)
```

---

## 📋 CHANTIER-02 : Ressources Rares

**Priorité** : 🔴 **CRITIQUE** (Bloquant pour 03, 04, 05)  
**Durée estimée** : 2-3 jours  
**Complexité** : 🟡 Moyenne  
**Préparation** : 20%

### Objectif

Implémenter le système de ressources rares (Quantum et Points Innovation) qui récompense les resets.

### Dépendances

**Bloque** :
- CHANTIER-03 (Points Innovation pour recherches)
- CHANTIER-04 (Quantum pour agents)
- CHANTIER-05 (Récompenses reset)

**Dépend de** :
- ✅ CHANTIER-01 (entrepriseId, snapshot v3)

### Déjà Préparé (20%)

**Architecture** :
- ✅ `RareResourcesManager` créé
- ✅ `RareResourcesCalculator` créé
- ✅ Champs dans GameState (quantum, pointsInnovation)
- ✅ Snapshot v3 prêt

**Tests** :
- ✅ 6 tests dans `test/chantiers/CHANTIER-02/`
- ✅ Structure de test prête

**Documentation** :
- ✅ README chantier
- ⚠️ Plan détaillé à créer

### À Implémenter (80%)

#### Phase 1 : Formules de Calcul (1 jour)

**Quantum** :
```dart
// Formule : BASE + (niveau × 2) + (paperclips / 1M) + (machines × 5)
// Plafond : 500 Quantum
// Bonus premier reset : ×1.5
```

**Points Innovation** :
```dart
// Formule : BASE + (niveau × 1) + (upgrades × 2) + (recherches × 3)
// Plafond : 200 PI
// Bonus premier reset : ×1.5
```

**Tests** :
- Calcul Quantum correct
- Calcul PI correct
- Plafonds respectés
- Bonus premier reset

#### Phase 2 : UI Affichage (0.5 jour)

**Composants** :
- Widget affichage Quantum
- Widget affichage PI
- Icônes ressources rares
- Tooltips explicatifs

**Tests** :
- Widget tests
- Affichage correct
- Mise à jour temps réel

#### Phase 3 : Intégration (0.5 jour)

**Intégration** :
- Calcul lors du reset
- Sauvegarde dans snapshot
- Synchronisation cloud
- Affichage dans UI

**Tests** :
- Tests intégration
- Tests E2E
- Tests cloud sync

### Checklist

- [ ] Implémenter formules Quantum
- [ ] Implémenter formules PI
- [ ] Créer widgets affichage
- [ ] Intégrer avec reset
- [ ] Tests unitaires (6 tests)
- [ ] Tests intégration
- [ ] Tests E2E
- [ ] Documentation complète
- [ ] Valider et ranger tests

---

## 📋 CHANTIER-05 : Reset Progression

**Priorité** : 🟠 **HAUTE** (Gameplay core)  
**Durée estimée** : 2-3 jours  
**Complexité** : 🟡 Moyenne  
**Préparation** : 25%

### Objectif

Implémenter le système de reset progression qui conserve Quantum et Points Innovation.

### Dépendances

**Bloque** :
- Gameplay META complet

**Dépend de** :
- ✅ CHANTIER-01 (entrepriseId)
- 🚧 CHANTIER-02 (Quantum, PI)

### Déjà Préparé (25%)

**Architecture** :
- ✅ `ResetManager` créé
- ✅ `ResetHistoryEntry` model créé
- ✅ `RareResourcesCalculator` prêt
- ✅ Dialogs reset créés

**Tests** :
- ✅ 6 tests dans `test/chantiers/CHANTIER-05/`
- ✅ Structure de test prête

**Documentation** :
- ✅ README chantier
- ⚠️ Plan détaillé à créer

### À Implémenter (75%)

#### Phase 1 : Calcul Récompenses (1 jour)

**Fonctionnalités** :
- Calcul Quantum selon formule
- Calcul PI selon formule
- Bonus premier reset
- Plafonds respectés

**Tests** :
- Calcul récompenses correct
- Bonus appliqués
- Plafonds respectés

#### Phase 2 : Reset Progression (1 jour)

**Fonctionnalités** :
- Reset GameState
- Conservation Quantum/PI
- Historique resets
- Statistiques totales

**Tests** :
- Reset complet
- Conservation ressources
- Historique correct

#### Phase 3 : UI (0.5 jour)

**Composants** :
- Dialog confirmation reset
- Dialog récompenses
- Historique resets
- Statistiques META

**Tests** :
- Widget tests
- Flow complet

### Checklist

- [ ] Implémenter calcul récompenses
- [ ] Implémenter reset progression
- [ ] Créer UI reset
- [ ] Historique resets
- [ ] Tests unitaires (6 tests)
- [ ] Tests intégration
- [ ] Tests E2E
- [ ] Documentation complète
- [ ] Valider et ranger tests

---

## 📋 CHANTIER-03 : Arbre de Recherche

**Priorité** : 🟡 **MOYENNE** (Feature importante)  
**Durée estimée** : 3-4 jours  
**Complexité** : 🔴 Élevée  
**Préparation** : 15%

### Objectif

Implémenter l'arbre de recherche technologique avec déblocage via Points Innovation.

### Dépendances

**Bloque** :
- CHANTIER-04 (Agents débloqués par recherches)

**Dépend de** :
- ✅ CHANTIER-01 (entrepriseId)
- 🚧 CHANTIER-02 (Points Innovation)

### Déjà Préparé (15%)

**Architecture** :
- ✅ `ResearchManager` créé
- ✅ `ResearchNode` model créé
- ✅ Structure recherches META

**Tests** :
- ✅ 3 tests dans `test/chantiers/CHANTIER-03/`
- ✅ Structure de test prête

**Documentation** :
- ✅ README chantier
- ⚠️ Plan détaillé à créer

### À Implémenter (85%)

#### Phase 1 : Arbre de Recherche (2 jours)

**Recherches** :
- Recherches production (5)
- Recherches marché (5)
- Recherches agents (5)
- Recherches META (5)

**Fonctionnalités** :
- Déblocage avec PI
- Dépendances recherches
- Effets recherches
- Persistance

**Tests** :
- Déblocage correct
- Dépendances respectées
- Effets appliqués

#### Phase 2 : UI Arbre (1 jour)

**Composants** :
- Widget arbre de recherche
- Widget nœud recherche
- Lignes dépendances
- Tooltips

**Tests** :
- Widget tests
- Navigation arbre
- Affichage correct

#### Phase 3 : Intégration (0.5 jour)

**Intégration** :
- Effets recherches
- Sauvegarde snapshot
- Synchronisation cloud

**Tests** :
- Tests intégration
- Tests E2E

### Checklist

- [ ] Définir toutes les recherches
- [ ] Implémenter arbre de recherche
- [ ] Implémenter déblocage
- [ ] Créer UI arbre
- [ ] Effets recherches
- [ ] Tests unitaires (3 tests)
- [ ] Tests intégration
- [ ] Tests E2E
- [ ] Documentation complète
- [ ] Valider et ranger tests

---

## 📋 CHANTIER-04 : Agents IA

**Priorité** : 🟢 **BASSE** (Feature avancée)  
**Durée estimée** : 3-4 jours  
**Complexité** : 🔴 Élevée  
**Préparation** : 20%

### Objectif

Implémenter les agents IA qui automatisent certaines tâches.

### Dépendances

**Bloque** :
- Rien (feature finale)

**Dépend de** :
- ✅ CHANTIER-01 (entrepriseId)
- 🚧 CHANTIER-02 (Quantum)
- 🚧 CHANTIER-03 (Recherches pour débloquer)

### Déjà Préparé (20%)

**Architecture** :
- ✅ `AgentManager` créé
- ✅ `Agent` model créé
- ✅ 5 agents définis

**Agents** :
- ProductionOptimizer
- MarketAnalyst
- MetalBuyer
- InnovationResearcher
- QuantumResearcher

**Tests** :
- ✅ 9 tests dans `test/chantiers/CHANTIER-04/`
- ✅ Structure de test prête

**Documentation** :
- ✅ README chantier
- ⚠️ Plan détaillé à créer

### À Implémenter (80%)

#### Phase 1 : Logique Agents (2 jours)

**Fonctionnalités** :
- Activation/désactivation agents
- Coût en Quantum
- Durée agents
- Effets agents

**Tests** :
- Activation correct
- Coût appliqué
- Effets corrects

#### Phase 2 : UI Agents (1 jour)

**Composants** :
- Widget liste agents
- Widget carte agent
- Dialog activation
- Timer agent

**Tests** :
- Widget tests
- Flow activation

#### Phase 3 : Intégration (0.5 jour)

**Intégration** :
- Effets agents
- Sauvegarde snapshot
- Synchronisation cloud

**Tests** :
- Tests intégration
- Tests E2E

### Checklist

- [ ] Implémenter logique agents
- [ ] Implémenter activation
- [ ] Créer UI agents
- [ ] Effets agents
- [ ] Tests unitaires (9 tests)
- [ ] Tests intégration
- [ ] Tests E2E
- [ ] Documentation complète
- [ ] Valider et ranger tests

---

## 📊 Planning Recommandé

### Semaine 1-2 : CHANTIER-02 (Ressources Rares)

**Jours 1-2** : Formules et calculs  
**Jour 3** : UI affichage  
**Jour 4** : Intégration et tests  
**Jour 5** : Documentation et validation

**Livrable** : Système ressources rares opérationnel

---

### Semaine 3-4 : CHANTIER-05 (Reset Progression)

**Jours 1-2** : Calcul récompenses et reset  
**Jour 3** : UI reset  
**Jour 4** : Tests et intégration  
**Jour 5** : Documentation et validation

**Livrable** : Reset progression fonctionnel

---

### Semaine 5-7 : CHANTIER-03 (Arbre de Recherche)

**Jours 1-3** : Arbre de recherche complet  
**Jours 4-5** : UI arbre  
**Jour 6** : Intégration  
**Jour 7** : Tests et documentation

**Livrable** : Arbre de recherche opérationnel

---

### Semaine 8-10 : CHANTIER-04 (Agents IA)

**Jours 1-3** : Logique agents  
**Jours 4-5** : UI agents  
**Jour 6** : Intégration  
**Jour 7** : Tests et documentation

**Livrable** : Agents IA fonctionnels

---

## 🎯 Jalons Clés

### Jalon 1 : Ressources Rares (Semaine 2)
- ✅ Quantum et PI implémentés
- ✅ Calculs corrects
- ✅ UI affichage
- ✅ Tests validés

### Jalon 2 : Reset Progression (Semaine 4)
- ✅ Reset progression fonctionnel
- ✅ Conservation ressources
- ✅ Historique resets
- ✅ Tests validés

### Jalon 3 : Arbre de Recherche (Semaine 7)
- ✅ Arbre complet
- ✅ Déblocage fonctionnel
- ✅ UI arbre
- ✅ Tests validés

### Jalon 4 : Agents IA (Semaine 10)
- ✅ Agents fonctionnels
- ✅ Activation/effets
- ✅ UI agents
- ✅ Tests validés

### Jalon Final : Release (Semaine 12)
- ✅ Tous les chantiers terminés
- ✅ Tests 100% validés
- ✅ Documentation complète
- ✅ Prêt pour production

---

## 📈 Métriques de Succès

### Par Chantier

**Implémentation** :
- ✅ 100% des fonctionnalités
- ✅ Code propre et maintenu
- ✅ Pas de dette technique

**Tests** :
- ✅ 100% des tests passent
- ✅ Couverture > 85%
- ✅ Tests E2E validés

**Documentation** :
- ✅ Plan figé
- ✅ Architecture documentée
- ✅ Guide utilisateur

### Globales

**Qualité** :
- ✅ 100% tests validés
- ✅ Architecture propre
- ✅ Documentation complète

**Performance** :
- ✅ Temps de réponse < 100ms
- ✅ Sync cloud < 2s
- ✅ Pas de lag UI

**UX** :
- ✅ Interface intuitive
- ✅ Feedback utilisateur
- ✅ Pas de bugs critiques

---

## 🚀 Stratégie d'Implémentation

### Principe : Itératif et Incrémental

**Pour chaque chantier** :
1. **Analyse** : Lire plan existant, identifier gaps
2. **Design** : Finaliser architecture et UX
3. **Implémentation** : Phase par phase
4. **Tests** : Au fur et à mesure
5. **Documentation** : Figer décisions
6. **Validation** : Vérifier qualité
7. **Rangement** : Déplacer tests validés

### Workflow

```
1. Créer branche feature/CHANTIER-XX
2. Implémenter phase 1
3. Tests phase 1
4. Commit phase 1
5. Implémenter phase 2
6. Tests phase 2
7. Commit phase 2
8. ...
9. Documentation finale
10. Merge vers main
11. Déplacer tests vers validés
12. Nettoyer chantier
```

---

## ✅ Checklist Globale

### CHANTIER-02 : Ressources Rares
- [ ] Plan détaillé créé
- [ ] Formules implémentées
- [ ] UI créée
- [ ] Tests validés (6 tests)
- [ ] Documentation figée
- [ ] Tests déplacés vers validés

### CHANTIER-05 : Reset Progression
- [ ] Plan détaillé créé
- [ ] Reset implémenté
- [ ] UI créée
- [ ] Tests validés (6 tests)
- [ ] Documentation figée
- [ ] Tests déplacés vers validés

### CHANTIER-03 : Arbre de Recherche
- [ ] Plan détaillé créé
- [ ] Arbre implémenté
- [ ] UI créée
- [ ] Tests validés (3 tests)
- [ ] Documentation figée
- [ ] Tests déplacés vers validés

### CHANTIER-04 : Agents IA
- [ ] Plan détaillé créé
- [ ] Agents implémentés
- [ ] UI créée
- [ ] Tests validés (9 tests)
- [ ] Documentation figée
- [ ] Tests déplacés vers validés

---

## 🎉 Vision Finale

**Objectif** : Jeu complet avec système META

**Fonctionnalités** :
- ✅ Sauvegarde cloud multi-device
- ✅ Entreprise unique personnalisée
- ✅ Ressources rares (Quantum, PI)
- ✅ Reset progression avec récompenses
- ✅ Arbre de recherche technologique
- ✅ Agents IA automatisation

**Qualité** :
- ✅ 100% tests validés
- ✅ Architecture propre
- ✅ Documentation complète
- ✅ Prêt pour production

**Timeline** : 10-12 semaines

---

**Créé le** : 9 avril 2026  
**Horizon** : 2-3 mois  
**Statut** : 🎯 Vision claire et actionnable
