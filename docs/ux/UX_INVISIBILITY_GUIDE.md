# UX — Invisibilité Backend & Conformité (Play Store)

Objectif: garantir une expérience utilisateur claire, sans jargon technique, respectant les attentes implicites du Play Store.

## Principes

- Backend invisible (aucune mention de "Supabase", "JWT", etc.).
- Opt-in strict: aucune synchronisation automatique sans consentement explicite.
- Multi-device conditionné: nécessite connexion Google Play Games + session cloud prête.
- Zéro hypothèse silencieuse: messages explicites et compréhensibles.

## Wording recommandé

- Identité
  - État: "Connecté" / "Non connecté" (Google Play Games)
- Synchronisation
  - Libellé switch: "Synchronisation cloud (optionnelle)"
  - Info-bulle: "Pour activer la synchronisation multi‑appareils, connectez‑vous avec Google Play Games."
  - Messages
    - Succès: "Session cloud prête."
    - Erreur: "Connexion Google requise pour la synchronisation."
- Cloud Save
  - Publication: "Publier ma sauvegarde locale"
  - Listing: "Charger révisions cloud"
  - Import: confirmation explicite avant remplacement local
- Amis
  - Ajout manuel: demande d'un identifiant ami (UUID), sans exposer l'origine technique

## Parcours recommandé (contrôle)

1) Ouvrir Centre Google
2) (Optionnel) Se connecter Google Play Games
3) Activer "Synchronisation cloud (optionnelle)" (si souhaité)
4) Publier / Lister / Importer des révisions
5) Gérer les amis (optionnel)

## Checklist Conformité (Play Store)

- [ ] Aucun terme technique de backend dans l'UI
- [ ] Consentement explicite nécessaire avant toute synchronisation
- [ ] Messages d'erreur compréhensibles et orientés action
- [ ] Parcours cohérent avec le store listing

## Captures (à maintenir)

- Écran Centre Google (états: Non connecté / Connecté, Sync OFF / ON)
- Flux Publication / Listing / Import
- Ajout ami et listing
