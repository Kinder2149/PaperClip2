# Backups — Politique de Rétention (PaperClip2)

## 1) Format & portée
- Nom de backup: `partieId|timestamp` (timestamp en millisecondes)
- Backups internes uniquement: exclus de la liste principale dans l’UI
- Restauration: ciblée sur l’ID de partie en cours (overwrite strict)

## 2) Politique de rétention
- N = 10 backups au maximum par `partieId`
- TTL = 30 jours (suppressions des backups plus vieux)
- Méthode centralisée: `SaveManagerAdapter.applyBackupRetention(partieId)`

## 3) Quand appliquer
- Après chaque création de backup (autosave/lifecycle)
- Nettoyage manuel global via action UI (enjeux maintenance)
- Routine quotidienne (timer) via `AutoSaveService`/orchestrateur

## 4) Sécurité et intégrité
- `runIntegrityChecks()` signale:
  - Formats invalides (pas exactement une séparation)
  - Timestamps non numériques
  - Backups orphelins (aucune sauvegarde régulière pour `partieId`)
  - Dépassements N/TTL

## 5) Tests
- `backups_retention_test.dart`
  - Génère >10 backups, vérifie purge TTL et quota
- `integrity_checks_test.dart`
  - Signale formats invalides, orphelins, dépassements
