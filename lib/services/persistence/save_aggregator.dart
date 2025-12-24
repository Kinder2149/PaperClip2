import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/models/save_game.dart';
import 'package:paperclip2/services/persistence/local_game_persistence.dart';
import 'package:paperclip2/services/save_system/save_manager_adapter.dart';
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
  final GameMode gameMode;
  final String? playerId; // for cloud
  final String version;
  final bool isBackup;
  final bool isRestored;
  final double money;
  final int paperclips;
  final int totalPaperclipsSold;
  final String? cloudSyncState; // in_sync | ahead_local | ahead_remote | diverged | unknown
  final int? remoteVersion; // présent si un snapshot cloud existe
  final String? integrityStatus; // valid | migratable | corrupt
  final bool canLoad; // actionnable depuis l'UI

  const SaveEntry({
    required this.source,
    required this.id,
    required this.name,
    required this.lastModified,
    required this.gameMode,
    required this.version,
    required this.isBackup,
    required this.isRestored,
    required this.money,
    required this.paperclips,
    required this.totalPaperclipsSold,
    this.playerId,
    this.cloudSyncState,
    this.remoteVersion,
    this.integrityStatus,
    this.canLoad = true,
  });
}

class SaveAggregator {
  // Cache supprimé: plus de dépendance au statut cloud technique

  Future<List<SaveEntry>> listAll(BuildContext context) async {
    final List<SaveEntry> result = [];

    // Local saves (utiliser l'API d'agrégation qui enrichit avec les stats)
    final localInfos = await SaveManagerAdapter.listSaves();
    final enableCloudPerPartie = (dotenv.env['FEATURE_CLOUD_PER_PARTIE'] ?? 'false').toLowerCase() == 'true';
    final Set<String> localIds = localInfos.map((e) => e.id).toSet();
    // Précharger l'index cloud une seule fois pour enrichir les entrées locales
    Map<String, CloudIndexEntry> cloudIndex = {};
    if (enableCloudPerPartie) {
      try {
        final cloud = await GamePersistenceOrchestrator.instance.listCloudParties();
        for (final c in cloud) {
          cloudIndex[c.partieId] = c;
        }
      } catch (_) {}
    }
    for (final s in localInfos) {
      // Mission 5: la liste principale ne doit pas afficher les backups
      if (s.isBackup) continue;
      // Validation d'intégrité centralisée
      String? integrity;
      bool canLoad = true;
      try {
        integrity = await GamePersistenceOrchestrator.instance.validateForListing(s.id);
        if (integrity == GamePersistenceOrchestrator.integrityMissing) {
          // Masquer les entrées orphelines (métadonnées sans données)
          if (kDebugMode) {
            print('SaveAggregator: exclusion entrée orpheline id=${s.id}');
          }
          continue;
        }
        if (integrity == GamePersistenceOrchestrator.integrityCorrupt) {
          canLoad = false; // bloquer le chargement
        }
      } catch (_) {}
      int? remoteVersion;
      String? playerId;
      if (enableCloudPerPartie) {
        final entry = cloudIndex[s.id];
        remoteVersion = entry?.remoteVersion;
        playerId = entry?.playerId;
      }
      result.add(SaveEntry(
        source: SaveSource.local,
        id: s.id,
        name: s.name,
        lastModified: s.timestamp,
        gameMode: s.gameMode,
        version: s.version,
        isBackup: s.isBackup,
        isRestored: s.isRestored,
        money: s.money.toDouble(),
        paperclips: s.paperclips.toInt(),
        totalPaperclipsSold: s.totalPaperclipsSold.toInt(),
        playerId: playerId,
        cloudSyncState: null,
        remoteVersion: remoteVersion,
        integrityStatus: integrity,
        canLoad: canLoad,
      ));
    }

    // Cloud-only (par partie): ajouter les entrées distantes qui n'existent pas en local
    if (enableCloudPerPartie) {
      try {
        for (final c in cloudIndex.values) {
          if (localIds.contains(c.partieId)) continue; // déjà reflété par l'entrée locale enrichie
          result.add(SaveEntry(
            source: SaveSource.cloud,
            id: c.partieId,
            name: c.name ?? c.partieId,
            lastModified: c.lastPushAt ?? c.lastPullAt,
            gameMode: GameMode.INFINITE, // inconnu côté index → défaut conservateur
            version: c.gameVersion ?? GameConstants.VERSION,
            isBackup: false,
            isRestored: false,
            money: 0,
            paperclips: 0,
            totalPaperclipsSold: 0,
            playerId: c.playerId,
            cloudSyncState: null,
            remoteVersion: c.remoteVersion,
            integrityStatus: null,
            canLoad: false,
          ));
        }
      } catch (_) {}
    }

    // Trier par date décroissante (cloud-only sans date passent en dernier)
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
