# 🤖 JARVIS — Analyse et Définition des Agents Spécialisés

**Date** : 10 février 2026  
**Contexte** : Définition de l'architecture multi-agents pour assistant IA personnel  
**Utilisateur unique** : Développeur Flutter/Backend avec projets structurés

---

## 📊 ÉTAPE 1 — SYNTHÈSE DE L'ANALYSE

### Patterns Observés dans l'Historique

#### 1. **Architecture et Décisions Techniques (Très Fréquent)**
- Définition de stratégies d'authentification (Firebase vs GPG)
- Décisions de persistance (cloud-first, ID-first, snapshot-first)
- Harmonisation de systèmes parallèles (double auth, double source de vérité)
- Documentation d'invariants système
- Audits d'architecture complets

**Exemples concrets** :
- `AUTH_STRATEGY.md` : Décision Firebase comme source unique
- `DECISIONS_PERSISTANCE.md` : Règles cloud-first verrouillées
- `AUDIT_HARMONISATION_COMPLETE.md` : Analyse de dualité auth

#### 2. **Debugging et Correction de Bugs (Fréquent)**
- Analyse de bugs complexes avec traçabilité complète
- Identification de causes racines multiples
- Plans de correction séquentiels et priorisés
- Vérifications d'intégrité post-correction

**Exemples concrets** :
- `ANALYSE_BUG_CONFUSION_MONDES.md` : Bug de confusion d'identité
- `PLAN_CORRECTION_COMPLET.md` : Plan en 4 phases avec checklist
- Corrections avec logs de traçabilité

#### 3. **Documentation Structurée (Très Fréquent)**
- Documentation technique multi-niveaux (débutant → avancé)
- Index thématiques et par objectif
- Guides utilisateur et développeur
- Rapports de mission avec synthèses exécutives

**Exemples concrets** :
- `documentation/INDEX.md` : Index complet par thème/niveau/objectif
- Structure `01-architecture/`, `02-guides-developpeur/`, etc.
- Documentation produit (PHASE5)

#### 4. **Migration et Refactoring (Récurrent)**
- Migration Firebase → FastAPI (puis retour Firebase Functions)
- Remplacement de services (Auth, Storage, Analytics)
- Nettoyage de code legacy
- Harmonisation de nomenclature

**Exemples concrets** :
- Migration complète de Firebase vers backend personnalisé
- Suppression de références obsolètes
- Unification de terminologie (Monde/Partie/SaveGame)

#### 5. **Planification et Gating (Systématique)**
- Plans séquentiels avec gates de validation
- Priorisation P0/P1/P2
- Checklists de validation finale
- Aucune exécution sans plan validé

**Exemples concrets** :
- "Mission Cloud Save minimal : étapes séquentielles avec gate de validation"
- "Audit avant tout code"
- "Zéro dette technique"

#### 6. **Respect des Contraintes Strictes (Constant)**
- ID-first, snapshot-first, cloud-first
- Aucune logique implicite
- Vérification systématique
- Documentation contractuelle

**Exemples concrets** :
- UUID v4 obligatoire pour partieId
- Cloud = source unique de vérité
- Aucune fusion/arbitrage local-cloud

### Domaines d'Expertise Identifiés

1. **Backend/API** : FastAPI, Firebase Functions, Express, REST
2. **Mobile** : Flutter, Dart, Provider, SharedPreferences
3. **Architecture** : Cloud-first, Microservices, Port/Adapter
4. **Persistance** : Firestore, SQL, SharedPreferences, Snapshots
5. **Auth** : Firebase Auth, OAuth, JWT, Google Play Games
6. **DevOps** : Déploiement Render/Fly.io, Firebase Functions
7. **Testing** : Tests unitaires, E2E, intégration

### Frustrations et Limitations Observées

1. **Dualité de systèmes** : Deux sources de vérité créant confusion
2. **Dette technique silencieuse** : Code mort, doublons non documentés
3. **Manque de traçabilité** : Logs insuffisants pour debugging
4. **Validation insuffisante** : Échecs silencieux sans exceptions
5. **Documentation obsolète** : Références à systèmes abandonnés

### Types de Raisonnement Utilisés

- **Analytique** : Audit complet, identification causes racines
- **Technique** : Corrections code, architecture, patterns
- **Organisationnel** : Plans séquentiels, priorisation, checklists
- **Documentaire** : Structuration, indexation, guides multi-niveaux
- **Préventif** : Invariants, validation, tests de non-régression

---

## 🎯 ÉTAPE 2 — AGENTS CANDIDATS PROPOSÉS

### Agent 1 : **Architecte** 🏗️

**Rôle** : Définir, auditer et harmoniser l'architecture technique des projets

**Déclenché quand** :
- "Analyse l'architecture de X"
- "Identifie les incohérences dans le système"
- "Propose une stratégie pour Y"
- "Audit complet de Z"
- Détection de dualité de systèmes ou sources de vérité multiples

**Exemples réels** :
- Audit dualité Firebase/GPG → Décision Firebase comme source unique
- Analyse architecture persistance → Définition cloud-first strict
- Harmonisation nomenclature (Monde/Partie/SaveGame)

**Ce qu'il ne fait pas** :
- N'écrit pas de code (délègue à Codeur)
- Ne corrige pas de bugs (délègue à Debugger)
- Ne rédige pas la documentation finale (délègue à Documentaliste)

**Fréquence** : Hebdomadaire / Début de projet / Avant refactoring majeur

**Priorité** : **ESSENTIEL** (fondation de tous les autres travaux)

---

### Agent 2 : **Debugger** 🔍

**Rôle** : Analyser les bugs, identifier les causes racines, proposer corrections priorisées

**Déclenché quand** :
- "J'ai un bug où X fait Y au lieu de Z"
- "Analyse pourquoi cette fonctionnalité ne marche pas"
- "Identifie la cause de ce comportement inattendu"
- Comportement incohérent ou perte de données

**Exemples réels** :
- Bug confusion des mondes → Analyse complète avec 3 causes racines
- Identification contournement validation UUID dans `applySnapshot()`
- Reconstruction du scénario de bug en 5 étapes

**Ce qu'il ne fait pas** :
- N'applique pas les corrections (délègue à Codeur)
- Ne définit pas l'architecture (délègue à Architecte)
- Ne rédige pas les tests (délègue à Testeur)

**Fréquence** : Quotidien / À la demande

**Priorité** : **ESSENTIEL** (bugs bloquants fréquents)

---

### Agent 3 : **Planificateur** 📋

**Rôle** : Créer des plans d'action séquentiels, priorisés, avec gates de validation

**Déclenché quand** :
- "Crée un plan pour implémenter X"
- "Comment aborder cette migration ?"
- "Définis les étapes pour Y"
- Début de toute tâche complexe (règle utilisateur)

**Exemples réels** :
- `PLAN_CORRECTION_COMPLET.md` : 4 phases (P0/P1/P2) avec checklist
- Plans séquentiels avec gates de validation
- "Audit avant tout code, zéro dette technique"

**Ce qu'il ne fait pas** :
- N'exécute pas le plan (orchestre mais ne code pas)
- N'analyse pas l'architecture (délègue à Architecte)
- Ne documente pas (délègue à Documentaliste)

**Fréquence** : Quotidien / Début de chaque tâche non triviale

**Priorité** : **ESSENTIEL** (requis par règles utilisateur)

---

### Agent 4 : **Codeur** 💻

**Rôle** : Implémenter les modifications code selon spécifications précises

**Déclenché quand** :
- Plan validé nécessitant modifications code
- Corrections de bugs identifiées par Debugger
- Implémentation d'architecture définie par Architecte
- "Applique les corrections de la Phase 1"

**Exemples réels** :
- Correction `setPartieId()` avec logs et validation
- Correction `applySnapshot()` pour utiliser validation
- Ajout vérification intégrité dans `loadGameById()`

**Ce qu'il ne fait pas** :
- Ne décide pas de l'architecture (suit Architecte)
- N'analyse pas les bugs (suit Debugger)
- Ne crée pas de plans (suit Planificateur)

**Fréquence** : Quotidien

**Priorité** : **ESSENTIEL** (exécution concrète)

---

### Agent 5 : **Documentaliste** 📚

**Rôle** : Créer et maintenir documentation structurée multi-niveaux

**Déclenché quand** :
- "Documente cette décision"
- "Crée un guide pour X"
- "Mets à jour la documentation"
- Après validation d'architecture ou correction majeure

**Exemples réels** :
- `documentation/INDEX.md` : Index par thème/niveau/objectif
- `AUTH_STRATEGY.md` : Stratégie complète avec règles et anti-patterns
- `DECISIONS_PERSISTANCE.md` : Document verrouillé contractuel

**Ce qu'il ne fait pas** :
- Ne définit pas l'architecture (documente décisions d'Architecte)
- N'analyse pas les bugs (documente corrections de Debugger)
- Ne code pas (documente implémentations de Codeur)

**Fréquence** : Hebdomadaire / Après chaque décision majeure

**Priorité** : **ESSENTIEL** (traçabilité et maintenabilité)

---

### Agent 6 : **Testeur** 🧪

**Rôle** : Définir stratégies de test, créer tests unitaires/intégration/E2E

**Déclenché quand** :
- "Crée des tests pour valider X"
- "Définis une stratégie de test pour Y"
- Après corrections de bugs (tests de non-régression)
- Avant déploiement (validation complète)

**Exemples réels** :
- Tests unitaires `game_state_identity_test.dart`
- Tests d'intégration multi-mondes
- Scénarios de validation utilisateur complets

**Ce qu'il ne fait pas** :
- N'implémente pas les fonctionnalités (teste ce que Codeur crée)
- Ne corrige pas les bugs (identifie, délègue à Debugger)
- Ne définit pas l'architecture (teste ce qu'Architecte définit)

**Fréquence** : Hebdomadaire / Après chaque correction majeure

**Priorité** : **UTILE** (qualité et non-régression)

---

### Agent 7 : **Auditeur** 🔎

**Rôle** : Auditer le code existant, identifier dette technique, doublons, incohérences

**Déclenché quand** :
- "Audit le système X"
- "Identifie la dette technique dans Y"
- "Trouve les doublons et code mort"
- Avant refactoring ou migration majeure

**Exemples réels** :
- `AUDIT_HARMONISATION_COMPLETE.md` : Inventaire complet des composants
- Identification widgets obsolètes/redondants
- Détection double système auth (Firebase + GPG)

**Ce qu'il ne fait pas** :
- Ne corrige pas (identifie, délègue à Codeur)
- Ne définit pas la nouvelle architecture (délègue à Architecte)
- Ne documente pas les résultats (délègue à Documentaliste)

**Fréquence** : Mensuel / Avant refactoring majeur

**Priorité** : **UTILE** (prévention dette technique)

---

### Agent 8 : **Chercheur** 🌐

**Rôle** : Rechercher informations externes, APIs, best practices, solutions techniques

**Déclenché quand** :
- "Quelle est la meilleure approche pour X ?"
- "Recherche comment implémenter Y avec Z"
- "Trouve des exemples de A"
- Besoin de références externes ou documentation API

**Exemples réels** :
- Recherche patterns Port/Adapter
- Documentation Firebase Functions v2
- Best practices JWT refresh token
- Comparaison solutions cloud (Render, Fly.io, Firebase)

**Ce qu'il ne fait pas** :
- Ne décide pas de l'architecture (informe Architecte)
- N'implémente pas (fournit références à Codeur)
- Ne crée pas de plans (fournit contexte à Planificateur)

**Fréquence** : Hebdomadaire / Début de nouvelle fonctionnalité

**Priorité** : **UTILE** (contexte et références)

---

## 🔄 ÉTAPE 3 — ARCHITECTURE DE COORDINATION

### Rôle de Jarvis Maître 🎯

**Jarvis Maître** est l'**orchestrateur** qui :
1. Reçoit la requête utilisateur
2. Identifie le(s) agent(s) approprié(s)
3. Délègue avec contexte précis
4. Agrège les résultats
5. Coordonne les dépendances entre agents
6. Présente la synthèse à l'utilisateur

**Jarvis Maître ne fait PAS** :
- D'analyse technique approfondie (délègue)
- De codage (délègue)
- De documentation détaillée (délègue)
- De debugging (délègue)

### Flux de Délégation

#### Cas 1 : Requête Simple (1 agent)
```
Utilisateur : "Documente cette décision d'architecture"
  ↓
Jarvis Maître : Identifie → Documentaliste
  ↓
Documentaliste : Crée documentation structurée
  ↓
Jarvis Maître : Présente résultat
```

#### Cas 2 : Requête Complexe (agents séquentiels)
```
Utilisateur : "J'ai un bug de confusion des mondes"
  ↓
Jarvis Maître : Identifie → Debugger → Planificateur → Codeur → Testeur
  ↓
Debugger : Analyse causes racines (3 causes identifiées)
  ↓
Planificateur : Crée plan correction 4 phases P0/P1/P2
  ↓
Jarvis Maître : Présente analyse + plan, demande validation
  ↓
Utilisateur : "OK, applique Phase 1"
  ↓
Codeur : Implémente corrections Phase 1
  ↓
Testeur : Crée tests de non-régression
  ↓
Jarvis Maître : Présente résultat + checklist validation
```

#### Cas 3 : Requête avec Agents Parallèles
```
Utilisateur : "Prépare la migration vers FastAPI"
  ↓
Jarvis Maître : Identifie → Auditeur + Chercheur (parallèle) → Architecte → Planificateur
  ↓
Auditeur : Audit système actuel (Firebase)
Chercheur : Best practices FastAPI + exemples
  ↓
Architecte : Définit architecture cible avec résultats Auditeur + Chercheur
  ↓
Planificateur : Crée plan migration séquentiel
  ↓
Jarvis Maître : Présente audit + architecture + plan
```

### Règles de Coordination

1. **Planificateur TOUJOURS en premier** pour tâches complexes (règle utilisateur)
2. **Architecte avant Codeur** pour décisions structurelles
3. **Debugger avant Codeur** pour corrections de bugs
4. **Auditeur avant Architecte** pour refactoring
5. **Testeur après Codeur** pour validation
6. **Documentaliste en dernier** pour traçabilité

### Matrice de Collaboration

| Agent | Collabore avec | Pour |
|-------|----------------|------|
| **Architecte** | Auditeur, Chercheur | Contexte et références |
| **Debugger** | Auditeur | Identifier patterns de bugs |
| **Planificateur** | Tous | Orchestrer séquences |
| **Codeur** | Architecte, Debugger | Spécifications précises |
| **Documentaliste** | Tous | Documenter décisions/résultats |
| **Testeur** | Codeur, Debugger | Validation et non-régression |
| **Auditeur** | Architecte | État des lieux avant décisions |
| **Chercheur** | Architecte, Codeur | Références et best practices |

---

## ❓ ÉTAPE 4 — QUESTIONS DE VALIDATION

### Questions Architecturales

1. **Nombre d'agents** : 8 agents te semble-t-il approprié ou préfères-tu consolider certains rôles ?
   - Option A : Garder 8 agents spécialisés
   - Option B : Fusionner Auditeur + Debugger (analyse)
   - Option C : Fusionner Chercheur dans Jarvis Maître

2. **Périmètre Architecte** : Doit-il aussi gérer les décisions de stack technique ou uniquement l'architecture logicielle ?

3. **Périmètre Planificateur** : Doit-il aussi gérer la priorisation (P0/P1/P2) ou est-ce le rôle de Jarvis Maître ?

### Questions Opérationnelles

4. **Déclenchement automatique** : Jarvis Maître doit-il automatiquement appeler Planificateur pour toute tâche complexe ou demander confirmation ?

5. **Validation gates** : Jarvis Maître doit-il systématiquement demander validation entre chaque phase ou enchaîner si le plan est validé ?

6. **Gestion erreurs** : Si un agent échoue (ex: Codeur ne peut pas implémenter), Jarvis Maître doit-il :
   - Remonter immédiatement à l'utilisateur
   - Tenter une approche alternative (via Architecte)
   - Demander à Chercheur des références supplémentaires

### Questions de Priorité

7. **Agents essentiels** : Es-tu d'accord que Architecte, Debugger, Planificateur, Codeur, Documentaliste sont ESSENTIELS ?

8. **Agents optionnels** : Testeur, Auditeur, Chercheur sont-ils vraiment nécessaires ou peuvent-ils être intégrés dans les agents essentiels ?

### Questions de Contexte

9. **Projets multiples** : Jarvis doit-il gérer plusieurs projets simultanément ou un seul à la fois (actuellement PaperClip2) ?

10. **Historique** : Les agents doivent-ils avoir accès à l'historique complet des conversations ou uniquement au contexte de la tâche en cours ?

---

## 🚀 ÉTAPE 5 — PROCHAINES ÉTAPES SUGGÉRÉES

### Phase 1 : Validation Architecture (Maintenant)
1. Répondre aux questions de validation
2. Ajuster liste des agents si nécessaire
3. Valider les règles de coordination

### Phase 2 : Spécification Détaillée (Après validation)
1. Définir les prompts système de chaque agent
2. Spécifier les formats d'entrée/sortie
3. Définir les contextes minimaux requis
4. Créer les règles de handoff entre agents

### Phase 3 : Implémentation Jarvis Maître (Semaine 1)
1. Logique de routage des requêtes
2. Identification automatique des agents
3. Gestion des dépendances séquentielles
4. Agrégation des résultats

### Phase 4 : Implémentation Agents Essentiels (Semaine 2-3)
1. Architecte
2. Debugger
3. Planificateur
4. Codeur
5. Documentaliste

### Phase 5 : Implémentation Agents Optionnels (Semaine 4)
1. Testeur
2. Auditeur
3. Chercheur

### Phase 6 : Tests et Ajustements (Semaine 5)
1. Tests avec scénarios réels (historique)
2. Ajustements des prompts
3. Optimisation des handoffs
4. Documentation finale

---

## 📝 NOTES TECHNIQUES

### Contraintes Respectées

✅ **Périmètres clairs et non redondants** : Chaque agent a un rôle unique  
✅ **Maximum 8 agents** : Respecté  
✅ **Jarvis Maître = orchestrateur** : Ne fait pas de travail spécialisé  
✅ **Justification par besoins réels** : Tous les agents basés sur patterns observés  
✅ **Agents larges bien définis** : Pas de micro-spécialisation

### Patterns d'Utilisation Anticipés

**Quotidien** :
- Debugger (bugs fréquents)
- Codeur (implémentations)
- Planificateur (tâches complexes)

**Hebdomadaire** :
- Architecte (décisions structurelles)
- Documentaliste (traçabilité)
- Testeur (validation)
- Chercheur (références)

**Mensuel** :
- Auditeur (dette technique)

---

## 🎯 DÉCISION ATTENDUE

Valide ou ajuste cette proposition pour passer à la spécification détaillée des agents.

**Questions prioritaires à trancher** :
1. Nombre d'agents (8 ou consolidation ?)
2. Agents essentiels vs optionnels
3. Déclenchement automatique ou avec confirmation
4. Gestion multi-projets ou projet unique

---

**Fin de l'Analyse — En attente de validation**
