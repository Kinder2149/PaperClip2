import 'dart:convert' show jsonDecode;
import 'package:flutter/foundation.dart';
import '../../utils/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/models/save_game.dart';
import 'package:paperclip2/services/persistence/local_game_persistence.dart';
// SaveManagerAdapter supprimé - LocalSaveGameManager utilisé directement
import 'package:paperclip2/services/save_system/local_save_game_manager.dart';
import 'package:paperclip2/services/save_game.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:paperclip2/services/persistence/game_persistence_orchestrator.dart';
import 'package:paperclip2/services/cloud/cloud_persistence_port.dart';

enum SaveSource { local, cloud }

class SaveEntry {
  final SaveSource source;
  final String id; // local: save.id; cloud: fixed slotName
  final String name; // display name
  final DateTime? lastModified;
  final String? playerId; // for cloud
  final String version;
  final bool isBackup;
  final bool isRestored;
  final double money;
  final int paperclips;
  final int totalPaperclipsSold;
  final int level; // Niveau du joueur
  final String? cloudSyncState; // in_sync | ahead_local | ahead_remote | diverged | unknown
  final int? remoteVersion; // présent si un snapshot cloud existe
  final String? integrityStatus; // valid | migratable | corrupt
  final bool canLoad; // actionnable depuis l'UI

  const SaveEntry({
    required this.source,
    required this.id,
    required this.name,
    required this.lastModified,
    required this.version,
    required this.isBackup,
    required this.isRestored,
    required this.money,
    required this.paperclips,
    required this.totalPaperclipsSold,
    this.level = 1,
    this.playerId,
    this.cloudSyncState,
    this.remoteVersion,
    this.integrityStatus,
    this.canLoad = true,
  });
}

class SaveAggregator {
  // Cache supprimé: plus de dépendance au statut cloud technique
  static final Logger _logger = Logger.forComponent('save-aggregator');

  /// CORRECTION POST-AUDIT: Cloud-first strict - Le cloud est la source de vérité.
  /// Cette méthode affiche d'abord les mondes cloud, enrichis avec les stats locales.
  /// Les mondes locaux orphelins sont ajoutés à la fin (seront poussés au prochain login).
  Future<List<SaveEntry>> listAll(BuildContext context) async {
    final List<SaveEntry> result = [];
    final enableCloudPerPartie = (dotenv.env['FEATURE_CLOUD_PER_PARTIE'] ?? 'false').toLowerCase() == 'true';

    // 1. CLOUD D'ABORD (source de vérité)
    Map<String, CloudIndexEntry> cloudIndex = {};
    if (enableCloudPerPartie) {
      try {
        final cloud = await GamePersistenceOrchestrator.instance.listCloudParties();
        for (final c in cloud) {
          cloudIndex[c.enterpriseId] = c;
        }
      } catch (_) {}
    }

    // 2. LOCAL pour enrichissement (stats de jeu)
    final mgr = await LocalSaveGameManager.getInstance();
    final localMeta = await mgr.listSaves();
    
    // CORRECTION CRITIQUE: Charger les vraies données depuis les snapshots
    final List<SaveGameInfo> localInfos = [];
    for (final meta in localMeta) {
      try {
        // Charger le snapshot complet pour extraire les stats
        final save = await mgr.loadSave(meta.id);
        
        // CORRECTION: Le snapshot est dans gameData[snapshotKey], pas directement dans gameData
        Map<String, dynamic>? snapshotData;
        if (save?.gameData != null) {
          final gameData = save!.gameData;
          // Le snapshot est stocké sous la clé LocalGamePersistenceService.snapshotKey
          if (gameData.containsKey(LocalGamePersistenceService.snapshotKey)) {
            final snapRaw = gameData[LocalGamePersistenceService.snapshotKey];
            if (snapRaw is Map) {
              snapshotData = Map<String, dynamic>.from(snapRaw as Map);
            } else if (snapRaw is String) {
              // Si c'est une String JSON, la parser
              try {
                final decoded = jsonDecode(snapRaw);
                if (decoded is Map) {
                  snapshotData = Map<String, dynamic>.from(decoded as Map);
                }
              } catch (_) {}
            }
          }
        }
        
        localInfos.add(SaveGameInfo.fromMetadata(
          meta,
          gameData: snapshotData,
          isBackup: meta.name.contains(GameConstants.BACKUP_DELIMITER),
        ));
      } catch (e) {
        // Fallback si le chargement échoue : utiliser des valeurs par défaut
        if (kDebugMode) {
          _logger.warn('[SAVE] Échec chargement snapshot pour ${meta.id}: $e');
        }
        localInfos.add(SaveGameInfo(
          id: meta.id,
          name: meta.name,
          timestamp: meta.lastModified,
          version: meta.version,
          paperclips: 0,
          money: 0,
          totalPaperclipsSold: 0,
          autoClipperCount: 0,
          isBackup: meta.name.contains(GameConstants.BACKUP_DELIMITER),
          isRestored: meta.isRestored,
        ));
      }
    }
    
    final Map<String, SaveGameInfo> localIndex = {};
    for (final s in localInfos) {
      if (!s.isBackup) {
        localIndex[s.id] = s;
      }
    }

    // 3. Construire la liste à partir du CLOUD (source de vérité)
    for (final cloudEntry in cloudIndex.values) {
      final localInfo = localIndex[cloudEntry.enterpriseId];

      if (localInfo != null) {
        // Monde cloud + local: utiliser les stats locales pour enrichir
        String? integrity;
        bool canLoad = true;
        try {
          integrity = await GamePersistenceOrchestrator.instance.validateForListing(localInfo.id);
          if (integrity == GamePersistenceOrchestrator.integrityMissing) {
            if (kDebugMode) {
              _logger.debug('[SAVE] SaveAggregator: exclusion entrée orpheline id='+localInfo.id);
            }
            continue;
          }
          if (integrity == GamePersistenceOrchestrator.integrityCorrupt) {
            canLoad = false;
          }
        } catch (_) {}

        result.add(SaveEntry(
          source: SaveSource.cloud, // CORRECTION: Source = cloud (vérité)
          id: cloudEntry.enterpriseId,
          name: cloudEntry.name ?? localInfo.name,
          lastModified: cloudEntry.lastPushAt ?? localInfo.timestamp,
          version: localInfo.version,
          isBackup: false,
          isRestored: localInfo.isRestored,
          money: localInfo.money.toDouble(),
          paperclips: localInfo.paperclips.toInt(),
          totalPaperclipsSold: localInfo.totalPaperclipsSold.toInt(),
          level: localInfo.level,
          playerId: cloudEntry.playerId,
          cloudSyncState: 'in_sync', // Cloud + local = synchronisé
          remoteVersion: cloudEntry.remoteVersion,
          integrityStatus: integrity,
          canLoad: canLoad,
        ));
      } else {
        // Monde cloud-only: matérialisation à la demande
        result.add(SaveEntry(
          source: SaveSource.cloud,
          id: cloudEntry.enterpriseId,
          name: cloudEntry.name ?? cloudEntry.enterpriseId,
          lastModified: cloudEntry.lastPushAt ?? cloudEntry.lastPullAt,
          version: cloudEntry.gameVersion ?? GameConstants.VERSION,
          isBackup: false,
          isRestored: false,
          money: 0,
          paperclips: 0,
          totalPaperclipsSold: 0,
          level: 1, // Niveau par défaut pour cloud-only
          playerId: cloudEntry.playerId,
          cloudSyncState: 'ahead_remote',
          remoteVersion: cloudEntry.remoteVersion,
          integrityStatus: null,
          canLoad: true, // Jouable (matérialisation auto dans loadGameById)
        ));
      }
    }

    // 4. Ajouter les mondes locaux orphelins (seront poussés au prochain login)
    for (final localInfo in localInfos) {
      if (localInfo.isBackup) continue;
      if (cloudIndex.containsKey(localInfo.id)) continue; // Déjà traité ci-dessus

      String? integrity;
      bool canLoad = true;
      try {
        integrity = await GamePersistenceOrchestrator.instance.validateForListing(localInfo.id);
        if (integrity == GamePersistenceOrchestrator.integrityMissing) {
          if (kDebugMode) {
            _logger.debug('[SAVE] SaveAggregator: exclusion entrée orpheline id='+localInfo.id);
          }
          continue;
        }
        if (integrity == GamePersistenceOrchestrator.integrityCorrupt) {
          canLoad = false;
        }
      } catch (_) {}

      result.add(SaveEntry(
        source: SaveSource.local,
        id: localInfo.id,
        name: localInfo.name,
        lastModified: localInfo.timestamp,
        version: localInfo.version,
        isBackup: false,
        isRestored: localInfo.isRestored,
        money: localInfo.money.toDouble(),
        paperclips: localInfo.paperclips.toInt(),
        totalPaperclipsSold: localInfo.totalPaperclipsSold.toInt(),
        level: localInfo.level,
        playerId: null,
        cloudSyncState: 'ahead_local', // À pousser au cloud
        remoteVersion: null,
        integrityStatus: integrity,
        canLoad: canLoad,
      ));
    }

    // Trier par date décroissante
    result.sort((a, b) {
      final ad = a.lastModified?.millisecondsSinceEpoch ?? 0;
      final bd = b.lastModified?.millisecondsSinceEpoch ?? 0;
      return bd.compareTo(ad);
    });

    return result;
  }

  DateTime? _parseIso(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    try {
      return DateTime.parse(iso);
    } catch (_) {
      return null;
    }
  }
}
