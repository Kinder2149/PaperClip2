# PHASE 5 — Conditions de récupérabilité cross‑device

Objectif: préciser les conditions et procédures permettant de récupérer un monde sur un autre appareil, sans ajout d’API.

## Prérequis
- Authentification sur le même compte Google/Firebase (même uid).
- Connexion réseau fonctionnelle.
- Monde présent côté cloud (au moins une version) sous l’ownership de l’uid.

## Scénarios de récupération
- Nouveau device (aucune sauvegarde locale):
  - Ouvrir « Mes mondes » → le monde apparaît « Cloud uniquement ».
  - Action « Télécharger tout » ou matérialisation individuelle → création de la sauvegarde locale à partir du snapshot cloud.
  - Après matérialisation: flux normal de synchronisation (badge « À jour »/« À synchroniser » selon état).

- Réinstallation sur device existant:
  - Identique au scénario précédent (cloud‑only → matérialisation locale).

- Conflit de fraîcheur (cloud plus récent que local):
  - L’arbitre côté client détecte un `updated_at` > `localUpdatedAt`.
  - Action: pull cloud et application (ou matérialisation si pas de jeu chargé), puis badge « À jour ».

## Limites et attentes
- Pas de merge multi‑branche: le flux est linéaire (dernier snapshot gagne selon arbitrage temps).
- Pas de récupération sans réseau.
- La récupération est limitée par l’ownership: un monde d’un autre uid n’est jamais visible.

## Procédures
- Matérialisation: `materializeFromCloud(partieId)` crée/écrase la sauvegarde locale à partir du snapshot cloud.
- Récupération en jeu ouvert: application du snapshot sur l’état de jeu puis sauvegarde locale (write‑through).

## UX minimale
- Badge « Cloud uniquement » pour mondes distants non matérialisés.
- Bouton « Télécharger tout » et/ou action individuelle « Télécharger ».
- En cas d’échec réseau/auth: toast + état « En attente »/« Erreur » selon PHASE 4.
