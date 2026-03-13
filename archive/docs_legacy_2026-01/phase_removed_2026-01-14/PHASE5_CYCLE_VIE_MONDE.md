# PHASE 5 — Cycle de vie d’un monde

Objectif: documenter clairement le flux de vie d’un monde (création → modification → synchronisation → suppression/restauration), en cohérence stricte avec les phases 1–4 et le backend existant.

## Principes contractuels
- Source d’auth: Firebase Auth (uid dans l’ID Token). Sécurité 100% serveur-side.
- Ownership: un monde appartient au uid du token qui a effectué le premier PUT `/worlds/:worldId`.
- Identité monde: `worldId` = UUID v4, identique dans l’URL et dans `snapshot.metadata.worldId`.
- 1 monde = 1 sauvegarde principale (backups exclus du décompte « mondes »).
- API canonique côté client: `/worlds` (alias fonctionnel de `/saves`).

## 1) Création
- Génération locale d’un `worldId` (UUID v4).
- Création d’une sauvegarde locale principale (snapshot minimal viable; voir structure minimale dans la doc backend).
- Si connecté (phases 1–2): déclenchement du push immédiat `PUT /worlds/:worldId`.
- Échec réseau/auth: marquage « En attente » et retry auto (auth change, resume) + retry manuel possible.

## 2) Modification
- Les modifications (sauvegarde locale) mettent à jour le snapshot et ses métadonnées (`lastModified`, etc.).
- Si connecté: push cloud (write-through) selon PHASE 2, surface d’erreur non silencieuse selon PHASE 4.
- Invariants: pas de logique métier déportée serveur; le client garde la responsabilité métier.

## 3) États de synchronisation (UX)
- Synchronisé: aucun push en attente ni erreur; timestamps local≈serveur.
- En attente: livraison planifiée/non livrée (offline/queue locale).
- Erreur: échec du dernier push (toast + badge persistant; action « Réessayer »).
- Cloud uniquement: entrée distante sans matérialisation locale.

## 4) Suppression
- Suppression locale via l’UI « Mes mondes » → enlève la sauvegarde principale.
- Best-effort suppression cloud via l’API (si disponible, non bloquant pour l’UX).
- Backups: non considérés « mondes »; politique de rétention séparée (TTL/N max).

## 5) Restauration
- Restauration depuis un backup local (sélectionné par date).
- Après restauration: push cloud selon règles habituelles si connecté.
- Conformité: le `worldId` reste la clé canonique (pas de renommage d’ID), seul le nom est modifiable.

## 6) Cross-device (aperçu)
- Condition: même compte Firebase (uid), et présence cloud du monde.
- Listing: le client peut afficher les mondes présents côté cloud (cloud-only), avec option de matérialisation locale.
- Récupération: téléchargement (pull) puis réinjection locale, ensuite synchronisation normale.

## 7) Erreurs et observabilité
- Aucune erreur PUT `/worlds` n’est silencieuse (snackbar, badge, logs).
- Logs structurés: `worlds_put_attempt/success/failure` avec `worldId` et `latency_ms`.
- Métriques: taux d’échec, délai moyen de resync, durée « En attente ». Voir PHASE4_VISIBILITE.md.

## 8) Non-objectifs
- Aucun endpoint additionnel.
- Pas de logique métier sur le serveur.
- Pas de filtrage client côté sécurité (ownership serveur-side).
