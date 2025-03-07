// lib/services/cloud_save_manager.dart

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

  // Récupérer les sauvegardes du cloud - compatible avec l'API actuelle
  Future<List<sm.SaveGameInfo>> getCloudSaves() async {
    try {
      // Adapter cette méthode à l'API disponible dans games_services v4.0.3
      // Note: Cette version ne supporte pas directement loadSnapshots

      // Version modifiée utilisant les API disponibles
      final snapshots = await _getAvailableSnapshots();

      if (snapshots.isEmpty) {
        debugPrint('Aucune sauvegarde cloud trouvée');
        return [];
      }

      // Convertir les snapshots en SaveGameInfo
      List<sm.SaveGameInfo> cloudSaves = [];
      for (var snapshot in snapshots) {
        try {
          // Charger le contenu du snapshot
          final content = await _loadSnapshotContent(snapshot);
          if (content == null) continue;

          // Décoder le contenu JSON
          final jsonData = jsonDecode(content) as Map<String, dynamic>;

          // Créer un SaveGameInfo à partir des données
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

  // Méthode adaptée pour obtenir les snapshots disponibles
  Future<List<String>> _getAvailableSnapshots() async {
    try {
      // Utiliser les API disponibles dans games_services 4.0.3
      // Cette implémentation est une approximation

      // Dans cette version, on pourrait utiliser une approche différente
      // comme accéder à un point d'accès spécifique ou utiliser une méthode alternative

      // Exemple utilisant une méthode alternative
      final snapshots = <String>[];

      // Tenter de charger les métadonnées disponibles
      try {
        await gs.GamesServices.signIn();
        // Ici, il faudrait utiliser une méthode disponible dans la version 4.0.3
        // Si aucune méthode équivalente n'existe, il faut créer une implémentation personnalisée
      } catch (e) {
        debugPrint('Erreur lors de la récupération des snapshots: $e');
      }

      return snapshots;
    } catch (e) {
      debugPrint('Erreur lors de la récupération des snapshots: $e');
      return [];
    }
  }

  // Méthode adaptée pour charger le contenu d'un snapshot
  Future<String?> _loadSnapshotContent(String snapshotName) async {
    try {
      // Cette implémentation doit être adaptée pour utiliser les API disponibles

      // Dans games_services 4.0.3, nous devons adapter notre approche
      // Placeholder pour l'implémentation réelle
      return null;
    } catch (e) {
      debugPrint('Erreur lors du chargement du snapshot $snapshotName: $e');
      return null;
    }
  }

  // Sauvegarder une partie dans le cloud
  Future<bool> saveToCloud(AppSaveGame save) async {
    try {
      bool isSignedIn = await gs.GamesServices.isSignedIn == true;
      if (!isSignedIn) {
        debugPrint('Utilisateur non connecté à Google Play Games');
        return false;
      }

      // Préparer les données de sauvegarde
      final saveData = jsonEncode(save.toJson());

      // Nom du snapshot: prefix + id
      String snapshotName = save.cloudId ?? '${CLOUD_SAVE_PREFIX}${save.id}';

      // Description pour l'affichage dans l'UI de Google Play Games
      String description = 'PaperClip2 - ${save.name} (${save.lastSaveTime.day}/${save.lastSaveTime.month}/${save.lastSaveTime.year})';

      // Adapter cette partie pour utiliser les API disponibles dans games_services 4.0.3
      final result = await _saveSnapshotToCloud(snapshotName, saveData, description);

      // Mettre à jour le statut local
      if (result) {
        save.isSyncedWithCloud = true;
        save.cloudId = snapshotName;

        // Mettre à jour la sauvegarde locale pour refléter le statut cloud
        await sm.SaveManager.saveGame(save);

        return true;
      }

      return false;
    } catch (e, stack) {
      debugPrint('Erreur lors de la sauvegarde cloud: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
      return false;
    }
  }

  // Implémentation adaptée pour sauvegarder dans le cloud
  Future<bool> _saveSnapshotToCloud(String snapshotName, String data, String description) async {
    try {
      // Adapter cette méthode pour utiliser games_services 4.0.3
      // Cette version pourrait ne pas offrir directement l'API saveSnapshot

      // Exemple d'implémentation alternative
      try {
        await gs.GamesServices.signIn();
        // Utiliser une autre approche ou interface pour sauvegarder les données
        // Exemple: utiliser Firebase Cloud Storage comme alternative
        return true;
      } catch (e) {
        debugPrint('Erreur lors de la sauvegarde dans le cloud: $e');
        return false;
      }
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde cloud: $e');
      return false;
    }
  }

  // Charger une sauvegarde depuis le cloud
  Future<AppSaveGame?> loadFromCloud(String cloudId) async {
    try {
      bool isSignedIn = await gs.GamesServices.isSignedIn == true;
      if (!isSignedIn) {
        debugPrint('Utilisateur non connecté à Google Play Games');
        return null;
      }

      // Charger le snapshot - adapter pour games_services 4.0.3
      final content = await _loadSnapshotContent(cloudId);
      if (content == null) {
        debugPrint('Snapshot non trouvé: $cloudId');
        return null;
      }

      // Décoder le contenu JSON
      final jsonData = jsonDecode(content) as Map<String, dynamic>;

      // Créer un SaveGame à partir des données
      final saveGame = AppSaveGame.fromJson(jsonData);
      saveGame.isSyncedWithCloud = true;
      saveGame.cloudId = cloudId;

      return saveGame;
    } catch (e, stack) {
      debugPrint('Erreur lors du chargement cloud: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
      return null;
    }
  }

  // Méthodes privées pour la synchronisation
  Future<void> _uploadLocalSaves(List<sm.SaveGameInfo> localSaves, List<sm.SaveGameInfo> cloudSaves) async {
    // Identifier les sauvegardes locales qui ne sont pas sur le cloud ou qui ont été modifiées
    for (var localSave in localSaves) {
      // Ignorer les sauvegardes déjà synchronisées et à jour
      if (localSave.isSyncedWithCloud) {
        final matchingCloud = cloudSaves.firstWhere(
              (cloud) => cloud.id == localSave.id || cloud.cloudId == localSave.cloudId,
          orElse: () => localSave,
        );

        // Si la sauvegarde locale est plus récente que celle du cloud, on la téléverse
        if (localSave.timestamp.isAfter(matchingCloud.timestamp)) {
          final fullSave = await sm.SaveManager.loadGame(localSave.name);
          if (fullSave != null) {
            await saveToCloud(fullSave);
          }
        }
      } else {
        // Sauvegarde non encore synchronisée, on la téléverse
        final fullSave = await sm.SaveManager.loadGame(localSave.name);
        if (fullSave != null) {
          await saveToCloud(fullSave);
        }
      }
    }
  }

  Future<void> _downloadCloudSaves(List<sm.SaveGameInfo> localSaves, List<sm.SaveGameInfo> cloudSaves) async {
    // Identifier les sauvegardes cloud qui ne sont pas en local ou qui ont été modifiées
    for (var cloudSave in cloudSaves) {
      // Chercher une sauvegarde locale correspondante
      final matchingLocal = localSaves.firstWhere(
            (local) => local.id == cloudSave.id || (cloudSave.cloudId != null && local.cloudId == cloudSave.cloudId),
        orElse: () => sm.SaveGameInfo(
          id: cloudSave.id,
          name: cloudSave.name,
          timestamp: DateTime(1970), // Date ancienne pour forcer le téléchargement
          version: cloudSave.version,
          paperclips: cloudSave.paperclips,
          money: cloudSave.money,
          gameMode: cloudSave.gameMode,
        ),
      );

      // Si la sauvegarde cloud est plus récente ou n'existe pas en local
      if (cloudSave.timestamp.isAfter(matchingLocal.timestamp)) {
        final fullSave = await loadFromCloud(cloudSave.cloudId!);
        if (fullSave != null) {
          // Vérifier si le nom existe déjà localement et ajuster si nécessaire
          String adjustedName = fullSave.name;
          bool exists = await sm.SaveManager.saveExists(adjustedName);
          int counter = 1;

          while (exists && counter < 100) {
            adjustedName = '${fullSave.name} (Cloud ${counter})';
            exists = await sm.SaveManager.saveExists(adjustedName);
            counter++;
          }

          // Créer une nouvelle sauvegarde locale avec les données du cloud
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
    }
  }
}