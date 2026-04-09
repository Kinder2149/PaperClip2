# Analyse de Cohérence - Chantiers PaperClip2

**Date** : 7 avril 2026  
**Analyste** : Cascade AI  
**Objectif** : Vérifier cohérence entre documentation chantiers et code réel

---

## 🎯 RÉSUMÉ EXÉCUTIF

### ✅ Bonne Nouvelle
- Chantiers 01-04 sont **réellement terminés** (Migration, Ressources, Recherche, Agents)
- CHANTIER-05 (Reset) est **partiellement implémenté** (~60% fait)
- CHANTIER-06 (Interface) a une **base solide** (PageView fonctionnel)
- CHANTIER-07 (Tests) a une **bonne couverture** (36 fichiers de tests)

### 🔴 Problème Critique Détecté

**Code legacy `worldId` NON nettoyé** malgré migration terminée :
- Backend expose encore 8 endpoints obsolètes `/worlds/*` et `/saves/*`
- Validation hybride accepte `partieId ?? worldId ?? enterpriseId`
- 176 occurrences `worldId` dans 17 fichiers Dart
- Classe `World` existe encore (devrait être `Enterprise`)

**Impact** : Architecture hybride instable, confusion, risque de bugs

### 📋 Recommandation

**CRÉER CHANTIER-00 : Nettoyage Code Legacy (PRIORITÉ CRITIQUE)**
- Durée : 2-3 jours
- À faire AVANT CHANTIER-05
- Bloquant pour stabilité du projet

---

## 📊 ANALYSE DÉTAILLÉE PAR CHANTIER

### CHANTIER-05 : Système de Reset

**Statut réel** : ⚠️ Partiellement implémenté (60%)

**Déjà fait** :
- ✅ `ResetManager` créé et fonctionnel (`lib/managers/reset_manager.dart`)
- ✅ `ResetRewardsCalculator` implémenté avec formules complètes
- ✅ Dialog confirmation créé (`lib/dialogs/reset_progression_dialog.dart`)
- ✅ Dialog succès créé (`lib/dialogs/reset_success_dialog.dart`)
- ✅ Tests unitaires présents (`test/unit/reset_manager_test.dart`)

**Manquant** :
- ❌ Bouton UI dans panels (ProgressionPanel ou DashboardPanel)
- ❌ Méthodes `reset()` dans tous les managers
- ❌ Tutorial post-reset (premier reset)
- ❌ Historique resets dans snapshot
- ❌ Tests intégration reset complet

**Estimation restante** : 2-3 jours (au lieu de 4-5 jours initialement)

### CHANTIER-06 : Refonte Interface

**Statut réel** : ⚠️ Base implémentée, panels manquants

**Déjà fait** :
- ✅ PageView avec navigation swipe (`lib/screens/main_screen.dart`)
- ✅ 6 panneaux créés et fonctionnels :
  - ProductionPanel
  - MarketPanel
  - ResearchPanel
  - AgentsPanel
  - ProgressionPanel
  - SettingsPanel
- ✅ Indicateur de page
- ✅ Animations transitions

**Manquant** :
- ❌ DashboardPanel (vue d'ensemble)
- ❌ StatisticsPanel (métriques détaillées)
- ❌ Header ressources rares unifié

**Estimation restante** : 2-3 jours

### CHANTIER-07 : Tests & Équilibrage

**Statut réel** : ⚠️ Couverture partielle

**Existant** :
- ✅ 36 fichiers de tests
- ✅ Tests unitaires : RareResources, Research, Agents, Reset
- ✅ Tests intégration : Cloud sync, Enterprise flow, Agents
- ✅ Structure organisée (unit/, integration_test/)

**Manquant** :
- ❌ Tests performance (FPS, mémoire)
- ❌ Tests équilibrage (simulations)
- ❌ Couverture 80% unitaire (objectif)
- ❌ Couverture 60% intégration (objectif)

**Estimation** : Continu

---

## 🔴 PROBLÈME CRITIQUE : Code Legacy

### Backend (`functions/src/index.ts`)

**Endpoints obsolètes ENCORE PRÉSENTS** :
```
Ligne 155  : PUT /worlds/:worldId
Ligne 314  : GET /worlds/:worldId
Ligne 357  : GET /worlds
Ligne 424  : DELETE /worlds/:worldId
Ligne 471  : PUT /saves/:partieId
Ligne 520  : GET /saves/:partieId/latest
Ligne 563  : GET /saves
Ligne 608  : DELETE /saves/:partieId
```

**Validation hybride** (ligne 175) :
```typescript
const metaPid = metadata.partieId ?? metadata.partie_id ?? metadata.worldId ?? metadata.world_id;
```
❌ Accepte 4 formats différents au lieu de `enterpriseId` uniquement

**Logique obsolète** (lignes 203-207) :
```typescript
const MAX_WORLDS = 10;
if (existingWorlds.length >= MAX_WORLDS) {
  return res.status(429).json({ error: 'max_worlds_exceeded' });
}
```
❌ Limite 10 mondes alors qu'on a 1 seule entreprise

### Frontend (Dart)

**176 occurrences `worldId`** dans 17 fichiers :
- `game_persistence_orchestrator.dart` : 46 occurrences
- Tests cloud : 72 occurrences (3 fichiers)
- `local_game_persistence.dart` : 18 occurrences
- `sync_result.dart` : 5 occurrences
- `world_model.dart` : 5 occurrences (classe `World` existe encore)

**Classe obsolète** :
```dart
// lib/services/persistence/world_model.dart
class World {
  final String worldId;  // ❌ Devrait être enterpriseId
  // ...
}
```

---

## 📋 PLAN D'ACTION RECOMMANDÉ

### Phase 0 : CHANTIER-00 - Nettoyage Legacy (2-3 jours) 🔴 CRITIQUE

**Backend** :
1. Supprimer 8 endpoints `/worlds/*` et `/saves/*`
2. Corriger validation : accepter uniquement `metadata.enterpriseId`
3. Supprimer logique limite 10 mondes
4. Nettoyer logs (`worldId` → `enterpriseId`)
5. Mettre à jour `LogContext` interface

**Frontend** :
1. Renommer `world_model.dart` → `enterprise_model.dart`
2. Renommer classe `World` → `Enterprise`
3. Renommer `worldId` → `enterpriseId` (176 occurrences)
4. Mettre à jour imports (17 fichiers)
5. Supprimer méthodes obsolètes
6. Nettoyer logs (46 occurrences)

**Tests** :
1. Mettre à jour tests backend
2. Mettre à jour tests frontend (17 fichiers)
3. Vérifier endpoints legacy retournent 404

**Validation finale** :
- Grep search : 0 occurrence `worldId`
- Grep search : 0 occurrence `partieId`
- Tous les tests passent

### Phase 1 : CHANTIER-05 - Finaliser Reset (2-3 jours)

1. Ajouter méthodes `reset()` dans managers
2. Créer bouton UI dans ProgressionPanel
3. Intégrer dialogs existants
4. Créer tutorial post-reset
5. Intégrer historique dans snapshot
6. Tests intégration

### Phase 2 : CHANTIER-06 - Finaliser Interface (2-3 jours)

1. Créer DashboardPanel
2. Améliorer StatisticsPanel
3. Créer header ressources rares
4. Optimisations performance

### Phase 3 : CHANTIER-07 - Tests & Équilibrage (continu)

1. Compléter couverture tests
2. Tests performance
3. Simulations équilibrage

---

## 🎯 MÉTRIQUES DE COHÉRENCE

### Documentation vs Code

| Chantier | Doc dit | Code réel | Écart |
|----------|---------|-----------|-------|
| CHANTIER-01 | ✅ Terminé | ⚠️ Legacy reste | 40% nettoyage manquant |
| CHANTIER-02 | ✅ Terminé | ✅ Terminé | ✅ Cohérent |
| CHANTIER-03 | ✅ Terminé | ✅ Terminé | ✅ Cohérent |
| CHANTIER-04 | ✅ Terminé | ✅ Terminé | ✅ Cohérent |
| CHANTIER-05 | ❌ À faire | ⚠️ 60% fait | 60% implémenté |
| CHANTIER-06 | ❌ À faire | ⚠️ 50% fait | 50% implémenté |
| CHANTIER-07 | ❌ À faire | ⚠️ 40% fait | 40% implémenté |

### Fichiers Vérifiés

**Backend** :
- ✅ `functions/src/index.ts` (995 lignes)
- ✅ `functions/src/utils/logger.ts`

**Frontend** :
- ✅ `lib/managers/reset_manager.dart` (101 lignes)
- ✅ `lib/services/reset/reset_rewards_calculator.dart`
- ✅ `lib/dialogs/reset_progression_dialog.dart` (209 lignes)
- ✅ `lib/dialogs/reset_success_dialog.dart`
- ✅ `lib/screens/main_screen.dart` (1390 lignes)
- ✅ `lib/services/persistence/world_model.dart` (55 lignes)
- ✅ `lib/services/persistence/game_persistence_orchestrator.dart`
- ✅ `lib/services/persistence/sync_result.dart`

**Tests** :
- ✅ 36 fichiers de tests identifiés
- ✅ `test/unit/reset_manager_test.dart` existe

---

## ⚠️ RISQUES IDENTIFIÉS

### Risque 1 : Architecture Hybride (CRITIQUE)
- **Impact** : Bugs imprévisibles, confusion développeurs
- **Probabilité** : Haute
- **Mitigation** : CHANTIER-00 immédiat

### Risque 2 : Tests Obsolètes
- **Impact** : Tests passent mais testent ancien code
- **Probabilité** : Moyenne
- **Mitigation** : Mise à jour tests dans CHANTIER-00

### Risque 3 : Propagation Legacy
- **Impact** : Nouveau code utilise anciens patterns
- **Probabilité** : Haute si pas nettoyé
- **Mitigation** : CHANTIER-00 avant CHANTIER-05

---

## ✅ CONCLUSION

### Points Positifs
1. Chantiers 01-04 fonctionnels
2. CHANTIER-05 bien avancé (60%)
3. Bonne base tests (36 fichiers)
4. Architecture cible claire

### Points d'Attention
1. **CRITIQUE** : Code legacy non nettoyé
2. Documentation surestimait travail restant
3. Certains éléments déjà implémentés

### Recommandation Finale

**DÉMARRER IMMÉDIATEMENT CHANTIER-00** (2-3 jours)
- Stabilise architecture
- Évite bugs
- Facilite chantiers suivants
- Bloquant pour qualité projet

**Puis enchaîner** :
1. CHANTIER-05 (2-3 jours)
2. CHANTIER-06 (2-3 jours)
3. CHANTIER-07 (continu)

**Durée totale révisée** : ~2 semaines (au lieu de 9-10 semaines)

---

**Statut** : ✅ Analyse terminée  
**Prochaine étape** : Validation utilisateur + Démarrage CHANTIER-00
