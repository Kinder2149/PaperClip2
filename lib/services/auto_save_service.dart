// lib/services/auto_save_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/event_system.dart';
import '../models/game_config.dart'; // Ajout de cette ligne
import 'save_manager.dart';
import '../utils/update_manager.dart';

class AutoSaveService {
  static const Duration AUTO_SAVE_INTERVAL = Duration(minutes: 5);
  final GameState _gameState;
  Timer? _autoSaveTimer;
  Timer? _backupTimer;
  DateTime? _lastAutoSave;
  bool _isInitialized = false;
  static const int MAX_STORAGE_SIZE = 50 * 1024 * 1024; // 50MB total
  static const Duration MAX_SAVE_AGE = Duration(days: 30);
  final Map<String, int> _saveSizes = {};
  static const int MAX_TOTAL_SAVES = 10;
  static const Duration CLEANUP_INTERVAL = Duration(hours: 24);

  AutoSaveService(this._gameState);

  Future<void> initialize() async {
    if (_isInitialized) return;

    _setupPeriodicSave();
    _setupPeriodicBackup();
    _setupAppLifecycleSave();

    _isInitialized = true;
  }

  void _setupPeriodicSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(AUTO_SAVE_INTERVAL, (_) => _performAutoSave());
  }

  void _setupPeriodicBackup() {
    _backupTimer?.cancel();
    _backupTimer = Timer.periodic(const Duration(hours: 24), (_) => _performBackup());
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
      var gameData = _gameState.prepareGameData();

      // Ajouter les métadonnées
      gameData['metadata'] = {
        'saveDate': DateTime.now().toIso8601String(),
        'userLogin': 'Kinder2149',
        'gameVersion': GameConstants.VERSION,
        'saveType': 'auto',
      };

      // Vérifications existantes
      if (!await _checkSaveSize(gameData)) {
        throw SaveError('SIZE_ERROR', 'Taille de sauvegarde excessive');
      }

      final validationResult = SaveIntegrityService.deepValidate(gameData);
      if (!validationResult.isValid) {
        throw SaveError('VALIDATION_ERROR', validationResult.errors.join('\n'));
      }

      await SaveManager.saveGame(_gameState, _gameState.gameName!);
      _lastAutoSave = DateTime.now();

      // Notification existante
      EventManager.instance.addEvent(
        EventType.INFO,
        "Sauvegarde Automatique",
        description: "Partie sauvegardée avec succès",
        importance: EventImportance.LOW,
        additionalData: {
          'silent': true,
          'timestamp': DateTime.now().toIso8601String(),
          'saveSize': _saveSizes[_gameState.gameName!],
        },
      );
    } catch (e) {
      print('Erreur lors de la sauvegarde automatique: $e');
      _handleSaveError(e);
    }
  }

  Future<bool> _checkSaveSize(Map<String, dynamic> data) async {
    final jsonString = jsonEncode(data);
    final size = utf8.encode(jsonString).length;

    // Mettre à jour le suivi de la taille
    if (_gameState.gameName != null) {
      _saveSizes[_gameState.gameName!] = size;
    }

    // Vérifier la taille totale
    int totalSize = _saveSizes.values.fold(0, (sum, size) => sum + size);
    if (totalSize > MAX_STORAGE_SIZE) {
      await _cleanupStorage();
    }

    return size <= MAX_STORAGE_SIZE;
  }
  Future<void> _cleanupStorage() async {
    final saves = await SaveManager.listSaves();
    // Trier par date, plus ancien d'abord
    saves.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Supprimer les sauvegardes trop anciennes
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
      await SaveManager.saveGame(_gameState, backupName);
      await _cleanupOldBackups();

      EventManager.instance.addEvent(
        EventType.INFO,
        "Backup Créé",
        description: "Sauvegarde de secours créée avec succès",
        importance: EventImportance.LOW,
      );
    } catch (e) {
      print('Erreur lors de la création du backup: $e');
    }
  }

  Future<void> _cleanupOldBackups() async {
    final backups = await SaveManager.listSaves();
    final gameBackups = backups.where((save) =>
        save.name.startsWith('${_gameState.gameName!}_backup_'))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (backups.length > 3) { // Garder seulement les 3 derniers backups
      for (var i = 3; i < backups.length; i++) {
        await SaveManager.deleteSave(backups[i].name);
      }
    }
  }

  Future<void> _performSaveOnExit() async {
    if (!_gameState.isInitialized || _gameState.gameName == null) return;

    try {
      await _performBackup();
      await SaveManager.saveGame(_gameState, _gameState.gameName!);
      _lastAutoSave = DateTime.now();
    } catch (e) {
      print('Erreur lors de la sauvegarde de sortie: $e');
    }
  }

  void _handleSaveError(dynamic error) {
    EventManager.instance.addEvent(
      EventType.RESOURCE_DEPLETION,  // Changé de ERROR à RESOURCE_DEPLETION
      "Erreur de Sauvegarde",
      description: "Impossible de sauvegarder la partie",
      importance: EventImportance.HIGH,
      additionalData: {'error': error.toString()},
    );
  }

  DateTime? get lastAutoSave => _lastAutoSave;

  void dispose() {
    _autoSaveTimer?.cancel();
    _backupTimer?.cancel();
    _autoSaveTimer = null;
    _backupTimer = null;
  }
}
class SaveIntegrityService {
  static const int SAVE_VERSION = 1;

  static bool validateSaveData(Map<String, dynamic> saveData) {
    if (!_checkRequiredFields(saveData)) {
      print('Validation échouée: champs requis manquants');
      return false;
    }

    if (!_checkDataConsistency(saveData)) {
      print('Validation échouée: incohérence des données');
      return false;
    }

    return true;
  }
  static ValidationResult deepValidate(Map<String, dynamic> saveData) {
    final errors = <String>[];

    if (!_checkRequiredFields(saveData)) {
      errors.add('Champs requis manquants');
    }

    if (!_checkDataConsistency(saveData)) {
      errors.add('Incohérence des données');
    }

    if (!_validateGameState(saveData)) {
      errors.add('État de jeu invalide');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  // Ajouter cette méthode
  static bool _validateGameState(Map<String, dynamic> saveData) {
    try {
      final playerData = saveData['playerManager'] as Map<String, dynamic>;
      final marketData = saveData['marketManager'] as Map<String, dynamic>;

      // Vérification des valeurs négatives
      if ((playerData['money'] as double) < 0 ||
          (playerData['metal'] as double) < 0 ||
          (playerData['paperclips'] as double) < 0) {
        return false;
      }

      // Vérification des limites
      if ((playerData['metal'] as double) > (playerData['maxMetalStorage'] as double)) {
        return false;
      }

      // Vérification de la cohérence du marché
      if ((marketData['marketMetalStock'] as double) < 0) {
        return false;
      }

      return true;
    } catch (e) {
      print('Erreur de validation: $e');
      return false;
    }
  }


  static bool _checkRequiredFields(Map<String, dynamic> saveData) {
    final requiredFields = [
      'version',
      'timestamp',
      'playerManager',
      'marketManager',
      'levelSystem',
      'statistics'
    ];

    return requiredFields.every((field) => saveData.containsKey(field));
  }

  static bool _checkDataConsistency(Map<String, dynamic> saveData) {
    try {
      // Vérification de la version
      final version = saveData['version'] as String;
      if (version != GameConstants.VERSION) {
        print('Version de sauvegarde incompatible');
        return false;
      }

      // Vérification de la cohérence des ressources
      final playerData = saveData['playerManager'] as Map<String, dynamic>;
      if (!_validateResourceLimits(playerData)) {
        return false;
      }

      return true;
    } catch (e) {
      print('Erreur lors de la vérification de cohérence: $e');
      return false;
    }
  }

  static bool _validateResourceLimits(Map<String, dynamic> playerData) {
    final metal = playerData['metal'] as double? ?? 0.0;
    final maxStorage = playerData['maxMetalStorage'] as double? ?? 0.0;

    if (metal < 0 || metal > maxStorage) {
      print('Valeurs de ressources invalides');
      return false;
    }

    return true;
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