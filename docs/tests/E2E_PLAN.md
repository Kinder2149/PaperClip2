# Plan E2E — Identité / Cloud / Social / UX (Paperclip)

Objectif: exécuter la batterie E2E et consigner les résultats OK/KO, pour statuer Go/Stop.

## Scénarios

- [ ] Identité & Sessions
  - [ ] Connexion Play Games
  - [ ] Activation "Synchronisation cloud"
  - [ ] Message succès: "Session cloud prête."
  - [ ] Désactivation sans effet de bord

- [ ] Cloud Save
  - [ ] Publication d'une sauvegarde locale
  - [ ] Listing des révisions
  - [ ] Import d'une révision (confirmation explicite)
  - [ ] Blocage si `lastSavedAt` manquant (erreur propre)

- [ ] Conflits
  - [ ] Local plus récent → keepLocalCreateNewRevision
  - [ ] Cloud plus récent → importCloudReplaceLocal
  - [ ] Égalité/Absence → undecided

- [ ] Amis (Option A)
  - [ ] Ajout ami (UUID)
  - [ ] Listing amis
  - [ ] Erreur claire si pas d'OAuth actif
  - [ ] Isolation RLS (autre compte = liste vide)

- [ ] Offline / Online
  - [ ] OFFLINE: activation sync + tentative publication → aucun upload
  - [ ] ONLINE: préparation session cloud + publication OK

- [ ] Multi-device
  - [ ] A publie, B voit après session cloud OK
  - [ ] Aucune révision anonyme après activation

## Environnement

- Appareil(s) utilisés:
- Version app:
- Compte Google Play Games:
- Réseau:

## Observations

- Notes, captures, timestamps, anomalies:

## Décision finale

- [ ] Go
- [ ] Stop
