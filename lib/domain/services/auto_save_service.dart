﻿import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:paperclip2/models/save_game.dart';
import 'package:paperclip2/constants/game_constants.dart';
import 'package:paperclip2/services/save_manager.dart';
import 'package:paperclip2/services/event_manager.dart';
import 'package:paperclip2/models/event_type.dart';
import 'package:paperclip2/models/event_importance.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/game_state.dart';
import '../../domain/services/event_manager.dart';
import '../models/event_system.dart';
import '../models/game_config.dart';
import '../models/game_state.dart';
import 'save_manager.dart';



// lib/services/auto_save_service.dart


class AutoSaveService {
  static const Duration AUTO_SAVE_INTERVAL = Duration(minutes: 5);
  final GameState _gameState;
  Timer? _mainTimer;
  DateTime? _lastAutoSave;
  bool _isInitialized = false;
  static const int MAX_STORAGE_SIZE = 50 * 1024 * 1024;
  static const Duration MAX_SAVE_AGE = Duration(days: 30);
  final Map<String, int> _saveSizes = {};
  static const int MAX_TOTAL_SAVES = 10;
  static const Duration CLEANUP_INTERVAL = Duration(hours: 24);
  int _failedSaveAttempts = 0;
  static const int MAX_FAILED_ATTEMPTS = 3;

  AutoSaveService(this._gameState);

  Future<void> initialize() async {
    if (_isInitialized) return;

    await Future.microtask(() {
      _setupMainTimer();
      _setupAppLifecycleSave();
      _isInitialized = true;
    });
  }

  void _setupMainTimer() {
    _mainTimer?.cancel();
    _mainTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      // VÃ©rifier si l'UI n'est pas occupÃ©e avant de sauvegarder
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performAutoSave();
      });
    });
  }

  Future<void> createBackup() async {
    if (!_isInitialized || _gameState.gameName == null) return;

    try {
      final backupName = '${_gameState.gameName!}_backup_${DateTime.now().millisecondsSinceEpoch}';

      // CrÃ©er un objet SaveGame pour le backup
      final saveData = SaveGame(
        name: backupName,
        lastSaveTime: DateTime.now(),
        gameData: _gameState.prepareGameData(),
        version: GameConstants.VERSION,
        gameMode: _gameState.gameMode,
      );

      // CrÃ©er le backup de maniÃ¨re asynchrone pour ne pas bloquer l'UI
      await Future.microtask(() async {
        await SaveManager.saveGame(saveData);
      });

      // Nettoyer les vieux backups de maniÃ¨re asynchrone
      Future.microtask(() => _cleanupOldBackups());
    } catch (e) {
      print('Erreur lors de la crÃ©ation du backup: $e');
    }
  }

  Future<void> _cleanupOldBackups() async {
    try {
      final saves = await SaveManager.listSaves();
      final backups = saves.where((save) =>
          save.name.contains('_backup_')).toList();

      // Garder seulement les 3 derniers backups
      if (backups.length > 3) {
        backups.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        for (var i = 3; i < backups.length; i++) {
          await SaveManager.deleteSave(backups[i].name);
        }
      }
    } catch (e) {
      print('Erreur lors du nettoyage des backups: $e');
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
    if (!_gameState.isInitialized || _gameState.gameName == null) return;

    try {
      // CrÃ©er un objet SaveGame pour la sauvegarde automatique
      final saveData = SaveGame(
        name: _gameState.gameName!,
        lastSaveTime: DateTime.now(),
        gameData: _gameState.prepareGameData(),
        version: GameConstants.VERSION,
        gameMode: _gameState.gameMode,
      );

      await SaveManager.saveGame(saveData);
      _failedSaveAttempts = 0;  // RÃ©initialiser le compteur en cas de succÃ¨s
      _lastAutoSave = DateTime.now();
    } catch (e) {
      print('Erreur lors de la sauvegarde automatique: $e');
      await _handleSaveError(e);
    }
  }

  Future<bool> _checkSaveSize(Map<String, dynamic> data) async {
    final jsonString = jsonEncode(data);
    final size = utf8.encode(jsonString).length;

    if (_gameState.gameName != null) {
      _saveSizes[_gameState.gameName!] = size;
    }

    return size <= MAX_STORAGE_SIZE;
  }

  Future<void> _cleanupStorage() async {
    final saves = await SaveManager.listSaves();
    saves.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final now = DateTime.now();
    for (var save in saves) {
      if (now.difference(save.timestamp) > MAX_SAVE_AGE &&
          !save.name.contains('_backup_')) {
        await SaveManager.deleteSave(save.name);
        _saveSizes.remove(save.name);
      }
    }
  }

  Future<void> _performBackup() async {
    if (!_gameState.isInitialized || _gameState.gameName == null) return;

    try {
      final backupName = '${_gameState.gameName!}_backup_${DateTime.now().millisecondsSinceEpoch}';

      // CrÃ©er un objet SaveGame pour le backup
      final saveData = SaveGame(
        name: backupName,
        lastSaveTime: DateTime.now(),
        gameData: _gameState.prepareGameData(),
        version: GameConstants.VERSION,
        gameMode: _gameState.gameMode,
      );

      await SaveManager.saveGame(saveData);
      await _cleanupOldBackups();
    } catch (e) {
      print('Erreur lors de la crÃ©ation du backup: $e');
    }
  }

  Future<void> _performSaveOnExit() async {
    if (!_gameState.isInitialized || _gameState.gameName == null) return;

    try {
      // CrÃ©er un objet SaveGame pour la sauvegarde Ã  la sortie
      final saveData = SaveGame(
        name: _gameState.gameName!,
        lastSaveTime: DateTime.now(),
        gameData: _gameState.prepareGameData(),
        version: GameConstants.VERSION,
        gameMode: _gameState.gameMode,
      );

      await SaveManager.saveGame(saveData);
      _lastAutoSave = DateTime.now();
    } catch (e) {
      print('Erreur lors de la sauvegarde de sortie: $e');
    }
  }

  Future<void> _handleSaveError(dynamic error) async {
    _failedSaveAttempts++;

    if (_failedSaveAttempts >= MAX_FAILED_ATTEMPTS) {
      await createBackup();
      _failedSaveAttempts = 0;

      // Changer ERROR pour RESOURCE_DEPLETION ou un autre type existant
      EventManager().addEvent(
        EventType.RESOURCE_DEPLETION,  // Au lieu de EventType.ERROR
        "ProblÃ¨me de sauvegarde",
        description: "Une sauvegarde de secours a Ã©tÃ© crÃ©Ã©e",
        importance: EventImportance.HIGH,
      );
    }
  }

  DateTime? get lastAutoSave => _lastAutoSave;

  void dispose() {
    _mainTimer?.cancel();
    _mainTimer = null;
  }

  void startAutoSave() {
    // Implémentation de la méthode
  }

  void stopAutoSave() {
    // Implémentation de la méthode
  }
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;

  ValidationResult({
    required this.isValid,
    this.errors = const [],
  });
}



