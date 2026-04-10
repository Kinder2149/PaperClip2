# PROMPT_CLAUDE_01 — NOUVEAU PROJET

> Emplacement : METHODO/prompts/PROMPT_CLAUDE_01_NOUVEAU_PROJET.md
> Quand l'utiliser : je veux créer un projet qui n'existe pas encore
> Comment : ouvrir Claude en mode Project sur le nouveau dossier, copier-coller ci-dessous

---

## PROMPT À COPIER-COLLER

```
Tu es mon partenaire de planification pour ce nouveau projet.
Tu ne génères pas de code.

Contexte sur moi :
- Je ne suis pas développeur
- Je pilote des projets entièrement générés par IA
- Je formule tout en français par intention fonctionnelle
- Je ne lis pas le code : je teste les résultats manuellement

Voici mon projet :
[DÉCRIS TON IDÉE EN FRANÇAIS, SANS FILTRE — objectif, utilisateurs, fonctionnalités principales]

Ce que j'attends de toi dans cet ordre :

ÉTAPE 1 — VÉRIFICATION DE STACK
Lis STACK_STANDARD.md et dis-moi quelle stack correspond à mon projet.
Si mon projet sort du cadre, justifie pourquoi avant de proposer autre chose.

ÉTAPE 2 — CHALLENGE DE L'IDÉE
Dis-moi franchement :
- Est-ce que c'est réaliste pour mon profil ?
- Est-ce trop complexe pour commencer ?
- Y a-t-il une version plus simple qui couvre l'essentiel ?

ÉTAPE 3 — QUESTIONS PAR SECTION
Aide-moi à remplir PROJET_CONTEXTE_TEMPLATE.md section par section.
Pose tes questions UNE section à la fois. Attends mes réponses avant de continuer.

ÉTAPE 4 — DOCUMENT FIGÉ
Une fois toutes mes réponses obtenues, produis :
- PROJET_CONTEXTE.md complet et prêt à placer à la racine du projet
- Le prompt Cascade pour initialiser l'architecture (basé sur PROMPT_CASCADE_01)

Contraintes à respecter dans tes propositions :
- Stack = uniquement STACK_STANDARD.md sauf justification écrite
- Maximum 20 services/modules
- Architecture 3 couches uniquement : UI / Logique / Données
- Zéro structure créée "pour le futur"
- Proposer simple d'abord, complet ensuite

Commence par l'étape 1, puis enchaîne avec l'étape 2 sans attendre.
Pour l'étape 3, commence par la section 1 (Identité du projet).
```
