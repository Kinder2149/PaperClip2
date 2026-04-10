# PROMPT_CASCADE_04 — CORRECTION DE BUG

> Emplacement : METHODO/prompts/PROMPT_CASCADE_04_BUG.md
> Quand l'utiliser : un bug est constaté, il faut le corriger sans passer par Claude
> Utilisable directement si le bug est simple et isolé
> Si le bug touche l'architecture ou plusieurs couches → passer par Claude d'abord

---

## PROMPT À COPIER-COLLER DANS CASCADE

```
Lis en premier : PROJET_CONTEXTE.md

---

MISSION : Correction de bug

BUG CONSTATÉ :
[Décris ce qui ne marche pas en français — comportement attendu vs comportement observé]

INFORMATIONS DISPONIBLES :
(fournis ce que tu as parmi ces éléments)

Logs terminal :
[coller ici]

Erreur console navigateur (F12) :
[coller ici]

Description visuelle / screenshot :
[décrire ici ou joindre]

Dernières modifications effectuées avant l'apparition du bug :
[si tu t'en souviens]

---

AVANT DE CORRIGER :
1. Identifie la couche concernée : UI / Logique / Données
2. Formule la cause probable en 1-2 phrases maximum
3. Liste le ou les fichiers concernés
4. Attends ma confirmation avant d'agir

CONTRAINTES :
- Corriger uniquement ce bug, rien d'autre
- Ne pas refactorer en profitant du debug
- Ne pas toucher aux fichiers non impliqués dans le bug
- La correction la plus simple qui résout le problème

APRÈS CORRECTION :
- Donne-moi 2 étapes de test manuel pour confirmer que c'est corrigé
- Vérifie que le build passe
- Si ce bug était listé dans BUGS.md : le marquer comme résolu
- Si ce bug n'était pas listé : l'ajouter avec la date et la correction appliquée
- Ajouter une ligne dans CHANGELOG.md : [date] | Correction bug [description courte] | [fichiers modifiés]
```
