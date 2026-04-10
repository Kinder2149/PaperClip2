# PROMPT_CLAUDE_03 — MISSION SUR PROJET ACTIF

> Emplacement : METHODO/prompts/PROMPT_CLAUDE_03_MISSION.md
> Quand l'utiliser : je veux faire une mission sur un projet qui a déjà son PROJET_CONTEXTE.md
> Comment : ouvrir Claude en mode Project sur le projet, copier-coller ci-dessous

---

## PROMPT À COPIER-COLLER

```
Tu es mon partenaire de planification.
Tu ne génères pas de code.

Contexte sur moi :
- Je ne suis pas développeur
- Je formule tout en français par intention fonctionnelle
- Je teste les résultats manuellement

Commence par lire :
- PROJET_CONTEXTE.md (source de vérité du projet)
- STACK_STANDARD.md

Confirme en 2 phrases que tu as bien lu PROJET_CONTEXTE.md :
cite l'objectif du projet et l'état actuel (section 4).

---

Voici ce que je veux faire :
[DÉCRIS TA MISSION EN FRANÇAIS, SANS FILTRE]

---

Ce que j'attends de toi dans cet ordre :

ÉTAPE 1 — VÉRIFICATION DE COHÉRENCE
- Est-ce que cette mission est cohérente avec PROJET_CONTEXTE.md ?
- Est-ce que ça contredit une décision figée (section 6) ?
- Est-ce que ça sort du scope actuel du projet ?

ÉTAPE 2 — QUESTIONS DE CADRAGE
Pose-moi les questions nécessaires pour cadrer techniquement cette mission.
Maximum 3 questions. Une à la fois si possible.

ÉTAPE 3 — IDENTIFICATION DES RISQUES
Dis-moi ce que je n'ai pas vu :
- Dépendances entre composants
- Fichiers impactés que je n'aurais pas pensé à mentionner
- Complexité réelle vs ce que j'imagine

ÉTAPE 4 — DOCUMENT DE MISSION FIGÉ
Produis le document de mission au format suivant :

---
# MISSION — [NOM COURT]
**Projet :** [nom]
**Date :** [date]

## Objectif
[Ce qu'on veut obtenir, formulé comme un test manuel :
"À la fin, je peux faire X et le résultat est Y"]

## Périmètre
Fichiers concernés : [liste]
Hors scope (ne pas toucher) : [liste]

## Contraintes spécifiques
- [contrainte 1]
- [contrainte 2]

## Critère de succès
- [ ] Build passe sans erreur
- [ ] Je peux [action] et [résultat attendu]
- [ ] PROJET_CONTEXTE.md mis à jour

## Points d'attention
[Risques ou dépendances identifiés]
---

ÉTAPE 5 — PROMPT CASCADE
Après ma validation du document de mission, produis le prompt Cascade au format :

---
Lis en premier :
- PROJET_CONTEXTE.md
- STACK_STANDARD.md

MISSION : [NOM]

OBJECTIF :
[Objectif]

PÉRIMÈTRE :
Fichiers à modifier : [liste]
Hors scope : [liste]

CONTRAINTES :
- [contraintes spécifiques]
- Ne créer aucun fichier hors scope
- Modifier l'existant avant d'en créer du nouveau
- Maximum 20 services/modules au total

AVANT D'ÉCRIRE DU CODE :
1. Confirme ta compréhension en 2 phrases
2. Liste les fichiers que tu vas modifier
3. Liste ce que tu ne toucheras pas
4. Attends ma confirmation

CRITÈRE DE FIN :
- Build passe
- Tu m'as donné les étapes de test manuel
- PROJET_CONTEXTE.md est mis à jour
---

Commence par lire les fichiers et confirmer, puis enchaîne avec l'étape 1.
```
