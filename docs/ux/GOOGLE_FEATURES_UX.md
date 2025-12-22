# UX Google — Compréhension & Sécurité (Mission 6)

Objectif: rendre les fonctionnalités Google (identité, succès, classements, sauvegarde cloud) compréhensibles et sûres, sans modifier le gameplay ni le core local.

Principes non négociables
- Opt‑in explicite pour toute fonctionnalité connectée
- Local > Cloud par défaut
- Jamais d’action silencieuse (pas d’upload/pull automatique destructeur)
- Messages FR, simples, non techniques

---

## 1) États visibles (centre de contrôle)

- Identité
  - Anonymous: « Non connecté »
  - Signed‑in: « Connecté à Google »
  - Sync enabled: « Synchronisation cloud activée »

- Synchronisation
  - Achievements: files en attente N, derniers résultats (✓/! horodatés)
  - Classements: files en attente N, derniers résultats (✓/!)
  - Sauvegarde cloud: révisions disponibles (liste), statut dernier push (✓/!)

- Résumé local (lecture seule)
  - Nom de la sauvegarde locale, date dernière sauvegarde, version app

---

## 2) Actions manuelles

- Identité
  - Se connecter / Se déconnecter
  - Activer / Désactiver la synchronisation cloud (consentement)

- Succès & Classements (Google = récepteur passif)
  - Publier mes succès / scores (envoi de la file, avec résumé)
  - Voir l’historique des tentatives (journal simplifié)

- Sauvegarde cloud
  - Importer une sauvegarde (liste → prévisualisation → confirmation)
  - Publier ma sauvegarde locale (append‑only, confirmation)
  - Marquer une révision « favorite » (non destructeur)

- Maintenance
  - Réessayer les envois en échec
  - Purger les files (confirmation forte)

---

## 3) Messages (exemples FR)

- Connexion
  - « Connectez‑vous pour activer les succès, classements et la synchronisation cloud. »
  - « Synchronisation inactive: vous pouvez jouer 100% hors‑ligne. »

- Publications
  - Succès/scores: « X éléments en file. Publier maintenant ? »
  - Sauvegarde: « Publier une nouvelle révision cloud ? (aucun écrasement) »

- Import cloud
  - « Choisissez une sauvegarde cloud à importer. Votre état local sera remplacé. Continuer ? »
  - Prévisualisation: argent, trombones, autoclippers, niveau, date

- Erreurs & Retry
  - « Publication échouée (réseau). Réessayer dans 5 min. »
  - « Succès déjà débloqué — ignoré. »

- Confirmations fortes
  - Purge file: « Supprimer définitivement X éléments en file ? »
  - Désactiver sync: « La synchronisation est désactivée. Votre progression reste locale. »

---

## 4) Écrans & composants

- Centre de contrôle (écran unique)
  - Sections: Identité • Succès/Classements • Sauvegarde Cloud • Journal
  - Boutons: Se connecter • Activer la sync • Publier succès/scores • Publier sauvegarde • Importer • Réessayer • Purger

- Listes & cartes
  - Révisions cloud: carte avec date, version, résumé (displayData) et actions (Importer, Favori)
  - Files d’attente: compteur + dernier état (✓/! avec date)

- Prompts
  - Dialogs de confirmation pour actions sensibles (import/purge/publish)

---

## 5) Scénarios clés (parcours UX)

- Nouvelle installation
  1. L’utilisateur joue hors‑ligne (aucun blocage)
  2. Il ouvre Centre de contrôle → Se connecter → Activer sync (optionnel)
  3. Il choisit d’importer une sauvegarde cloud (liste + prévisualisation + confirmation)

- Multi‑device
  1. Même parcours; sur le 2e appareil, il peut Importer une révision cloud ou Publier la locale
  2. Aucune écriture cloud destructrice (append‑only)

- Conflit
  1. Centre de contrôle → Comparer (résumés) → Choisir: Conserver local & Publier ou Importer cloud
  2. Toujours confirmation claire avant remplacement local

---

## 6) Sécurité & ergonomie

- Toujours explicite: aucune action réseau sans bouton
- Labels clairs (FR), unités et formats lisibles
- Affichage des dates/versions pour guider les choix
- Journal minimal (dernier statut par type et horodatage)

---

## 7) Accessibilité & internationalisation

- Textes FR par défaut; prévoir i18n ultérieurement
- Couleurs/icônes cohérentes (✓ succès, ! attention)
- Boutons suffisamment espacés, confirmations pour actions critiques

---

## 8) Points d’alignement avec l’architecture

- L’UX consomme l’état: IdentityFacade, Orchestrateur (statuts de files), listes cloud
- Aucune dépendance UI → Domain
- Respect strict: core local maître, Google = récepteur passif, sync opt‑in
