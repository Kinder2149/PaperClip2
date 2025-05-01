import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'dart:async';

import 'save_data_provider.dart';
import 'local_save_service.dart';
import 'cloud_save_service.dart';
import 'save_migration_service.dart';
import 'save_recovery_service.dart';
import '../auto_save_service.dart';
import '../../models/game_config.dart';
import '../../models/game_state.dart';
import '../../models/event_system.dart';
import '../games_services_controller.dart';
import '../../screens/main_screen.dart';
import '../../services/save_manager.dart' show SaveGame, SaveError;
import 'package:shared_preferences/shared_preferences.dart';

class SaveSystem {
  static final SaveSystem _instance = SaveSystem._internal();
  factory SaveSystem() => _instance;

  late final LocalSaveService _localService;
  late final CloudSaveService _cloudService;
  late AutoSaveService? _autoSaveService;
  SaveDataProvider? _dataProvider;
  BuildContext? _context;
  DateTime? _lastSaveTime;

  bool _isRecoveryModeEnabled = false;

  SaveSystem._internal() {
    _localService = LocalSaveService();
    _cloudService = CloudSaveService();
  }

  void initialize(SaveDataProvider dataProvider, {GameState? gameState, BuildContext? context}) {
    _dataProvider = dataProvider;
    _context = context;

    if (gameState != null) {
      _autoSaveService = AutoSaveService(gameState);
      _autoSaveService?.initialize();
    }
  }

  void setContext(BuildContext context) {
    _context = context;
  }

  void enableRecoveryMode() {
    _isRecoveryModeEnabled = true;
  }

  Future<void> saveGame(String name, {bool syncToCloud = true}) async {
    if (_dataProvider == null) {
      throw Exception('Le système de sauvegarde n\'est pas initialisé');
    }

    try {
      // Préparation des données de jeu
      final gameData = _dataProvider!.prepareGameData();

      // Appliquer les migrations préventives
      final migratedData = SaveMigrationService.migrateIfNeeded(gameData);

      // Création de l'objet SaveGame
      final saveData = SaveGame(
        name: name,
        lastSaveTime: DateTime.now(),
        gameData: migratedData,
        version: GameConstants.VERSION,
        gameMode: _dataProvider!.gameMode,
        isSyncedWithCloud: false,
      );

      // Sauvegarde locale
      await _localService.saveGame(saveData);
      _lastSaveTime = DateTime.now();

      // Notification de succès si le contexte est disponible
      if (_context != null) {
        ScaffoldMessenger.of(_context!).showSnackBar(
          const SnackBar(
            content: Text('Partie sauvegardée localement'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Synchronisation avec le cloud si demandé
      if (syncToCloud) {
        final gamesServices = GamesServicesController();
        if (await gamesServices.isSignedIn()) {
          final success = await gamesServices.saveGameToCloud(saveData);
          if (success && _context != null) {
            ScaffoldMessenger.of(_context!).showSnackBar(
              const SnackBar(
                content: Text('Partie synchronisée avec le cloud'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e, stack) {
      print('Erreur dans SaveSystem.saveGame: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Erreur de sauvegarde');

      if (_context != null) {
        ScaffoldMessenger.of(_context!).showSnackBar(
          SnackBar(
            content: Text('Erreur de sauvegarde: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }

  Future<void> loadGame(String name, {String? cloudId}) async {
    if (_dataProvider == null) {
      throw Exception('Le système de sauvegarde n\'est pas initialisé');
    }

    try {
      SaveGame? saveGame;

      // Tentative de chargement depuis le cloud si un cloudId est fourni
      if (cloudId != null) {
        final gamesServices = GamesServicesController();
        saveGame = await gamesServices.loadGameFromCloud(cloudId);

        if (saveGame == null) {
          throw SaveError('CLOUD_ERROR', 'Erreur lors du chargement depuis le cloud');
        }

        // Sauvegarder localement la version cloud avec migration
        final migratedData = SaveMigrationService.migrateIfNeeded(saveGame.gameData);
        saveGame = SaveGame(
          id: saveGame.id,
          name: saveGame.name,
          lastSaveTime: saveGame.lastSaveTime,
          gameData: migratedData,
          version: saveGame.version,
          gameMode: saveGame.gameMode,
          isSyncedWithCloud: saveGame.isSyncedWithCloud,
          cloudId: saveGame.cloudId,
        );
        await _localService.saveGame(saveGame);
      } else {
        // Chargement local normal
        saveGame = await _localService.loadGame(name);
        if (saveGame == null) {
          throw SaveError('NOT_FOUND', 'Sauvegarde non trouvée');
        }
      }

      // Charger les données dans le provider
      _dataProvider!.loadGameData(saveGame.gameData);
      _lastSaveTime = saveGame.lastSaveTime;

      // Notification de succès
      if (_context != null) {
        ScaffoldMessenger.of(_context!).showSnackBar(
          const SnackBar(
            content: Text('Partie chargée avec succès'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stack) {
      print('Erreur dans SaveSystem.loadGame: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Erreur de chargement');

      if (_context != null) {
        // Si le mode récupération est activé, proposer d'activer le mode sans échec
        if (_isRecoveryModeEnabled) {
          _showRecoveryOptions(name, e.toString());
        } else {
          ScaffoldMessenger.of(_context!).showSnackBar(
            SnackBar(
              content: Text('Erreur de chargement: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Options',
                onPressed: () => _showRecoveryOptions(name, e.toString()),
              ),
            ),
          );
        }
      }
      rethrow;
    }
  }

  void _showRecoveryOptions(String saveName, String errorMessage) {
    if (_context == null) return;

    showDialog(
      context: _context!,
      builder: (context) => AlertDialog(
        title: const Text('Problème de chargement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Impossible de charger cette sauvegarde. Que souhaitez-vous faire ?'),
            const SizedBox(height: 12),
            Text('Erreur: $errorMessage',
                style: const TextStyle(fontSize: 12, color: Colors.red)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _attemptRecovery(saveName);
            },
            child: const Text('Tenter une récupération'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadBackupIfAvailable(saveName);
            },
            child: const Text('Charger un backup'),
          ),
        ],
      ),
    );
  }

  Future<void> _attemptRecovery(String saveName) async {
    try {
      // Activer explicitement le mode récupération
      _isRecoveryModeEnabled = true;

      // Essayer de charger avec récupération forcée
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString('${LocalSaveService.SAVE_PREFIX}$saveName');

      if (savedData == null) {
        _showErrorMessage('Sauvegarde non trouvée');
        return;
      }

      // Tenter la récupération
      final recoveredData = await SaveRecoveryService.attemptRecovery(savedData, saveName);
      if (recoveredData == null) {
        _showErrorMessage('Échec de la récupération');
        return;
      }

      // Charger les données récupérées
      _dataProvider!.loadGameData(recoveredData);
      _lastSaveTime = DateTime.now();

      // Notifier l'utilisateur
      if (_context != null) {
        ScaffoldMessenger.of(_context!).showSnackBar(
          const SnackBar(
            content: Text('Récupération réussie ! Certaines données peuvent avoir été perdues.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );

        // Créer un backup de la version récupérée
        saveGame('${saveName}_recovered', syncToCloud: false);
      }
    } catch (e, stack) {
      print('Échec de la tentative de récupération: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Recovery attempt failed');

      _showErrorMessage('Échec de la récupération: $e');
    }
  }

  Future<void> _loadBackupIfAvailable(String saveName) async {
    try {
      // Rechercher les backups
      final saves = await listSaves();
      final backups = saves.where((save) =>
      save.name.contains('_backup_') &&
          save.name.startsWith(saveName.split('_')[0])).toList();

      if (backups.isEmpty) {
        _showErrorMessage('Aucun backup disponible');
        return;
      }

      // Trier par date (plus récent d'abord)
      backups.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Charger le backup le plus récent
      await loadGame(backups[0].name);

      if (_context != null) {
        ScaffoldMessenger.of(_context!).showSnackBar(
          SnackBar(
            content: Text('Backup chargé: ${backups[0].name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stack) {
      print('Erreur lors du chargement du backup: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Backup loading failed');

      _showErrorMessage('Échec du chargement du backup: $e');
    }
  }

  void _showErrorMessage(String message) {
    if (_context != null) {
      ScaffoldMessenger.of(_context!).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<List<SaveGameInfo>> listSaves() async {
    return await _localService.listSaves();
  }

  Future<List<SaveGameInfo>> listCloudSaves() async {
    final gamesServices = GamesServicesController();
    if (await gamesServices.isSignedIn()) {
      return await gamesServices.getCloudSaves();
    }
    return [];
  }

  Future<void> deleteSave(String name, {bool deleteFromCloud = false}) async {
    try {
      // Supprimer la sauvegarde locale
      await _localService.deleteSave(name);

      // Supprimer du cloud si demandé
      if (deleteFromCloud) {
        // Cette fonctionnalité n'était pas dans le code original,
        // nous pouvons l'ajouter plus tard si nécessaire
      }

      if (_context != null) {
        ScaffoldMessenger.of(_context!).showSnackBar(
          const SnackBar(
            content: Text('Sauvegarde supprimée'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stack) {
      print('Erreur lors de la suppression: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Erreur de suppression');

      if (_context != null) {
        ScaffoldMessenger.of(_context!).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }

  Future<bool> syncSavesToCloud() async {
    final gamesServices = GamesServicesController();
    if (!await gamesServices.isSignedIn()) {
      if (_context != null) {
        ScaffoldMessenger.of(_context!).showSnackBar(
          const SnackBar(
            content: Text('Connectez-vous à Google Play Games pour synchroniser'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return false;
    }

    try {
      return await gamesServices.syncSaves();
    } catch (e, stack) {
      print('Erreur lors de la synchronisation: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Erreur de synchronisation');

      if (_context != null) {
        ScaffoldMessenger.of(_context!).showSnackBar(
          SnackBar(
            content: Text('Erreur de synchronisation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  Future<void> saveOnImportantEvent() async {
    if (_dataProvider == null || _dataProvider!.gameName == null) return;

    try {
      await saveGame(_dataProvider!.gameName!);
    } catch (e) {
      print('Erreur lors de la sauvegarde événementielle: $e');
    }
  }

  Future<void> checkAndRestoreFromBackup() async {
    if (_dataProvider == null || _dataProvider!.gameName == null) return;

    try {
      final saves = await listSaves();
      final backups = saves.where((save) =>
          save.name.startsWith('${_dataProvider!.gameName!}_backup_'))
          .toList();

      if (backups.isEmpty) return;

      // Tenter de charger le dernier backup valide
      backups.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      for (var backup in backups) {
        try {
          await loadGame(backup.name);
          print('Restauration réussie depuis le backup: ${backup.name}');
          return;
        } catch (e) {
          print('Échec de la restauration depuis ${backup.name}: $e');
          continue;
        }
      }
    } catch (e) {
      print('Erreur lors de la vérification des backups: $e');
    }
  }

  Future<void> showCloudSaveSelector() async {
    if (_dataProvider == null || _context == null) return;

    try {
      final gamesServices = GamesServicesController();
      if (!await gamesServices.isSignedIn()) {
        await gamesServices.signIn();
      }

      if (await gamesServices.isSignedIn()) {
        final selectedSave = await gamesServices.showSaveSelector();
        if (selectedSave != null) {
          // Sauvegarder d'abord la partie actuelle si elle existe
          if (_dataProvider!.gameName != null) {
            await saveGame(_dataProvider!.gameName!);
          }

          // Charger la partie sélectionnée
          await loadGame(selectedSave.name, cloudId: selectedSave.cloudId);

          // Naviguer vers l'écran principal si nécessaire
          if (_context != null && _context!.mounted) {
            Navigator.of(_context!).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainScreen()),
            );
          }
        }
      }
    } catch (e, stack) {
      print('Erreur lors de l\'affichage du sélecteur cloud: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Erreur du sélecteur cloud');

      if (_context != null) {
        ScaffoldMessenger.of(_context!).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Accesseurs
  AutoSaveService? get autoSaveService => _autoSaveService;
  DateTime? get lastSaveTime => _lastSaveTime;
}