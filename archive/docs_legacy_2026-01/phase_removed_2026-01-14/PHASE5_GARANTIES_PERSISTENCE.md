# PHASE 5 — Garanties de persistance

Objectif: formaliser les garanties offertes au joueur concernant la persistance et la durabilité des mondes, sans introduire de nouvelle logique serveur.

## Invariants (rappel)
- Identité canonique: `player_uid` (Firebase Auth) est la source d’identité côté serveur.
- Ownership strict: un monde appartient au `uid` ayant effectué le premier `PUT /worlds/:worldId`.
- 1 monde = 1 sauvegarde principale (backups exclus).
- `worldId` = UUID v4, identique au path et à `snapshot.metadata.worldId`.
- Aucune logique métier côté serveur: le serveur stocke, valide le contrat et applique l’ownership.

## Durabilité des données
- Sauvegarde locale: écrite sur l’appareil (write-through), immédiate.
- Sauvegarde cloud: déclenchée dès que connecté; en cas d’échec réseau/auth → état « En attente » + retry auto.
- Backups locaux: créés périodiquement/événementiellement, soumis à une politique de rétention (TTL/N max) côté client.

## Cohérence et conflits
- Tolérance horloge: 2–3s pour comparer `localUpdatedAt` vs `server.updated_at`.
- Arbitrage côté client: 
  - Si cloud plus récent → pull cloud (materialization ou application sur l’état en cours).
  - Si local plus récent → push `PUT /worlds/:worldId`.
  - Égal → no-op.
- Jamais d’écrasement aveugle: les opérations suivent l’arbitrage ci‑dessus.

## États et garanties UX
- « Synchronisé »: local et cloud concordent (dans la tolérance).
- « En attente »: une livraison est planifiée/non livrée; pas de perte, retry auto sur évènements (auth, resume).
- « Erreur »: dernier push échoué; l’état est persistant jusqu’au prochain succès; action « Réessayer » disponible.
- « Cloud uniquement »: présence côté cloud assurée; matérialisation locale sur demande.

## Backups
- Non comptés comme mondes.
- Conservent une trace de l’historique local.
- Politique configurable par constantes (TTL/N max). La suppression de backups n’affecte pas la sauvegarde principale.

## Sécurité & confidentialité
- Le client n’opère aucun filtrage de sécurité: tout contrôle d’accès est serveur‑side via `uid`.
- Le `playerId` exposé côté client est contextuel (analytics/UX), jamais un critère de sécurité.

## Non‑objectifs
- Pas de SLA serveur dans cette phase.
- Pas de versioning serveur multi‑branches: un monde correspond à un flux linéaire de snapshots.
