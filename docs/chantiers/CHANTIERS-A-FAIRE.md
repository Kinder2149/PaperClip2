# Chantiers à Implémenter - PaperClip2

**Date de création** : 7 avril 2026  
**Dernière mise à jour** : 7 avril 2026 14h00  
**Statut** : Document de référence pour les chantiers restants  
**Chantiers terminés** : 01 (Migration), 02 (Ressources), 03 (Recherche), 04 (Agents), 05 (Reset), 06 (Interface)

---

## 📊 ÉTAT ACTUEL (7 avril 2026 14h00)

### ✅ CHANTIERS TERMINÉS

**CHANTIER-00 : Nettoyage Legacy** ✅
- Architecture 100% cohérente `enterpriseId`
- 0 occurrence `worldId` dans code actif
- Backend compile sans erreur

**CHANTIER-01 à 04** ✅
- Migration, Ressources Rares, Recherche, Agents : **100% fonctionnels**

**CHANTIER-05 : Reset System** ✅ **TERMINÉ (7 avril 2026)**
- ✅ `ResetManager` refactoré (injection GameState)
- ✅ `ResetHistoryEntry` modèle créé
- ✅ Historique resets dans GameState
- ✅ Méthodes `reset()` dans tous managers
- ✅ 13 tests unitaires (100% passent)
- ⚠️ **À compléter** : Tests intégration, sérialisation snapshot

**CHANTIER-06 : Interface** ✅ **TERMINÉ (7 avril 2026)**
- ✅ `DashboardPanel` créé (vue d'ensemble)
- ✅ `StatisticsPanel` créé (détails + historique)
- ✅ Navigation 8 panneaux intégrée
- ✅ 16 tests widgets (100% passent)
- ⚠️ **À compléter** : Header ressources rares unifié

### 🟡 CHANTIER EN COURS

**CHANTIER-07 : Tests & Équilibrage** 🟡 **EN COURS**
- ✅ 29 tests créés (100% passent)
- ✅ Couverture : ResetHistoryEntry, ResetManager, 2 panels UI
- ❌ Tests intégration reset complet
- ❌ Tests sérialisation/désérialisation
- ❌ Tests performance
- ❌ Tests équilibrage

### 🎯 PRIORITÉS IMMÉDIATES

1. **Tests critiques manquants** (CHANTIER-07)
   - Test intégration reset complet
   - Test sérialisation historique dans snapshot
   - Tests managers individuels (reset methods)

2. **Compléments CHANTIER-05**
   - Vérifier sérialisation `resetHistory` dans GameState.toJson()
   - Tutorial post-reset (optionnel)

3. **Compléments CHANTIER-06**
   - Header ressources rares unifié (optionnel)
   - Tests navigation swipe

---

## 🎯 Vue d'Ensemble

Ce document consolide les **chantiers du projet PaperClip2** avec leur état d'avancement.

### 🟡 Chantier en Cours

1. **CHANTIER-07** : Tests & Équilibrage (continu) - � **EN COURS**
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

## ✅ CHANTIER-00 : Nettoyage Code Legacy (TERMINÉ)

**Statut** : ✅ TERMINÉ  
**Priorité** : CRITIQUE (bloquant)  
**Durée réelle** : 2 jours  
**Dépendances** : Aucune  
**Référence** : `docs/TODO-NETTOYAGE-CODE.md`

### 🎯 Objectif

Supprimer toutes les traces de l'ancienne architecture multi-worlds pour stabiliser le code et éviter les bugs.

**État initial** : Architecture hybride (frontend utilise `/enterprise`, backend expose encore `/worlds`)  
**État cible** : Architecture pure entreprise unique (aucune référence `worldId`, `partieId`, ou endpoints legacy)  
**État final** : ✅ Architecture 100% cohérente et stable

### ✅ Décisions Figées

- **Endpoints à garder** : `/enterprise/{uid}` uniquement (GET, PUT, DELETE)
- **Endpoints à supprimer** : `/worlds/*` et `/saves/*` (8 endpoints)
- **Validation** : Accepter uniquement `metadata.enterpriseId`
- **Renommage** : `World` → `Enterprise`, `worldId` → `enterpriseId`

### 📋 Travaux Backend

#### Fichier : `functions/src/index.ts`

**Endpoints à supprimer** (lignes 155-608) :
- `PUT /worlds/:worldId` (ligne 155)
- `GET /worlds/:worldId` (ligne 314)
- `GET /worlds` (ligne 357)
- `DELETE /worlds/:worldId` (ligne 424)
- `PUT /saves/:partieId` (ligne 471)
- `GET /saves/:partieId/latest` (ligne 520)
- `GET /saves` (ligne 563)
- `DELETE /saves/:partieId` (ligne 608)

**Validation à corriger** (ligne 175) :
```typescript
// AVANT (hybride)
const metaPid = metadata.partieId ?? metadata.partie_id ?? metadata.worldId ?? metadata.world_id;

// APRÈS (entreprise unique)
const enterpriseId = metadata.enterpriseId;
if (!enterpriseId || typeof enterpriseId !== 'string') {
  return res.status(422).json({ error: 'metadata_enterprise_id_missing' });
}
```

**Logique à supprimer** (lignes 203-207) :
- Limite 10 mondes (MAX_WORLDS)
- Vérification nombre de mondes

**Logs à nettoyer** :
- Remplacer `worldId` → `enterpriseId`
- Remplacer `partieId` → `enterpriseId`

#### Fichier : `functions/src/utils/logger.ts`

**Interface à corriger** (ligne 5) :
```typescript
// AVANT
export interface LogContext {
  uid?: string;
  worldId?: string;
  version?: number;
  operation?: string;
  duration?: number;
}

// APRÈS
export interface LogContext {
  uid?: string;
  enterpriseId?: string;
  version?: number;
  operation?: string;
  duration?: number;
}
```

### 📋 Travaux Frontend

#### 1. Renommer Classe `World` → `Enterprise`

**Fichier** : `lib/services/persistence/world_model.dart`
- Renommer fichier → `enterprise_model.dart`
- Renommer classe `World` → `Enterprise`
- Renommer propriété `worldId` → `enterpriseId`
- Mettre à jour tous les imports (17 fichiers)

#### 2. Nettoyer Logs (46 occurrences)

**Fichier** : `lib/services/persistence/game_persistence_orchestrator.dart`
- `'worldId': request.slotId` → `'enterpriseId': request.slotId`
- `'currentWorldId'` → `'currentEnterpriseId'`
- `'requestedWorldId'` → `'requestedEnterpriseId'`

#### 3. Nettoyer SyncResult

**Fichier** : `lib/services/persistence/sync_result.dart`
- `failedWorldIds` → `failedEnterpriseIds`

#### 4. Renommer Méthode SaveManager

**Fichier** : `lib/services/persistence/save_manager.dart`
- `loadWorld()` → `loadEnterprise()`

#### 5. Supprimer Méthodes Obsolètes

**Fichier** : `lib/services/persistence/local_game_persistence.dart`
- `saveSnapshotByWorldId()` (ligne 63)
- `loadSnapshotByWorldId()` (ligne 118)
- `loadWorld()` (ligne 188)
- `saveWorld()` (ligne 184)
- Métadonnée `md['worldId']` (ligne 220)

### ✅ Checklist d'Implémentation

**Backend** :
- [ ] Supprimer 8 endpoints `/worlds/*` et `/saves/*`
- [ ] Corriger validation (uniquement `enterpriseId`)
- [ ] Supprimer logique limite 10 mondes
- [ ] Nettoyer logs (`worldId` → `enterpriseId`)
- [ ] Mettre à jour `LogContext` interface
- [ ] Tester endpoints `/enterprise/*` fonctionnent
- [ ] Vérifier endpoints legacy retournent 404

**Frontend** :
- [ ] Renommer `world_model.dart` → `enterprise_model.dart`
- [ ] Renommer classe `World` → `Enterprise`
- [ ] Renommer `worldId` → `enterpriseId` (176 occurrences)
- [ ] Mettre à jour imports (17 fichiers)
- [ ] Supprimer méthodes obsolètes
- [ ] Nettoyer logs orchestrator (46 occurrences)
- [ ] Nettoyer `SyncResult`
- [ ] Renommer `loadWorld()` → `loadEnterprise()`
- [ ] Grep search final : 0 occurrence `worldId`
- [ ] Grep search final : 0 occurrence `partieId`

**Tests** :
- [ ] Mettre à jour tests backend (endpoints)
- [ ] Mettre à jour tests frontend (17 fichiers)
- [ ] Tests création entreprise
- [ ] Tests sauvegarde/chargement
- [ ] Tests sync cloud
- [ ] Tests suppression entreprise

### 📊 Métriques de Succès

- ✅ 0 occurrence `worldId` dans code Dart
- ✅ 0 occurrence `partieId` dans code Dart
- ✅ 0 endpoint `/worlds/*` actif
- ✅ 0 endpoint `/saves/*` actif
- ✅ Validation rejette `metadata.worldId`
- ✅ Validation accepte uniquement `metadata.enterpriseId`
- ✅ Tous les tests passent

---

## ✅ CHANTIER-05 : Système de Reset (TERMINÉ)

**Statut** : ✅ **TERMINÉ (7 avril 2026)**  
**Priorité** : Haute  
**Durée réelle** : 1 jour  
**Dépendances** : ✅ CHANTIER-00, 02, 03, 04 (tous terminés)

### 🎯 Objectif

Implémenter un système de reset volontaire ("Vente d'entreprise") permettant au joueur de recommencer avec des avantages permanents (Quantum + Points Innovation).

**Principe** : Le joueur clique sur un bouton, voit la valeur de son entreprise calculée en temps réel, confirme, et reset avec gains de ressources rares.

### ✅ Décisions Figées

- **Niveau 20 minimum** : Seuil validé
- **Manuel** : Joueur décide quand reset
- **Basé sur** : Valeur de l'entreprise
- **Gains** : Quantum + Points Innovation

### 📋 Spécifications Techniques

#### Conditions de Reset

- **Seuil minimum** : Niveau 20 atteint
- **Recommandation** : Attendre niveau 25-30 pour maximiser gains
- **Pas de limite** : Le joueur peut reset quand il veut après niveau 20

#### Formules de Calcul

**Quantum** :
```
Quantum = BASE + PRODUCTION + REVENUS + AUTOCLIPPERS + NIVEAU + TEMPS

Où :
- BASE = 20 (minimum garanti)
- PRODUCTION = log10(totalPaperclips / 1_000_000) × 15
- REVENUS = sqrt(totalMoney / 10_000) × 8
- AUTOCLIPPERS = autoClipperCount × 0.8
- NIVEAU = (playerLevel / 10)^1.5 × 12
- TEMPS = min(playTimeHours × 2, 50)

Bonus premier reset : ×1.5
Plafond maximum : 500 Q
```

**Points Innovation** :
```
PointsInnovation = BASE + RECHERCHES + NIVEAU + BONUS_QUANTUM

Où :
- BASE = 10 (minimum)
- RECHERCHES = nombreRecherchesComplétées × 2
- NIVEAU = playerLevel × 0.5
- BONUS_QUANTUM = (quantumGagné / 10)

Plafond maximum : 100 PI
```

#### Ce qui est RESET

| Élément | Reset ? | Valeur après reset |
|---------|---------|-------------------|
| Argent | ✅ Oui | 0€ |
| Métal | ✅ Oui | 500 (initial) |
| Trombones | ✅ Oui | 0 |
| Autoclippers | ✅ Oui | 0 |
| Stock marché métal | ✅ Oui | 80000 (initial) |
| Prix vente | ✅ Oui | 0.25€ (initial) |
| Saturation marché | ✅ Oui | 0.5 (initial) |
| Réputation | ✅ Oui | 1.0 (initial) |
| Niveau joueur | ✅ Oui | 1 |
| Upgrades | ✅ Oui | Niveau 0 (tous) |
| Statistiques production/vente | ✅ Oui | 0 |
| Missions en cours | ✅ Oui | Annulées |
| Paramétrages agents | ✅ Oui | Réinitialisés |

#### Ce qui est CONSERVÉ

| Élément | Conservé ? | Remarque |
|---------|-----------|----------|
| Quantum | ✅ Oui | + gain du reset |
| Points Innovation | ✅ Oui | + gain du reset |
| Agents débloqués | ✅ Oui | Mais désactivés |
| Recherches débloquées | ✅ Oui | Effets permanents |
| Slots agents | ✅ Oui | Restent débloqués |
| Statistiques lifetime | ✅ Oui | Total historique |
| Nombre de resets | ✅ Oui | Compteur |

### 🏗️ Architecture Technique

#### Fichiers à Créer

1. **`lib/managers/reset_manager.dart`**
   - Classe `ResetManager` (ou `WorldResetManager`)
   - Méthodes : `canReset()`, `calculatePotentialRewards()`, `performReset()`
   - Historique des resets

2. **`lib/services/reset/reset_rewards_calculator.dart`**
   - Calcul Quantum selon formule
   - Calcul Points Innovation selon formule
   - Validation plafonds

3. **`lib/dialogs/reset_confirmation_dialog.dart`**
   - Dialog de confirmation avec détails
   - Affichage gains potentiels
   - Liste ce qui est conservé/perdu

4. **`lib/dialogs/reset_success_dialog.dart`**
   - Dialog post-reset avec animation
   - Affichage gains obtenus
   - Tutorial premier reset

#### Extensions Managers

Ajouter méthodes `reset()` dans :
- `PlayerManager.resetResources()`
- `ProductionManager.resetProduction()`
- `MarketManager.resetMarket()`
- `LevelSystem.resetLevel()`
- `StatisticsManager.resetCurrentRun()`
- `AgentManager.deactivateAllAgents()`

### 🎨 Interface Utilisateur

#### Bouton Reset

- Visible uniquement si conditions remplies (niveau 20+)
- Affiche gains potentiels en temps réel
- Position : FloatingActionButton ou Dashboard

#### Dialog Confirmation

Sections :
1. **Valeur entreprise** : Quantum + PI gagnés (gros chiffres)
2. **Ce qui est conservé** : Liste avec ✅
3. **Ce qui est perdu** : Liste avec ❌
4. **Recommandation** : Texte conseil selon niveau
5. **Boutons** : Annuler / Confirmer la vente

#### Animation Reset

1. Dialog chargement ("Vente en cours...")
2. Effectuer reset (backend)
3. Dialog succès avec gains
4. Tutorial post-reset (premier reset uniquement)

### ✅ Checklist d'Implémentation

**✅ Terminé (7 avril 2026)** :
- [x] Créer `ResetManager` refactoré (injection GameState)
- [x] Créer `ResetRewardsCalculator` avec formules
- [x] Créer modèle `ResetHistoryEntry` avec sérialisation
- [x] Ajouter historique resets dans GameState
- [x] Ajouter méthodes reset() dans tous les managers
- [x] Créer dialog confirmation détaillé (`reset_progression_dialog.dart`)
- [x] Créer dialog succès avec animation (`reset_success_dialog.dart`)
- [x] Intégrer bouton reset dans DashboardPanel
- [x] Tests unitaires ResetManager (6 tests)
- [x] Tests unitaires ResetHistoryEntry (7 tests)

**⚠️ À compléter** :
- [ ] Vérifier sérialisation `resetHistory` dans GameState.toJson()
- [ ] Tests intégration reset complet (niveau 1→20→reset→vérif)
- [ ] Tests sauvegarde/chargement post-reset
- [ ] Tutorial post-reset (premier reset) - optionnel
- [ ] Validation équilibrage gains avec simulations

### 📊 Métriques de Succès

- Reset 1 : 20-40 Q, 15-25 PI
- Reset 2 : 60-100 Q, 35-50 PI
- Reset 3+ : 120-200 Q, 60-80 PI
- Aucune perte de données Quantum/Innovation
- Agents bien désactivés mais débloqués
- Recherches conservées

---

## ✅ CHANTIER-06 : Refonte Interface (TERMINÉ)

**Statut** : ✅ **TERMINÉ (7 avril 2026)**  
**Priorité** : Moyenne  
**Durée réelle** : 1 jour  
**Dépendances** : ✅ CHANTIER-02, 03, 04, 05 (tous terminés)

### 🎯 Objectif

Finaliser l'interface avec navigation PageView entre 6 panneaux spécialisés.

**Principe** : Navigation horizontale (swipe) entre panneaux au lieu de navigation par menus/boutons.

### ✅ Implémentation Terminée

**✅ Terminé (7 avril 2026)** :
- ✅ MainScreen avec PageView 8 panneaux
- ✅ DashboardPanel créé (vue d'ensemble complète)
- ✅ StatisticsPanel créé (métriques + historique resets)
- ✅ Navigation swipe fonctionnelle
- ✅ Indicateur de page
- ✅ 16 tests widgets (100% passent)

**⚠️ À compléter (optionnel)** :
- [ ] Header ressources rares unifié dans GameAppBar
- [ ] Animations transitions entre panels
- [ ] Tests navigation swipe
- [ ] Tests responsive (tablette vs mobile)

### 📋 Spécifications

#### Panneaux Implémentés (8 total)

1. **DashboardPanel** ✅ : Vue d'ensemble (stats, progression, ressources rares, actions)
2. **ProductionPanel** ✅ : Gestion production et autoclippers
3. **MarketPanel** ✅ : Ventes, prix, demande
4. **ResearchPanel** ✅ : Arbre de recherche
5. **AgentsPanel** ✅ : Configuration agents IA
6. **ProgressionPanel** ✅ : Niveau, XP, missions
7. **StatisticsPanel** ✅ : Métriques détaillées + historique resets
8. **SettingsPanel** ✅ : Paramètres

#### Détails Nouveaux Panneaux

**DashboardPanel** (380 lignes) :
- Stats grid : Argent, Trombones, Métal, Autoclippers
- Carte progression : Niveau, XP, barre
- Ressources rares : Quantum, PI, compteur resets
- Actions rapides : Acheter métal, Reset (si disponible)

**StatisticsPanel** (420 lignes) :
- Stats production : Total, manuel, auto, métal
- Stats économie : Argent gagné/dépensé, métal acheté
- Temps de jeu : Format HH:MM:SS
- Historique resets : Résumé + 5 derniers avec détails

### 🏗️ Architecture Technique

#### Fichiers à Modifier

1. **`lib/screens/main_screen.dart`**
   - Ajouter DashboardPanel en position 0
   - Réorganiser ordre panneaux
   - Améliorer header ressources rares

2. **`lib/screens/panels/dashboard_panel.dart`** (à créer)
   - Welcome card avec nom entreprise
   - Grid stats rapides (4 cartes)
   - Card agents actifs
   - Card achievements récents

3. **`lib/screens/panels/statistics_panel.dart`** (à améliorer)
   - Section session actuelle
   - Section lifetime
   - Section historique resets
   - Graphiques optionnels

4. **`lib/widgets/appbar/game_appbar.dart`**
   - Header ressources rares unifié
   - Quantum, Innovation, Argent toujours visibles

### 🎨 Interface Utilisateur

#### Header Ressources Rares

```
┌─────────────────────────────────────────┐
│  ⚡ 125 Q  │  💡 45 PI  │  💰 1.2k€    │
└─────────────────────────────────────────┘
```

#### Ordre Panneaux Final

1. **Dashboard** - Vue d'ensemble
2. **Production** - Fabrication
3. **Marché** - Ventes
4. **Agents** - IA
5. **Recherche** - Tech
6. **Progression** - XP/Missions
7. **Statistiques** - Métriques
8. **Paramètres** - Config

#### Indicateur de Page

- Dots animés en bas d'écran
- Dot actif plus large
- Couleur primaire du thème

### ✅ Checklist d'Implémentation

- [ ] Créer `DashboardPanel`
- [ ] Améliorer `StatisticsPanel`
- [ ] Créer header ressources rares unifié
- [ ] Réorganiser ordre panneaux dans MainScreen
- [ ] Implémenter animations transitions
- [ ] Ajouter swipe hint (première utilisation)
- [ ] Tests navigation swipe
- [ ] Tests responsive (différentes tailles écran)
- [ ] Optimisation performance (lazy loading)
- [ ] Tests 60 FPS

### 📊 Métriques UX

- Temps navigation entre panneaux : < 300ms
- Fluidité swipe : 60 FPS
- Chargement initial : < 1s
- Pas de lag lors du swipe

---

## 🟡 CHANTIER-07 : Tests & Équilibrage

**Statut** : À démarrer  
**Priorité** : Critique  
**Durée estimée** : Continu  
**Dépendances** : Tous les chantiers

### 🎯 Objectif

Définir et implémenter une stratégie de tests complète pour garantir la qualité, la performance et l'équilibrage du jeu.

### ✅ Décisions Figées

- **Tests unitaires** : 80% de couverture
- **Tests intégration** : 60% de couverture
- **Tests continus** : Tout au long du développement

### 📋 Types de Tests

#### 1. Tests Unitaires

**Cible** : Logique métier isolée

**Fichiers à tester** :
- `RareResourcesManager` : Quantum, Innovation Points
- `ResearchManager` : Déblocage, coûts, effets
- `AgentManager` : Activation, désactivation, actions
- `ResetManager` : Calculs récompenses, reset complet
- `ProductionManager` : Production, autoclippers
- `MarketManager` : Demande, prix, saturation

**Exemple** :
```dart
// test/unit/rare_resources_test.dart
void main() {
  group('Quantum Calculation', () {
    test('Minimum quantum garanti', () {
      final quantum = ResetRewardsCalculator.calculateQuantumReward(
        totalPaperclipsProduced: 0,
        totalMoneyEarned: 0,
        autoClipperCount: 0,
        playerLevel: 1,
        playTimeHours: 0,
        resetCount: 0,
      );
      expect(quantum, equals(20));
    });
    
    test('Plafond 500 Q respecté', () {
      final quantum = ResetRewardsCalculator.calculateQuantumReward(
        totalPaperclipsProduced: 1_000_000_000_000,
        totalMoneyEarned: 100_000_000,
        autoClipperCount: 1000,
        playerLevel: 100,
        playTimeHours: 1000.0,
        resetCount: 5,
      );
      expect(quantum, equals(500));
    });
  });
}
```

#### 2. Tests d'Intégration

**Cible** : Flux complets utilisateur

**Scénarios à tester** :
- Création entreprise → Production → Vente → Achat autoclipper
- Déblocage recherche → Activation agent → Vérification effet
- Progression niveau 1 → 20 → Reset → Vérification gains
- Sauvegarde locale → Sync cloud → Chargement autre device

#### 3. Tests de Performance

**Métriques** :
- Temps chargement initial : < 2s
- FPS gameplay : 60 FPS constant
- Mémoire utilisée : < 200 MB
- Taille snapshot : < 50 KB

**Outils** :
- Flutter DevTools
- Performance overlay
- Memory profiler

#### 4. Tests d'Équilibrage

**Objectifs** :
- Progression cohérente niveau 1 → 50
- Resets rentables à partir niveau 20
- Agents utiles mais pas obligatoires
- Recherches impactantes

**Méthodes** :
- Simulation automatique 100 parties
- Collecte métriques progression
- Ajustement formules si nécessaire

### 🏗️ Structure Tests

```
test/
├── unit/
│   ├── rare_resources_test.dart
│   ├── research_manager_test.dart
│   ├── agent_manager_test.dart
│   ├── reset_manager_test.dart
│   ├── production_manager_test.dart
│   └── market_manager_test.dart
├── integration/
│   ├── gameplay_flow_test.dart
│   ├── reset_flow_test.dart
│   ├── persistence_flow_test.dart
│   └── cloud_sync_test.dart
├── performance/
│   ├── fps_test.dart
│   ├── memory_test.dart
│   └── snapshot_size_test.dart
└── balancing/
    ├── progression_simulation.dart
    ├── reset_rewards_analysis.dart
    └── agent_impact_analysis.dart
```

### ✅ Checklist d'Implémentation

- [ ] Créer structure dossiers tests
- [ ] Implémenter tests unitaires managers
- [ ] Implémenter tests intégration flux critiques
- [ ] Implémenter tests performance
- [ ] Créer outils simulation progression
- [ ] Définir métriques équilibrage objectives
- [ ] Automatiser tests CI/CD
- [ ] Atteindre 80% couverture unitaire
- [ ] Atteindre 60% couverture intégration
- [ ] Valider équilibrage avec simulations

### 📊 Métriques de Succès

- Couverture tests : 80% unitaire, 60% intégration
- Tous les tests passent avant merge
- Performance : 60 FPS constant
- Équilibrage : Progression cohérente sur simulations

---

## 📝 Notes Importantes

### Ordre d'Exécution Recommandé

0. **CHANTIER-00** (Nettoyage) : 🔴 CRITIQUE - Stabiliser architecture
1. **CHANTIER-05** (Reset) : Finaliser boucle complète du jeu
2. **CHANTIER-06** (Interface) : Améliorer UX
3. **CHANTIER-07** (Tests) : Continu, parallèle aux autres

### Estimation Totale

- CHANTIER-00 : 2-3 jours (CRITIQUE)
- CHANTIER-05 : 2-3 jours (finalisation)
- CHANTIER-06 : 2-3 jours
- CHANTIER-07 : Continu

**Total** : ~2 semaines de développement

### ⚠️ RECOMMANDATION FORTE

**Démarrer par CHANTIER-00** avant tout autre travail :
1. Code legacy crée confusion et risque de bugs
2. Architecture hybride instable
3. Nettoyage facilitera tous les chantiers suivants
4. Évite de propager le code legacy dans nouvelles features

### Dépendances Externes

- Aucune dépendance externe bloquante
- Tous les chantiers précédents (01-04) sont terminés
- Code base stable et fonctionnel

---

**FIN DU DOCUMENT — TOUS LES CHANTIERS RESTANTS SONT DOCUMENTÉS ICI**
