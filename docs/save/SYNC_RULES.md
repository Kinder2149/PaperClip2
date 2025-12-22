# Règles de Synchronisation Cloud — Paperclip (Mission 4)

Objectif: permettre au joueur de retrouver sa partie sans risque. Le local reste maître. Toute action cloud requiert consentement explicite.

Références:
- Schéma local: `docs/save/SAVE_SCHEMA_V1.md`
- Modèle cloud: `docs/save/CLOUD_SAVE_MODEL.md`
- Identité: `docs/google/IDENTITY_LAYER.md`

Règles non négociables:
- Local > Cloud par défaut
- Choix utilisateur explicite (opt‑in)
- Aucune écriture cloud automatique destructrice

---

## 1) États et prérequis
- Identity.status ∈ {anonymous, signed_in, signed_in_sync_enabled}
- Seul `signed_in_sync_enabled` autorise des opérations cloud
- Le core local fonctionne intégralement hors‑ligne

---

## 2) Scénarios

### A) Nouvelle installation (même joueur)
1. L’utilisateur se connecte → status = signed_in
2. Il active la synchronisation → status = signed_in_sync_enabled
3. L’app affiche les révisions cloud disponibles (liste).
4. L’utilisateur choisit explicitement "Importer":
   - `GET /cloudsave/{id}`
   - Appliquer le snapshot localement (en respectant SAVE_SCHEMA_V1)
   - Aucune suppression cloud

### B) Multi‑device (appareil B)
1. Même prérequis (sign‑in + opt‑in)
2. L’appareil B liste les révisions cloud
3. L’utilisateur choisit:
   - Importer une révision cloud (remplace l’état local B) — non destructif côté cloud
   - OU conserver l’état local B et ignorer le cloud

### C) Conflit (appareil A et B ont tous deux avancé)
- Local > Cloud par défaut
- L’application propose:
  1) Conserver le local et créer une nouvelle révision cloud (append‑only)
  2) Importer une révision cloud choisie par l’utilisateur
  3) Comparer (diff résumé: money/paperclips/autoClipperCount/level) avant décision
- Aucune écriture destructrice sur le cloud: chaque push crée une nouvelle révision

---

## 3) Opérations (conceptuelles)
- Pull (Importer): `GET /cloudsave` (liste) → `GET /cloudsave/{id}` (snapshot)
- Push (Publier): `POST /cloudsave` (append‑only) → associer owner, timestamps, displayData
- Label (facultatif): `PUT /cloudsave/{id}/label` (favorite/current)

---

## 4) Politique d’affichage & consentement
- Jamais de push/pull silencieux
- Boutons explicites: "Importer une sauvegarde cloud", "Publier ma sauvegarde locale"
- Avertissement avant toute importation qui écrase l’état local courant

---

## 5) Arbitrage, intégrité, résilience
- Arbitrage: priorité au local pour toute ambiguïté
- Intégrité: validation snapshot avant application (structure, types), sinon refuser l’import
- Résilience: en cas d’échec réseau, aucune mutation locale irréversible
- Historisation cloud: conserver les dernières N révisions (append‑only), nettoyage serveur à définir

---

## 6) Télémétrie (informative)
- Journaliser: import/push/date/révision choisie, sans PII
- Surface UI: dates, device, version app, displayData pour aider la décision

---

## 7) Déploiement progressif
- Phase 1: lecture (pull) seule
- Phase 2: écriture (push) append‑only
- Phase 3: label "favorite/current"

Ce document cadre la synchronisation sans imposer d’implémentation. Toute opération reste opt‑in et non destructrice, en conformité avec SAVE_SCHEMA_V1 et l’Identity Layer.
