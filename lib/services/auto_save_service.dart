// lib/services/auto_save_service.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

import '../models/game_state.dart';
import '../constants/game_config.dart';  // Import des constantes centralisÃ©es
import 'save_game.dart';  // Import du fichier point d'entrÃ©e pour le systÃ¨me de sauvegarde
import '../constants/storage_constants.dart';  // Chemin corrigÃ© vers les constantes de stockage
import 'save_system/save_validator.dart';  // Import du nouveau validateur de sauvegarde
import '../services/persistence/game_persistence_orchestrator.dart';
import 'package:paperclip2/domain/events/domain_event.dart';
import 'package:paperclip2/domain/events/domain_event_type.dart';
import 'package:paperclip2/domain/ports/domain_event_sink.dart';
import 'package:paperclip2/domain/ports/no_op_domain_event_sink.dart';

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
}

class _DefaultAutoSaveStoragePort implements AutoSaveStoragePort {
  @override
  Future<List<SaveGameInfo>> listSaves() => GamePersistenceOrchestrator.instance.listSaves();
}

class AutoSaveService {
  // DÃ©finition du logger (static pour Ãªtre partagÃ© entre les instances)
  static final Logger _logger = Logger('AutoSaveService');
  
  // Utilise les constantes centralisÃ©es depuis GameConstants
  final GameState _gameState;
  final AutoSaveOrchestratorPort _orchestrator;
  final AutoSaveStoragePort _storage;
  DomainEventSink _eventSink;
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
    DomainEventSink? eventSink,
    AutoSavePostFrameScheduler? postFrame,
    int? maxStorageSizeBytes,
    int? maxFailedAttempts,
  })  : _orchestrator = orchestrator ??
            _DefaultAutoSaveOrchestratorPort(GamePersistenceOrchestrator.instance),
        _storage = storage ?? _DefaultAutoSaveStoragePort(),
        _eventSink = eventSink ?? const NoOpDomainEventSink(),
        _postFrame = postFrame ?? ((callback) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            callback();
          });
        }),
        _maxStorageSizeBytes = maxStorageSizeBytes ?? GameConstants.MAX_STORAGE_SIZE,
        _maxFailedAttempts = maxFailedAttempts ?? GameConstants.MAX_FAILED_ATTEMPTS;

  void setDomainEventSink(DomainEventSink sink) {
    _eventSink = sink;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    await Future.microtask(() {
      _setupMainTimer();
      _isInitialized = true;
    });
  }

  // MÃ©thode start pour compatibilitÃ© avec le code existant
  Future<void> start() async {
    await initialize();
  }
  
  // MÃ©thode pour arrÃªter temporairement l'auto-sauvegarde
  void stop() {
    _mainTimer?.cancel();
    _mainTimer = null;
    print('Auto-sauvegarde arrÃªtÃ©e temporairement');
  }
  
  // MÃ©thode pour relancer l'auto-sauvegarde aprÃ¨s un arrÃªt
  void restart() {
    _setupMainTimer();
    print('Auto-sauvegarde relancÃ©e');
  }

  Future<void> requestLifecycleSave({String? reason}) async {
    if (!_gameState.isInitialized || _gameState.gameName == null) {
      return;
    }

    await _orchestrator.requestLifecycleSave(
      _gameState,
      reason: reason,
    );
    _lastAutoSave = DateTime.now();
  }

  void _setupMainTimer() {
    _mainTimer?.cancel();
    _mainTimer = Timer.periodic(GameConstants.AUTO_SAVE_INTERVAL, (_) {
      // VÃ©rifier si l'UI n'est pas occupÃ©e avant de sauvegarder
      _postFrame(() {
        _performAutoSave();
      });
    });
  }

  Future<void> createBackup() async {
    if (!_isInitialized || _gameState.gameName == null) return;

    try {
      final baseKey = _gameState.partieId;
      if (baseKey == null || baseKey.isEmpty) {
        return;
      }
      final backupName = '$baseKey${StorageConstants.BACKUP_DELIMITER}${DateTime.now().millisecondsSinceEpoch}';

      await _orchestrator.requestBackup(
        _gameState,
        backupName: backupName,
        reason: 'autosave_service_create_backup',
      );
      
      print('CrÃ©ation de backup pour: $backupName');

      // Nettoyer les vieux backups de maniÃ¨re asynchrone
      Future.microtask(() => _cleanupOldBackups());
    } catch (e) {
      print('Erreur lors de la crÃ©ation du backup: $e');
    }
  }

  Future<void> _cleanupOldBackups() async {
    try {
      final saves = await _storage.listSaves();
      // Regrouper par partieId (base avant le délimiteur)
      final bases = <String>{};
      for (final s in saves.where((e) => e.name.contains(GameConstants.BACKUP_DELIMITER))) {
        final base = s.name.split(GameConstants.BACKUP_DELIMITER).first;
        if (base.isNotEmpty) bases.add(base);
      }
      int totalDeleted = 0;
      for (final base in bases) {
        try {
          final deleted = await SaveManagerAdapter.applyBackupRetention(partieId: base);
          totalDeleted += deleted;
        } catch (e) {
          print('Rétention backups échouée pour $base: $e');
        }
      }
      print('Nettoyage des anciens backups terminé (supprimés=$totalDeleted)');
    } catch (e) {
      print('Erreur lors du nettoyage des backups: $e');
    }
  }

  void _setupAppLifecycleSave() {
    // Mission 2: le lifecycle est orchestrÃ© hors AutoSaveService (AppLifecycleHandler).
  }

  // Le logger est dÃ©jÃ  dÃ©fini comme static au niveau de la classe
  
  Future<void> _performAutoSave() async {
    if (!_gameState.isInitialized || _gameState.gameName == null) {
      _logger.warning('Tentative de sauvegarde automatique avec un Ã©tat de jeu non initialisÃ© ou sans nom');
      return;
    }

    try {
      _logger.info('DÃ©but de la sauvegarde automatique pour: ${_gameState.gameName}');
      
      // PR3: persistance snapshot-only.
      // On contrÃ´le la taille du payload rÃ©ellement Ã©crit (snapshot).
      final snapshot = _gameState.toSnapshot();
      final savePayload = <String, dynamic>{
        'version': GameConstants.CURRENT_SAVE_FORMAT_VERSION,
        'timestamp': DateTime.now().toIso8601String(),
        'gameData': <String, dynamic>{
          'gameSnapshot': snapshot.toJson(),
        },
      };

      // Validation best-effort (structure conteneur minimale + existence du snapshot)
      final validationResult = SaveValidator.validate(savePayload, quickMode: true);
      if (!validationResult.isValid) {
        _logger.warning(
          'Validation rapide Ã©chouÃ©e avant sauvegarde snapshot-only: ${validationResult.errors.join(", ")}',
        );
      }

      // VÃ©rifier la taille avant de sauvegarder
      if (!await _checkSaveSize(savePayload)) {
        _logger.warning('Sauvegarde automatique trop volumineuse pour: ${_gameState.gameName}');
        await _handleSaveError('Sauvegarde trop volumineuse');
        return;
      }

      await _orchestrator.requestAutoSave(
        _gameState,
        reason: 'autosave_timer',
      );
      
      _failedSaveAttempts = 0;  // RÃ©initialiser le compteur en cas de succÃ¨s
      _lastAutoSave = DateTime.now();
      _logger.info('Sauvegarde automatique effectuÃ©e avec succÃ¨s pour: ${_gameState.gameName}');
      
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
        await GamePersistenceOrchestrator.instance.deleteSaveById(save.id);
        _saveSizes.remove(save.name);
      }
    }
    print('Nettoyage du stockage terminÃ©');
  }

  Future<void> _performBackup() async {
    if (!_isInitialized || _gameState.gameName == null) return;

    try {
      final baseKey = _gameState.partieId;
      if (baseKey == null || baseKey.isEmpty) {
        return;
      }
      final backupName = '$baseKey${StorageConstants.BACKUP_DELIMITER}${DateTime.now().millisecondsSinceEpoch}';

      await _orchestrator.requestBackup(
        _gameState,
        backupName: backupName,
        reason: 'autosave_service_perform_backup',
      );
      print('Backup effectuÃ© pour: $backupName');
      await _cleanupOldBackups();
    } catch (e) {
      print('Erreur lors de la crÃ©ation du backup: $e');
    }
  }

  Future<void> _performSaveOnExit() async {
    if (!_gameState.isInitialized || _gameState.gameName == null) {
      _logger.warning('Tentative de sauvegarde Ã  la sortie avec un Ã©tat de jeu non initialisÃ© ou sans nom');
      return;
    }

    try {
      _logger.info('DÃ©but de la sauvegarde Ã  la sortie pour: ${_gameState.gameName}');
      
      // PR3: validation rapide sur le payload snapshot-only rÃ©ellement Ã©crit.
      final snapshot = _gameState.toSnapshot();
      final payload = <String, dynamic>{
        'version': GameConstants.CURRENT_SAVE_FORMAT_VERSION,
        'timestamp': DateTime.now().toIso8601String(),
        'gameData': <String, dynamic>{
          'gameSnapshot': snapshot.toJson(),
        },
      };

      final validationResult = SaveValidator.validate(payload, quickMode: true);
      if (!validationResult.isValid) {
        _logger.warning('Validation rapide Ã©chouÃ©e lors de la sauvegarde Ã  la sortie');
        // CrÃ©er un backup de sÃ©curitÃ© avant de continuer
        await _performBackup();
      }
      
      await requestLifecycleSave(reason: 'autosave_service_save_on_exit');
      _logger.info('Sauvegarde Ã  la sortie effectuÃ©e avec succÃ¨s pour: ${_gameState.gameName}');
      
    } catch (e) {
      _logger.severe('Erreur lors de la sauvegarde de sortie: $e');
      // Tenter de crÃ©er une sauvegarde de secours mÃªme en cas d'erreur
      try {
        await _performBackup();
      } catch (_) {
        _logger.severe('Impossible de crÃ©er une sauvegarde de secours Ã  la sortie');
      }
    }
  }

  Future<void> _handleSaveError(dynamic error) async {
    _failedSaveAttempts++;

    _logger.warning('Tentative de sauvegarde Ã©chouÃ©e ($_failedSaveAttempts/$_maxFailedAttempts): $error');

    if (_failedSaveAttempts >= _maxFailedAttempts) {
      _logger.severe('Nombre maximum d\'erreurs de sauvegarde atteint, crÃ©ation d\'une sauvegarde de secours');
      
      try {
        await createBackup();
        _failedSaveAttempts = 0;

        _eventSink.publish(
          const DomainEvent(
            type: DomainEventType.resourceDepletion,
            data: <String, Object?>{
              'title': 'ProblÃ¨me de sauvegarde',
              'description': 'Une sauvegarde de secours a Ã©tÃ© crÃ©Ã©e automatiquement',
            },
          ),
        );
        
        _logger.info('Sauvegarde de secours crÃ©Ã©e avec succÃ¨s');
      } catch (backupError) {
        _logger.severe('Impossible de crÃ©er une sauvegarde de secours: $backupError');

        _eventSink.publish(
          const DomainEvent(
            type: DomainEventType.resourceDepletion,
            data: <String, Object?>{
              'title': 'Erreur critique de sauvegarde',
              'description': 'Impossible de sauvegarder vos donnÃ©es de jeu',
            },
          ),
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

// Utilisation de la classe ValidationResult du nouveau systÃ¨me de sauvegarde