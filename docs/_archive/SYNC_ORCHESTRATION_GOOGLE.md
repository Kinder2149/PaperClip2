# Orchestration & Synchronisation — Paperclip (Mission 5)

Objectif: coordonner identité, succès, scores et sauvegarde sans dépendances croisées. Aucune logique automatique intrusive; tout est opt‑in et découplé.

Références:
- Identité: `docs/google/IDENTITY_LAYER.md`
- Événements & courbe: `docs/progression/GAME_EVENTS_REFERENCE.md`, `docs/progression/PROGRESSION_CURVE_REFERENCE.md`
- Succès & Classements: `docs/google/ACHIEVEMENTS_MAPPING.md`, `docs/google/LEADERBOARDS_MAPPING.md`
- Sauvegarde: `docs/save/SAVE_SCHEMA_V1.md`, `docs/save/CLOUD_SAVE_MODEL.md`, `docs/save/SYNC_RULES.md`

Principes:
- Couplage minimal: chaque sous-système vit séparément; l’orchestrateur ne fait que router et cadencer.
- Opt‑in strict: pas d’émission sans `signed_in_sync_enabled`.
- Robustesse: files d’attente locales, retry exponentiel borné, idempotence.

---

## 1) Rôle de l’Orchestrateur (conceptuel)
- Observer les événements normalisés (jeu) et les mettre en file d’attente locale (persistée) pour:
  - Tentatives de déblocage Succès (Achievements)
  - Soumissions de scores (Leaderboards)
  - Opérations Cloud Save (push/pull) déclenchées par l’utilisateur
- Appliquer des politiques de cadence: throttling, batch, fenêtres calmes (ex: fin de session)
- Respecter l’état d’identité et les règles de synchronisation

---

## 2) Files d’attente locales
- Trois files séparées (conceptuellement):
  - `queue_achievements` (événements à tenter de publier)
  - `queue_leaderboards` (métriques à soumettre)
  - `queue_cloudsave` (push cloud demandés)
- Format de message (exemple générique):
```json
{
  "id": "local-uuid",
  "type": "achievement|leaderboard|cloudsave",
  "createdAt": "2025-12-20T10:00:00Z",
  "payload": { /* conforme aux docs de mapping ou au CLOUD_SAVE_MODEL */ },
  "attempts": 0,
  "lastError": null
}
```
- Persistance locale (clé-valeur ou fichier) — hors scope implémentation, l’invariant est la stabilité du format.

---

## 3) Retry & politiques d’envoi
- Conditions préalables:
  - `Identity.status == signed_in_sync_enabled`
  - Connectivité réseau OK
- Retry exponentiel borné (ex: 1m, 5m, 30m, 2h; max 5 tentatives)
- Idempotence:
  - Achievements: ignorer si déjà déverrouillé côté Google
  - Leaderboards: soumettre la meilleure valeur (ou la plus récente selon le cas)
  - Cloud Save: append‑only; si serveur renvoie un conflit, créer une nouvelle révision
- Throttling: limiter les pulsations (ex: pas plus de X envois/minute par type)

---

## 4) Conditions de synchronisation
- Déclencheurs manuels:
  - Bouton "Publier mes succès/scores"
  - Bouton "Publier ma sauvegarde locale"
- Déclencheurs contextuels (optionnels, non automatiques):
  - Fin de session (dialog de sortie avec options explicites)
- Jamais de push/pull silencieux

---

## 5) Sécurité & Observabilité
- Journaliser localement: envois, succès/échecs, derniers codes erreur anonymisés
- Surface UI simple: statut de sync (OK / en attente / erreurs), nombre d’éléments en file, actions de purge/retry manuel
- Diagnostics: expose une commande “Test de connectivité Google”, sans émettre de données de jeu

---

## 6) Diagramme opérationnel
```
Événements Jeu → Orchestrateur → Files locales → (conditions OK) → Adapters Google (Achievements/Leaderboards)
                                                ↘ (opt‑in cloud) → API Cloud Save (append‑only)
```

---

## 7) Gouvernance des dépendances
- L’orchestrateur dépend seulement de:
  - IdentityFacade (état/consentement)
  - Event stream normalisé (jeu)
  - Adapters concrets (Google / Cloud) via interfaces
- Le core local (GameState/Snapshot) ne dépend pas de l’orchestrateur.

---

## 8) Phasage de déploiement
- Phase 1: Achievements/Leaderboards en lecture/filtrage local (prévisualisation) — aucune émission
- Phase 2: Émission manuelle de quelques succès/leaderboards (file locale + retry)
- Phase 3: Cloud Save push/pull, append‑only, avec UI de comparaison
- Phase 4: Batches, throttling avancé et dashboards d’état
