# VÉRIFICATION DÉTAILLÉE TECHNIQUE - PAPERCLIP2

**Date** : 30 mars 2026  
**Complément au rapport principal** : `verification-chantiers-paperclip2-60eba5.md`

---

## 📐 FORMULES DE CALCUL VÉRIFIÉES

### Quantum (Reset Rewards)

**Fichier** : `lib/services/reset/reset_rewards_calculator.dart`

**Formule implémentée** :
```
Quantum = BASE + PRODUCTION + REVENUS + AUTOCLIPPERS + NIVEAU + TEMPS
```

**Constantes vérifiées** :
- ✅ `QUANTUM_BASE = 20.0`
- ✅ `QUANTUM_PRODUCTION_MULTIPLIER = 15.0`
- ✅ `QUANTUM_REVENUE_MULTIPLIER = 8.0`
- ✅ `QUANTUM_AUTOCLIPPER_MULTIPLIER = 0.8`
- ✅ `QUANTUM_LEVEL_MULTIPLIER = 12.0`
- ✅ `QUANTUM_TIME_MULTIPLIER = 2.0`
- ✅ `QUANTUM_TIME_CAP = 50.0`
- ✅ `QUANTUM_FIRST_RESET_BONUS = 1.5` (×1.5 premier reset)
- ✅ `QUANTUM_MAX_CAP = 500.0`

**Détails calcul** :
1. Production : `log10(totalPaperclips / 1_000_000) × 15`
2. Revenus : `sqrt(totalMoney / 10_000) × 8`
3. Autoclippers : `count × 0.8`
4. Niveau : `(level / 10)^1.5 × 12`
5. Temps : `min(playTimeHours × 2, 50)`
6. Bonus META : `total × (1.0 + researchBonus)`

**Correspondance doc** : ⚠️ **À VÉRIFIER** - Comparer avec CHANTIER-02 doc ligne par ligne

---

### Points Innovation (Reset Rewards)

**Formule implémentée** :
```
PI = BASE + RECHERCHES + NIVEAU + BONUS_QUANTUM
```

**Constantes vérifiées** :
- ✅ `INNOVATION_BASE = 10.0`
- ✅ `INNOVATION_RESEARCH_MULTIPLIER = 2.0`
- ✅ `INNOVATION_LEVEL_MULTIPLIER = 0.5`
- ✅ `INNOVATION_QUANTUM_DIVISOR = 10.0`
- ✅ `INNOVATION_MAX_CAP = 100.0`

**Détails calcul** :
1. Recherches : `count × 2`
2. Niveau : `level × 0.5`
3. Bonus Quantum : `quantumGained / 10`
4. Bonus META : `total × (1.0 + researchBonus)`

**Correspondance doc** : ⚠️ **À VÉRIFIER**

---

## 🔍 INTÉGRATION MANAGERS VÉRIFIÉE

### GameState - Initialisation Managers

**Fichier** : `lib/models/game_state.dart`

**Ordre d'initialisation** :
1. ✅ PlayerManager
2. ✅ MarketManager
3. ✅ ResourceManager
4. ✅ LevelSystem
5. ✅ MissionSystem (en pause)
6. ✅ StatisticsManager
7. ✅ ProductionManager
8. ✅ ProgressionRulesService
9. ✅ GameEngine
10. ✅ GameEventBus
11. ✅ **RareResourcesManager** (ligne 59)
12. ✅ **ResearchManager** (ligne 61)
13. ✅ **AgentManager** (ligne 63)
14. ✅ **ResetManager** (ligne 65)

**Dépendances respectées** :
- ✅ ResearchManager dépend de RareResourcesManager
- ✅ AgentManager dépend de RareResourcesManager + ResearchManager
- ✅ ResetManager utilise callbacks vers GameState

---

### Reset Progression - Méthodes `resetForProgression()`

**Vérification implémentation dans chaque manager** :

1. ✅ **PlayerManager** : `resetForProgression()` - ligne 593 GameState
2. ✅ **ProductionManager** : `resetForProgression()` - ligne 594 GameState
3. ✅ **MarketManager** : `resetForProgression()` - ligne 595 GameState
4. ✅ **LevelSystem** : `resetForProgression()` - ligne 596 GameState
5. ✅ **StatisticsManager** : `resetCurrentRun()` - ligne 597 GameState
6. ✅ **AgentManager** : `resetForProgression()` - ligne 598 GameState
7. ✅ **ResourceManager** : `resetResources()` - ligne 599 GameState
8. ✅ **ResearchManager** : `resetForProgression()` - ligne 602 GameState (conserve META)

**Conservation après reset** :
- ✅ Quantum (dans RareResourcesManager)
- ✅ Points Innovation (dans RareResourcesManager)
- ✅ Recherches META (dans ResearchManager)
- ✅ Agents débloqués (statut UNLOCKED conservé)
- ✅ Slots agents débloqués
- ✅ Statistiques lifetime

---

## 🎨 UI/UX IMPLÉMENTÉE

### Dialogs Reset

**Fichiers vérifiés** :
1. ✅ `lib/dialogs/reset_progression_dialog.dart` (209 lignes)
   - Affiche gains potentiels Quantum + PI
   - Recommandation reset
   - Liste ce qui est conservé/perdu
   - Bouton confirmation

2. ✅ `lib/dialogs/reset_success_dialog.dart`
   - Animation post-reset
   - Affichage gains obtenus

**Éléments UI** :
- ✅ Icons : `Icons.blur_on` (Quantum), `Icons.lightbulb_outline` (PI)
- ✅ Couleurs : Purple (Quantum), Amber (PI)
- ✅ Recommandation dynamique selon niveau

---

### Navigation Main Screen

**Fichier** : `lib/screens/main_screen.dart`

**Architecture actuelle** :
- ❌ **PAS de PageView** avec swipe horizontal
- ❌ **PAS de 6 panneaux** intégrés
- ✅ Navigation classique par `BottomNavigationBar`
- ✅ 5 écrans séparés :
  1. ProductionScreen (index 0)
  2. MarketScreen (index 1)
  3. ResearchScreen (index 2)
  4. AgentsScreen (index 3)
  5. ProgressionScreen (index 4)

**Écart avec CHANTIER-06 Interface** :
- Doc prévoit : PageView + 6 panneaux (Dashboard, Production, Marché, Agents, Recherche, Stats)
- Implémenté : Navigation classique + 5 écrans
- **Décision requise** : Implémenter PageView OU documenter choix actuel

---

## 🧪 AGENTS - DÉTAILS TECHNIQUES

### Configuration Agents

**Fichier** : `lib/managers/agent_manager.dart`

**4 agents implémentés** :

1. **Production Optimizer**
   - ID : `production_optimizer`
   - Type : PRODUCTION
   - Coût activation : 5 Quantum
   - Intervalle : 0 min (passif continu)
   - Effet : +25% vitesse autoclippers pendant 1h

2. **Market Analyst**
   - ID : `market_analyst`
   - Type : MARKET
   - Coût activation : 5 Quantum
   - Intervalle : 5 min
   - Effet : Ajuste prix automatiquement selon demande

3. **Metal Buyer**
   - ID : `metal_buyer`
   - Type : RESOURCE
   - Coût activation : 5 Quantum
   - Intervalle : 10 min
   - Effet : Achète métal quand stock bas

4. **Innovation Researcher**
   - ID : `innovation_researcher`
   - Type : INNOVATION
   - Coût activation : 5 Quantum
   - Intervalle : 10 min
   - Effet : +1 PI toutes les 10 min

**Slots** :
- Base : 2 slots
- Extensible : 3 et 4 via recherches `agent_slot_3` et `agent_slot_4`

**Synchronisation** :
- ✅ Méthode `syncWithResearch()` implémentée
- ✅ Déblocage automatique quand recherche complétée
- ✅ Vérification slots selon recherches

---

## 🌳 ARBRE DE RECHERCHE - DÉTAILS

### Nœuds META Vérifiés

**Fichier** : `lib/managers/research_manager.dart`

**5 nœuds META implémentés** :

1. **quantum_amplifier**
   - Coût : 5 Quantum
   - Prérequis : root
   - Effet : +10% gains Quantum reset

2. **innovation_catalyst**
   - Coût : 5 PI
   - Prérequis : root
   - Effet : +10% gains PI reset

3. **meta_researcher**
   - Coût : 10 Quantum + 10 PI
   - Prérequis : quantum_amplifier + innovation_catalyst
   - Effet : Débloque agent Innovation Researcher

4. **quantum_efficiency**
   - Coût : 15 Quantum
   - Prérequis : quantum_amplifier
   - Effet : +15% gains Quantum reset

5. **innovation_mastery**
   - Coût : 15 PI
   - Prérequis : innovation_catalyst
   - Effet : +15% gains PI reset

**Vérification coût mixte** :
- ✅ `quantumCost` dans ResearchNode (ligne 53)
- ✅ Vérification dans `canResearch()` (ligne 674)
- ✅ Dépense dans `research()` (ligne 735-740)

**Conservation reset** :
- ✅ Méthode `resetForProgression()` (ligne 901)
- ✅ Filtre par catégorie META
- ✅ Recherches non-META réinitialisées

---

## 🔧 PROBLÈMES TECHNIQUES DÉTECTÉS

### 1. Architecture Hybride partieId/enterpriseId

**Fichiers critiques à nettoyer** :

**game_persistence_orchestrator.dart** (62 occurrences `partieId`) :
- Ligne 112 : Commentaire mentionne `enterpriseId`
- Ligne 125 : `_lastBackupAtByEnterprise` (bon)
- Ligne 171-177 : `deleteCloudById(enterpriseId:)` (bon)
- Ligne 391-392 : `final pid = state.enterpriseId;` (bon)
- Ligne 619-620 : Vérification `currentPid != next.slotId` (logique hybride)
- Ligne 652 : Log avec `partieId` (devrait être `enterpriseId`)

**Recommandation** :
- Remplacer tous les logs/commentaires `partieId` par `enterpriseId`
- Nettoyer variables `pid` en `eid` pour clarté
- Vérifier logique coalescing slots

---

### 2. GameMode - Clarification Requise

**Occurrences principales** :
- `lib/models/game_state.dart` : `GameMode _gameMode = GameMode.INFINITE;`
- `lib/services/save_system/local_save_game_manager.dart` : 33 occurrences
- `lib/models/save_game.dart` : 11 occurrences

**Questions** :
1. Mode compétitif toujours utilisé ?
2. Si oui : Documenter comment il s'intègre avec entreprise unique
3. Si non : Supprimer et simplifier

---

### 3. Tests Unitaires - État

**Fichiers tests trouvés** :
- `test/unit/research_meta_test.dart` (mentionné dans doc)
- Autres tests à localiser

**Actions requises** :
- [ ] Lister tous les fichiers de tests
- [ ] Exécuter suite complète
- [ ] Vérifier couverture (objectif 80%)
- [ ] Ajouter tests manquants

---

## 📊 MÉTRIQUES CODE

### Taille Managers (lignes)

| Manager | Lignes | Complexité |
|---------|--------|------------|
| RareResourcesManager | 319 | Faible |
| ResearchManager | 960 | Élevée |
| AgentManager | 409 | Moyenne |
| ResetManager | 101 | Faible |
| ResetRewardsCalculator | 162 | Moyenne |

### Modèles (lignes)

| Modèle | Lignes | Sérialisation |
|--------|--------|---------------|
| ResearchNode | 120 | ✅ JSON |
| Agent | 119 | ✅ JSON |
| ResearchEffect | ~44 | ✅ JSON |
| ResetRewards | ~12 | ❌ (simple data class) |

---

## ✅ CHECKLIST VALIDATION FINALE

### CHANTIER-02 : Ressources Rares
- [x] RareResourcesManager créé
- [x] Quantum + PI (type int)
- [x] Méthodes add/spend/canSpend
- [x] Statistiques lifetime
- [x] Sérialisation JSON
- [x] Intégré GameState
- [ ] Tests unitaires passent
- [ ] Formules correspondent doc exactement
- [ ] UI header ressources rares

### CHANTIER-03 : Arbre de Recherche
- [x] ResearchManager créé
- [x] ResearchNode modèle
- [x] Catégories + Types effets
- [x] Prérequis + Exclusivités
- [x] Méthodes canResearch/research
- [x] Intégré GameState
- [x] UI ResearchScreen
- [ ] Compter nœuds total (objectif 15-20+)
- [ ] Vérifier coûts PI vs doc
- [ ] Tests choix exclusifs

### CHANTIER-04 : Agents
- [x] AgentManager créé
- [x] Agent modèle
- [x] 4 agents implémentés
- [x] BaseAgentExecutor
- [x] Système slots (2→4)
- [x] Méthodes activate/deactivate
- [x] SyncWithResearch
- [x] Intégré GameState
- [x] UI AgentsScreen
- [ ] Vérifier durée 1h implémentée
- [ ] Vérifier offline-compatible
- [ ] Tests agents actifs/inactifs

### CHANTIER-05 : Reset
- [x] ResetManager créé
- [x] ResetRewardsCalculator créé
- [x] Constantes MIN_LEVEL/MIN_PAPERCLIPS
- [x] Méthodes canReset/calculateRewards/performReset
- [x] Callbacks vers GameState
- [x] Intégré GameState
- [x] resetForProgression() dans tous managers
- [x] UI ResetProgressionDialog
- [x] UI ResetSuccessDialog
- [ ] Animation post-reset vérifiée
- [ ] Tutorial premier reset
- [ ] Tests reset complet

### CHANTIER-06 : META + Interface
- [x] 5 nœuds META implémentés
- [x] Coût mixte Quantum+PI
- [x] Conservation reset
- [x] resetForProgression() ResearchManager
- [x] Tests unitaires créés
- [ ] Interface PageView 6 panneaux (NON FAIT)
- [ ] Navigation swipe (NON FAIT)
- [ ] Décision : Implémenter OU documenter choix actuel

---

## 🎯 ACTIONS PRIORITAIRES TECHNIQUES

### Critique (Bloquer release)
1. **Décider CHANTIER-01** : Finir migration OU documenter hybride
2. **Clarifier GameMode** : Conserver OU supprimer
3. **Tests unitaires** : Exécuter et valider tous passent

### Important (Avant release)
4. **Vérifier formules** : Quantum/PI vs doc ligne par ligne
5. **CHANTIER-06 Interface** : Implémenter OU documenter
6. **Tests intégration** : Cycle complet reset

### Qualité (Post-release)
7. **Nettoyage code** : Supprimer `partieId` legacy
8. **Documentation** : Mettre à jour statuts chantiers
9. **Couverture tests** : Atteindre 80%

---

**Rapport technique généré le** : 30 mars 2026  
**Complément au rapport principal de vérification**
