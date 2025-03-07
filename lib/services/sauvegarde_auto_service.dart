import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/game_config.dart';
import 'save_manager.dart';

class ServiceSauvegardeAuto {
  static const Duration INTERVALLE_SAUVEGARDE_AUTO = Duration(minutes: 5);
  static const int TAILLE_MAX_STOCKAGE = 50 * 1024 * 1024; // 50 MB
  static const Duration AGE_MAX_SAUVEGARDE = Duration(days: 30);
  static const int MAX_TOTAL_SAUVEGARDES = 10;
  static const Duration INTERVALLE_NETTOYAGE = Duration(hours: 24);

  final GameState _gameState;
  Timer? _timerPrincipal;
  DateTime? _derniereSauvegardeAuto;
  bool _estInitialise = false;
  final Map<String, int> _taillesSauvegardes = {};
  int _tentativesEchouees = 0;
  static const int MAX_TENTATIVES = 3;

  ServiceSauvegardeAuto(this._gameState);

  Future<void> initialiser() async {
    if (_estInitialise) return;

    await Future.microtask(() {
      _configurerTimerPrincipal();
      _configurerSauvegardeEtatApp();
      _estInitialise = true;
    });
  }

  void _configurerTimerPrincipal() {
    _timerPrincipal?.cancel();
    _timerPrincipal = Timer.periodic(INTERVALLE_SAUVEGARDE_AUTO, (_) {
      // Vérifier si l'UI n'est pas occupée avant de sauvegarder
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _effectuerSauvegardeAuto();
      });
    });
  }

  Future<void> creerBackup() async {
    if (!_estInitialise || _gameState.gameName == null) return;

    try {
      final nomBackup = '${_gameState.gameName!}_backup_${DateTime.now().millisecondsSinceEpoch}';

      // Créer un objet SaveGame pour le backup
      final donneesSauvegarde = SaveGame(
        name: nomBackup,
        lastSaveTime: DateTime.now(),
        gameData: _gameState.prepareGameData(),
        version: GameConstants.VERSION,
        gameMode: _gameState.gameMode,
      );

      // Créer le backup de manière asynchrone
      await Future.microtask(() async {
        await SaveManager.saveGame(donneesSauvegarde);
      });

      // Nettoyer les vieux backups de manière asynchrone
      Future.microtask(() => _nettoyerVieuxBackups());
    } catch (e) {
      print('Erreur lors de la création du backup: $e');
    }
  }

  Future<void> _nettoyerVieuxBackups() async {
    try {
      final sauvegardes = await SaveManager.listSaves();
      final backups = sauvegardes.where((sauvegarde) =>
          sauvegarde.name.contains('_backup_')).toList();

      // Garder seulement les 3 derniers backups
      if (backups.length > 3) {
        backups.sort((a, b) => b.lastSaveTime.compareTo(a.lastSaveTime));
        for (var i = 3; i < backups.length; i++) {
          await SaveManager.deleteSave(backups[i].name);
        }
      }
    } catch (e) {
      print('Erreur lors du nettoyage des backups: $e');
    }
  }

  void _configurerSauvegardeEtatApp() {
    SystemChannels.lifecycle.setMessageHandler((String? state) async {
      if (state == 'paused' || state == 'inactive') {
        await _effectuerSauvegardeSortie();
      }
      return null;
    });
  }

  Future<void> _effectuerSauvegardeAuto() async {
    if (!_gameState.isInitialized || _gameState.gameName == null) return;

    try {
      // Créer un objet SaveGame pour la sauvegarde automatique
      final donneesSauvegarde = SaveGame(
        name: _gameState.gameName!,
        lastSaveTime: DateTime.now(),
        gameData: _gameState.prepareGameData(),
        version: GameConstants.VERSION,
        gameMode: _gameState.gameMode,
      );

      await SaveManager.saveGame(donneesSauvegarde);
      _tentativesEchouees = 0;  // Réinitialiser le compteur en cas de succès
      _derniereSauvegardeAuto = DateTime.now();
    } catch (e) {
      print('Erreur lors de la sauvegarde automatique: $e');
      await _gererErreurSauvegarde(e);
    }
  }

  Future<bool> _verifierTailleSauvegarde(Map<String, dynamic> donnees) async {
    final jsonString = jsonEncode(donnees);
    final taille = utf8.encode(jsonString).length;

    if (_gameState.gameName != null) {
      _taillesSauvegardes[_gameState.gameName!] = taille;
    }

    return taille <= TAILLE_MAX_STOCKAGE;
  }

  Future<void> _nettoyerStockage() async {
    final sauvegardes = await SaveManager.listSaves();
    sauvegardes.sort((a, b) => a.lastSaveTime.compareTo(b.lastSaveTime));

    final maintenant = DateTime.now();
    for (var sauvegarde in sauvegardes) {
      if (maintenant.difference(sauvegarde.lastSaveTime) > AGE_MAX_SAUVEGARDE &&
          !sauvegarde.name.contains('_backup_')) {
        await SaveManager.deleteSave(sauvegarde.name);
        _taillesSauvegardes.remove(sauvegarde.name);
      }
    }
  }

  Future<void> _effectuerSauvegardeSortie() async {
    if (!_gameState.isInitialized || _gameState.gameName == null) return;

    try {
      // Créer un objet SaveGame pour la sauvegarde à la sortie
      final donneesSauvegarde = SaveGame(
        name: _gameState.gameName!,
        lastSaveTime: DateTime.now(),
        gameData: _gameState.prepareGameData(),
        version: GameConstants.VERSION,
        gameMode: _gameState.gameMode,
      );

      await SaveManager.saveGame(donneesSauvegarde);
      _derniereSauvegardeAuto = DateTime.now();
    } catch (e) {
      print('Erreur lors de la sauvegarde de sortie: $e');
    }
  }

  Future<void> _gererErreurSauvegarde(dynamic erreur) async {
    _tentativesEchouees++;
    if (_tentativesEchouees >= MAX_TENTATIVES) {
      // Créer un backup d'urgence
      await creerBackup();
      _tentativesEchouees = 0;
    }
  }

  void dispose() {
    _timerPrincipal?.cancel();
  }
} 