# Couche Identité Google — Cadrage (Mission 2)

Objectif: définir comment un joueur est identifié, sans toucher au gameplay ni au core local. Aucune dépendance directe avec la sauvegarde, aucun automatisme forcé.

## 1. Modèle conceptuel

- Joueur local (Local Player)
  - Identité minimale, hors-ligne
  - Porte l’état de jeu (save locale) — mais l’identité n’est pas la save
  - Stable sans réseau et sans Google

- Joueur connecté (Google Identity)
  - Identité fédérée via Google Sign-In / Play Games
  - Porte uniquement des identifiants externes (accountId, playerId, displayName, avatarUrl)
  - Ne remplace pas l’identité locale; sert de surcouche

- Principe clé: **Couplage faible**
  - Le core local reste maître; l’identité Google est un attribut optionnel qui permet la synchronisation cloud et les services sociaux (succès, classements)

## 2. États de l’identité

- Non connecté
  - Aucun identifiant Google disponible
  - Jeu 100% local, toutes fonctionnalités offline
  - Aucun push cloud, aucune lecture cloud

- Connecté
  - Identifiant Google valide (session active)
  - Succès/classements peuvent être utilisés côté client (si explicitement déclenchés par l’utilisateur)
  - Pas d’upload automatique de la save

- Connecté + synchronisable
  - Identité Google présente ET consentement/paramètre activé pour la synchronisation
  - Autorise des opérations de synchronisation (push/pull) sur demande
  - Le local reste la source de vérité (arbitrage local en cas de conflit)

## 3. Interfaces et responsabilités (conceptuelles)

- IdentityFacade (UI / Application)
  - Expose l’état: `status = {anonymous | signed_in | signed_in_sync_enabled}`
  - Expose les métadonnées: `playerId`, `displayName`, `avatarUrl`
  - Événements utilisateur: `signIn`, `signOut`, `toggleSync(bool enabled)`
  - Ne touche ni au gameplay ni à la save

- PlayGamesAdapter (Infrastructure)
  - Fournit `signIn()` / `getProfile()` / `isSignedIn()`
  - Fournit des capacités sociales (succès/classements) indépendantes du système de sauvegarde

- SyncController (Application) — hors scope implémentation, cadrage seulement
  - N’opère que si `IdentityFacade.status == signed_in_sync_enabled`
  - Médiateur entre core local (snapshot) et couche réseau (plus tard)

## 4. Diagramme de couches (simplifié)

```
Presentation (UI)
  └─ IdentityFacade ───────────────┐
                                   │ expose état identité (pas de save)
Application                         │
  └─ SyncController (opt-in) ◄─────┘ dépend de l’état identité

Infrastructure
  └─ PlayGamesAdapter (Google)  ←→  Services Google (Sign-In / Play Games)

Domain / Core Local
  └─ GameState / Snapshot  (Source de vérité locale, indépendante)
```

## 5. Règles de non‑couplage
- Aucune référence à la save dans l’IdentityFacade
- Aucun déclenchement automatique de synchronisation lors d’un sign-in
- Toute action cloud doit être explicitement déclenchée (ex: bouton « Synchroniser »)

## 6. Données d’identité (conceptuelles)
- `playerId` (Google Play Games ID)
- `displayName`
- `avatarUrl`
- `signInProvider` (google)
- `status` ∈ {anonymous, signed_in, signed_in_sync_enabled}

## 7. Transitions d’état
- anonymous → signed_in: réussite du sign-in Google (action explicite)
- signed_in → signed_in_sync_enabled: l’utilisateur active la sync (paramètre/consentement)
- signed_in_* → anonymous: sign-out explicite ou échec critique d’auth

## 8. Vérifications (Mission 2)
- Aucun lien direct avec la save: ✔
- Aucun automatisme forcé: ✔
- Gameplay inchangé: ✔
- Core local maître confirmé: ✔
