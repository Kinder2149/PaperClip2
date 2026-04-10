# PROMPT_CASCADE_03 — MISSION STANDARD

> Emplacement : METHODO/prompts/PROMPT_CASCADE_03_MISSION.md
> Quand l'utiliser : pour toute mission fonctionnelle sur un projet actif
> ⚠️ Ce prompt est un template. Il est produit et rempli par Claude (PROMPT_CLAUDE_03).
> Claude remplace les [CHAMPS] avant de te le donner.

---

## PROMPT À COPIER-COLLER DANS CASCADE
## (produit par Claude — copier tel quel sans modifier)

```
Lis en premier, dans cet ordre :
1. PROJET_CONTEXTE.md (source de vérité absolue)
2. STACK_STANDARD.md (technologies autorisées)

Confirme en 1 phrase que tu as bien lu PROJET_CONTEXTE.md
en citant l'objectif du projet.

---

MISSION : [NOM DE LA MISSION]

OBJECTIF :
[Description de ce qu'on veut obtenir.
Formulé comme un test manuel : "À la fin, je peux faire X et le résultat est Y"]

PÉRIMÈTRE :
Fichiers à modifier :
- [fichier 1]
- [fichier 2]

Hors scope — ne pas toucher :
- [fichier/fonctionnalité 1]
- [fichier/fonctionnalité 2]

CONTRAINTES SPÉCIFIQUES :
- [contrainte 1]
- [contrainte 2]

CONTRAINTES PERMANENTES :
- Ne créer aucun fichier hors du périmètre défini
- Modifier l'existant avant d'en créer du nouveau
- Maximum 20 services/modules au total dans le projet
- Zéro refactoring non demandé
- Zéro dépendance ajoutée sans demande explicite

POINTS D'ATTENTION :
[Risques ou dépendances identifiés par Claude]

---

AVANT D'ÉCRIRE DU CODE :
1. Confirme ta compréhension de la mission en 2 phrases
2. Liste exactement les fichiers que tu vas modifier
3. Liste ce que tu ne toucheras pas
4. Attends ma confirmation explicite

---

CRITÈRE DE FIN :
- [ ] Build passe sans erreur
- [ ] Tu m'as donné les étapes de test manuel (3 max, en français simple)
- [ ] PROJET_CONTEXTE.md section 8 mis à jour
- [ ] Une ligne ajoutée dans CHANGELOG.md
```

---

## FORMAT DU DOCUMENT DE MISSION (produit par Claude avant ce prompt)

> Claude produit d'abord ce document. Je le valide. Puis Claude produit le prompt ci-dessus.

```markdown
# MISSION — [NOM COURT]
**Projet :** [nom]
**Date :** [date]
**Statut :** À valider

## Objectif
[Ce qu'on veut obtenir, formulé comme un test manuel]

## Périmètre
Fichiers concernés : [liste]
Hors scope : [liste]

## Contraintes spécifiques
- [contrainte 1]

## Critère de succès
- [ ] Build passe
- [ ] Je peux [action] et [résultat]
- [ ] PROJET_CONTEXTE.md à jour

## Points d'attention
[Risques identifiés par Claude]
```
