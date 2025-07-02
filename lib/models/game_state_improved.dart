// lib/models/game_state_improved.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/game_config.dart';
import '../services/save_manager_improved.dart';
import '../services/auto_save_service.dart';
import '../managers/player_manager.dart';
import '../managers/market_manager.dart';
import '../managers/level_system.dart';
import '../services/notification_storage_service.dart';

/// Classe principale gérant l'état du jeu
/// Centralise l'accès aux gestionnaires et la logique métier principale
/// Refactorisée pour déléguer la logique de sauvegarde au SaveManager
class GameState extends ChangeNotifier {
  // Le nom du jeu actuel (null si nouveau jeu)
  String? gameName;

  // Mode de jeu (par défaut: infini)
  GameMode gameMode = GameMode.INFINITE;

  // Moment du début de la partie (pour le mode compétitif)
  DateTime? startTime;

  // Managers de jeu
  late PlayerManager playerManager;
  late MarketManager marketManager;
  late LevelSystem levelSystem;

  // Service de sauvegarde automatique
  AutoSaveService? _autoSaveService;

  // Constructeur 
  GameState() {
    _initializeManagers();
  }

  // Initialiser les managers
  void _initializeManagers() {
    playerManager = PlayerManager();
    marketManager = MarketManager();
    levelSystem = LevelSystem();

    // Établir les connexions entre managers si nécessaire
    playerManager.setMarketManager(marketManager);
    marketManager.setPlayerManager(playerManager);
    levelSystem.setPlayerManager(playerManager);
  }

  /// Démarrer une nouvelle partie
  Future<void> startNewGame(String name, {GameMode mode = GameMode.INFINITE}) async {
    // Vérifier si le nom existe déjà
    if (await SaveManager.saveExists(name)) {
      throw Exception('Une partie avec ce nom existe déjà');
    }

    // Réinitialiser les managers
    _initializeManagers();

    // Configurer les propriétés de base
    gameName = name;
    gameMode = mode;
    startTime = DateTime.now();

    // Sauvegarder la nouvelle partie
    await _saveGame();

    // Démarrer le service de sauvegarde automatique
    _startAutoSaveService();
    
    notifyListeners();
  }

  /// Charger une partie existante
  Future<void> loadGame(String saveName) async {
    try {
      // Charger la sauvegarde via SaveManager
      final saveGame = await SaveManager.loadGame(saveName);

      // Extraire les données du jeu
      final gameData = SaveManager.extractGameData(saveGame);
      
      // Mettre à jour les propriétés de base
      gameName = saveName;
      gameMode = saveGame.gameMode;
      
      // Extraire le temps de début si disponible
      if (gameData.containsKey('startTime')) {
        startTime = DateTime.parse(gameData['startTime']);
      } else {
        startTime = DateTime.now();
      }

      // Réinitialiser les managers
      _initializeManagers();

      // Restaurer l'état des managers à partir des données chargées
      _restoreManagersState(gameData);

      // Démarrer le service de sauvegarde automatique
      _startAutoSaveService();

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors du chargement de la partie: $e');
      }
      rethrow;
    }
  }

  /// Restaurer l'état des managers à partir des données sauvegardées
  void _restoreManagersState(Map<String, dynamic> data) {
    try {
      // Restaurer l'état du PlayerManager
      if (data.containsKey('playerManager')) {
        playerManager.fromJson(data['playerManager']);
      }

      // Restaurer l'état du MarketManager
      if (data.containsKey('marketManager')) {
        marketManager.fromJson(data['marketManager']);
      }

      // Restaurer l'état du LevelSystem
      if (data.containsKey('levelSystem')) {
        levelSystem.fromJson(data['levelSystem']);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la restauration des managers: $e');
      }
      throw Exception('Impossible de restaurer l\'état du jeu: $e');
    }
  }

  /// Restaurer un jeu à partir d'un backup
  /// @param data Les données du backup
  /// @param originalName Le nom original du jeu (sans le suffixe _backup_...)
  Future<void> loadGameDataFromBackup(Map<String, dynamic> data, String originalName) async {
    // Mettre à jour le nom du jeu
    gameName = originalName;

    // Déterminer le mode de jeu
    if (data.containsKey('gameMode')) {
      final modeIndex = data['gameMode'] as int;
      gameMode = GameMode.values[modeIndex];
    }

    // Extraire le temps de début
    if (data.containsKey('startTime')) {
      startTime = DateTime.parse(data['startTime']);
    }

    // Réinitialiser les managers
    _initializeManagers();

    // Restaurer l'état des managers
    _restoreManagersState(data);

    // Sauvegarder sous le nom original
    await _saveGame();

    // Démarrer le service de sauvegarde automatique
    _startAutoSaveService();

    notifyListeners();
  }

  /// Préparer les données du jeu pour la sauvegarde
  Map<String, dynamic> prepareGameData() {
    final Map<String, dynamic> gameData = {
      'gameMode': gameMode.index,
      'startTime': startTime?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'playerManager': playerManager.toJson(),
      'marketManager': marketManager.toJson(),
      'levelSystem': levelSystem.toJson(),
    };
    return gameData;
  }

  /// Sauvegarder l'état actuel du jeu
  Future<void> _saveGame() async {
    if (gameName == null) {
      throw Exception('Impossible de sauvegarder: pas de nom de jeu');
    }

    try {
      // Utiliser SaveManager pour sauvegarder le jeu
      await SaveManager.saveGameState(this, gameName!);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la sauvegarde: $e');
      }
      rethrow;
    }
  }

  /// Démarrer le service de sauvegarde automatique
  void _startAutoSaveService() {
    // Arrêter le service existant si nécessaire
    _autoSaveService?.dispose();
    
    // Créer et démarrer un nouveau service
    _autoSaveService = AutoSaveService(
      gameState: this,
      saveInterval: const Duration(minutes: 2),
      onSaveCompleted: (success) {
        if (success && kDebugMode) {
          print('Sauvegarde automatique réussie');
        } else if (!success && kDebugMode) {
          print('Échec de la sauvegarde automatique');
        }
      },
    );
    
    _autoSaveService?.start();
  }

  /// Créer un backup de la partie actuelle
  Future<String?> createBackup() async {
    if (gameName == null) return null;
    
    try {
      return await SaveManager.createBackup(this);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la création du backup: $e');
      }
      return null;
    }
  }

  /// Forcer une sauvegarde manuelle
  Future<bool> saveGameManually() async {
    try {
      await _saveGame();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la sauvegarde manuelle: $e');
      }
      return false;
    }
  }

  /// Récupérer les statistiques actuelles pour l'UI
  Map<String, dynamic> getCurrentStats() {
    return {
      'paperclips': playerManager.paperclips,
      'money': playerManager.money,
      'metal': playerManager.metal,
      'level': levelSystem.level,
      'experience': levelSystem.experience,
    };
  }

  @override
  void dispose() {
    // Sauvegarder avant de fermer
    if (gameName != null) {
      // Utiliser un saveGameManually synchrone pour s'assurer que la sauvegarde est terminée
      saveGameManually().then((success) {
        if (kDebugMode) {
          print('Sauvegarde finale: ${success ? 'réussie' : 'échouée'}');
        }
      });
    }
    
    // Arrêter le service de sauvegarde automatique
    _autoSaveService?.dispose();
    _autoSaveService = null;
    
    super.dispose();
  }

  // Gérer l'état de l'application (premier plan / arrière-plan)
  void handleAppLifecycleChange(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      // L'application passe en arrière-plan, sauvegarder
      if (gameName != null) {
        saveGameManually().then((success) {
          if (kDebugMode) {
            print('Sauvegarde en arrière-plan: ${success ? 'réussie' : 'échouée'}');
          }
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      // L'application revient au premier plan
      if (_autoSaveService != null && !_autoSaveService!.isRunning) {
        _autoSaveService!.start();
      }
    }
  }
}
