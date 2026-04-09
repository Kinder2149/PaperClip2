# 🔒 DÉCISIONS DE PERSISTANCE — PAPERCLIP2

**Statut** : ✅ VERROUILLÉ  
**Date** : 16 janvier 2026  
**Dernière mise à jour** : 20 janvier 2026  
**Autorité** : Document de référence final

---

## 🎯 DÉCISION FIGÉE : ENTREPRISE UNIQUE

### Principe fondamental (CHANTIER-01)
**1 utilisateur = 1 entreprise persistante**  
Le cloud est **l'unique source de vérité** pour l'entreprise.  
Le stockage local est **un cache temporaire** post-login uniquement.

### Conséquences immédiates
- ✅ Architecture entreprise unique (pas de multi-save)
- ✅ `enterpriseId` = UUID v4 généré une fois à la création
- ✅ Cloud always wins au login
- ✅ Push immédiat après chaque sauvegarde locale
- ❌ Aucune logique de "fusion" ou "arbitrage"

---

## 📊 FLUX DE SYNCHRONISATION AUTOMATIQUE

### 1️⃣ Création d'une entreprise
```
Utilisateur crée "Mon Entreprise"
  ↓
UUID généré : f4edf80a-139e-48b0-a32b-b4902a0ccdf5
  ↓
Sauvegarde locale (cache)
  ↓
Push cloud IMMÉDIAT vers /enterprise/{uid}
  ↓
Entreprise disponible sur tous les appareils
```

### 2️⃣ Login utilisateur
```
Utilisateur se connecte avec Firebase
  ↓
Pull cloud AUTOMATIQUE de l'entreprise
  ↓
Écrasement du cache local (cloud always wins)
  ↓
Chargement dans MainScreen
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
Utilisateur non authentifié crée une entreprise
  ↓
Sauvegarde locale uniquement
  ↓
Marquage pending_identity = true
  ↓
À la reconnexion : retryPendingCloudPushes()
  ↓
Push automatique vers /enterprise/{uid}
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
- **CloudPersistenceAdapter** : Communication HTTP avec `/enterprise/{uid}`
- **GamePersistenceOrchestrator** : Orchestration save + cloud sync

### Flux de données
```
UI (MainScreen, GameState)
  ↓
GamePersistenceOrchestrator
  ↓ ↓
LocalSaveGameManager    CloudPersistenceAdapter
(cache temporaire)      (source de vérité)
```

### Identité unique
- **enterpriseId** : UUID v4 généré à la création de l'entreprise
- Immuable et unique (ne change jamais)
- Stocké dans `snapshot.metadata.enterpriseId`
- 1 utilisateur = 1 entreprise (pas de multi-save)

---

## ✅ VALIDATION FINALE

### Scénarios go/no-go
1. ✅ **Login → entreprise visible** : Sync automatique au login
2. ✅ **Création → reconnexion → entreprise présente** : `retryPendingCloudPushes()` fonctionne
3. ✅ **Modification → crash → données conservées** : push immédiat après save
4. ✅ **Hors ligne → reconnexion → entreprise récupérée** : `pending_identity` + retry auto

### Invariants garantis
- Cloud = vérité unique
- Local = cache post-login
- Sync automatique (zéro action manuelle)
- Aucune logique d'arbitrage ou fusion

---

## 🔗 RÉFÉRENCES

- `persistance-cloud.md` : Architecture entreprise unique
- `ENTREPRISE-UNIQUE.md` : Référence complète entreprise unique
- `../02-guides-developpeur/GUIDE_COMPLET_SAUVEGARDE_CLOUD.md` : Guide complet

---

**FIN DU DOCUMENT — AUCUNE MODIFICATION SANS VALIDATION EXPLICITE**
