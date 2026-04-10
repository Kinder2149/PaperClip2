# PROMPT_CASCADE_05 — CLÔTURE DE SESSION

> Emplacement : METHODO/prompts/PROMPT_CASCADE_05_CLOTURE.md
> Quand l'utiliser : à la fin de CHAQUE session, quelle que soit la mission
> Obligatoire avant de fermer Windsurf

---

## PROMPT À COPIER-COLLER DANS CASCADE

```
La session est terminée. Effectue la clôture proprement.

---

MISE À JOUR PROJET_CONTEXTE.md :

Section 4 — Fonctionnalités :
- Ce qui était "En cours" et est maintenant terminé et testé → déplacer vers "Stables"
- Mettre à jour "En cours" avec l'état réel après cette session
- Ajouter dans "Bugs connus" si des bugs ont été découverts

Section 6 — Décisions figées :
- Ajouter les décisions techniques prises pendant cette session
- Format : [date du jour] | [décision] | [raison]

Section 8 — Session en cours :
- Compléter "Résultat de fin de session" avec ce qui a réellement été fait
- Vider les champs pour préparer la prochaine session

Section 9 — Backlog :
- Retirer la mission qui vient d'être terminée
- Réordonner si nécessaire selon les nouvelles priorités

---

MISE À JOUR CHANGELOG.md :
Ajouter une ligne :
[DATE DU JOUR] | [Nom de la mission] | [Ce qui a été fait en 1 phrase] | [Liste des fichiers modifiés]

---

MISE À JOUR BUGS.md si nécessaire :
- Ajouter les bugs découverts pendant la session (avec date)
- Marquer comme résolus les bugs corrigés (avec date)

---

RAPPORT DE FIN DE SESSION :
Présente-moi :

1. CE QUI A ÉTÉ FAIT
   [Liste des fichiers modifiés]

2. COMMENT TESTER
   Étape 1 : [action]
   Étape 2 : [vérification attendue]
   Étape 3 : [si nécessaire]

3. CE QUI N'A PAS ÉTÉ FAIT (si pertinent)
   [Et pourquoi]

4. PROCHAINE MISSION RECOMMANDÉE
   [Première entrée du backlog mis à jour]

---

⚠️ Ne modifie aucun autre fichier du projet.
```
