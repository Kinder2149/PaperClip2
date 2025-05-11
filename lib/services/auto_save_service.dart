// lib/services/auto_save_service.dart

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
// Ajouter cet import pour EventType et EventImportance
import '../models/event_system.dart';
import 'save/save_system.dart';
import 'save/save_types.dart';
import '../models/game_state.dart';

class AutoSaveService {
  static const Duration AUTO_SAVE_INTERVAL = Duration(minutes: 5);
  static const int MAX_BACKUPS = 3;

  final SaveSystem _saveSystem;
  final GameState _gameState;

  Timer? _timer;
  DateTime? _lastAutoSave;
  bool _isInitialized = false;
  int _failedSaveAttempts = 0;

  AutoSaveService(this._saveSystem, this._gameState);

  Future<void> initialize({Duration interval = AUTO_SAVE_INTERVAL}) async {
    if (_isInitialized) return;

    await Future.microtask(() {
      _setupTimer(interval);
      _setupAppLifecycleSave();
      _isInitialized = true;
    });
  }

  void _setupTimer(Duration interval) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) {
      // Vérifier si l'UI n'est pas occupée avant de sauvegarder
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performAutoSave();
      });
    });
  }

  Future<void> createBackup() async {
    if (!_isInitialized) return;

    try {
      final gameState = _gameState;
      if (gameState.gameName == null) return;

      final backupName = '${gameState.gameName!}_backup_${DateTime.now().millisecondsSinceEpoch}';

      // Sauvegarde asynchrone pour ne pas bloquer l'UI
      await Future.microtask(() async {
        await _saveSystem.saveGame(backupName, syncToCloud: false);
      });

      // Nettoyer les vieux backups
      await _cleanupOldBackups(gameState.gameName!);
    } catch (e) {
      debugPrint('Erreur lors de la création du backup: $e');
    }
  }

  Future<void> _cleanupOldBackups(String saveName) async {
    try {
      final saves = await _saveSystem.listSaves();
      final backups = saves.where((save) =>
          save.name.contains('${saveName}_backup_')).toList();

      // Garder seulement les MAX_BACKUPS plus récents
      if (backups.length > MAX_BACKUPS) {
        backups.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        for (var i = MAX_BACKUPS; i < backups.length; i++) {
          await _saveSystem.deleteSave(backups[i].name);
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du nettoyage des backups: $e');
    }
  }

  void _setupAppLifecycleSave() {
    SystemChannels.lifecycle.setMessageHandler((String? state) async {
      if (state == 'paused' || state == 'inactive') {
        await _performSaveOnExit();
      }
      return null;
    });
  }

  Future<void> _performAutoSave() async {
    if (!_isInitialized) return;

    final gameState = _gameState;
    if (gameState.gameName == null) return;

    try {
      await _saveSystem.saveGame(gameState.gameName!, syncToCloud: false);
      _failedSaveAttempts = 0;  // Réinitialiser le compteur en cas de succès
      _lastAutoSave = DateTime.now();
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde automatique: $e');
      await _handleSaveError(e);
    }
  }

  Future<void> _performSaveOnExit() async {
    if (!_isInitialized) return;

    final gameState = _gameState;
    if (gameState.gameName == null) return;

    try {
      await _saveSystem.saveGame(gameState.gameName!, syncToCloud: false);
      _lastAutoSave = DateTime.now();
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde de sortie: $e');
    }
  }

  Future<void> _handleSaveError(dynamic error) async {
    _failedSaveAttempts++;

    // Après plusieurs échecs, créer une sauvegarde de secours
    if (_failedSaveAttempts >= 3) {
      await createBackup();
      _failedSaveAttempts = 0;

      // Notifier l'utilisateur
      EventManager.instance.addEvent(
        EventType.RESOURCE_DEPLETION,
        "Problème de sauvegarde",
        description: "Une sauvegarde de secours a été créée",
        importance: EventImportance.HIGH,
      );
    }
  }

  // Getters
  DateTime? get lastAutoSave => _lastAutoSave;

  // Libération des ressources
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}