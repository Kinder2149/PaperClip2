import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:games_services/games_services.dart' as gs;
import '../models/game_config.dart';
import 'save_manager.dart' as sm;

// Définition claire des types pour éviter les conflits
typedef GServicesSaveGame = gs.SaveGame;
typedef AppSaveGame = sm.SaveGame;

class CloudSaveManager {
  static const String CLOUD_SAVE_PREFIX = 'paperclip2_save_';
  static const int MAX_CLOUD_SAVES = 20;

  static final CloudSaveManager _instance = CloudSaveManager._internal();
  factory CloudSaveManager() => _instance;
  CloudSaveManager._internal();

  // Méthode principale pour synchroniser les sauvegardes
  Future<bool> syncSaves() async {
    try {
      // Vérifier si le joueur est connecté
      bool isSignedIn = await gs.GamesServices.isSignedIn == true;
      if (!isSignedIn) {
        debugPrint('Utilisateur non connecté à Google Play Games');
        return false;
      }

      // 1. Récupérer les sauvegardes locales
      final localSaves = await sm.SaveManager.listSaves();

      // 2. Récupérer les sauvegardes cloud
      final cloudSaves = await getCloudSaves();

      // 3. Synchroniser dans les deux sens
      await _uploadLocalSaves(localSaves, cloudSaves);
      await _downloadCloudSaves(localSaves, cloudSaves);

      return true;
    } catch (e, stack) {
      debugPrint('Erreur lors de la synchronisation des sauvegardes: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
      return false;
    }
  }

  // Récupérer les sauvegardes du cloud
  Future<List<sm.SaveGameInfo>> getCloudSaves() async {
    try {
      final snapshots = await _getAvailableSnapshots();

      if (snapshots.isEmpty) {
        debugPrint('Aucune sauvegarde cloud trouvée');
        return [];
      }

      // Convertir les snapshots en SaveGameInfo
      List<sm.SaveGameInfo> cloudSaves = [];
      for (var snapshot in snapshots) {
        try {
          final content = await _loadSnapshotContent(snapshot);
          if (content == null) continue;

          final jsonData = jsonDecode(content) as Map<String, dynamic>;

          cloudSaves.add(sm.SaveGameInfo(
            id: jsonData['id'] ?? snapshot,
            name: jsonData['name'] ?? snapshot.substring(CLOUD_SAVE_PREFIX.length),
            timestamp: DateTime.parse(jsonData['timestamp'] ?? DateTime.now().toIso8601String()),
            version: jsonData['version'] ?? GameConstants.VERSION,
            paperclips: (jsonData['gameData']?['playerManager']?['paperclips'] as num?)?.toDouble() ?? 0,
            money: (jsonData['gameData']?['playerManager']?['money'] as num?)?.toDouble() ?? 0,
            isSyncedWithCloud: true,
            cloudId: snapshot,
            gameMode: jsonData['gameMode'] != null
                ? GameMode.values[jsonData['gameMode'] as int]
                : GameMode.INFINITE,
          ));
        } catch (e) {
          debugPrint('Erreur lors du décodage du snapshot $snapshot: $e');
          continue;
        }
      }

      return cloudSaves;
    } catch (e, stack) {
      debugPrint('Erreur lors de la récupération des sauvegardes cloud: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
      return [];
    }
  }

  Future<List<String>> _getAvailableSnapshots() async {
    try {
      // Simuler la récupération des snapshots disponibles
      return [];
    } catch (e) {
      debugPrint('Erreur lors de la récupération des snapshots: $e');
      return [];
    }
  }

  Future<String?> _loadSnapshotContent(String snapshotName) async {
    try {
      // Simuler le chargement du contenu d'un snapshot
      return null;
    } catch (e) {
      debugPrint('Erreur lors du chargement du snapshot $snapshotName: $e');
      return null;
    }
  }

  Future<void> _uploadLocalSaves(
    List<sm.SaveGameInfo> localSaves,
    List<sm.SaveGameInfo> cloudSaves,
  ) async {
    try {
      for (var localSave in localSaves) {
        if (!localSave.isSyncedWithCloud) {
          // Charger la sauvegarde complète
          final fullSave = await sm.SaveManager.loadGame(localSave.name);
          if (fullSave == null) continue;

          // Créer un nouveau snapshot dans le cloud
          await _createCloudSave(fullSave);
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'upload des sauvegardes: $e');
    }
  }

  Future<void> _createCloudSave(AppSaveGame save) async {
    try {
      final saveData = jsonEncode(save.toJson());
      // Simuler la création d'une sauvegarde cloud
    } catch (e) {
      debugPrint('Erreur lors de la création de la sauvegarde cloud: $e');
    }
  }

  Future<void> _downloadCloudSaves(
    List<sm.SaveGameInfo> localSaves,
    List<sm.SaveGameInfo> cloudSaves,
  ) async {
    try {
      for (var cloudSave in cloudSaves) {
        final localSaveExists = localSaves.any((local) =>
            local.cloudId == cloudSave.cloudId ||
            local.name == cloudSave.name);

        if (!localSaveExists) {
          // Charger la sauvegarde complète du cloud
          final fullSave = await _loadCloudSave(cloudSave.cloudId!);
          if (fullSave == null) continue;

          // Trouver un nom unique pour la sauvegarde locale
          String adjustedName = fullSave.name;
          bool exists = await sm.SaveManager.saveExists(adjustedName);
          int counter = 1;

          while (exists && counter < 100) {
            adjustedName = '${fullSave.name} (Cloud ${counter})';
            exists = await sm.SaveManager.saveExists(adjustedName);
            counter++;
          }

          // Créer une nouvelle sauvegarde locale
          final newLocalSave = AppSaveGame(
            id: fullSave.id,
            name: adjustedName,
            lastSaveTime: fullSave.lastSaveTime,
            gameData: fullSave.gameData,
            version: fullSave.version,
            isSyncedWithCloud: true,
            cloudId: fullSave.cloudId,
            gameMode: fullSave.gameMode,
          );

          await sm.SaveManager.saveGame(newLocalSave);
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du téléchargement des sauvegardes: $e');
    }
  }

  Future<AppSaveGame?> _loadCloudSave(String cloudId) async {
    try {
      // Simuler le chargement d'une sauvegarde cloud
      return null;
    } catch (e) {
      debugPrint('Erreur lors du chargement de la sauvegarde cloud: $e');
      return null;
    }
  }
} 