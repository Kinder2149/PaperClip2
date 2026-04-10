# PROMPT_CASCADE_01 — INITIALISATION NOUVEAU PROJET

> Emplacement : METHODO/prompts/PROMPT_CASCADE_01_INIT_NOUVEAU_PROJET.md
> Quand l'utiliser : après avoir rempli PROJET_CONTEXTE.md avec Claude
> Ce prompt est produit/adapté par Claude — il peut être utilisé directement ou ajusté

---

## PROMPT À COPIER-COLLER DANS CASCADE

```
Lis en premier, dans cet ordre :
1. PROJET_CONTEXTE.md (source de vérité absolue)
2. STACK_STANDARD.md (technologies autorisées)

Si l'un de ces fichiers est absent : stop, signale-le, n'agis pas.

---

MISSION : Initialiser l'architecture de base du projet

OBJECTIF :
Créer uniquement la structure de dossiers et les fichiers de base vides,
conformément à la section 3 (Architecture) de PROJET_CONTEXTE.md.

À CRÉER :
- Structure de dossiers définie dans PROJET_CONTEXTE.md section 3
- Fichiers de base vides avec leur rôle en commentaire en en-tête
- Fichier de configuration principal (pubspec.yaml / package.json / requirements.txt selon la stack)
- CHANGELOG.md avec première ligne : [date] | Initialisation du projet | Structure de base créée

À NE PAS CRÉER :
- Aucune logique métier
- Aucun composant UI avec du contenu
- Aucun service avec du code fonctionnel
- Aucun fichier qui ne soit pas listé dans PROJET_CONTEXTE.md

CONTRAINTES :
- Maximum 20 fichiers/dossiers créés
- Nommage conforme à la stack définie dans STACK_STANDARD.md
- Zéro dépendance ajoutée sans qu'elle soit dans PROJET_CONTEXTE.md section 2

AVANT D'AGIR :
1. Confirme ta compréhension : cite le nom du projet et son objectif en 1 phrase
2. Liste exactement les dossiers et fichiers que tu vas créer
3. Attends ma confirmation avant de commencer

CRITÈRE DE FIN :
- Structure créée conforme au plan validé
- Build/compilation de base passe sans erreur
- Tu me donnes 2 étapes de vérification manuelle
- PROJET_CONTEXTE.md section 8 mis à jour
```
