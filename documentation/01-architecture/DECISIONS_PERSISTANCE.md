# 🔒 DÉCISIONS DE PERSISTANCE — PAPERCLIP2

**Statut** : ✅ VERROUILLÉ  
**Date** : 16 janvier 2026  
**Dernière mise à jour** : 20 janvier 2026  
**Autorité** : Document de référence final

---

## 🎯 RÈGLE ABSOLUE : CLOUD = SOURCE DE VÉRITÉ UNIQUE

### Principe fondamental
Le cloud est **l'unique source de vérité** pour toutes les parties de jeu.  
Le stockage local est **un cache temporaire** post-login uniquement.

### Conséquences immédiates
- ❌ Aucune logique de "fusion" ou "arbitrage" entre local et cloud
- ❌ Aucune décision basée sur "le plus récent"
- ✅ Cloud always wins au login
- ✅ Push immédiat après chaque sauvegarde locale

---

## 📊 FLUX DE SYNCHRONISATION AUTOMATIQUE

### 1️⃣ Création d'un monde
```
Utilisateur crée "Monde Alpha"
  ↓
UUID généré : f4edf80a-139e-48b0-a32b-b4902a0ccdf5
  ↓
Sauvegarde locale (cache)
  ↓
Push cloud IMMÉDIAT (si authentifié)
  ↓
Monde disponible sur tous les appareils
```

### 2️⃣ Login utilisateur
```
Utilisateur se connecte
  ↓
Pull cloud AUTOMATIQUE de tous les mondes
  ↓
Écrasement du cache local
  ↓
Affichage dans WorldsScreen
```

### 3️⃣ Sauvegarde en jeu
```
GameState.save() appelé
  ↓
Écriture locale (cache)
  ↓
Push cloud IMMÉDIAT via pushCloudForState()
  ↓
Données synchronisées
```

### 4️⃣ Création hors-ligne
```
Utilisateur non authentifié crée un monde
  ↓
Sauvegarde locale uniquement
  ↓
Marquage pending_identity = true
  ↓
À la reconnexion : retryPendingCloudPushes()
  ↓
Push automatique vers cloud
```

---

## 🚫 AUCUNE ACTION MANUELLE REQUISE

### Ce que l'utilisateur NE DOIT JAMAIS faire
- ❌ Cliquer sur un bouton "Synchroniser"
- ❌ Choisir entre "local" ou "cloud"
- ❌ Résoudre des conflits manuellement
- ❌ Télécharger manuellement ses mondes

### Ce qui se passe automatiquement
- ✅ Sync au login (pull complet)
- ✅ Sync à la création (push immédiat)
- ✅ Sync à la sauvegarde (push immédiat)
- ✅ Retry automatique après reconnexion

---

## 🔧 GESTION DES CAS EXCEPTIONNELS

### Hors-ligne (pas de connexion réseau)
**Comportement** :
- Création locale autorisée
- Marquage `pending_identity` dans SharedPreferences
- Message UI : "Connectez-vous pour activer la synchronisation cloud"
- Retry automatique à la prochaine connexion via `retryPendingCloudPushes()`

**L'utilisateur** :
- Est informé de l'état
- N'est PAS bloqué
- Ne fait AUCUNE action manuelle

### Erreur réseau temporaire
**Comportement** :
- `syncState.value = 'error'`
- Message UI : "Hors-ligne ou erreur réseau — certaines actions cloud indisponibles"
- Retry automatique au prochain appel

### Token JWT expiré
**Comportement** :
- `ApiClient` détecte 401
- `AuthService._callAuthenticatedApi` tente `signInWithGoogle(silent: true)`
- Si succès : nouveau token + retry de l'appel original
- Si échec : déconnexion + message de reconnexion

---

## 🏗️ ARCHITECTURE TECHNIQUE

### Composants clés
- **LocalSaveGameManager** : Cache local (SharedPreferences)
- **CloudPersistenceAdapter** : Communication HTTP avec backend FastAPI
- **GamePersistenceOrchestrator** : Orchestration save + cloud sync
- **SavesFacade** : API unifiée pour l'UI

### Flux de données
```
UI (WorldsScreen, GameState)
  ↓
SavesFacade
  ↓
GamePersistenceOrchestrator
  ↓ ↓
LocalSaveGameManager    CloudPersistenceAdapter
(cache temporaire)      (source de vérité)
```

### Identité unique
- **partieId** : UUID v4 généré à la création
- Immuable et unique
- Aucune clé métier basée sur le nom
- Une partie = un partieId

---

## ✅ VALIDATION FINALE

### Scénarios go/no-go
1. ✅ **Login → mondes visibles** : `syncAllWorldsFromCloud()` exécuté
2. ✅ **Création → reconnexion → monde présent** : `retryPendingCloudPushes()` fonctionne
3. ✅ **Modification → crash → données conservées** : push immédiat après save
4. ✅ **Hors ligne → reconnexion → monde récupéré** : `pending_identity` + retry auto

### Invariants garantis
- Cloud = vérité unique
- Local = cache post-login
- Sync automatique (zéro action manuelle)
- Aucune logique d'arbitrage ou fusion

---

## 🔗 RÉFÉRENCES

- `@documentation/01-architecture/persistance-cloud.md` : Architecture cloud-first
- `@documentation/02-guides-developpeur/flux-persistance.md` : Flux techniques
- `@lib/services/persistence/game_persistence_orchestrator.dart` : Implémentation

---

**FIN DU DOCUMENT — AUCUNE MODIFICATION SANS VALIDATION EXPLICITE**
