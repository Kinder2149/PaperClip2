// lib/services/auto_save_service.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

import '../models/game_state.dart';
import '../constants/game_config.dart';  // Import des constantes centralisées
import 'save_game.dart';  // Import du fichier point d'entrée pour le système de sauvegarde
import '../managers/event_manager.dart';
import '../constants/storage_constants.dart';  // Chemin corrigé vers les constantes de stockage
import 'save_system/save_validator.dart';  // Import du nouveau validateur de sauvegarde
import '../services/persistence/game_persistence_orchestrator.dart';

typedef AutoSavePostFrameScheduler = void Function(VoidCallback callback);

abstract class AutoSaveOrchestratorPort {
  Future<void> requestAutoSave(GameState state, {String? reason});
  Future<void> requestBackup(
    GameState state, {
    required String backupName,
    String? reason,
    bool bypassCooldown,
  });

  Future<void> requestLifecycleSave(GameState state, {String? reason});
}

class _DefaultAutoSaveOrchestratorPort implements AutoSaveOrchestratorPort {
  final GamePersistenceOrchestrator _inner;

  _DefaultAutoSaveOrchestratorPort(this._inner);

  @override
  Future<void> requestAutoSave(GameState state, {String? reason}) {
    return _inner.requestAutoSave(state, reason: reason);
  }

  @override
  Future<void> requestBackup(
    GameState state, {
    required String backupName,
    String? reason,
    bool bypassCooldown = false,
  }) {
    return _inner.requestBackup(
      state,
      backupName: backupName,
      reason: reason,
      bypassCooldown: bypassCooldown,
    );
  }

  @override
  Future<void> requestLifecycleSave(GameState state, {String? reason}) {
    return _inner.requestLifecycleSave(state, reason: reason);
  }
}

abstract class AutoSaveStoragePort {
  Future<List<SaveGameInfo>> listSaves();
  Future<void> deleteSaveByName(String name);
}

class _DefaultAutoSaveStoragePort implements AutoSaveStoragePort {
  @override
  Future<List<SaveGameInfo>> listSaves() => SaveManagerAdapter.listSaves();

  @override
  Future<void> deleteSaveByName(String name) => SaveManagerAdapter.deleteSaveByName(name);
}

abstract class AutoSaveEventPort {
  void addEvent(
    EventType type,
    String title, {
    required String description,
    required EventImportance importance,
  });
}

class _DefaultAutoSaveEventPort implements AutoSaveEventPort {
  @override
  void addEvent(
    EventType type,
    String title, {
    required String description,
    required EventImportance importance,
  }) {
    EventManager.instance.addEvent(
      type,
      title,
      description: description,
      importance: importance,
    );
  }
}

class AutoSaveService {
  // Définition du logger (static pour être partagé entre les instances)
  static final Logger _logger = Logger('AutoSaveService');
  
  // Utilise les constantes centralisées depuis GameConstants
  final GameState _gameState;
  final AutoSaveOrchestratorPort _orchestrator;
  final AutoSaveStoragePort _storage;
  final AutoSaveEventPort _events;
  final AutoSavePostFrameScheduler _postFrame;
  final int _maxStorageSizeBytes;
  final int _maxFailedAttempts;
  Timer? _mainTimer;
  DateTime? _lastAutoSave;
  bool _isInitialized = false;
  final Map<String, int> _saveSizes = {};
  int _failedSaveAttempts = 0;

  AutoSaveService(
    this._gameState, {
    AutoSaveOrchestratorPort? orchestrator,
    AutoSaveStoragePort? storage,
    AutoSaveEventPort? events,
    AutoSavePostFrameScheduler? postFrame,
    int? maxStorageSizeBytes,
    int? maxFailedAttempts,
  })  : _orchestrator = orchestrator ??
            _DefaultAutoSaveOrchestratorPort(GamePersistenceOrchestrator.instance),
        _storage = storage ?? _DefaultAutoSaveStoragePort(),
        _events = events ?? _DefaultAutoSaveEventPort(),
        _postFrame = postFrame ?? ((callback) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            callback();
          });
        }),
        _maxStorageSizeBytes = maxStorageSizeBytes ?? GameConstants.MAX_STORAGE_SIZE,
        _maxFailedAttempts = maxFailedAttempts ?? GameConstants.MAX_FAILED_ATTEMPTS;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await Future.microtask(() {
      _setupMainTimer();
      _isInitialized = true;
    });
  }

  // Méthode start pour compatibilité avec le code existant
  Future<void> start() async {
    await initialize();
  }
  
  // Méthode pour arrêter temporairement l'auto-sauvegarde
  void stop() {
    _mainTimer?.cancel();
    _mainTimer = null;
    print('Auto-sauvegarde arrêtée temporairement');
  }
  
  // Méthode pour relancer l'auto-sauvegarde après un arrêt
  void restart() {
    _setupMainTimer();
    print('Auto-sauvegarde relancée');
  }

  void _setupMainTimer() {
    _mainTimer?.cancel();
    _mainTimer = Timer.periodic(GameConstants.AUTO_SAVE_INTERVAL, (_) {
      // Vérifier si l'UI n'est pas occupée avant de sauvegarder
      _postFrame(() {
        _performAutoSave();
      });
    });
  }

  Future<void> createBackup() async {
    if (!_isInitialized || _gameState.gameName == null) return;

    try {
      final backupName = '${_gameState.gameName!}${StorageConstants.BACKUP_DELIMITER}${DateTime.now().millisecondsSinceEpoch}';

      // Créer un objet SaveGame pour le backup
      final saveData = SaveGame(
        name: backupName,
        lastSaveTime: DateTime.now(),
        gameData: _gameState.prepareGameData(),
        version: GameConstants.VERSION,
        gameMode: _gameState.gameMode,
      );

      await _orchestrator.requestBackup(
        _gameState,
        backupName: backupName,
        reason: 'autosave_service_create_backup',
      );
      
      print('Création de backup pour: $backupName');

      // Nettoyer les vieux backups de manière asynchrone
      Future.microtask(() => _cleanupOldBackups());
    } catch (e) {
      print('Erreur lors de la création du backup: $e');
    }
  }

  Future<void> _cleanupOldBackups() async {
    try {
      final saves = await _storage.listSaves();
      final backups = saves.where((save) =>
          save.name.contains(GameConstants.BACKUP_DELIMITER)).toList();

      // Garder seulement les 3 derniers backups
      if (backups.length > GameConstants.MAX_BACKUPS) {
        backups.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Utilisation de timestamp pour compatibilité avec SaveGameInfo
        for (var i = GameConstants.MAX_BACKUPS; i < backups.length; i++) {
          await _storage.deleteSaveByName(backups[i].name);
        }
      }
      print('Nettoyage des anciens backups terminé');
    } catch (e) {
      print('Erreur lors du nettoyage des backups: $e');
    }
  }

  void _setupAppLifecycleSave() {
    // Mission 2: le lifecycle est orchestré hors AutoSaveService (AppLifecycleHandler).
  }

  // Le logger est déjà défini comme static au niveau de la classe
  
  Future<void> _performAutoSave() async {
    if (!_gameState.isInitialized || _gameState.gameName == null) {
      _logger.warning('Tentative de sauvegarde automatique avec un état de jeu non initialisé ou sans nom');
      return;
    }

    try {
      _logger.info('Début de la sauvegarde automatique pour: ${_gameState.gameName}');
      
      // Préparer les données de jeu
      final gameData = _gameState.prepareGameData();
      
      // Validation préalable des données de jeu avec le nouveau validateur
      final validationResult = SaveValidator.validate(gameData);
      
      if (!validationResult.isValid) {
        _logger.warning('Problème de validation avant sauvegarde: ${validationResult.errors.join(", ")}');
        // Continuer quand même, mais avec les données sanitizées
        validationResult.sanitizedData?.forEach((key, value) {
          gameData[key] = value;
        });
        _logger.info('Données de jeu corrigées pour la sauvegarde automatique');
      }
      
      // Créer un objet SaveGame pour la sauvegarde automatique
      final saveData = SaveGame(
        id: _gameState.gameId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _gameState.gameName!,
        lastSaveTime: DateTime.now(),
        gameData: gameData,
        version: GameConstants.VERSION,
        gameMode: _gameState.gameMode,
      );

      // Vérifier la taille avant de sauvegarder
      if (!await _checkSaveSize(saveData.toJson())) {
        _logger.warning('Sauvegarde automatique trop volumineuse pour: ${_gameState.gameName}');
        await _handleSaveError('Sauvegarde trop volumineuse');
        return;
      }

      await _orchestrator.requestAutoSave(
        _gameState,
        reason: 'autosave_timer',
      );
      
      _failedSaveAttempts = 0;  // Réinitialiser le compteur en cas de succès
      _lastAutoSave = DateTime.now();
      _logger.info('Sauvegarde automatique effectuée avec succès pour: ${_gameState.gameName}');
      
    } catch (e) {
      _logger.severe('Erreur lors de la sauvegarde automatique: $e\nStacktrace: ${StackTrace.current}');
      await _handleSaveError(e);
    }
  }

  Future<bool> _checkSaveSize(Map<String, dynamic> data) async {
    final jsonString = jsonEncode(data);
    final size = utf8.encode(jsonString).length;

    if (_gameState.gameName != null) {
      _saveSizes[_gameState.gameName!] = size;
    }

    return size <= _maxStorageSizeBytes;
  }

  Future<void> _cleanupStorage() async {
    final saves = await _storage.listSaves();
    saves.sort((a, b) => a.lastModified.compareTo(b.lastModified));

    final now = DateTime.now();
    for (var save in saves) {
      if (now.difference(save.lastModified) > GameConstants.MAX_SAVE_AGE &&
          !save.name.contains(GameConstants.BACKUP_DELIMITER)) {
        await _storage.deleteSaveByName(save.name);
        _saveSizes.remove(save.name);
      }
    }
    print('Nettoyage du stockage terminé');
  }

  Future<void> _performBackup() async {
    if (!_gameState.isInitialized || _gameState.gameName == null) return;

    try {
      final backupName = '${_gameState.gameName!}${StorageConstants.BACKUP_DELIMITER}${DateTime.now().millisecondsSinceEpoch}';

      // Créer un objet SaveGame pour le backup
      final saveData = SaveGame(
        name: backupName,
        lastSaveTime: DateTime.now(),
        gameData: _gameState.prepareGameData(),
        version: GameConstants.VERSION,
        gameMode: _gameState.gameMode,
      );

      await _orchestrator.requestBackup(
        _gameState,
        backupName: backupName,
        reason: 'autosave_service_perform_backup',
      );
      print('Backup effectué pour: $backupName');
      await _cleanupOldBackups();
    } catch (e) {
      print('Erreur lors de la création du backup: $e');
    }
  }

  Future<void> _performSaveOnExit() async {
    if (!_gameState.isInitialized || _gameState.gameName == null) {
      _logger.warning('Tentative de sauvegarde à la sortie avec un état de jeu non initialisé ou sans nom');
      return;
    }

    try {
      _logger.info('Début de la sauvegarde à la sortie pour: ${_gameState.gameName}');
      
      // Préparer les données de jeu
      final gameData = _gameState.prepareGameData();
      
      // Validation rapide des données de jeu (version allégée pour la sortie rapide)
      final validationResult = SaveValidator.validate(gameData, quickMode: true);
      if (!validationResult.isValid) {
        _logger.warning('Validation rapide échouée lors de la sauvegarde à la sortie');
        // Créer un backup de sécurité avant de continuer
        await _performBackup();
      }
      
      // Créer un objet SaveGame pour la sauvegarde à la sortie
      final saveData = SaveGame(
        name: _gameState.gameName!,
        lastSaveTime: DateTime.now(),
        gameData: gameData,
        version: GameConstants.VERSION,
        gameMode: _gameState.gameMode,
        id: _gameState.gameId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      );

      await _orchestrator.requestLifecycleSave(
        _gameState,
        reason: 'autosave_service_save_on_exit',
      );
      _lastAutoSave = DateTime.now();
      _logger.info('Sauvegarde à la sortie effectuée avec succès pour: ${_gameState.gameName}');
      
    } catch (e) {
      _logger.severe('Erreur lors de la sauvegarde de sortie: $e');
      // Tenter de créer une sauvegarde de secours même en cas d'erreur
      try {
        await _performBackup();
      } catch (_) {
        _logger.severe('Impossible de créer une sauvegarde de secours à la sortie');
      }
    }
  }

  Future<void> _handleSaveError(dynamic error) async {
    _failedSaveAttempts++;

    _logger.warning('Tentative de sauvegarde échouée ($_failedSaveAttempts/$_maxFailedAttempts): $error');

    if (_failedSaveAttempts >= _maxFailedAttempts) {
      _logger.severe('Nombre maximum d\'erreurs de sauvegarde atteint, création d\'une sauvegarde de secours');
      
      try {
        await createBackup();
        _failedSaveAttempts = 0;

        _events.addEvent(
          EventType.RESOURCE_DEPLETION,  // Au lieu de EventType.ERROR
          "Problème de sauvegarde",
          description: "Une sauvegarde de secours a été créée automatiquement",
          importance: EventImportance.HIGH,
        );
        
        _logger.info('Sauvegarde de secours créée avec succès');
      } catch (backupError) {
        _logger.severe('Impossible de créer une sauvegarde de secours: $backupError');
        
        _events.addEvent(
          EventType.RESOURCE_DEPLETION, // Utilisation de RESOURCE_DEPLETION au lieu de ERROR
          "Erreur critique de sauvegarde",
          description: "Impossible de sauvegarder vos données de jeu",
          importance: EventImportance.CRITICAL,
        );
      }
    }
  }

  @visibleForTesting
  Future<void> performAutoSaveForTest() => _performAutoSave();

  @visibleForTesting
  Future<void> cleanupOldBackupsForTest() => _cleanupOldBackups();

  DateTime? get lastAutoSave => _lastAutoSave;

  void dispose() {
    _mainTimer?.cancel();
    _mainTimer = null;
  }
}

// Utilisation de la classe ValidationResult du nouveau système de sauvegarde