# SaveLoadScreen — Filtres & Badges Cloud (PaperClip2)

## 1) Liste principale
- Sauvegardes locales uniquement (exclut backups) par défaut.
- Stats dérivées depuis snapshot (money, paperclips, etc.).

## 2) Filtre “Sauvegardes locales uniquement”
- Affiché si `.env: FEATURE_CLOUD_PER_PARTIE=true`.
- Masque les entrées avec `remoteVersion != null` (déjà synchronisées côté cloud).

## 3) Badges cloud
- Statut: `cloudSyncState` (ex: `in_sync`, `ahead_remote`, `unknown`).
- Affichage: chip coloré + tooltip d’aide.
- Loader mince si statut en cours de résolution.

## 4) Actions par entrée
- Push cloud (par `partieId`) — confirmation, puis `pushCloudFromSaveId`.
- Pull cloud (par `partieId`) — confirmation, puis écriture locale immédiate.
- Restore dernier backup — accès direct au plus récent.
- Supprimer — suppression stricte par ID.
- Charger — ouvre la partie par ID.

## 5) Sécurité UX
- Confirmations modales pour Push/Pull.
- Notifications de succès/erreur via `NotificationManager`.

## 6) Accessibilité
- Tooltips systématiques sur actions.
- Icônes contrastées (upload/download).
