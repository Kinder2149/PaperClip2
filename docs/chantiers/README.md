# 🏗️ CHANTIERS DE TRANSFORMATION PAPERCLIP2

## 📋 Fonctionnement du Dossier

Ce dossier contient la roadmap et les spécifications des chantiers de transformation du jeu.

**Structure** :
- **README.md** (ce fichier) : Décisions figées + état d'avancement
- **CHANTIERS-A-FAIRE.md** : Détails de tous les chantiers restants à implémenter
- **archives/** : Historique des chantiers terminés et documents obsolètes

## 🎯 Objectif Global

Transformation de PaperClip2 : **Idle multi-parties** → **Simulation d'entreprise unique stratégique**

## ✅ DÉCISIONS FIGÉES (Chantiers 01-04)

### Architecture (CHANTIER-01)
- **1 utilisateur = 1 entreprise** : UUID v4 unique
- **Endpoint cloud** : `/enterprise/{uid}` exclusif
- **Format snapshot v3** : `enterpriseId` + `enterpriseName`
- **Cloud always wins** : Synchronisation automatique

### Ressources Rares (CHANTIER-02)
- **Quantum** : Monnaie stratégique pour agents et capacités majeures
- **Points Innovation** : Monnaie pour arbre de recherche
- **Persistance** : Conservés après reset
- **Gains** : Via reset entreprise (formules figées)

### Arbre Recherche (CHANTIER-03)
- **Fusion upgrades** : Upgrades existants → Recherches
- **Choix exclusifs** : Certaines branches A OU B
- **Déblocage agents** : Via nœuds recherche
- **Monnaie** : Points Innovation
- **Persistance** : Recherches conservées après reset

### Agents IA (CHANTIER-04)
- **4 agents** : Production Optimizer, Market Analyst, Metal Buyer, Innovation Researcher
- **Déblocage** : Via recherche (coût PI)
- **Activation** : 5 Quantum par agent par heure
- **Slots** : 2 de base, extensible à 4
- **Actions** : Event-driven, toutes les 5-10 minutes

## 🎯 ORDRE D'EXÉCUTION VALIDÉ

### ✅ CHANTIER-01 : Migration Multi→Unique — TERMINÉ
- Architecture entreprise unique implémentée
- Endpoint `/enterprise/{uid}` fonctionnel
- Format snapshot v3 avec `enterpriseId`
- **Note** : Traces `worldId` à nettoyer (voir `docs/TODO-NETTOYAGE-CODE.md`)

### ✅ CHANTIER-02 : Ressources Rares — TERMINÉ
- `RareResourcesManager` implémenté
- Quantum + Points Innovation fonctionnels
- Formules de calcul reset implémentées
- Intégration snapshot v3

### ✅ CHANTIER-03 : Arbre de Recherche — TERMINÉ
- `ResearchManager` implémenté
- Arbre complet avec 30+ nœuds
- Choix exclusifs fonctionnels
- `ResearchPanel` UI créé

### ✅ CHANTIER-04 : Système d'Agents — TERMINÉ
- `AgentManager` implémenté
- 4 agents fonctionnels (Production, Market, Metal, Innovation)
- Activation/désactivation avec Quantum
- `AgentsPanel` UI créé

### ✅ CHANTIER-05 : Système de Reset — TERMINÉ (7 avril 2026)
- ✅ `ResetManager` refactoré (injection GameState directe)
- ✅ `ResetHistoryEntry` modèle créé avec sérialisation
- ✅ Historique resets intégré dans GameState
- ✅ Méthodes reset() dans tous les managers
- ✅ 13 tests unitaires (100% passent)
- ⚠️ **À compléter** : Tests intégration, sérialisation snapshot

### ✅ CHANTIER-06 : Refonte Interface — TERMINÉ (7 avril 2026)
- ✅ `DashboardPanel` créé (vue d'ensemble)
- ✅ `StatisticsPanel` créé (détails + historique)
- ✅ Navigation 8 panneaux intégrée dans MainScreen
- ✅ 16 tests widgets (100% passent)
- ⚠️ **À compléter** : Header ressources rares unifié, tests navigation

### 🟡 CHANTIER-07 : Tests & Équilibrage — EN COURS
- ✅ 29 tests créés (100% passent)
- ✅ Couverture : ResetHistoryEntry (100%), ResetManager (100%), 2 panels UI
- ❌ Tests intégration reset complet
- ❌ Tests sérialisation snapshot
- ❌ Tests performance (FPS, mémoire)
- ❌ Tests équilibrage progression
- **Voir** : `CHANTIERS-A-FAIRE.md` pour détails

## 📁 Documents

### Document Principal
- **[CHANTIERS-A-FAIRE.md](./CHANTIERS-A-FAIRE.md)** : Tous les chantiers restants (05, 06, 07)

### Archives
- **[archives/](./archives/)** : Historique des chantiers terminés (01-04) et documents obsolètes

## 🔗 Dépendances Restantes

```
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

## ⚠️ RÈGLES STRICTES

1. **RESPECTER L'ORDRE** : Ne pas commencer un chantier avant ses dépendances
2. **Migration d'abord** : CHANTIER-01 bloquant pour tout le reste
3. **Tests unitaires** pour chaque chantier avant de passer au suivant
4. **Backup Git** avant chaque phase
5. **Documentation code** obligatoire et à jour

## 📊 Estimation réaliste

- **Durée totale** : **9-10 semaines** (avec Phase 0 design)
- **Complexité** : Très élevée
- **Risques** : Migration architecture, équilibrage gameplay, performance agents
