# PROMPT_CASCADE_02 — REPRISE PROJET EXISTANT

> Emplacement : METHODO/prompts/PROMPT_CASCADE_02_REPRISE_PROJET.md
> Quand l'utiliser : après avoir produit PROJET_CONTEXTE.md avec Claude sur un projet existant
> Ce prompt est produit/adapté par Claude — il peut être utilisé directement ou ajusté

---

## PROMPT À COPIER-COLLER DANS CASCADE

```
Lis en premier, dans cet ordre :
1. PROJET_CONTEXTE.md (vient d'être créé — source de vérité)
2. STACK_STANDARD.md
3. PROJET_CONTEXTE_TEMPLATE.md (pour comprendre le format attendu)

Si l'un de ces fichiers est absent : stop, signale-le, n'agis pas.

---

MISSION : Nettoyer et aligner le projet sur PROJET_CONTEXTE.md

Cette mission se fait en 3 étapes séquentielles.
Tu ne passes à l'étape suivante qu'après ma confirmation explicite.

---

ÉTAPE 1 — ARCHIVAGE DOCUMENTATION

Crée un dossier _archives/ à la racine du projet.

Déplace dedans TOUS les fichiers .md existants SAUF :
- PROJET_CONTEXTE.md
- STACK_STANDARD.md
- CHANGELOG.md
- BUGS.md
- README.md

⚠️ Déplacer uniquement, ne jamais supprimer.

Présente-moi la liste de ce qui a été archivé.
Attends ma confirmation avant l'étape 2.

---

ÉTAPE 2 — VÉRIFICATION DE STRUCTURE

Compare la structure de dossiers réelle du projet avec celle définie dans
PROJET_CONTEXTE.md section 3.

Présente-moi sous forme de tableau :
| Dossier/Fichier | Statut | Action recommandée |
| [nom] | Conforme / En trop / Manquant | [rien / à archiver / à créer] |

⚠️ Ne modifie rien encore. Rapport uniquement.
Attends ma confirmation avant l'étape 3.

---

ÉTAPE 3 — ALIGNEMENT (seulement après validation étape 2)

Applique uniquement les actions que j'ai validées dans l'étape 2.

Contraintes absolues :
- Aucune suppression définitive
- Aucune modification du code existant
- Aucun refactoring
- Aucune création de fichier non validé

---

CRITÈRE DE FIN :
- Les 3 étapes sont validées par moi
- PROJET_CONTEXTE.md section 8 est mis à jour
- CHANGELOG.md contient une ligne : [date] | Reprise projet | Nettoyage et alignement
- Tu me donnes l'état final : ce qui a été fait, ce qui reste à faire
```
