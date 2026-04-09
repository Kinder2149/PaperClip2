# Features PaperClip2

**Date** : 9 avril 2026  
**Version** : 3.0  
**Statut** : ✅ Production

## 📋 Vue d'Ensemble

PaperClip2 est un jeu incrémental avec méta-progression basé sur les resets volontaires.

---

## ✅ Features Implémentées

### 1. Entreprise Unique (CHANTIER-01)

**Principe** : Un joueur = une entreprise avec UUID unique

**Fonctionnalités** :
- Création entreprise avec nom personnalisable
- UUID v4 généré automatiquement
- Nom modifiable après création
- Suppression entreprise (testeurs uniquement)

**Implémentation** :
- `GameState.createNewEnterprise(name)`
- `GameState.setEnterpriseName(name)`
- `GameState.deleteEnterprise()`

---

### 2. Ressources Rares (CHANTIER-02)

**Principe** : Monnaies de méta-progression qui persistent après reset

#### Quantum

**Usage** : Débloquer agents IA et capacités majeures  
**Gain** : Reset progression (formule basée sur valeur entreprise)  
**Plafond** : 500 Q

#### Points Innovation

**Usage** : Débloquer recherches dans l'arbre technologique  
**Gain** : Reset progression (formule basée sur recherches complétées)  
**Plafond** : 100 PI

**Implémentation** :
- `RareResourcesManager`
- Statistiques lifetime (total gagné/dépensé)
- Historique resets

---

### 3. Système de Recherche (CHANTIER-03)

**Principe** : Arbre technologique débloqué avec Points Innovation

**Catégories** :
- Recherches Production (5)
- Recherches Marché (5)
- Recherches Agents (5)
- Recherches META (5)

**Fonctionnalités** :
- Déblocage avec Points Innovation
- Dépendances entre recherches
- Effets permanents (conservés après reset)
- Persistance dans snapshot

**Implémentation** :
- `ResearchManager`
- `ResearchNode` model
- UI `ResearchPanel`

---

### 4. Agents IA (CHANTIER-04)

**Principe** : Assistants IA qui automatisent certaines tâches

**5 Agents** :
1. **ProductionOptimizer** - Optimise production autoclippers
2. **MarketAnalyst** - Analyse demande et ajuste prix
3. **MetalBuyer** - Achète métal automatiquement
4. **InnovationResearcher** - Accélère recherches
5. **QuantumResearcher** - Bonus Quantum sur reset

**Fonctionnalités** :
- Activation/désactivation
- Coût en Quantum
- Durée limitée
- Effets spécifiques par agent
- Déblocage via recherches

**Implémentation** :
- `AgentManager`
- `Agent` model
- UI `AgentsPanel`

---

### 5. Système de Reset (CHANTIER-05)

**Principe** : Vendre l'entreprise pour recommencer avec avantages

**Conditions** :
- Niveau 20 minimum
- Manuel (joueur décide)
- Recommandation : niveau 25-30

**Gains** :
- Quantum (formule basée sur valeur entreprise)
- Points Innovation (formule basée sur recherches)
- Bonus premier reset : ×1.5

**Conservation** :
- ✅ Quantum et Points Innovation
- ✅ Recherches débloquées
- ✅ Agents débloqués (mais désactivés)
- ✅ Statistiques lifetime
- ✅ Nombre de resets

**Reset** :
- ❌ Argent, métal, trombones
- ❌ Autoclippers
- ❌ Niveau joueur
- ❌ Upgrades
- ❌ Missions en cours

**Implémentation** :
- `ResetManager`
- `ResetHistoryEntry` model
- Dialogs confirmation et succès
- Historique resets dans GameState

---

### 6. Interface PageView (CHANTIER-06)

**Principe** : Navigation horizontale entre 8 panneaux spécialisés

**8 Panneaux** :
1. **DashboardPanel** - Vue d'ensemble (stats, progression, actions rapides)
2. **ProductionPanel** - Gestion production et autoclippers
3. **MarketPanel** - Ventes, prix, demande
4. **AgentsPanel** - Configuration agents IA
5. **ResearchPanel** - Arbre de recherche
6. **ProgressionPanel** - Niveau, XP, missions
7. **StatisticsPanel** - Métriques détaillées + historique resets
8. **SettingsPanel** - Paramètres

**Fonctionnalités** :
- Navigation swipe horizontale
- Indicateur de page (dots)
- Header ressources rares unifié
- Transitions fluides

**Implémentation** :
- `MainScreen` avec PageView
- 8 panels créés
- 16 tests widgets validés

---

### 7. Sauvegarde Cloud (CHANTIER-SAUVEGARDE-CLOUD)

**Principe** : Synchronisation automatique multi-device via Firebase

**Fonctionnalités** :
- Authentification Google
- Sauvegarde automatique
- Sync multi-device
- Résolution conflits (Last-Write-Wins)
- Offline-first

**Infrastructure** :
- Backend Node.js + Express
- Firebase Auth + Firestore
- Endpoints REST `/enterprise/{uid}`
- 132 tests (100% passent)

**Implémentation** :
- `GamePersistenceOrchestrator`
- `CloudPersistenceAdapter`
- `ProtectedHttpClient`
- Retry policy

---

### 8. Sauvegarde Locale (CHANTIER-SAUVEGARDE-LOCALE)

**Principe** : Sauvegarde locale robuste avec backup

**Fonctionnalités** :
- Sauvegarde automatique (SQLite)
- Système de backup
- Gestion versions
- Migration données

**Implémentation** :
- `LocalSaveGameManager`
- Tests unitaires complets
- Backup/restore

---

## 📊 Métriques Features

### Gameplay

| Feature | Statut | Tests |
|---------|--------|-------|
| Entreprise unique | ✅ 100% | ✅ Validés |
| Ressources rares | ✅ 100% | ✅ Validés |
| Recherche | ✅ 100% | ✅ Validés |
| Agents IA | ✅ 100% | ✅ Validés |
| Reset | ✅ 100% | ✅ Validés |
| Interface | ✅ 100% | ✅ 16 tests |

### Infrastructure

| Feature | Statut | Tests |
|---------|--------|-------|
| Cloud sync | ✅ 100% | ✅ 132 tests |
| Local save | ✅ 100% | ✅ Validés |
| Persistance | ✅ 100% | ✅ Validés |

---

## 🚀 Roadmap Future

### Court Terme
- Équilibrage progression
- Tests performance
- CI/CD automatisé

### Moyen Terme
- Analytics gameplay
- Tests sur devices réels
- Optimisations

### Long Terme
- Beta testing
- Release production
- Déploiement stores

---

**Dernière mise à jour** : 9 avril 2026  
**Statut** : ✅ Production
