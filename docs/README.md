# PaperClip2 — Documentation (Index Canonique)

Dernière mise à jour: 2025-12-25

Ce README référence les documents de conception canoniques et signale les documents archivés. Toute nouvelle documentation doit se conformer à cet index pour éviter les doublons et contradictions.

## Documents canoniques (source de vérité)
- Identité & Persistance: `identity/INVARIANTS_IDENTITE_PERSISTENCE.md`
- Invariants système de sauvegarde: `SAVE_SYSTEM_INVARIANTS.md`
- Stratégie de persistance (snapshot-first): `persistence.md`
- Rétention des backups: `backups/Backup_Retention.md`
- Références progression/événements: `progression/GAME_EVENTS_REFERENCE.md`, `progression/PROGRESSION_CURVE_REFERENCE.md`, `progression/flows/Save_Load_Flow.md`
- UI/UX: `ui/SaveLoad_UI.md`, `ux/UX_INVISIBILITY_GUIDE.md`, `ux/GOOGLE_FEATURES_UX.md`
- Social: `social/SOCIAL_MODEL_FINAL.md`
- CI & validation: `ci/TESTS_AND_CI_CHECKLIST.md`, `VALIDATION_REPORT.md`
- Architecture: `ARCHITECTURE.md`

## Documents archivés (obsolètes/contradictoires)
Archivé dans `docs/_archive/` pour traçabilité. Ne plus modifier ni référencer.
- Cloud (ancienne pile Supabase/flux opt‑in) et orchestrations Google:
  - `_archive/CLOUD_SYSTEM_FINAL.md`
  - `_archive/Cloud_Persistence.md`
  - `_archive/CLOUD_SAVE_MODEL.md`
  - `_archive/SYNC_RULES.md`
  - `_archive/cloudsave_README.md`
  - `_archive/CLOUD_SAVE_CONFLICT_POLICY.md`
  - `_archive/supabase_migration.sql`
  - `_archive/SYNC_ORCHESTRATION_GOOGLE.md`
  - `_archive/IDENTITY_FLOW_FINAL_SUPABASE.md`

## Règles de gouvernance documentaire
- Un seul document canonique par sujet. Si un nouveau document remplace un existant, déplacer l’ancien dans `_archive/` et ajouter un lien/renvoi croisé.
- Préfixer les documents normatifs d’invariants par « Invariants » et mentionner la date de mise à jour en tête.
- Les liens internes doivent pointer vers les fichiers canoniques listés ci‑dessus.
- Toute décision irréversible doit être explicitement listée dans le document concerné.

## Prochaines actions (recommandé)
- Vérifier et mettre à jour les renvois internes dans les documents conservés vers `identity/INVARIANTS_IDENTITE_PERSISTENCE.md`.
- Ajouter, si nécessaire, une page "Glossaire" centralisée pour `player_uid`, `partie_id`, `snapshot`, `rev`.
- Compléter la section "Tests E2E" dans `tests/E2E_PLAN.md` avec les nouveaux invariants d'identité & persistance.
