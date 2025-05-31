// lib/services/save/save_system.dart

import 'package:flutter/material.dart';
import 'dart:async';
import '../../main.dart' show serviceLocator;
import 'package:uuid/uuid.dart';

import 'save_types.dart';
import 'storage/storage_engine.dart';
import 'storage/local_storage_engine.dart';
import 'storage/cloud_storage_engine.dart';
import '../auto_save_service.dart';
import '../../models/game_config.dart';
import '../../models/event_system.dart';
import '../../services/user/user_manager.dart';
import '../../models/game_state.dart';

class SaveSystem {
  static final SaveSystem _instance = SaveSystem._internal();
  factory SaveSystem() => _instance;

  // Storage engines
  final LocalStorageEngine _localEngine = LocalStorageEngine();
  final CloudStorageEngine _cloudEngine = CloudStorageEngine();

  // État et dépendances
  SaveDataProvider? _dataProvider;
  BuildContext? _context;
  DateTime? _lastSaveTime;
  UserManager? _userManager;
  AutoSaveService? _autoSaveService;

  bool _isRecoveryModeEnabled = false;
  bool _isInitialized = false;

  // Constructeur interne
  SaveSystem._internal();

  // Setter pour injecter UserManager
  void setUserManager(UserManager userManager) {
    _userManager = userManager;
    debugPrint('SaveSystem: UserManager injecté');
  }

  // Initialisation
  Future<void> initialize(SaveDataProvider? dataProvider, {BuildContext? context}) async {
    _dataProvider = dataProvider;
    _context = context;

    // Initialiser les moteurs de stockage
    await _localEngine.initialize();
    await _cloudEngine.initialize();

    if (dataProvider is GameState) {
      _autoSaveService = AutoSaveService(this, dataProvider as GameState);
      await _autoSaveService?.initialize();
    }

    _isInitialized = true;
    debugPrint('SaveSystem: initialization terminée avec succès');
  }

// Ajouter une méthode pour exposer _cloudEngine publiquement
  Future<List<SaveGameInfo>> getCloudSaves() async {
    if (!_cloudEngine.isInitialized) {
      await _cloudEngine.initialize();
    }
    return await _cloudEngine.listSaves();
  }

  // Setter pour le contexte
  void setContext(BuildContext context) {
    _context = context;
  }
  Future<bool> exists(String name) async {
    return await _localEngine.exists(name);
  }

  // Activer le mode récupération
  void enableRecoveryMode() {
    _isRecoveryModeEnabled = true;
  }

  // Sauvegarder une partie
  Future<void> saveGame(String name, {bool syncToCloud = true}) async {
    if (_dataProvider == null) {
      throw Exception('Le système de sauvegarde n\'est pas initialisé');
    }

    try {
      // Préparation des données
      final gameData = _dataProvider!.prepareGameData();

      // Création de la sauvegarde
      final saveData = SaveGame(
        id: const Uuid().v4(),
        name: name,
        lastSaveTime: DateTime.now(),
        gameData: gameData,
        version: GameConstants.VERSION,
        gameMode: _dataProvider!.gameMode,
        isSyncedWithCloud: false,
      );

      // Sauvegarde locale
      await _localEngine.save(saveData);
      _lastSaveTime = DateTime.now();

      // Ajouter au profil utilisateur si disponible
      if (_userManager != null && _userManager!.hasProfile) {
        await _userManager!.addSaveToProfile(saveData.id, saveData.gameMode);
      }

      // Notification de succès
      if (_context != null && _context!.mounted) {
        ScaffoldMessenger.of(_context!).showSnackBar(
          const SnackBar(
            content: Text('Partie sauvegardée localement'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Synchronisation cloud si demandé
      if (syncToCloud && _userManager != null && _userManager!.currentProfile?.googleId != null) {
        try {
          await _syncToCloud(saveData);

          if (_context != null && _context!.mounted) {
            ScaffoldMessenger.of(_context!).showSnackBar(
              const SnackBar(
                content: Text('Partie synchronisée avec le cloud'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (syncError) {
          debugPrint('Erreur synchronisation cloud: $syncError');
          // Ne pas bloquer le processus en cas d'erreur
        }
      }
    } catch (e, stack) {
      debugPrint('Erreur dans SaveSystem.saveGame: $e');
      serviceLocator.analyticsService?.recordError(e, stack, reason: 'Erreur de sauvegarde');

      if (_context != null && _context!.mounted) {
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

  // Charger une partie
  Future<void> loadGame(String name, {String? cloudId}) async {
    if (_dataProvider == null) {
      throw Exception('Le système de sauvegarde n\'est pas initialisé');
    }

    try {
      SaveGame? saveGame;

      // Tentative de chargement depuis le cloud si cloudId fourni
      if (cloudId != null) {
        saveGame = await _cloudEngine.load(cloudId);

        if (saveGame == null) {
          throw SaveError('CLOUD_ERROR', 'Erreur lors du chargement depuis le cloud');
        }

        // Sauvegarder localement la version cloud
        await _localEngine.save(saveGame);
      } else {
        // Chargement local normal
        saveGame = await _localEngine.load(name);
        if (saveGame == null) {
          throw SaveError('NOT_FOUND', 'Sauvegarde non trouvée');
        }
      }

      // Charger les données dans le provider
      _dataProvider!.loadGameData(saveGame.gameData);
      _lastSaveTime = saveGame.lastSaveTime;

      // Notification de succès
      if (_context != null && _context!.mounted) {
        ScaffoldMessenger.of(_context!).showSnackBar(
          const SnackBar(
            content: Text('Partie chargée avec succès'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stack) {
      debugPrint('Erreur dans SaveSystem.loadGame: $e');
      serviceLocator.analyticsService?.recordError(e, stack, reason: 'Erreur de chargement');

      if (_context != null && _context!.mounted) {
        // Si mode récupération, proposer options
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

  // Lister les sauvegardes
  Future<List<SaveGameInfo>> listSaves() async {
    return await _localEngine.listSaves();
  }

  // Lister les sauvegardes cloud
  Future<List<SaveGameInfo>> listCloudSaves() async {
    return await _cloudEngine.listSaves();
  }

  // Supprimer une sauvegarde
  Future<void> deleteSave(String name, {bool deleteFromCloud = false}) async {
    try {
      // Récupérer l'ID de la sauvegarde
      final saveList = await _localEngine.listSaves();
      final saveGameInfo = saveList.firstWhere(
            (save) => save.name == name,
        orElse: () => throw SaveError('NOT_FOUND', 'Sauvegarde non trouvée'),
      );

      // Supprimer la sauvegarde locale
      await _localEngine.delete(name);

      // Retirer la sauvegarde du profil utilisateur
      if (_userManager != null && _userManager!.hasProfile) {
        await _userManager!.removeSaveFromProfile(saveGameInfo.id);
      }

      // Supprimer du cloud si demandé
      if (deleteFromCloud && saveGameInfo.cloudId != null) {
        await _cloudEngine.delete(saveGameInfo.cloudId!);
      }

      if (_context != null && _context!.mounted) {
        ScaffoldMessenger.of(_context!).showSnackBar(
          const SnackBar(
            content: Text('Sauvegarde supprimée'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stack) {
      debugPrint('Erreur lors de la suppression: $e');
      serviceLocator.analyticsService?.recordError(e, stack, reason: 'Erreur de suppression');

      if (_context != null && _context!.mounted) {
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

  // Synchroniser les sauvegardes vers le cloud
  Future<bool> syncSavesToCloud() async {
    try {
      // Vérifier si le moteur cloud est initialisé
      if (!_cloudEngine.isInitialized) {
        await _cloudEngine.initialize();
        if (!_cloudEngine.isInitialized) {
          if (_context != null && _context!.mounted) {
            ScaffoldMessenger.of(_context!).showSnackBar(
              const SnackBar(
                content: Text('Connectez-vous à Google pour synchroniser'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return false;
        }
      }

      // Récupérer toutes les sauvegardes locales
      final localSaves = await _localEngine.listSaves();

      // Synchroniser chaque sauvegarde
      int syncCount = 0;
      for (final saveInfo in localSaves) {
        try {
          final fullSave = await _localEngine.load(saveInfo.name);
          if (fullSave != null) {
            await _cloudEngine.save(fullSave);
            syncCount++;

            // Mettre à jour le statut local de la sauvegarde
            fullSave.isSyncedWithCloud = true;
            if (fullSave.cloudId == null) {
              fullSave.cloudId = fullSave.id;
            }
            await _localEngine.save(fullSave);
          }
        } catch (e) {
          debugPrint('Erreur lors de la synchronisation de ${saveInfo.name}: $e');
          // Continuer avec les autres sauvegardes
        }
      }

      if (_context != null && _context!.mounted) {
        ScaffoldMessenger.of(_context!).showSnackBar(
          SnackBar(
            content: Text('$syncCount sauvegardes synchronisées avec le cloud'),
            backgroundColor: Colors.green,
          ),
        );
      }

      return syncCount > 0;
    } catch (e, stack) {
      debugPrint('Erreur lors de la synchronisation: $e');
      serviceLocator.analyticsService?.recordError(e, stack, reason: 'Error syncing to cloud');

      if (_context != null && _context!.mounted) {
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

  // Sauvegarder lors d'un événement important
  Future<void> saveOnImportantEvent() async {
    if (_dataProvider == null || _dataProvider!.gameName == null) return;

    try {
      await saveGame(_dataProvider!.gameName!);
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde événementielle: $e');
    }
  }

  // Vérifier et restaurer depuis une sauvegarde de secours
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
          debugPrint('Restauration réussie depuis le backup: ${backup.name}');
          return;
        } catch (e) {
          debugPrint('Échec de la restauration depuis ${backup.name}: $e');
          continue;
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la vérification des backups: $e');
    }
  }

  // Afficher le sélecteur de sauvegarde cloud
  Future<void> showCloudSaveSelector() async {
    if (_dataProvider == null || _context == null || !_context!.mounted) return;

    try {
      // Initialiser le moteur cloud si nécessaire
      if (!_cloudEngine.isInitialized) {
        await _cloudEngine.initialize();
      }

      if (!_cloudEngine.isInitialized) {
        if (_context!.mounted) {
          ScaffoldMessenger.of(_context!).showSnackBar(
            const SnackBar(
              content: Text('Connectez-vous à Google pour accéder aux sauvegardes cloud'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Récupérer les sauvegardes cloud
      final cloudSaves = await _cloudEngine.listSaves();

      if (cloudSaves.isEmpty) {
        if (_context!.mounted) {
          ScaffoldMessenger.of(_context!).showSnackBar(
            const SnackBar(
              content: Text('Aucune sauvegarde cloud trouvée'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Afficher la liste des sauvegardes pour sélection
      if (_context!.mounted) {
        final selectedSave = await showDialog<SaveGameInfo>(
          context: _context!,
          builder: (context) => AlertDialog(
            title: const Text('Sauvegardes Cloud'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: cloudSaves.length,
                itemBuilder: (context, index) {
                  final save = cloudSaves[index];
                  return ListTile(
                    title: Text(save.name),
                    subtitle: Text('${save.timestamp.day}/${save.timestamp.month}/${save.timestamp.year} - Trombones: ${save.paperclips.toInt()}'),
                    onTap: () => Navigator.of(context).pop(save),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
            ],
          ),
        );

        if (selectedSave != null && selectedSave.cloudId != null) {
          // Sauvegarder d'abord la partie actuelle si elle existe
          if (_dataProvider!.gameName != null) {
            await saveGame(_dataProvider!.gameName!);
          }

          // Charger la partie sélectionnée
          await loadGame(selectedSave.name, cloudId: selectedSave.cloudId);
        }
      }
    } catch (e, stack) {
      debugPrint('Erreur lors de l\'affichage du sélecteur cloud: $e');
      serviceLocator.analyticsService?.recordError(e, stack, reason: 'Erreur du sélecteur cloud');

      if (_context != null && _context!.mounted) {
        ScaffoldMessenger.of(_context!).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Méthodes privées

  // Synchroniser une sauvegarde avec le cloud
  Future<void> _syncToCloud(SaveGame saveGame) async {
    if (!_cloudEngine.isInitialized) {
      await _cloudEngine.initialize();
      if (!_cloudEngine.isInitialized) {
        throw Exception('Le moteur de stockage cloud n\'est pas disponible');
      }
    }

    await _cloudEngine.save(saveGame);
  }

  // Afficher les options de récupération
  void _showRecoveryOptions(String saveName, String errorMessage) {
    if (_context == null || !_context!.mounted) return;

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

  // Tenter de récupérer une sauvegarde
  Future<void> _attemptRecovery(String saveName) async {
    try {
      // Activer explicitement le mode récupération
      _isRecoveryModeEnabled = true;

      // Tenter de récupérer la sauvegarde
      final saveGame = await _localEngine.load(saveName);

      if (saveGame == null) {
        _showErrorMessage('Échec de la récupération');
        return;
      }

      // Charger la sauvegarde récupérée
      _dataProvider!.loadGameData(saveGame.gameData);
      _lastSaveTime = DateTime.now();

      // Notifier l'utilisateur
      if (_context != null && _context!.mounted) {
        ScaffoldMessenger.of(_context!).showSnackBar(
          const SnackBar(
            content: Text('Récupération réussie ! Certaines données peuvent avoir été perdues.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );

        // Créer un backup de la version récupérée
        await this.saveGame('${saveName}_recovered', syncToCloud: false);
      }
    } catch (e, stack) {
      debugPrint('Échec de la tentative de récupération: $e');
      serviceLocator.analyticsService?.recordError(e, stack, reason: 'Recovery attempt failed');

      _showErrorMessage('Échec de la récupération: $e');
    }
  }

  // Charger un backup si disponible
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

      if (_context != null && _context!.mounted) {
        ScaffoldMessenger.of(_context!).showSnackBar(
          SnackBar(
            content: Text('Backup chargé: ${backups[0].name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stack) {
      debugPrint('Erreur lors du chargement du backup: $e');
      serviceLocator.analyticsService?.recordError(e, stack, reason: 'Backup loading failed');

      _showErrorMessage('Échec du chargement du backup: $e');
    }
  }

  // Afficher un message d'erreur
  void _showErrorMessage(String message) {
    if (_context != null && _context!.mounted) {
      ScaffoldMessenger.of(_context!).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Getters
  AutoSaveService? get autoSaveService => _autoSaveService;
  DateTime? get lastSaveTime => _lastSaveTime;
  bool get isInitialized => _isInitialized;
}