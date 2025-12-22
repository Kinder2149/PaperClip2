# Validation Globale — Missions 0 → 6 (Mission 7)

Objectif: vérifier la cohérence architecture, l'absence de dette majeure, et le respect des audits initiaux avant toute implémentation.

Références clés
- Progression/Événements: `docs/progression/GAME_EVENTS_REFERENCE.md`, `docs/progression/PROGRESSION_CURVE_REFERENCE.md`
- Sauvegarde locale: `docs/save/SAVE_SCHEMA_V1.md`
- Identité Google: `docs/google/IDENTITY_LAYER.md`
- Mapping PG: `docs/google/ACHIEVEMENTS_MAPPING.md`, `docs/google/LEADERBOARDS_MAPPING.md`
- Cloud Save: `docs/save/CLOUD_SAVE_MODEL.md`, `docs/save/SYNC_RULES.md`
- Orchestration: `docs/google/SYNC_ORCHESTRATION.md`
- UX: `docs/ux/GOOGLE_FEATURES_UX.md`
- Architecture (Clean): `docs/ARCHITECTURE.md`

---

## 1) Cohérence Architecture (OK)
- Clean Architecture respectée: core local (snapshot) distinct de l'UI, de l'orchestrateur et des adapters.
- "Source de vérité": réaffirmée dans SAVE_SCHEMA_V1; le cloud est append‑only, récepteur passif.
- Identité découplée: identité ≠ save; statut `signed_in_sync_enabled` comme condition nécessaire & suffisante pour la sync.
- Orchestrateur: routeur/cadenceur, dépend d'interfaces; aucune dépendance inverse du core.

Conclusion: **OK** — L'empilement est cohérent et prêt pour une implémentation incrémentale.

---

## 2) Respect des audits initiaux (OK)
- Événements normalisés couvrent missions & courbe: onboarding → marché → upgrades → automatisation → maîtrise → endgame.
- Aucune redéfinition des audits: uniquement formalisation/mapping.
- UX: opt‑in, local > cloud, confirmations — en ligne avec les contraintes.

Conclusion: **OK** — Les documents prolongent les audits sans les altérer.

---

## 3) Dette & Risques (mineurs, documentaires)
- Typologie des "crises marché": à préciser si plusieurs niveaux d'intensité existent (documentaire uniquement).
- Définition exacte du score composite (Classement Général): formule à geler (normalisation & poids) — pas bloquant.
- Détails retry/orchestration: paramètres (fenêtres, caps) à acter au moment de l'implémentation — principes déjà fixés.

Conclusion: **Accepter tel quel**; les points ouverts sont cadrés et non bloquants.

---

## 4) Checklist de validation
- [x] Architecture cohérente, séparation nette des responsabilités
- [x] Local maître (snapshot V1), cloud append‑only, pas d'écrasement
- [x] Identité Google: surcouche optionnelle, statuts & transitions définis
- [x] Événements normalisés → Succès/Classements (mapping fourni)
- [x] Règles de sync: opt‑in, scénarios (nouvelle install, multi‑device, conflit)
- [x] Orchestration: files locales, retry, idempotence, throttling
- [x] UX: messages FR, états visibles, actions manuelles, confirmations
- [x] Aucun code produit, aucun couplage Google imposé au core

---

## 5) Plan Global — Mise à jour finale (incrémental, sans surprise)

Phase A — Préparation technique (sans code métier)
- Geler interfaces (IdentityFacade, Orchestrator queues, Adapters Google/Cloud) — spécifications détaillées
- Définir DTO d'échange (succès, scores, cloudsave) alignés aux docs

Phase B — Implémentation minimale (derrière feature flag)
- IdentityFacade (état/consentement) + écrans UX (Centre de contrôle)
- Orchestrator skeleton + files locales (persistance simple), **sans émission** (lecture/preview seulement)

Phase C — Émissions PG opt‑in
- Activer l'envoi Achievements/Leaderboards pour un sous‑ensemble restreint
- Retry, throttling et journaux locaux

Phase D — Cloud Save (pull→push)
- Import (pull) des révisions cloud (prévisualisation + confirmation)
- Push append‑only sur action utilisateur + label "favorite"

Phase E — Consolidation
- Ajustements UX (accessibilité, i18n), paramètres retry, analytics de pilotage

Critères de sortie: aucune régression gameplay, latency UI stable, aucune action réseau silencieuse, logs propres.

---

## 6) Conclusion
L'ensemble documentaire Missions 0→6 est **cohérent** et **suffisant** pour démarrer une implémentation par phases, sans risque pour le core local. Les points ouverts sont mineurs et tracés. Recommandation: valider ce rapport et passer à la phase de spécification d'interfaces/DTO (Phase A du plan).
