// lib/services/auto_save_service.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../utils/logger.dart';

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
import 'package:paperclip2/services/runtime/clock.dart';
import 'package:paperclip2/services/save_system/save_game_manager.dart';
import 'package:paperclip2/services/save_system/local_save_game_manager.dart';
import 'package:paperclip2/services/persistence/snapshot_validator.dart';

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
  static final Logger _logger = Logger.forComponent('autosave');
  
  // Utilise les constantes centralisÃ©es depuis GameConstants
  final GameState _gameState;
  final AutoSaveOrchestratorPort _orchestrator;
  final AutoSaveStoragePort _storage;
  DomainEventSink _eventSink;
  final AutoSavePostFrameScheduler _postFrame;
  final Clock _clock;
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
    Clock? clock,
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
        _clock = (clock ?? SystemClock()),
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

  // MÃthode start pour compatibilitÃ avec le code existant
  Future<void> start() async {
    await initialize();
  }
  
  // MÃthode pour arrÃªter temporairement l'auto-sauvegarde
  void stop() {
    _stopMainTimer();
  }
  
  void _stopMainTimer() {
    _mainTimer?.cancel();
    _mainTimer = null;
  }
  
  // MÃthode pour relancer l'auto-sauvegarde aprÃ¨s un arrÃªt
  void restart() {
    _setupMainTimer();
  }

  Future<void> requestLifecycleSave({String? reason}) async {
    if (!_gameState.isInitialized || _gameState.enterpriseName == null) {
      return;
    }

    await _orchestrator.requestLifecycleSave(
      _gameState,
      reason: reason,
    );
    _lastAutoSave = _clock.now();
  }

  void _setupMainTimer() {
    _mainTimer?.cancel();
    _mainTimer = Timer.periodic(GameConstants.AUTO_SAVE_INTERVAL, (_) {
      // VÃrifier si l'UI n'est pas occupÃe avant de sauvegarder
      _postFrame(() {
        _performAutoSave();
      });
    });
  }

  Future<void> createBackup() async {
    if (!_isInitialized || _gameState.enterpriseName == null) return;

    try {
      final baseKey = _gameState.enterpriseId;
      if (baseKey == null || baseKey.isEmpty) {
        return;
      }
      final backupName = '$baseKey${StorageConstants.BACKUP_DELIMITER}${_clock.now().millisecondsSinceEpoch}';

      await _orchestrator.requestBackup(
        _gameState,
        backupName: backupName,
        reason: 'autosave_service_create_backup',
      );
      
      _logger.info('â¥ï¸ Backup crÃe | ${backupName.substring(0, 20)}...');
      Future.microtask(() => _cleanupOldBackups());
    } catch (e) {
      _logger.warn('â˜  Erreur backup | $e');
    }
  }

  Future<void> _cleanupOldBackups() async {
    try {
      final saves = await _storage.listSaves();
      // Regrouper par enterpriseId (base avant le dÃlimiteur)
      final bases = <String>{};
      for (final s in saves.where((e) => e.name.contains(GameConstants.BACKUP_DELIMITER))) {
        final base = s.name.split(GameConstants.BACKUP_DELIMITER).first;
        if (base.isNotEmpty) bases.add(base);
      }
      int totalDeleted = 0;
      for (final base in bases) {
        try {
          final mgr = await LocalSaveGameManager.getInstance();
          final deleted = await mgr.applyBackupRetention(enterpriseId: base);
          totalDeleted += deleted as int;
        } catch (e) {
        }
      }
      if (totalDeleted > 0) {
        _logger.info('â§ï¸ Nettoyage backups | ${totalDeleted} supprimÃs');
      }
    } catch (e) {
    }
  }

  void _setupAppLifecycleSave() {
    // Mission 2: le lifecycle est orchestrÃ hors AutoSaveService (AppLifecycleHandler).
  }

  // Le logger est dÃjÃ dÃfini comme static au niveau de la classe
  
  Future<void> _performAutoSave() async {
    if (_gameState.isPaused || !_gameState.isInitialized || _gameState.enterpriseName == null) {
      return;
    }

    try {
      
      // PR3: persistance snapshot-only.
      // On contrÃ´le la taille du payload rÃellement Ãcrit (snapshot).
      final snapshot = _gameState.toSnapshot();
      // Validation stricte: aucun snapshot invalide ne doit Ãªtre persistÃ
      final validation = SnapshotValidator.validate(snapshot);
      if (!validation.isValid) {
        final msg = validation.errors.map((e) => e.toString()).join('; ');
        _logger.error('â˜  AutoSave annulÃe | Snapshot invalide');
        await _handleSaveError('SNAPSHOT_INVALID');
        return;
      }
      final savePayload = <String, dynamic>{
        'version': GameConstants.CURRENT_SAVE_FORMAT_VERSION,
        'timestamp': _clock.now().toIso8601String(),
        'gameData': <String, dynamic>{
          'gameSnapshot': snapshot.toJson(),
        },
      };

      // Validation best-effort (structure conteneur minimale + existence du snapshot)
      final validationResult = SaveValidator.validate(savePayload, quickMode: true);
      if (!validationResult.isValid) {
        // Validation ÃchouÃe mais on continue  );
      }

      // VÃrifier la taille avant de sauvegarder
      if (!await _checkSaveSize(savePayload)) {
        _logger.warn('â˜  Sauvegarde trop volumineuse');
        await _handleSaveError('Trop volumineuse');
        return;
      }

      await _orchestrator.requestAutoSave(
        _gameState,
        reason: 'autosave_timer',
      );
      
      _failedSaveAttempts = 0;
      _lastAutoSave = _clock.now();
      
    } catch (e) {
      _logger.error('â˜  Erreur auto-save | $e');
      await _handleSaveError(e);
    }
  }

  Future<bool> _checkSaveSize(Map<String, dynamic> data) async {
    final jsonString = jsonEncode(data);
    final size = utf8.encode(jsonString).length;

    if (_gameState.enterpriseName != null) {
      _saveSizes[_gameState.enterpriseName!] = size;
    }

    return size <= _maxStorageSizeBytes;
  }

  Future<void> _cleanupStorage() async {
    final saves = await _storage.listSaves();
    saves.sort((a, b) => a.lastModified.compareTo(b.lastModified));

    final now = _clock.now();
    for (var save in saves) {
      if (now.difference(save.lastModified) > GameConstants.MAX_SAVE_AGE &&
          !save.name.contains(GameConstants.BACKUP_DELIMITER)) {
        await GamePersistenceOrchestrator.instance.deleteSaveById(save.id);
        _saveSizes.remove(save.name);
      }
    }
    // Nettoyage terminÃ silencieusement
  }

  Future<void> _performBackup() async {
    if (!_isInitialized || _gameState.enterpriseName == null) return;

    try {
      final baseKey = _gameState.enterpriseId;
      if (baseKey == null || baseKey.isEmpty) {
        return;
      }
      final backupName = '$baseKey${StorageConstants.BACKUP_DELIMITER}${_clock.now().millisecondsSinceEpoch}';

      await _orchestrator.requestBackup(
        _gameState,
        backupName: backupName,
        reason: 'autosave_service_perform_backup',
      );
      await _cleanupOldBackups();
    } catch (e) {
    }
  }

  Future<void> _performSaveOnExit() async {
    if (!_gameState.isInitialized || _gameState.enterpriseName == null) {
      return;
    }

    try {
      
      // PR3: validation rapide sur le payload snapshot-only rÃellement Ãcrit.
      final snapshot = _gameState.toSnapshot();
      final validation = SnapshotValidator.validate(snapshot);
      if (!validation.isValid) {
        final msg = validation.errors.map((e) => e.toString()).join('; ');
        _logger.error('❌ SaveOnExit annulée | Snapshot invalide');
        try { await _performBackup(); } catch (_) {}
        return;
      }
      final payload = <String, dynamic>{
        'version': GameConstants.CURRENT_SAVE_FORMAT_VERSION,
        'timestamp': _clock.now().toIso8601String(),
        'gameData': <String, dynamic>{
          'gameSnapshot': snapshot.toJson(),
        },
      };

      final validationResult = SaveValidator.validate(payload, quickMode: true);
      if (!validationResult.isValid) {
        await _performBackup();
      }
      
      await requestLifecycleSave(reason: 'autosave_service_save_on_exit');
      
    } catch (e) {
      _logger.error('❌ Erreur save exit | $e');
      try {
        await _performBackup();
      } catch (_) {}
    }
  }

  Future<void> _handleSaveError(dynamic error) async {
    _failedSaveAttempts++;

    if (_failedSaveAttempts >= _maxFailedAttempts) {
      _logger.error('🔥 Max erreurs atteint | Backup secours');
      
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
        
      } catch (backupError) {
        _logger.error('❌ Backup secours échoué');

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