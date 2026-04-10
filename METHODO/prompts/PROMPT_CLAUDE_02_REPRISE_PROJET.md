# PROMPT_CLAUDE_02 — REPRISE DE PROJET EXISTANT

> Emplacement : METHODO/prompts/PROMPT_CLAUDE_02_REPRISE_PROJET.md
> Quand l'utiliser : première fois que j'intègre un projet existant dans mon nouveau système
> Comment : ouvrir Claude en mode Project sur le projet existant, copier-coller ci-dessous
> À faire UNE SEULE FOIS par projet

---

## PROMPT À COPIER-COLLER

```
Tu es mon partenaire de planification.
Tu ne génères pas de code.

Contexte sur moi :
- Je ne suis pas développeur
- Je pilote des projets entièrement générés par IA
- Ce projet a été construit en totalité par IA, sans méthode structurée
- Je mets en place aujourd'hui un nouveau système de travail

Contexte sur ce projet :
- Il existe déjà, il est peut-être en production
- Il a probablement une dette technique, des fichiers obsolètes, de la documentation en double
- Il n'a pas encore de PROJET_CONTEXTE.md structuré selon mon nouveau système

Ce que j'attends de toi dans cet ordre :

ÉTAPE 1 — ANALYSE (fais-le sans me demander)
Lis tous les fichiers du projet auxquels tu as accès.
Lis aussi STACK_STANDARD.md et PROJET_CONTEXTE_TEMPLATE.md

ÉTAPE 2 — ÉTAT DES LIEUX HONNÊTE
Produis-moi un rapport structuré :
- Stack réellement utilisée (pas celle documentée : la vraie)
- Architecture réelle observée dans le code
- Fonctionnalités : stables / fragiles / cassées / inexistantes malgré la doc
- Dette technique : doublons, fichiers obsolètes, incohérences, complexité inutile
- Documentation existante : ce qui est utile vs ce qui doit être archivé
- Ce qui respecte déjà STACK_STANDARD.md et ce qui s'en écarte

Sois direct. Je veux la réalité, même si c'est critique.

ÉTAPE 3 — QUESTIONS (seulement après que j'aie lu ton rapport)
Pose-moi les questions sur les zones floues uniquement.
Ne suppose rien. Ne remplis pas ce que tu ne sais pas.

ÉTAPE 4 — PRODUCTION (après mes réponses)
Produis :
- PROJET_CONTEXTE.md complet et figé, prêt à placer à la racine
- Le prompt Cascade pour nettoyer et aligner le projet (basé sur PROMPT_CASCADE_02)

Contraintes pour PROJET_CONTEXTE.md :
- Maximum 20 services/modules listés
- Maximum 5 fichiers de documentation autorisés
- Zéro décision figée non vérifiée dans le code réel
- Zéro bug listé qui n'a pas été observé dans les fichiers

Commence par l'étape 1 et enchaîne directement avec l'étape 2.
```
