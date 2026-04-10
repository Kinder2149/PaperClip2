# README — MA MÉTHODE DE TRAVAIL IA

> Point d'entrée unique. Lis ce fichier en premier dans toute nouvelle situation.

---

## EMPLACEMENT DE LA MÉTHODE

```
METHODO/                          ← dossier à la racine de tous mes projets
  README_METHODE.md               ← ce fichier
  STACK_STANDARD.md               ← mes choix technologiques fixes
  CASCADE_GLOBAL_RULES.md         ← règles permanentes à coller dans Cascade
  PROJET_CONTEXTE_TEMPLATE.md     ← template vide à copier par projet
  prompts/                        ← un fichier par scénario, prêt à l'emploi
    PROMPT_CLAUDE_01_NOUVEAU_PROJET.md
    PROMPT_CLAUDE_02_REPRISE_PROJET.md
    PROMPT_CLAUDE_03_MISSION.md
    PROMPT_CASCADE_01_INIT_NOUVEAU_PROJET.md
    PROMPT_CASCADE_02_REPRISE_PROJET.md
    PROMPT_CASCADE_03_MISSION.md
    PROMPT_CASCADE_04_BUG.md
    PROMPT_CASCADE_05_CLOTURE.md
    PROMPT_CASCADE_06_SESSION_INTERROMPUE.md
```

**À la racine de chaque projet :**
```
MON_PROJET/
  PROJET_CONTEXTE.md    ← copié depuis METHODO/PROJET_CONTEXTE_TEMPLATE.md
  STACK_STANDARD.md     ← copié depuis METHODO/
  CHANGELOG.md          ← créé vide au démarrage
  BUGS.md               ← créé vide au démarrage
  [code du projet...]
```

---

## MON SYSTÈME EN DEUX TEMPS

```
TEMPS 1 — CLAUDE  (planification)
  Mode Project avec accès aux fichiers du projet
  Je réfléchis en français, on cadre, on fige
  Output : document de mission + prompt Cascade prêt

TEMPS 2 — CASCADE  (exécution dans Windsurf)
  Je colle le prompt produit par Claude
  Cascade lit PROJET_CONTEXTE.md en premier
  Elle exécute uniquement dans le périmètre défini
```

Ces deux temps ne se mélangent jamais.
Claude ne génère pas de code. Cascade ne réfléchit pas à ma place.

---

## QUEL PROMPT UTILISER SELON LA SITUATION

| Situation | Fichier à utiliser |
|---|---|
| Je crée un nouveau projet | `prompts/PROMPT_CLAUDE_01_NOUVEAU_PROJET.md` |
| Je reprends un projet existant (1ère fois) | `prompts/PROMPT_CLAUDE_02_REPRISE_PROJET.md` |
| Je veux faire une mission sur un projet actif | `prompts/PROMPT_CLAUDE_03_MISSION.md` |
| Cascade initialise un nouveau projet | `prompts/PROMPT_CASCADE_01_INIT_NOUVEAU_PROJET.md` |
| Cascade nettoie un projet existant | `prompts/PROMPT_CASCADE_02_REPRISE_PROJET.md` |
| Cascade exécute une mission | `prompts/PROMPT_CASCADE_03_MISSION.md` (produit par Claude) |
| Il y a un bug à corriger | `prompts/PROMPT_CASCADE_04_BUG.md` |
| Je ferme une session | `prompts/PROMPT_CASCADE_05_CLOTURE.md` |
| Session interrompue brutalement | `prompts/PROMPT_CASCADE_06_SESSION_INTERROMPUE.md` |

---

## SCÉNARIO 1 — NOUVEAU PROJET (étapes complètes)

```
1. Copier à la racine du nouveau projet :
   ✅ METHODO/PROJET_CONTEXTE_TEMPLATE.md → renommer en PROJET_CONTEXTE.md
   ✅ METHODO/STACK_STANDARD.md
   ✅ Créer CHANGELOG.md (vide)
   ✅ Créer BUGS.md (vide)

2. Ouvrir Claude en mode Project (accès aux fichiers)
   → Copier-coller : METHODO/prompts/PROMPT_CLAUDE_01_NOUVEAU_PROJET.md

3. Cadrage avec Claude → il produit PROJET_CONTEXTE.md rempli + prompt Cascade

4. Ouvrir Windsurf sur le projet
   → Copier-coller le prompt produit par Claude
   (basé sur METHODO/prompts/PROMPT_CASCADE_01_INIT_NOUVEAU_PROJET.md)

5. Fin de session :
   → Copier-coller : METHODO/prompts/PROMPT_CASCADE_05_CLOTURE.md
```

---

## SCÉNARIO 2 — REPRENDRE UN PROJET EXISTANT (1 seule fois par projet)

```
1. Copier à la racine du projet existant :
   ✅ METHODO/STACK_STANDARD.md
   ✅ METHODO/PROJET_CONTEXTE_TEMPLATE.md (garder ce nom)
   ✅ Créer CHANGELOG.md si absent (vide)
   ✅ Créer BUGS.md si absent (vide)
   ⚠️ Ne pas encore créer PROJET_CONTEXTE.md — Claude et Cascade le feront

2. Ouvrir Claude en mode Project (accès aux fichiers)
   → Copier-coller : METHODO/prompts/PROMPT_CLAUDE_02_REPRISE_PROJET.md

3. Claude analyse, pose questions, produit PROJET_CONTEXTE.md + prompt Cascade

4. Ouvrir Windsurf sur le projet
   → Copier-coller le prompt produit par Claude
   (basé sur METHODO/prompts/PROMPT_CASCADE_02_REPRISE_PROJET.md)

5. Valider PROJET_CONTEXTE.md produit avec Claude avant toute mission
```

---

## SCÉNARIO 3 — MISSION SUR PROJET ACTIF

```
1. Ouvrir Claude en mode Project (accès aux fichiers)
   → Copier-coller : METHODO/prompts/PROMPT_CLAUDE_03_MISSION.md
   → Décrire ma mission en français

2. Claude produit : document de mission figé + prompt Cascade

3. Ouvrir Windsurf
   → Copier-coller le prompt produit par Claude

4. Cascade confirme compréhension → je valide → elle exécute

5. Je teste manuellement selon les étapes données par Cascade

6. Fermeture :
   → Copier-coller : METHODO/prompts/PROMPT_CASCADE_05_CLOTURE.md
```

---

## RÈGLES PERSONNELLES (non négociables)

- Une seule mission à la fois
- Je ne passe pas à la suivante sans avoir testé la précédente ✅
- Je ne lance jamais Cascade sans avoir cadré avec Claude sur une mission complexe
- Je ne termine jamais une session sur "ça a l'air de marcher"
- Si les tokens s'épuisent → `PROMPT_CASCADE_06_SESSION_INTERROMPUE.md`

---

*Méthode établie avec Claude — à faire évoluer uniquement après discussion*
