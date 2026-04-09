# 📂 Structure du Code Source

Organisation du dossier `lib/` de PaperClip2.

---

## 📋 Vue d'Ensemble

```
lib/
├── constants/          # Configuration et constantes
├── controllers/        # Contrôleurs de session
├── domain/            # Logique métier (DDD)
├── gameplay/          # Mécanique de jeu
├── managers/          # Managers métier
├── models/            # Modèles de données
├── screens/           # Écrans UI
├── services/          # Services (persistance, auth, cloud)
├── utils/             # Utilitaires
├── widgets/           # Widgets réutilisables
└── main.dart          # Point d'entrée
```

---

## 📁 Détails des Dossiers

### `constants/`
Configuration centralisée du jeu.

- `game_config.dart` - Constantes de gameplay (prix, durées, limites)
- `storage_constants.dart` - Clés de stockage local
- Valeurs immuables utilisées dans toute l'app

### `controllers/`
Contrôleurs de session et boucle de jeu.

- `game_session_controller.dart` - Gestion du game loop
- Démarre/arrête/pause la session
- Timer périodique pour la production

### `domain/`
Logique métier pure (Domain-Driven Design).

- `engine/` - Moteur de jeu
- `events/` - Événements domaine
- `ports/` - Interfaces/abstractions
- Indépendant de Flutter

### `gameplay/`
Mécanique de jeu et règles.

- `events/` - Système d'événements gameplay
- `mechanics/` - Mécaniques (production, vente, etc.)
- Logique de progression

### `managers/`
Managers métier pour chaque aspect du jeu.

- `market_manager.dart` - Gestion du marché
- `production_manager.dart` - Gestion de la production
- `player_manager.dart` - Gestion du joueur
- Chaque manager encapsule une responsabilité

### `models/`
Modèles de données et état.

- `game_state.dart` - État central du jeu
- `event_system.dart` - Système d'événements
- `level_system.dart` - Système de niveaux
- `progression_system.dart` - Progression
- Sérialisation JSON pour persistance

### `screens/`
Écrans de l'application.

- `main_screen.dart` - Écran principal
- `production_screen.dart` - Écran production
- `market_screen.dart` - Écran marché
- `worlds_screen.dart` - Sélection des mondes
- `bootstrap_screen.dart` - Écran de démarrage
- Navigation et UI

### `services/`
Services transversaux.

#### `services/persistence/`
- `game_persistence_orchestrator.dart` - Orchestrateur sauvegarde/sync
- `local_save_game_manager.dart` - Sauvegarde locale
- `last_played_tracker.dart` - Tracking dernière partie
- `snapshot_validator.dart` - Validation snapshots

#### `services/auth/`
- `firebase_auth_service.dart` - Authentification Firebase
- Gestion des tokens JWT

#### `services/cloud/`
- `cloud_port_manager.dart` - Sync cloud
- Communication avec Firebase Functions

#### `services/lifecycle/`
- `app_lifecycle_handler.dart` - Gestion cycle de vie app
- Détection pause/resume

#### Autres services
- `auto_save_service.dart` - Sauvegarde automatique
- `offline_progress_service.dart` - Progression offline
- `game_runtime_coordinator.dart` - Coordination runtime
- `background_music.dart` - Musique de fond

### `utils/`
Utilitaires et helpers.

- `logger.dart` - Système de logs
- Fonctions helpers diverses

### `widgets/`
Widgets réutilisables organisés par catégorie.

- `appbar/` - Barres d'application
- `dialogs/` - Dialogues
- `worlds/` - Widgets liés aux mondes
- `layout/` - Layouts
- `common/` - Widgets communs

---

## 🏗️ Architecture

### Gestion d'État
- **Provider** pour injection de dépendances
- **GameState** comme état central
- Listeners pour réactivité UI

### Flux de Données
```
UI (Screens/Widgets)
    ↓
Services/Controllers
    ↓
Managers/Domain
    ↓
Models
```

### Persistance
- **Local** : SharedPreferences (snapshot)
- **Cloud** : Firebase Firestore (sync)
- **Orchestration** : GamePersistenceOrchestrator

---

## 🔑 Concepts Clés

### GameState
Point central d'accès à l'état du jeu.
- Contient tous les managers
- Sérializable en snapshot
- Observable via Provider

### Snapshot
Représentation sérialisée de l'état du jeu.
- Format JSON
- Validation stricte
- Source de vérité locale

### EnterpriseId
Identifiant unique de chaque monde (UUID v4).
- Clé primaire locale et cloud
- Immuable après création
- Utilisé pour sync multi-device

---

## 📚 Documentation

- [README Principal](../README.md)
- [Documentation Complète](../docs/INDEX.md)
- [Architecture Globale](../docs/01-architecture/architecture-globale.md)

---

**Dernière mise à jour** : Mars 2026
