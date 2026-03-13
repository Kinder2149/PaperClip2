# 📘 GUIDE COMPLET - SYSTÈME DE SAUVEGARDE ET CLOUD

**Date** : 15 janvier 2026  
**Dernière mise à jour** : 20 janvier 2026  
**Version** : 1.0  
**Application** : PaperClip2

---

## 🎯 INTRODUCTION

Ce guide explique de façon complète comment fonctionne le système de sauvegarde, le cloud, les mondes et le flux utilisateur de l'application PaperClip2.

---

## 📋 TABLE DES MATIÈRES

1. [Concepts fondamentaux](#concepts-fondamentaux)
2. [Architecture du système](#architecture-du-système)
3. [Les mondes (parties)](#les-mondes-parties)
4. [Système de sauvegarde locale](#système-de-sauvegarde-locale)
5. [Système de synchronisation cloud](#système-de-synchronisation-cloud)
6. [Flux utilisateur complet](#flux-utilisateur-complet)
7. [Choix techniques et justifications](#choix-techniques-et-justifications)

---

## 🧩 CONCEPTS FONDAMENTAUX

### Modèle Cloud-First

**Principe** : Le cloud est la source de vérité, le local est un cache temporaire.

```
┌─────────────────────────────────────────┐
│         MODÈLE CLOUD-FIRST              │
├─────────────────────────────────────────┤
│                                         │
│  ☁️ CLOUD (Source de vérité)           │
│     ↓                                   │
│  📱 LOCAL (Cache temporaire)            │
│                                         │
│  Toutes les parties disponibles         │
│  au login automatiquement               │
└─────────────────────────────────────────┘
```

**Conséquences** :
- ✅ Chaque partie est automatiquement sauvegardée au cloud
- ✅ L'utilisateur peut retrouver ses parties sur n'importe quel appareil
- ✅ Pas de perte de données si l'appareil est perdu/cassé
- ✅ Synchronisation automatique et transparente

---

### Identité unique : partieId (UUID v4)

**Principe** : Chaque monde a un identifiant unique universel.

```dart
// Exemple d'identifiant unique
partieId: "a5d1af60-bd44-4c9f-9531-0f394d44a318"
```

**Caractéristiques** :
- ✅ **UUID v4** : Identifiant universel unique (128 bits)
- ✅ **Généré automatiquement** : À la création du monde
- ✅ **Immuable** : Ne change jamais pendant toute la vie du monde
- ✅ **Pas de collision** : Probabilité de doublon quasi nulle
- ✅ **Pas de clé métier** : Indépendant du nom du monde

**Pourquoi UUID v4 ?**
- ✅ Génération côté client (pas besoin d'appeler le serveur)
- ✅ Unicité garantie même hors ligne
- ✅ Compatible avec tous les systèmes (mobile, web, backend)
- ✅ Standard universel (RFC 4122)

---

### Pas de slot global

**Principe** : Une partie = un partieId unique.

**Ancien modèle (rejeté)** :
```
❌ Slot 1 : "Ma partie"
❌ Slot 2 : "Test"
❌ Slot 3 : "Partie avancée"
```

**Nouveau modèle (actuel)** :
```
✅ partieId: a5d1af60... → "Ma partie"
✅ partieId: f4edf80a... → "Test"
✅ partieId: fffbcc22... → "Partie avancée"
```

**Avantages** :
- ✅ Nombre illimité de parties (pas de limite de slots)
- ✅ Pas de conflit de noms
- ✅ Synchronisation cloud simplifiée
- ✅ Gestion des backups claire

---

## 🏗️ ARCHITECTURE DU SYSTÈME

### Vue d'ensemble

```
┌─────────────────────────────────────────────────────────┐
│                    UTILISATEUR                          │
└────────────────────┬────────────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────────────┐
│                  INTERFACE UI                           │
│  - WorldsScreen (liste des mondes)                      │
│  - WorldCard (affichage d'un monde)                     │
│  - GameScreen (jeu en cours)                            │
└────────────────────┬────────────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────────────┐
│               COUCHE MÉTIER                             │
│  - GameState (état du jeu)                              │
│  - SavesFacade (façade de sauvegarde)                   │
│  - SaveManager (gestionnaire de sauvegarde)             │
└────────────────────┬────────────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────────────┐
│          ORCHESTRATEUR DE PERSISTANCE                   │
│  - GamePersistenceOrchestrator                          │
│    • File de priorités                                  │
│    • Coalescing (fusion des sauvegardes)               │
│    • Arbitrage local/cloud                              │
└────────────┬───────────────────────┬────────────────────┘
             │                       │
             ↓                       ↓
┌────────────────────┐    ┌─────────────────────┐
│  STOCKAGE LOCAL    │    │   STOCKAGE CLOUD    │
│  SharedPreferences │    │  Firebase Functions │
│  (Cache)           │    │  (Source de vérité) │
└────────────────────┘    └─────────────────────┘
```

---

### Composants principaux

#### 1. **GameState** (État du jeu)
- **Rôle** : Contient toutes les données du jeu en cours
- **Données** : Trombones, argent, upgrades, statistiques, etc.
- **Méthode clé** : `toSnapshot()` → Crée un instantané complet du jeu

#### 2. **SavesFacade** (Façade de sauvegarde)
- **Rôle** : Point d'entrée unique pour toutes les opérations de sauvegarde
- **Méthodes** :
  - `listEntries()` : Liste tous les mondes
  - `canonicalStateFor()` : État de synchronisation d'un monde
  - `setCloudEnabled()` : Active/désactive le cloud

#### 3. **GamePersistenceOrchestrator** (Orchestrateur)
- **Rôle** : Gère la file de sauvegarde et la synchronisation cloud
- **Responsabilités** :
  - File de priorités (manual > lifecycle > auto)
  - Coalescing (fusion des sauvegardes identiques)
  - Arbitrage local/cloud (qui est le plus récent ?)
  - Push/pull cloud automatique

#### 4. **LocalSaveGameManager** (Gestionnaire local)
- **Rôle** : Stockage local dans SharedPreferences
- **Données stockées** :
  - Métadonnées (nom, date, mode de jeu)
  - Snapshot complet (état du jeu)

#### 5. **CloudPersistenceAdapter** (Adaptateur cloud)
- **Rôle** : Communication avec le backend Firebase Functions
- **Opérations** :
  - `pushById()` : Envoyer un monde au cloud
  - `pullById()` : Récupérer un monde du cloud
  - `statusById()` : Vérifier l'état d'un monde au cloud
  - `listCloudParties()` : Lister tous les mondes au cloud

---

## 🌍 LES MONDES (PARTIES)

### Qu'est-ce qu'un monde ?

Un **monde** (ou **partie**) est une session de jeu complète et indépendante.

**Caractéristiques** :
- ✅ Identifiant unique (`partieId` UUID v4)
- ✅ Nom personnalisable (ex: "Ma partie", "Test")
- ✅ Mode de jeu (INFINITE, TIMED, etc.)
- ✅ État complet du jeu (trombones, argent, upgrades, etc.)
- ✅ Historique (date de création, dernière modification)

---

### Cycle de vie d'un monde

```
┌─────────────────────────────────────────────────────────┐
│                  CYCLE DE VIE D'UN MONDE                │
└─────────────────────────────────────────────────────────┘

1. CRÉATION
   ↓
   Utilisateur clique "Nouveau monde"
   ↓
   GameState.startNewGame()
   ↓
   Génération UUID v4 → partieId
   ↓
   Initialisation des données (trombones=0, argent=0, etc.)
   ↓
   Log : [world_create_after] worldId=xxx

2. PREMIÈRE SAUVEGARDE
   ↓
   Utilisateur clique "Sauvegarder" ou met l'app en pause
   ↓
   Sauvegarde locale (SharedPreferences)
   ↓
   Push cloud automatique (si connecté)
   ↓
   Log : [world_save_done] worldId=xxx
   Log : [cloud_success] pushCloudById

3. MODIFICATIONS
   ↓
   Utilisateur joue (produit des trombones, achète des upgrades)
   ↓
   Auto-save périodique (toutes les X secondes)
   ↓
   Sauvegarde locale uniquement (pas de push cloud)

4. PAUSE APP / BACKGROUND
   ↓
   Utilisateur met l'app en pause ou passe à une autre app
   ↓
   Lifecycle save (priorité normale)
   ↓
   Sauvegarde locale + Push cloud direct
   ↓
   Log : [cloud_start] reason=lifecycle:app_lifecycle_paused

5. CHANGEMENT DE MONDE
   ↓
   Utilisateur retourne à la liste et sélectionne un autre monde
   ↓
   Sauvegarde du monde actuel
   ↓
   Chargement du nouveau monde
   ↓
   Log : [world_switch_before] → [world_switch_after]

6. SUPPRESSION
   ↓
   Utilisateur supprime le monde
   ↓
   Suppression locale + Suppression cloud
   ↓
   Monde définitivement supprimé
```

---

### Création d'un monde (code)

```dart
// lib/models/game_state.dart

Future<void> startNewGame({
  String? customName,
  GameMode mode = GameMode.INFINITE,
}) async {
  // 1. Générer un UUID v4 unique
  final newPartieId = const Uuid().v4();
  
  // 2. Définir le nom du monde
  final worldName = customName ?? 'Partie ${DateTime.now().day}/${DateTime.now().month}';
  
  // 3. Initialiser l'état du jeu
  _partieId = newPartieId;
  _gameName = worldName;
  _gameMode = mode;
  
  // Réinitialiser toutes les données
  _money = 0;
  _paperclips = 0;
  _totalPaperclipsSold = 0;
  // ... autres initialisations
  
  // 4. Logger la création
  _logger.info('[WORLD-CREATE] after', code: 'world_create_after', ctx: {
    'worldId': newPartieId,
    'name': worldName,
    'mode': mode.toString(),
  });
  
  // 5. Marquer comme initialisé
  _isInitialized = true;
  notifyListeners();
}
```

---

## 💾 SYSTÈME DE SAUVEGARDE LOCALE

### Stockage : SharedPreferences

**Principe** : Stockage clé-valeur persistant sur l'appareil.

**Structure des données** :
```
SharedPreferences
├── metadata_<partieId>  → Métadonnées (JSON)
│   ├── id: "a5d1af60..."
│   ├── name: "Ma partie"
│   ├── gameMode: "INFINITE"
│   ├── lastModified: "2026-01-15T21:30:00Z"
│   └── version: "1.0.0"
│
└── savedata_<partieId>  → Données complètes (JSON)
    └── gameSnapshot: { ... }
        ├── metadata: { partieId, version, ... }
        ├── core: { money, paperclips, ... }
        ├── managers: { playerManager, marketManager, ... }
        └── stats: { totalPlayTime, totalPaperclipsSold, ... }
```

---

### Snapshot (instantané du jeu)

**Principe** : Capture complète de l'état du jeu à un instant T.

```dart
// lib/models/game_snapshot.dart

class GameSnapshot {
  final Map<String, dynamic> metadata;  // Identité (partieId, version)
  final Map<String, dynamic> core;      // Données essentielles (argent, trombones)
  final Map<String, dynamic> managers;  // État des managers (production, marché)
  final Map<String, dynamic> stats;     // Statistiques (temps de jeu, ventes)
  
  // Sérialisation JSON
  Map<String, dynamic> toJson() {
    return {
      'metadata': metadata,
      'core': core,
      'managers': managers,
      'stats': stats,
    };
  }
  
  // Désérialisation JSON
  factory GameSnapshot.fromJson(Map<String, dynamic> json) {
    return GameSnapshot(
      metadata: json['metadata'],
      core: json['core'],
      managers: json['managers'],
      stats: json['stats'],
    );
  }
}
```

**Avantages du snapshot** :
- ✅ Format standardisé et versionné
- ✅ Facile à sérialiser/désérialiser
- ✅ Compatible avec le cloud
- ✅ Permet la validation et la migration

---

### File de sauvegarde (priorités)

**Principe** : Les sauvegardes sont mises en file d'attente et traitées par priorité.

```
┌─────────────────────────────────────────────────────────┐
│              FILE DE SAUVEGARDE                         │
└─────────────────────────────────────────────────────────┘

PRIORITÉ HAUTE (traitée en premier)
├── Manual (utilisateur clique "Sauvegarder")
└── Backup (sauvegarde de secours)

PRIORITÉ NORMALE
├── Lifecycle (pause app, background)
└── Important Event (achat upgrade, milestone)

PRIORITÉ BASSE (traitée en dernier)
└── Auto-save (périodique, toutes les X secondes)
```

**Code** :
```dart
// lib/services/persistence/game_persistence_orchestrator.dart

enum SavePriority { low, normal, high }
enum SaveTrigger { autosave, importantEvent, lifecycle, manual, backup }

class SaveRequest {
  final SaveTrigger trigger;
  final SavePriority priority;
  final String slotId;  // partieId
  final bool isBackup;
  final DateTime requestedAt;
  final String? reason;
}

// Tri de la file par priorité puis ancienneté
void _pickNext() {
  _queue.sort((a, b) {
    final p = b.priority.index.compareTo(a.priority.index);
    if (p != 0) return p;
    return a.requestedAt.compareTo(b.requestedAt);
  });
  return _queue.removeAt(0);
}
```

---

### Coalescing (fusion des sauvegardes)

**Principe** : Éviter les sauvegardes redondantes en fusionnant les demandes identiques.

**Exemple** :
```
Sans coalescing :
├── Auto-save (monde A) à 10:00:00
├── Auto-save (monde A) à 10:00:01  ← Doublon !
├── Auto-save (monde A) à 10:00:02  ← Doublon !
└── Auto-save (monde A) à 10:00:03  ← Doublon !
→ 4 sauvegardes pour le même monde

Avec coalescing :
└── Auto-save (monde A) à 10:00:03  ← Une seule sauvegarde (la plus récente)
→ 1 sauvegarde
```

**Code** :
```dart
// Coalescing autosave : 1 seule autosave en attente par monde
if (request.trigger == SaveTrigger.autosave) {
  _queue.removeWhere((r) => 
    r.trigger == SaveTrigger.autosave && 
    r.slotId == request.slotId
  );
}

// Coalescing important events : 1 seul en attente par monde
if (request.trigger == SaveTrigger.importantEvent) {
  _queue.removeWhere((r) => 
    r.trigger == SaveTrigger.importantEvent && 
    r.slotId == request.slotId
  );
}
```

**Avantages** :
- ✅ Réduit la charge CPU
- ✅ Économise la batterie
- ✅ Évite les écritures inutiles

---

## ☁️ SYSTÈME DE SYNCHRONISATION CLOUD

### Backend : Firebase Functions

**Architecture** :
```
┌─────────────────────────────────────────────────────────┐
│                  BACKEND CLOUD                          │
└─────────────────────────────────────────────────────────┘

Firebase Functions (Node.js)
├── API REST (Express)
│   ├── PUT /worlds/:partieId  → Envoyer un monde
│   ├── GET /worlds/:partieId  → Récupérer un monde
│   ├── GET /worlds            → Lister tous les mondes
│   └── DELETE /worlds/:partieId → Supprimer un monde
│
├── Authentification (Firebase Auth)
│   └── Token JWT vérifié à chaque requête
│
├── Base de données (Firestore)
│   └── Collection "worlds"
│       └── Document <partieId>
│           ├── snapshot: { ... }  (état du jeu)
│           ├── playerId: "xxx"    (propriétaire)
│           ├── name: "Ma partie"
│           ├── gameVersion: "1.0.0"
│           ├── remoteVersion: 1   (numéro de version)
│           ├── createdAt: "..."
│           └── updatedAt: "..."
│
└── Rate Limiting
    ├── 100 requêtes/min par utilisateur
    └── 300 requêtes/min par IP
```

---

### Activation automatique du cloud

**Principe** : Le cloud est activé automatiquement quand l'utilisateur se connecte avec Firebase Auth.

```dart
// lib/main.dart

FirebaseAuthService.instance.authStateChanges().listen((user) async {
  if (user != null) {
    // Utilisateur connecté → Activer le cloud
    await facade.setCloudEnabled(true);
    
    // Déclencher la synchronisation
    final pid = _googleServices.identity.playerId;
    if (pid != null && pid.isNotEmpty) {
      await facade.onPlayerConnected(playerId: pid);
    }
  } else {
    // Utilisateur déconnecté → Désactiver le cloud
    await facade.setCloudEnabled(false);
  }
});
```

**Logs** :
```
[AUTH] Firebase user signed in (uid=xxx)
[AUTH] enabling cloud sync
[CLOUD] playerIdProvider → xxx
[CLOUD] onPlayerConnected(playerId=xxx)
```

---

### Arbitrage local/cloud

**Principe** : Comparer les timestamps pour déterminer quelle version est la plus récente.

```
┌─────────────────────────────────────────────────────────┐
│              ARBITRAGE LOCAL/CLOUD                      │
└─────────────────────────────────────────────────────────┘

Scénario 1 : Cloud plus récent
├── Local : 2026-01-15 10:00:00
├── Cloud : 2026-01-15 10:05:00  ← Plus récent
└── Action : PULL (importer le cloud)

Scénario 2 : Local plus récent
├── Local : 2026-01-15 10:10:00  ← Plus récent
├── Cloud : 2026-01-15 10:05:00
└── Action : PUSH (envoyer au cloud)

Scénario 3 : Égal
├── Local : 2026-01-15 10:05:00
├── Cloud : 2026-01-15 10:05:00  ← Identique
└── Action : NO-OP (rien à faire)

Scénario 4 : Première sauvegarde
├── Local : 2026-01-15 10:00:00  ← Existe
├── Cloud : null                 ← N'existe pas
└── Action : PUSH (envoyer au cloud)
```

**Code** :
```dart
// lib/services/persistence/game_persistence_orchestrator.dart

Future<void> _arbitrateFreshnessAndSync({
  required String partieId,
  GameState? state,
  String? playerId,
}) async {
  // 1. Récupérer timestamp local
  final localTs = await _getSaveMetadataByIdViaLocalManager(partieId);
  
  // 2. Récupérer timestamp cloud
  final status = await port.statusById(partieId: partieId);
  final cloudTs = status.exists ? status.lastSavedAt : null;
  
  // 3. Comparer et décider
  if (cloudTs != null && localTs != null) {
    if (cloudTs.isAfter(localTs)) {
      // Cloud plus récent → PULL
      await _importCloudObject(...);
    } else if (localTs.isAfter(cloudTs)) {
      // Local plus récent → PUSH
      await pushCloudFromSaveId(partieId: partieId, playerId: playerId);
    } else {
      // Égal → NO-OP
    }
  } else if (localTs != null && cloudTs == null) {
    // Première sauvegarde → PUSH
    await pushCloudFromSaveId(partieId: partieId, playerId: playerId);
  } else if (cloudTs != null && localTs == null) {
    // Monde cloud uniquement → PULL
    await _importCloudObject(...);
  }
}
```

---

### Push cloud (envoi)

**Principe** : Envoyer un monde au cloud.

```
┌─────────────────────────────────────────────────────────┐
│                  PUSH CLOUD                             │
└─────────────────────────────────────────────────────────┘

1. Vérifier que cloud_enabled = true
   ↓
2. Vérifier que playerId existe (utilisateur connecté)
   ↓
3. Charger le snapshot depuis le stockage local
   ↓
4. Récupérer le token Firebase Auth
   ↓
5. Envoyer la requête HTTP PUT au backend
   ↓
   PUT /worlds/<partieId>
   Headers:
     Authorization: Bearer <firebase_token>
   Body:
     {
       "snapshot": { ... },
       "name": "Ma partie",
       "gameVersion": "1.0.0"
     }
   ↓
6. Traiter la réponse
   ├── 200 OK → Succès
   ├── 409 Conflict → Conflit de version
   └── 401 Unauthorized → Token invalide
   ↓
7. Logger le résultat
   [cloud_success] pushCloudById | partieId=xxx
```

**Code** :
```dart
// lib/services/cloud/cloud_persistence_adapter.dart

Future<void> pushById({
  required String partieId,
  required Map<String, dynamic> snapshot,
  String? name,
}) async {
  // 1. Récupérer le token Firebase
  final token = await FirebaseAuthService.instance.getIdToken();
  if (token == null) throw StateError('No Firebase token');
  
  // 2. Préparer la requête
  final url = '$_baseUrl/worlds/$partieId';
  final body = {
    'snapshot': snapshot,
    'name': name ?? partieId,
    'gameVersion': GameConstants.VERSION,
  };
  
  // 3. Envoyer la requête
  final response = await _client.put(
    Uri.parse(url),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(body),
  );
  
  // 4. Traiter la réponse
  if (response.statusCode == 200) {
    _logger.info('[CLOUD-PUSH] SUCCESS', code: 'cloud_success');
  } else if (response.statusCode == 409) {
    throw CloudConflictException('Version conflict');
  } else {
    throw CloudException('Push failed: ${response.statusCode}');
  }
}
```

---

### Pull cloud (récupération)

**Principe** : Récupérer un monde depuis le cloud.

```
┌─────────────────────────────────────────────────────────┐
│                  PULL CLOUD                             │
└─────────────────────────────────────────────────────────┘

1. Vérifier que cloud_enabled = true
   ↓
2. Vérifier que playerId existe
   ↓
3. Récupérer le token Firebase Auth
   ↓
4. Envoyer la requête HTTP GET au backend
   ↓
   GET /worlds/<partieId>
   Headers:
     Authorization: Bearer <firebase_token>
   ↓
5. Traiter la réponse
   ├── 200 OK → Monde trouvé
   ├── 404 Not Found → Monde n'existe pas
   └── 401 Unauthorized → Token invalide
   ↓
6. Désérialiser le snapshot
   ↓
7. Sauvegarder en local
   ↓
8. Appliquer au GameState (si actif)
```

---

### Retry Policy (politique de réessai)

**Principe** : Réessayer automatiquement en cas d'échec réseau.

```
┌─────────────────────────────────────────────────────────┐
│              RETRY POLICY                               │
└─────────────────────────────────────────────────────────┘

Tentative 1
├── Échec réseau (timeout, connexion perdue)
├── Attendre 1 seconde
└── Log : [cloud_backoff] attempt=1 delay=1s

Tentative 2
├── Échec réseau
├── Attendre 2 secondes (backoff exponentiel)
└── Log : [cloud_backoff] attempt=2 delay=2s

Tentative 3
├── Échec réseau
├── Attendre 4 secondes
└── Log : [cloud_backoff] attempt=3 delay=4s

Tentative 4
└── Abandon → Marquer comme "erreur de sync"
```

**Code** :
```dart
// lib/services/cloud/cloud_retry_policy.dart

class CloudRetryPolicy {
  static const maxAttempts = 3;
  static const initialDelay = Duration(seconds: 1);
  
  Future<T> execute<T>(Future<T> Function() action) async {
    int attempt = 0;
    Duration delay = initialDelay;
    
    while (attempt < maxAttempts) {
      try {
        return await action();
      } catch (e) {
        attempt++;
        if (attempt >= maxAttempts) rethrow;
        
        _logger.info('[CLOUD-RETRY] backoff', code: 'cloud_backoff', ctx: {
          'attempt': attempt,
          'delay': delay.inSeconds,
        });
        
        await Future.delayed(delay);
        delay *= 2; // Backoff exponentiel
      }
    }
    
    throw Exception('Max retry attempts reached');
  }
}
```

---

## 👤 FLUX UTILISATEUR COMPLET

### Scénario 1 : Premier lancement (nouvel utilisateur)

```
┌─────────────────────────────────────────────────────────┐
│         PREMIER LANCEMENT (NOUVEL UTILISATEUR)          │
└─────────────────────────────────────────────────────────┘

1. Utilisateur lance l'app
   ↓
2. Écran d'accueil
   ├── Bouton "Connexion Google"
   └── Bouton "Jouer sans compte"
   ↓
3. Utilisateur clique "Connexion Google"
   ↓
4. Authentification Google + Firebase
   ↓
   [AUTH] Firebase user signed in (uid=xxx)
   [AUTH] enabling cloud sync
   ↓
5. Cloud sync activé automatiquement
   ↓
6. Écran "Liste des mondes" (vide)
   ├── Message : "Aucun monde. Créez-en un !"
   └── Bouton "Nouveau monde"
   ↓
7. Utilisateur clique "Nouveau monde"
   ↓
8. Dialogue de création
   ├── Champ : Nom du monde (ex: "Ma première partie")
   ├── Sélection : Mode de jeu (INFINITE, TIMED, etc.)
   └── Bouton "Créer"
   ↓
9. Création du monde
   ├── Génération UUID v4 → partieId
   ├── Initialisation GameState
   └── Log : [world_create_after] worldId=xxx
   ↓
10. Redirection vers le jeu
    ↓
11. Utilisateur joue (produit des trombones, achète des upgrades)
    ↓
12. Auto-save périodique (toutes les 30 secondes)
    ├── Sauvegarde locale uniquement
    └── Pas de push cloud (économie batterie)
    ↓
13. Utilisateur met l'app en pause (bouton Home)
    ↓
14. Lifecycle save
    ├── Sauvegarde locale
    ├── Push cloud automatique
    └── Log : [cloud_start] reason=lifecycle:app_lifecycle_paused
           [cloud_success] pushCloudById
    ↓
15. Monde sauvegardé au cloud ✅
```

---

### Scénario 2 : Utilisateur existant (changement d'appareil)

```
┌─────────────────────────────────────────────────────────┐
│    UTILISATEUR EXISTANT (CHANGEMENT D'APPAREIL)         │
└─────────────────────────────────────────────────────────┘

1. Utilisateur installe l'app sur un nouvel appareil
   ↓
2. Utilisateur se connecte avec Google (même compte)
   ↓
   [AUTH] Firebase user signed in (uid=xxx)
   [AUTH] enabling cloud sync
   ↓
3. Cloud sync activé
   ↓
4. Synchronisation automatique
   ├── Récupération de la liste des mondes depuis le cloud
   ├── Téléchargement des snapshots
   └── Sauvegarde en local (cache)
   ↓
5. Écran "Liste des mondes"
   ├── Monde 1 : "Ma première partie" (badge ☁️ À jour)
   ├── Monde 2 : "Test" (badge ☁️ À jour)
   └── Monde 3 : "Partie avancée" (badge ☁️ À jour)
   ↓
6. Utilisateur sélectionne "Ma première partie"
   ↓
7. Chargement du monde
   ├── Lecture du snapshot local (cache)
   ├── Application au GameState
   └── Log : [world_switch_after] worldId=xxx
   ↓
8. Utilisateur continue de jouer là où il s'était arrêté ✅
```

---

### Scénario 3 : Gestion de plusieurs mondes

```
┌─────────────────────────────────────────────────────────┐
│           GESTION DE PLUSIEURS MONDES                   │
└─────────────────────────────────────────────────────────┘

1. Utilisateur a 3 mondes existants
   ├── Monde A : "Partie principale" (en cours)
   ├── Monde B : "Test" (terminé)
   └── Monde C : "Expérimentation" (en cours)
   ↓
2. Utilisateur joue sur Monde A
   ↓
3. Utilisateur retourne à la liste des mondes
   ↓
   Sauvegarde automatique du Monde A
   ├── Sauvegarde locale
   └── Push cloud (si lifecycle)
   ↓
4. Utilisateur sélectionne Monde C
   ↓
   Chargement du Monde C
   ├── Lecture du snapshot local
   ├── Application au GameState
   └── Log : [world_switch_before] A → [world_switch_after] C
   ↓
5. Utilisateur joue sur Monde C
   ↓
6. Utilisateur retourne à la liste
   ↓
   Sauvegarde automatique du Monde C
   ↓
7. Utilisateur supprime Monde B
   ↓
   Dialogue de confirmation
   ├── "Êtes-vous sûr de vouloir supprimer 'Test' ?"
   └── Bouton "Supprimer"
   ↓
   Suppression
   ├── Suppression locale (SharedPreferences)
   ├── Suppression cloud (DELETE /worlds/B)
   └── Mise à jour de la liste
   ↓
8. Liste mise à jour
   ├── Monde A : "Partie principale"
   └── Monde C : "Expérimentation"
```

---

### Scénario 4 : Conflit de synchronisation

```
┌─────────────────────────────────────────────────────────┐
│           CONFLIT DE SYNCHRONISATION                    │
└─────────────────────────────────────────────────────────┘

Situation : Utilisateur a joué hors ligne sur 2 appareils

Appareil 1 (smartphone)
├── Monde A modifié à 10:00
└── Pas de connexion internet

Appareil 2 (tablette)
├── Monde A modifié à 10:05
└── Pas de connexion internet

Résolution :
1. Appareil 1 se reconnecte
   ↓
   Arbitrage : Local (10:00) vs Cloud (09:50)
   ↓
   Local plus récent → PUSH
   ↓
   Cloud mis à jour avec la version de l'appareil 1
   ↓
2. Appareil 2 se reconnecte
   ↓
   Arbitrage : Local (10:05) vs Cloud (10:00)
   ↓
   Local plus récent → PUSH
   ↓
   Cloud mis à jour avec la version de l'appareil 2
   ↓
3. Résultat : La version la plus récente (10:05) est conservée ✅
```

---

## 🎯 CHOIX TECHNIQUES ET JUSTIFICATIONS

### 1. Pourquoi UUID v4 ?

**Alternatives considérées** :
- ❌ Auto-increment (1, 2, 3, ...) → Collision possible, pas unique globalement
- ❌ Timestamp → Collision possible si création simultanée
- ❌ Nom du monde → Pas unique, peut changer

**Choix : UUID v4**
- ✅ Unique globalement (probabilité de collision quasi nulle)
- ✅ Généré côté client (pas besoin d'appeler le serveur)
- ✅ Fonctionne hors ligne
- ✅ Standard universel (RFC 4122)
- ✅ 128 bits (16 octets) → 2^128 combinaisons possibles

---

### 2. Pourquoi SharedPreferences ?

**Alternatives considérées** :
- ❌ SQLite → Trop complexe pour des données simples
- ❌ Fichiers JSON → Gestion manuelle, risque de corruption
- ❌ Hive → Dépendance externe, overhead

**Choix : SharedPreferences**
- ✅ Natif Flutter (pas de dépendance externe)
- ✅ Simple et rapide
- ✅ Persistant (survit aux redémarrages)
- ✅ Adapté pour des données clé-valeur
- ✅ Performant pour des petites/moyennes quantités de données

---

### 3. Pourquoi Firebase Functions ?

**Alternatives considérées** :
- ❌ Backend custom (Node.js, Python) → Maintenance, hébergement
- ❌ Firestore direct → Pas de logique métier, sécurité limitée
- ❌ AWS Lambda → Plus complexe, coût

**Choix : Firebase Functions**
- ✅ Serverless (pas de serveur à gérer)
- ✅ Scaling automatique
- ✅ Intégration Firebase Auth native
- ✅ Firestore intégré
- ✅ Gratuit jusqu'à un certain volume
- ✅ Déploiement simple (`firebase deploy`)

---

### 4. Pourquoi un arbitrage basé sur timestamps ?

**Alternatives considérées** :
- ❌ Dernier écrit gagne (Last Write Wins) → Perte de données possible
- ❌ Numéro de version incrémental → Complexe, nécessite coordination
- ❌ Merge automatique → Très complexe, risque d'incohérence

**Choix : Arbitrage par timestamp**
- ✅ Simple et efficace
- ✅ Privilégie toujours la version la plus récente
- ✅ Pas de perte de données (la version la plus récente est conservée)
- ✅ Facile à comprendre et débugger
- ✅ Fonctionne bien pour des sauvegardes complètes (snapshots)

---

### 5. Pourquoi une file de priorités ?

**Alternatives considérées** :
- ❌ Sauvegarde immédiate à chaque modification → Surcharge CPU/batterie
- ❌ Sauvegarde unique à la fermeture → Risque de perte si crash
- ❌ Sauvegarde périodique simple → Pas de contrôle sur les priorités

**Choix : File de priorités**
- ✅ Contrôle fin sur l'ordre de traitement
- ✅ Sauvegardes manuelles traitées en priorité
- ✅ Coalescing pour éviter les doublons
- ✅ Économie de ressources (CPU, batterie, réseau)
- ✅ Flexibilité (ajout de nouveaux triggers facile)

---

### 6. Pourquoi le cloud-first ?

**Alternatives considérées** :
- ❌ Local-first → Synchronisation complexe, conflits fréquents
- ❌ Cloud-only → Pas de mode hors ligne
- ❌ Sync bidirectionnel complexe → Merge difficile, bugs

**Choix : Cloud-first**
- ✅ Source de vérité unique (le cloud)
- ✅ Synchronisation simple (arbitrage par timestamp)
- ✅ Récupération facile sur nouvel appareil
- ✅ Pas de perte de données
- ✅ Mode hors ligne possible (cache local)

---

## 📊 RÉSUMÉ VISUEL

### Architecture complète

```
┌─────────────────────────────────────────────────────────────────┐
│                    ARCHITECTURE COMPLÈTE                        │
└─────────────────────────────────────────────────────────────────┘

UTILISATEUR
    ↓
┌───────────────────────────────────────┐
│  UI (WorldsScreen, GameScreen)        │
└───────────────┬───────────────────────┘
                ↓
┌───────────────────────────────────────┐
│  SavesFacade (Point d'entrée unique)  │
└───────────────┬───────────────────────┘
                ↓
┌───────────────────────────────────────┐
│  GamePersistenceOrchestrator          │
│  - File de priorités                  │
│  - Coalescing                         │
│  - Arbitrage local/cloud              │
└───────┬───────────────────┬───────────┘
        ↓                   ↓
┌───────────────┐   ┌───────────────────┐
│ LOCAL         │   │ CLOUD             │
│ SharedPref    │   │ Firebase Functions│
│ (Cache)       │   │ (Source vérité)   │
└───────────────┘   └───────────────────┘
```

---

### Flux de données

```
CRÉATION MONDE
    ↓
UUID v4 généré
    ↓
Initialisation GameState
    ↓
SAUVEGARDE LOCALE
    ↓
Snapshot créé
    ↓
SharedPreferences
    ↓
PUSH CLOUD (si connecté)
    ↓
Arbitrage (local vs cloud)
    ↓
HTTP PUT /worlds/<partieId>
    ↓
Firestore
    ↓
SYNCHRONISÉ ✅
```

---

## 🎓 CONCLUSION

### Points clés à retenir

1. **Modèle cloud-first** : Le cloud est la source de vérité
2. **UUID v4** : Identifiant unique universel pour chaque monde
3. **Snapshot** : Capture complète de l'état du jeu
4. **File de priorités** : Gestion intelligente des sauvegardes
5. **Arbitrage par timestamp** : Synchronisation simple et efficace
6. **Activation automatique** : Cloud sync activé au login Firebase
7. **Retry policy** : Réessai automatique en cas d'échec réseau

### Avantages du système

- ✅ **Fiabilité** : Pas de perte de données
- ✅ **Simplicité** : Architecture claire et maintenable
- ✅ **Performance** : Optimisations (coalescing, priorités)
- ✅ **Flexibilité** : Facile d'ajouter de nouvelles fonctionnalités
- ✅ **Expérience utilisateur** : Synchronisation transparente

---

**Date** : 15 janvier 2026  
**Version** : 1.0  
**Auteur** : Documentation PaperClip2
