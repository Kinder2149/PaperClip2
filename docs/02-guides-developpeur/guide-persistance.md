# Guide de persistance côté client (consolidé)

Ce document remplace les documents de phase liés à la persistance (PHASE 2–4) et détaille le comportement côté client: API canonique, états, machine d’états, UI minimale, observabilité et plan de test.

## API canonique
- Toutes les opérations fonctionnelles passent par `/worlds` (PUT/GET/LIST/DELETE).
- `/saves` est une API technique backend (versions/restauration), non appelée par l’UI.

## Identité & ownership (rappel)
- Auth: Firebase Auth (ID Token) — unique source de vérité. Vérification serveur-side, extraction `uid`.
- Ownership: déterminé uniquement par le serveur (`players/{uid}/saves/{worldId}`).
- `playerId`: prérequis opérationnel client (déclencheur cloud), non sécuritaire.
- `worldId`: UUID v4 identique dans l’URL et `snapshot.metadata.worldId`.

## Flux de sauvegarde/push
1) Sauvegarde locale write-through via `SaveManagerAdapter`.
2) Si utilisateur Firebase connecté, push automatique vers `/worlds/:worldId` (garanti à la création de monde).
3) En cas d'échec: flags `pending_cloud_push_<id>` et `last_push_error_<id>`, `syncState='error'`.
4) Retry automatique sur changement d'auth et au resume; retry manuel disponible par monde.
5) Synchronisation automatique au login via listener Firebase Auth → `onPlayerConnected()`.

## Limite de mondes
- Maximum 10 mondes par utilisateur (`GameConstants.MAX_WORLDS`).
- Validation côté client (message utilisateur clair) et backend (HTTP 429).
- Message d'erreur: "Limite de 10 mondes atteinte. Supprimez un monde existant pour en créer un nouveau."

## États d’un monde (UX)
- Synchronisé: aucun push en attente ni erreur; local≈cloud (tolérance 2–3s).
- En attente: livraison planifiée/non livrée (offline/queue locale).
- Erreur: échec dernier push (toast + badge persistant; action « Réessayer »).
- Cloud uniquement: présence cloud sans sauvegarde locale.

Priorité: Erreur > En attente > Synchronisé. « Cloud uniquement » s’applique aux entrées distantes non matérialisées.

## Machine d’états (résumé)
- Synchronisé → En attente: modification locale ou détection d’écart > 3s.
- En attente → Synchronisé: push réussi.
- En attente → Erreur: push échoue (réseau/serveur/auth).
- Erreur → En attente: retry manuel/auto.
- Erreur → Synchronisé: push réussi.

## UI minimale
- Badge/label par monde: « Synchronisé », « En attente », « Erreur », « Cloud uniquement ».
- Snackbar sur échec `PUT /worlds` (non silencieuse).
- Bouton « Réessayer » quand état = Erreur/En attente.

## Observabilité & métriques
- Logs (client): `worlds_put_attempt/success/failure` avec `worldId`, `latency_ms`, `http_code` (si connu), `cause_category`.
- Métriques low‑code:
  - Taux d’échec PUT /worlds (%) = failures/attempts (fenêtre 7j)
  - Délai moyen resync (ms) = moyenne des `latency_ms` sur success
  - Part de mondes « En attente » > 10 min (via flags persistants)

## Plan de tests (manuel)
1. Online nominal: créer/renommer → badge « À jour », logs attempt/success.
2. Offline → En attente → resync: couper réseau, sauvegarder, remettre réseau + resume → « À jour ».
3. Erreur 5xx: simuler indispo → snackbar + badge « Erreur » → retry manuel OK → « À jour ».
4. 401 récupérée: token expiré → failure auth → récupération silencieuse → retry auto → « À jour ».
5. Cloud‑only: entrée distante sans local → bandeau + « Télécharger tout » → matérialisation → consolidation d’état.

## Non‑objectifs
- Aucun nouvel endpoint ni logique métier serveur.
- Pas de merge multi‑branche; arbitrage par fraîcheur uniquement.
