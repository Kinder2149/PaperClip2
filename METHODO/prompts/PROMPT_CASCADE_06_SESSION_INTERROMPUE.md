# PROMPT_CASCADE_06 — SESSION INTERROMPUE

> Emplacement : METHODO/prompts/PROMPT_CASCADE_06_SESSION_INTERROMPUE.md
> Quand l'utiliser : une session s'est terminée sans clôture propre
> (tokens épuisés, fermeture par fatigue, crash, interruption)

---

## PROMPT À COPIER-COLLER DANS CASCADE

```
Lis en premier : PROJET_CONTEXTE.md

La session précédente s'est terminée sans clôture propre.
Avant toute action, je veux connaître l'état réel du projet.

---

DIAGNOSTIC — fais ceci sans me demander :

1. Lis PROJET_CONTEXTE.md section 8 (session en cours)
   → Quel était l'objectif de la session interrompue ?

2. Liste les fichiers modifiés récemment
   → Lance : git status (ou équivalent selon la stack)
   → Si pas de git : liste les fichiers avec une date de modification récente

3. Vérifie si le build passe actuellement
   → Lance le build/compilation
   → Note s'il y a des erreurs

4. Compare l'objectif prévu (section 8) avec ce qui a été modifié
   → Qu'est-ce qui a été fait ?
   → Qu'est-ce qui n'a pas été fait ?
   → Y a-t-il des fichiers modifiés à moitié (code incomplet) ?

---

RAPPORT :
Présente-moi :

1. ÉTAT DU BUILD
   ✅ Passe / ❌ Cassé — avec les erreurs si cassé

2. CE QUI A ÉTÉ FAIT
   [fichiers modifiés et ce qui a changé]

3. CE QUI EST INCOMPLET
   [fichiers à moitié modifiés ou fonctionnalités à moitié implémentées]

4. RECOMMANDATION
   Option A : finir la mission interrompue
   Option B : revenir à un état stable (et comment)
   Option C : la mission est en réalité terminée

---

⚠️ N'agis pas avant que j'aie lu ton rapport et donné une instruction claire.
Attends ma décision.
```
