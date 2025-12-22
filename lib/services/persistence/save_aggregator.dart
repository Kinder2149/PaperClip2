import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/models/save_game.dart';
import 'package:paperclip2/services/google/google_bootstrap.dart';
import 'package:paperclip2/services/google/identity/google_identity_service.dart';
import 'package:paperclip2/services/google/snapshots/snapshots_cloud_save.dart';
import 'package:paperclip2/services/persistence/local_game_persistence.dart';
import 'package:paperclip2/services/save_system/save_manager_adapter.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

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
  });
}

class SaveAggregator {
  Future<List<SaveEntry>> listAll(BuildContext context) async {
    final List<SaveEntry> result = [];

    // Local saves (utiliser l'API d'agrégation qui enrichit avec les stats)
    final localInfos = await SaveManagerAdapter.listSaves();
    for (final s in localInfos) {
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
      ));
    }

    // Cloud (GPG snapshot) under flag
    try {
      final enableGpg = (dotenv.env['FEATURE_CLOUD_SAVES_GPG'] ?? 'false').toLowerCase() == 'true';
      if (enableGpg) {
        final google = context.read<GoogleServicesBundle>();
        if (google.identity.status.name == 'signedIn') {
          final svc = createSnapshotsCloudSave(identity: google.identity);
          final json = await svc.loadJson();
          if (json != null) {
            final meta = (json['metadata'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
            final gmString = (meta['gameMode'] as String?) ?? '';
            final gm = gmString.contains('COMPETITIVE') ? GameMode.COMPETITIVE : GameMode.INFINITE;
            final version = (meta['gameVersion'] as String?) ?? GameConstants.VERSION;
            final money = ((json['core'] as Map?)?['money'] as num?)?.toDouble() ?? 0.0;
            final clips = ((json['stats'] as Map?)?['paperclips'] as int?) ?? 0;
            final sold = ((json['stats'] as Map?)?['totalPaperclipsSold'] as int?) ?? 0;
            result.add(SaveEntry(
              source: SaveSource.cloud,
              id: SnapshotsCloudSave.slotName,
              name: 'Cloud · ${SnapshotsCloudSave.slotName}',
              lastModified: _parseIso(meta['savedAt'] as String?),
              gameMode: gm,
              version: version,
              isBackup: false,
              isRestored: false,
              playerId: google.identity.playerId,
              money: money,
              paperclips: clips,
              totalPaperclipsSold: sold,
            ));
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[SaveAggregator] cloud listing error: $e');
      }
    }

    // Trier: cloud en premier, puis locaux récents
    result.sort((a, b) {
      if (a.source != b.source) {
        return a.source == SaveSource.cloud ? -1 : 1;
      }
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
