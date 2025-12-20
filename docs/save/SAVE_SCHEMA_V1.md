# SAVE_SCHEMA_V1 — Spécification de la sauvegarde locale (Paperclip)

Cette spécification gèle et formalise le format de sauvegarde local servant de source de vérité. Aucune dépendance cloud. Le cloud ne fera que transporter/synchroniser ce format (voir Mission ultérieure).

## 1. Principes
- Snapshot-first: l’état courant est sérialisé dans un « GameSnapshot » unique.
- Local maître: la sauvegarde locale est la seule source de vérité.
- Compat ascendante: nouvelles clés autorisées; les clés existantes ne changent pas de sens.
- Atomicité: écriture snapshot-only (évite divergence avec formats legacy).

## 2. Conteneur de sauvegarde
La sauvegarde persistée comporte deux couches:

- Métadonnées (hors snapshot) — gérées par le gestionnaire de sauvegarde:
  - `id` (string, stable) — identifiant interne de la sauvegarde
  - `name` (string) — nom logique (slot)
  - `creationDate` (ISO8601) — date de création
  - `lastModified` (ISO8601) — date de dernière modif
  - `version` (string) — version applicative (GameConstants.VERSION)
  - `gameMode` (int enum)
  - `flags` (optionnel) — `isBackup`, `isRestored`
  - `displayData` (optionnel) — extrait pour UI (argent, trombones…)

- Données de jeu — `gameData`:
  - `gameSnapshot` (object) — voir §3

Note: d’anciennes clés « legacy » peuvent exister lors d’import/migration, mais ne sont plus écrites.

## 3. GameSnapshot (source de vérité)
```json
{
  "gameSnapshot": {
    "core": {
      "playerManager": { /* état joueur (argent, métal, trombones, upgrades…) */ },
      "marketManager": { /* prix, demande, réputation, stocks… */ },
      "resourceManager": { /* capacités, achats métal… */ },
      "productionManager": { /* cadence, buffers… */ },
      "levelSystem": { /* xp, niveau… */ },
      "statistics": { /* compteurs cumulatifs et métriques */ }
    },
    "meta": {
      "appVersion": "<GameConstants.VERSION>",
      "timestamps": {
        "createdAt": "<ISO8601>",
        "lastSavedAt": "<ISO8601>",
        "lastOfflineAppliedAt": "<ISO8601>"
      },
      "gameMode": 0
    }
  }
}
```

Notes:
- Les sous-objets `core.*` sont alignés sur leurs managers/ systèmes.
- `statistics` regroupe les cumulés (money, clips produits, vendus, etc.).
- `meta.timestamps.lastOfflineAppliedAt` évite la ré-application offline d’un même intervalle.

## 4. Cycle de vie
- Création: première sauvegarde au lancement/slot → snapshot écrit.
- Mise à jour: autosave coalescée post-frame (événements importants), sauvegarde manuelle, lifecycle save.
- Backups: créés périodiquement (cooldown) sous `name|BACKUP_DELIMITER|timestamp`.
- Restauration: en cas de snapshot invalide, tentative depuis le backup le plus récent; sinon erreur explicite.
- Suppression: par nom (résolu en id le plus récent) ou par id.
- Import/Export: JSON (métadonnées + gameData), validation rapide avant import.

## 5. Invariants & Garanties
- Les nombres négatifs sont évités pour les ressources (argent, métal) au moment de la sérialisation.
- Les niveaux d’upgrades restent bornés par leurs caps/multiplicateurs.
- La lecture privilégie toujours `gameSnapshot`; aucune réécriture legacy.

## 6. Versionnement du schéma
- Nom de schéma: `SAVE_SCHEMA_V1`
- Compatibilité ascendante: V1 → V2 ajoutera des clés facultatives, jamais modifiera le sens d’une clé existante.
- Procédure d’évolution:
  1) Documenter la nouvelle clé dans ce fichier.
  2) Implémenter la migration (`migrateSnapshot`) côté persistance locale.
  3) Marquer la version app dans `meta.appVersion`.

## 7. Sécurité et résilience
- Coalescing autosave pour éviter freezes (écritures groupées).
- Backups cadencés et nettoyage périodique.
- Validation rapide (structure, présence du snapshot, types attendus basiques) avant écriture et import.

## 8. Interop Cloud (préparation)
- Le cloud synchronisera uniquement:
  - `gameSnapshot` (vérité)
  - Un sous-ensemble de `displayData` (optionnel) pour listings
  - Les métadonnées minimales (id logique/nom et horodatages)
- Conflits: arbitrage local par horodatage et/ou merging conservateur (à définir en Mission cloud).
