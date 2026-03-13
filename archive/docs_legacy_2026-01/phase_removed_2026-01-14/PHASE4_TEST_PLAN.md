# PHASE 4 — Plan de tests fonctionnels

Objectif: valider la visibilité et l’observabilité du cloud save sans modification backend.

## Pré-requis
- App configurée avec cloud activé (env valide).
- Compte Google/Firebase connecté.
- Backend accessible (sauf scénarios d’erreur contrôlée).

## Scénarios

1. Online nominal
- Étapes:
  - Lancer l’app (connecté).
  - Créer un monde ou renommer un monde existant.
- Attendus:
  - Badge “À jour”.
  - Aucun toast d’erreur.
  - Logs: worlds_put_attempt puis worlds_put_success (latency_ms > 0).

2. Offline → En attente → Resync
- Étapes:
  - Ouvrir “Mes mondes”.
  - Couper le réseau (mode avion).
  - Déclencher une sauvegarde (ex: rename).
  - Rétablir le réseau.
  - Revenir au premier plan (resume) ou “Actualiser”.
- Attendus:
  - Offline: badge “À synchroniser”.
  - Après retour: retry auto → badge “À jour”.
  - Logs: attempt → success après retour réseau.

3. Erreur serveur 5xx (non silencieuse)
- Étapes:
  - Temporiser une indispo (ex: URL base invalide, ou backend down).
  - Tenter un push (rename).
  - Revenir à config correcte et “Réessayer”.
- Attendus:
  - Toast “Échec de synchronisation cloud — réessayez”.
  - Badge “Erreur cloud” persistant jusqu’au succès.
  - Retry manuel fonctionne.
  - Logs: worlds_put_failure (cause_category=server) puis success.

4. 401 récupérée (auth expirée)
- Étapes:
  - Forcer expiration token, déclencher push.
- Attendus:
  - Échec initial puis récupération auth silencieuse.
  - Retry auto → “À jour”.
  - Logs: failure (http_code=401, cause_category=auth) puis success.

5. Cloud uniquement
- Étapes:
  - Avoir une entrée cloud sans local.
  - Ouvrir “Mes mondes”.
  - Utiliser “Télécharger tout”.
- Attendus:
  - Bandeau cloud-only affiché.
  - Badge “Cloud uniquement”, puis après téléchargement, badge “À jour” ou “À synchroniser”.

## Check de clôture
- Badges corrects sur chaque monde.
- Aucun échec PUT silencieux (toast + badge erreur).
- Retry manuel et auto opérationnels (auth change et resume).
- Logs présents (attempt/success/failure) avec worldId, latency_ms.
- Métriques observables selon PHASE4_VISIBILITE.md.
