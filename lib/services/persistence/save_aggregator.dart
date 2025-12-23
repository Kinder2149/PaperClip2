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
  // Mission 6: cache simple pour le statut cloud (TTL court)
  static const Duration _cloudStatusTtl = Duration(seconds: 10);
  static final Map<String, _CloudCacheEntry> _statusCache = {};

  Future<List<SaveEntry>> listAll(BuildContext context) async {
    final List<SaveEntry> result = [];

    // Local saves (utiliser l'API d'agrégation qui enrichit avec les stats)
    final localInfos = await SaveManagerAdapter.listSaves();
    final enableCloudPerPartie = (dotenv.env['FEATURE_CLOUD_PER_PARTIE'] ?? 'false').toLowerCase() == 'true';
    final Set<String> localIds = localInfos.map((e) => e.id).toSet();
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
      String? cloudState;
      int? remoteVersion;
      if (enableCloudPerPartie) {
        try {
          final now = DateTime.now();
          final cached = _statusCache[s.id];
          if (cached != null && now.difference(cached.storedAt) < _cloudStatusTtl) {
            cloudState = cached.syncState;
            remoteVersion = cached.remoteVersion;
          } else {
            final status = await GamePersistenceOrchestrator.instance.cloudStatusById(partieId: s.id);
            cloudState = status.syncState;
            remoteVersion = status.remoteVersion;
            _statusCache[s.id] = _CloudCacheEntry(syncState: cloudState!, remoteVersion: remoteVersion, storedAt: now);
            // Inject playerId into SaveEntry (non mis en cache pour garder la fraicheur si session évolue)
            // On l'appliquera plus bas lors de la construction de SaveEntry
            final playerId = status.playerId;
            // Stocker temporairement dans une variable locale via closure
            // (pas besoin d'un cache séparé puisque stateless au build)
            // Utiliser un map local serait lourd; on passe via champ optionnel ci-dessous
            // en réutilisant la variable localement.
          }
        } catch (_) {
          cloudState = null;
        }
      }
      // Note: playerId non mis en cache; on refait une lecture status à TTL pour obtenir sa dernière valeur
      String? playerId;
      if (enableCloudPerPartie) {
        try {
          final status = await GamePersistenceOrchestrator.instance.cloudStatusById(partieId: s.id);
          playerId = status.playerId;
        } catch (_) {}
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
        cloudSyncState: cloudState,
        remoteVersion: remoteVersion,
        integrityStatus: integrity,
        canLoad: canLoad,
      ));
    }

    // Cloud-only (par partie): ajouter les entrées distantes qui n'existent pas en local
    if (enableCloudPerPartie) {
      try {
        final cloud = await GamePersistenceOrchestrator.instance.listCloudParties();
        for (final c in cloud) {
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
            cloudSyncState: 'unknown',
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

class _CloudCacheEntry {
  final String syncState;
  final int? remoteVersion;
  final DateTime storedAt;
  const _CloudCacheEntry({required this.syncState, required this.remoteVersion, required this.storedAt});
}
