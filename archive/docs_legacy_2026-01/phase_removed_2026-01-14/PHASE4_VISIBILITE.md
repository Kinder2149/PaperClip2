# PHASE 4 — Visibilité & Observabilité (spécification contractuelle)

Ce document définit la sémantique des états d’un monde côté client, les règles de détermination (à partir des informations locales et des métadonnées backend), les transitions autorisées, ainsi que les exigences minimales de surface UI et d’observabilité. Il s’appuie sur les décisions validées en PHASES 1–3 et n’introduit aucun nouveau point d’API backend.

- Source de vérité Auth: Firebase Auth (uid token). Le backend applique la sécurité serveur-side (ownership par uid sur PUT /worlds/:worldId). Le client ne filtre pas par sécurité.
- API canonique: `/worlds` (alias fonctionnel de `/saves` avec métadonnées). Pas d’invention d’endpoint.
- Aucune limite côté backend; la limite produit (PHASE 3) est du ressort client.

## 1) Périmètre et sources

- Côté backend (lecture à lister côté client):
  - `updated_at` (horodatage ISO du dernier état accepté côté serveur)
  - `versions` (entier ≥ 0; ≥ 1 indique une existence côté cloud)
- Côté client (technique, déjà présent ou dérivable des mécanismes existants):
  - Indicateur local «push en attente» (ex. flag technique «pending_*» piloté par l’orchestrateur de persistance)
  - Mémo d’erreur dernier push (code/message/horodatage), si échec
  - Horodatage local «dernière modification significative» (utilisé pour comparer avec `updated_at`)
  - Connaissance de l’état réseau et de l’auth (connecté/offline, token valide)

Remarque: les noms exacts des champs/flags locaux restent internes au client. La présente spécification impose uniquement la sémantique.

## 2) États d’un monde (définitions et priorités)

- Synchronisé
  - Définition: aucun push en attente, aucun échec mémorisé, et l’horodatage local concorde avec `updated_at` (tolérance ≤ 3 s pour les écarts d’horloge). 
- En attente
  - Définition: un push est planifié/non livré (ex. offline récent, file locale, tentative en cours). 
- Erreur
  - Définition: le dernier push a échoué; une erreur est mémorisée et n’a pas encore été résolue par un succès. 
- Cloud uniquement
  - Définition: le monde existe côté cloud (`versions` ≥ 1) mais aucune sauvegarde principale locale correspondante n’est présente (ex. après réinstallation, avant récupération locale), ou l’entrée locale est un placeholder en lecture.

Priorité d’affichage (en cas de cas frontières): Erreur > En attente > Synchronisé. L’état «Cloud uniquement» s’applique aux entrées provenant du cloud non matérialisées localement.

## 3) Règles de détermination (client ↔ backend)

Soient:
- `hasPendingPush` — vrai si une livraison est planifiée/en cours
- `lastPushError` — nul si aucun échec non résolu, sinon structure (code/message/at)
- `localUpdatedAt` — horodatage local de la dernière modification significative
- `server.updated_at` — horodatage côté serveur
- `server.versions` — entier

Règles minimales:
- Erreur: `lastPushError != null`
- En attente: `lastPushError == null` ET `hasPendingPush == true`
- Synchronisé: `lastPushError == null` ET `hasPendingPush == false` ET `|localUpdatedAt - server.updated_at| ≤ 3s`
- Cloud uniquement: `server.versions ≥ 1` ET aucune sauvegarde principale locale correspondante

Notes:
- Si `server.updated_at` est inconnu (pas encore consulté), s’appuyer d’abord sur les marqueurs locaux pour afficher «En attente» ou «Synchronisé (local)»; l’état final sera consolidé à la prochaine synchronisation.
- En cas de delta > 3s avec `hasPendingPush == false` et pas d’erreur, l’état est «En attente» (re-synchronisation nécessaire) jusqu’à livraison effective.

## 4) Machine d’états (transitions et triggers)

États: Synchronisé, En attente, Erreur. «Cloud uniquement» est un cas de présence cloud sans sauvegarde locale, traité à part.

- Synchronisé → En attente
  - Trigger: modification locale d’un monde (sauvegarde) ou création locale quand connecté, ou détection d’écart > 3s avec serveur.
- En attente → Synchronisé
  - Trigger: push réussi (PUT /worlds/:worldId accepté) et consolidation `updated_at` ≈ `localUpdatedAt`.
- En attente → Erreur
  - Trigger: push échoue (ex. 5xx, 4xx non autorisé, timeout), l’erreur est mémorisée.
- Erreur → En attente
  - Trigger: action «Réessayer» ou retry automatique après rétablissement réseau/auth (efface l’erreur en cas de succès, sinon reste Erreur).
- Erreur → Synchronisé
  - Trigger: push réussi après retry.

Cas «Cloud uniquement»:
- Apparition: le client liste le cloud (versions ≥ 1) mais n’a pas encore de sauvegarde locale correspondante.
- Disparition: matérialisation locale (import/récupération) ou création locale qui remplace le placeholder.

## 5) Surface UI minimale (obligatoire)

- Liste des mondes et fiche monde affichent un badge/label d’état avec texte exact:
  - «Synchronisé»
  - «En attente»
  - «Erreur»
  - «Cloud uniquement» (si applicable)
- Snackbars/toasts:
  - À chaque échec PUT /worlds: afficher un toast court (non intrusif) avec cause synthétique (réseau/auth/serveur) + indication d’action.
- Action «Réessayer» visible quand état = Erreur ou En attente (si connecté): relance le push.
- Tolérance UX: aucun blocage dur de l’UI; le badge est la source de vérité visuelle, la snackbar est contextuelle et fugace.

## 6) Observabilité (logs et Analytics)

- Logs structurés côté client pour chaque tentative de push:
  - worldId, latency_ms, http_code, cause_category (network/auth/server/unknown), attempt_no
- Événements Analytics (recommandés, via service existant):
  - `worlds_put_attempt`
  - `worlds_put_success`
  - `worlds_put_failure`
- Spécificités:
  - 401 catégorisé «auth»; si récupération silencieuse d’auth aboutit, un retry automatique peut conduire à `worlds_put_success`.
  - Les échecs doivent toujours laisser une trace (log et/ou événement).

## 7) Scénarios de référence

- Online nominal:
  - Modification locale → En attente → PUT succès → Synchronisé.
- Offline au moment du push:
  - Modification locale → En attente → retour online → PUT succès auto → Synchronisé.
- Erreur serveur 5xx:
  - Tentative → Snackbar «Erreur» + badge «Erreur» → Réessayer manuel → Succès → Synchronisé.
- 401 (session expirée) avec récupération:
  - Tentative → 401 → récupération auth silencieuse → retry auto → Succès → Synchronisé.
- Cloud uniquement:
  - Monde listé depuis le cloud, pas en local → badge «Cloud uniquement». Dès matérialisation locale → état selon règles 2/3.

## 8) Critères d’acceptation (clôture PHASE 4)

- Les badges d’état apparaissent de manière cohérente en liste et détail.
- Aucune erreur PUT /worlds n’est silencieuse; un toast est affiché et un indicateur persistant («Erreur») reste visible jusqu’au succès.
- La file d’attente locale (sémantique «En attente») déclenche des retries automatiques sur retour réseau/auth et supporte un retry manuel.
- Les logs/analytics contiennent les trois événements avec champs requis.
- Les règles de détermination et transitions ci-dessus sont intégralement appliquées.

## 9) Non-objectifs

- Aucun nouveau champ backend ou endpoint.
- Pas de changement de sécurité/ownership: 100% serveur-side (PHASE 1).
- Pas de modification de la politique de création/push (PHASE 2) ni de la limite produit (PHASE 3).

## 10) Métriques & suivi opérationnel (p4-08)

Indicateurs calculables depuis les logs structurés (événements `worlds_put_attempt`, `worlds_put_success`, `worlds_put_failure`).

- Taux d'échec PUT /worlds (%) = failures / attempts (fenêtre 7 jours)
- Délai moyen de resynchronisation (ms) = moyenne des `latency_ms` sur `worlds_put_success`
- Part de mondes "En attente" > 10 min = proportion d'entrées dont le flag pendingCloud reste vrai au-delà de 10 min (snapshot onglet Saves via inspection locale)

Procédure low‑code (exploitation logs console/app):
- Filtrer par code = `worlds_put_*` et agréger par `worldId`
- Export CSV simple (copier/coller) si besoin de consolidation externe
- Seuils initiaux (alerte douce):
  - Taux d'échec > 5%
  - Délai moyen resync > 3000 ms
  - > 10% de mondes en "En attente" > 10 min

## 11) Checklist d’acceptation produit (p4-09)

- UI affiche un badge d’état exact pour chaque monde en liste
- Échec PUT /worlds génère un toast et un badge "Erreur" persistant jusqu’au succès
- Bouton "Réessayer" présent pour les états "Erreur" et "En attente"
- Retry automatique déclenché lors du retour d’auth et au resume d’app
- Logs présents pour `worlds_put_attempt/success/failure` avec `worldId` et `latency_ms`
- Métriques observables et interprétables selon la section 10
