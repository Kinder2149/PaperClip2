# CHANTIER-07 : Tests & Équilibrage

**Date de création** : 9 avril 2026  
**Dernière mise à jour** : 9 avril 2026  
**Statut** : 🟡 EN COURS  
**Chantiers terminés** : 00-06 (voir `docs/ARCHITECTURE.md` et `docs/FEATURES.md`)

---

## 📊 ÉTAT ACTUEL (9 avril 2026)

### ✅ Chantiers Terminés (00-06)

Tous les chantiers 00-06 sont **terminés et documentés** dans :
- `docs/ARCHITECTURE.md` - Architecture entreprise unique
- `docs/FEATURES.md` - Toutes les features implémentées
- `docs/FORMULES.md` - Formules de calcul
- `docs/REVUE-COMPLETE-PROJET.md` - Vue d'ensemble complète

### 🟡 CHANTIER-07 : Tests & Équilibrage (EN COURS)

**Progression** :
- ✅ 350 tests validés (97-98% passent)
- ✅ 132 tests cloud (100%)
- ✅ Architecture tests organisée
- ⚠️ Tests à compléter (voir ci-dessous)

### 🎯 PRIORITÉS IMMÉDIATES

1. **Tests intégration reset complet**
   - Test niveau 1 → 20 → reset → vérification gains
   - Test conservation Quantum/PI
   - Test reset historique

2. **Tests sérialisation**
   - Vérifier `resetHistory` dans GameState.toJson()
   - Test sauvegarde/chargement post-reset
   - Test migration snapshot

3. **Tests performance**
   - FPS gameplay (cible : 60 FPS)
   - Mémoire (cible : < 200 MB)
   - Taille snapshot (cible : < 50 KB)

4. **Tests équilibrage**
   - Simulation progression niveau 1-50
   - Validation formules Quantum/PI
   - Rentabilité resets

---

## 🎯 Vue d'Ensemble

Ce document consolide les **chantiers du projet PaperClip2** avec leur état d'avancement.

### 🟡 Chantier en Cours

1. **CHANTIER-07** : Tests & Équilibrage (continu) - 🟡 **EN COURS**
   - 29 tests créés (100% passent)
   - Tests intégration à compléter
   - Tests performance à créer
   - Équilibrage progression à valider

### ✅ Chantiers Terminés

0. **CHANTIER-00** : Nettoyage Code Legacy ✅ **TERMINÉ**
1. **CHANTIER-01** : Migration Multi→Unique ✅ **TERMINÉ**
2. **CHANTIER-02** : Ressources Rares ✅ **TERMINÉ**
3. **CHANTIER-03** : Système de Recherche ✅ **TERMINÉ**
4. **CHANTIER-04** : Agents IA ✅ **TERMINÉ**
5. **CHANTIER-05** : Système de Reset ✅ **TERMINÉ (7 avril 2026)**
6. **CHANTIER-06** : Refonte Interface ✅ **TERMINÉ (7 avril 2026)**

### Dépendances

```text
✅ CHANTIER-00 (Nettoyage Legacy)
    ↓
✅ CHANTIER-01 (Migration)
    ↓
✅ CHANTIER-02 (Ressources)
    ↓
✅ CHANTIER-03 (Recherche) ──→ ✅ CHANTIER-04 (Agents)
    ↓                              ↓
✅ CHANTIER-05 (Reset) ←──────────┘
    ↓
✅ CHANTIER-06 (Interface)
    ↓
🟡 CHANTIER-07 (Tests) — EN COURS
```

---

## 📋 Objectif CHANTIER-07

Définir et implémenter une stratégie de tests complète pour garantir la qualité, la performance et l'équilibrage du jeu.

### Décisions Figées

- **Tests unitaires** : 80% de couverture
- **Tests intégration** : 60% de couverture
- **Tests continus** : Tout au long du développement

---

## 📋 Types de Tests

### 1. Tests Unitaires

**Cible** : Logique métier isolée

**Fichiers à tester** :
- `RareResourcesManager` : Quantum, Innovation Points
- `ResearchManager` : Déblocage, coûts, effets
- `AgentManager` : Activation, désactivation, actions
- `ResetManager` : Calculs récompenses, reset complet
- `ProductionManager` : Production, autoclippers
- `MarketManager` : Demande, prix, saturation

**Statut** : ✅ ~200 tests unitaires passent

### 2. Tests d'Intégration

**Cible** : Flux complets utilisateur

**Scénarios à tester** :
- ✅ Création entreprise → Production → Vente → Achat autoclipper
- ⚠️ Déblocage recherche → Activation agent → Vérification effet
- ⚠️ Progression niveau 1 → 20 → Reset → Vérification gains
- ✅ Sauvegarde locale → Sync cloud → Chargement autre device

**Statut** : ✅ 9 tests intégration passent, ⚠️ 3 à créer

### 3. Tests de Performance

**Métriques** :
- Temps chargement initial : < 2s
- FPS gameplay : 60 FPS constant
- Mémoire utilisée : < 200 MB
- Taille snapshot : < 50 KB

**Statut** : ⚠️ À créer

### 4. Tests d'Équilibrage

**Objectifs** :
- Progression cohérente niveau 1 → 50
- Resets rentables à partir niveau 20
- Agents utiles mais pas obligatoires
- Recherches impactantes

**Méthodes** :
- Simulation automatique 100 parties
- Collecte métriques progression
- Ajustement formules si nécessaire

**Statut** : ⚠️ À créer

---

## 🏗️ Structure Tests

```
test/
├── cloud/              # ✅ 87 tests (100%)
├── integration/        # ✅ 9 tests
├── e2e_cloud/          # ✅ 30 tests (100%)
├── unit/               # ✅ ~200 tests
├── widget/             # ✅ 8 tests
└── chantiers/          # 🚧 24 tests (en développement)
```

---

## ✅ Checklist d'Implémentation

### Tests Intégration
- [ ] Test reset complet (niveau 1→20→reset→vérif)
- [ ] Test recherche + agent (déblocage→activation→effet)
- [ ] Test sauvegarde post-reset

### Tests Sérialisation
- [ ] Vérifier `resetHistory` dans toJson()
- [ ] Test migration snapshot v2→v3
- [ ] Test backup/restore

### Tests Performance
- [ ] Mesurer FPS gameplay
- [ ] Profiler mémoire
- [ ] Mesurer taille snapshot
- [ ] Optimiser si nécessaire

### Tests Équilibrage
- [ ] Créer simulateur progression
- [ ] Valider formules Quantum/PI
- [ ] Ajuster si nécessaire
- [ ] Documenter résultats

### CI/CD
- [ ] Automatiser tests dans CI
- [ ] Atteindre 80% couverture unitaire
- [ ] Atteindre 60% couverture intégration
- [ ] Tous tests passent avant merge

---

## 📊 Métriques de Succès

### Couverture
- ✅ Tests cloud : 100% (132 tests)
- ✅ Tests unitaires : ~80%
- ⚠️ Tests intégration : 60% (cible)
- ⚠️ Tests performance : À créer
- ⚠️ Tests équilibrage : À créer

### Qualité
- ✅ 350 tests passent (97-98%)
- ⚠️ Cible : 100% hors chantiers
- ✅ Architecture tests propre
- ✅ Documentation complète

---

## 📝 Notes Importantes

### Ordre d'Exécution Recommandé

1. **Tests intégration reset** : Critique pour valider CHANTIER-05
2. **Tests sérialisation** : Critique pour persistance
3. **Tests performance** : Important pour UX
4. **Tests équilibrage** : Important pour gameplay

### Estimation

- Tests intégration : 1-2 jours
- Tests sérialisation : 0.5 jour
- Tests performance : 1 jour
- Tests équilibrage : 2-3 jours
- CI/CD : 1 jour

**Total** : ~1 semaine de développement

---

**FIN DU DOCUMENT — CHANTIER-07 EN COURS