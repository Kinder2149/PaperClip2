import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/models/save_game.dart';
import 'package:paperclip2/services/save_system/save_manager_adapter.dart';
import 'package:paperclip2/services/cloud/cloud_persistence_port.dart';
import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/services/persistence/game_persistence_orchestrator.dart';
import 'package:paperclip2/models/save_metadata.dart';

class _MemoryPort implements CloudPersistencePort {
  List<Map<String, dynamic>> pushes = [];
  Map<String, Map<String, dynamic>?> pulls = {};
  CloudStatus status = const CloudStatus(partieId: 'x', syncState: 'unknown');

  @override
  Future<void> pushById({
    required String partieId,
    required Map<String, dynamic> snapshot,
    required Map<String, dynamic> metadata,
  }) async {
    pushes.add({'id': partieId, 'snapshot': snapshot, 'metadata': metadata});
  }

  @override
  Future<Map<String, dynamic>?> pullById({required String partieId}) async {
    return pulls[partieId];
  }

  @override
  Future<CloudStatus> statusById({required String partieId}) async {
    return status;
  }

  @override
  Future<List<CloudIndexEntry>> listParties() async {
    return <CloudIndexEntry>[];
  }

  @override
  Future<void> deleteById({required String partieId}) async {
    pushes = pushes.where((e) => e['id'] != partieId).toList();
    pulls.remove(partieId);
  }
}

void main() {
  group('Cloud-first integration (local ⇄ cloud)', () {
    setUp(() async {
      GamePersistenceOrchestrator.instance.resetForTesting();
      // Fournir un playerId pour les pushes orchestrés
      GamePersistenceOrchestrator.instance.setPlayerIdProvider(() async => 'player-test');
    });

    test('Push aligne metadata.name sur le nom local', () async {
      final id = 'test-partie-001';
      final localName = 'Ma Partie Sympa';
      final save = SaveGame(
        id: id,
        name: localName,
        lastSaveTime: DateTime.now(),
        version: GameConstants.VERSION,
        gameMode: GameMode.INFINITE,
        gameData: {
          'gameSnapshot': {
            'metadata': {'partieId': id},
            'core': {'money': 0},
          }
        },
      );
      final ok = await SaveManagerAdapter.saveGame(save);
      expect(ok, isTrue);

      final port = _MemoryPort();
      GamePersistenceOrchestrator.instance.setCloudPort(port);
      await GamePersistenceOrchestrator.instance.pushCloudFromSaveId(partieId: id, playerId: 'player-test');

      expect(port.pushes.length, 1);
      final meta = port.pushes.first['metadata'] as Map<String, dynamic>;
      expect(meta['partieId'], id);
      expect(meta['name'], localName);
    });

    test('Après renommage local, un nouveau push utilise le nouveau metadata.name', () async {
      final id = 'test-partie-002';
      final name1 = 'Campagne 1';
      final name2 = 'Campagne 1 — Renommée';
      final save = SaveGame(
        id: id,
        name: name1,
        lastSaveTime: DateTime.now(),
        version: GameConstants.VERSION,
        gameMode: GameMode.INFINITE,
        gameData: {
          'gameSnapshot': {
            'metadata': {'partieId': id},
            'core': {'money': 0},
          }
        },
      );
      expect(await SaveManagerAdapter.saveGame(save), isTrue);

      final port = _MemoryPort();
      GamePersistenceOrchestrator.instance.setCloudPort(port);

      await GamePersistenceOrchestrator.instance.pushCloudFromSaveId(partieId: id, playerId: 'player-test');
      expect(port.pushes.isNotEmpty, isTrue);
      var lastMeta = port.pushes.last['metadata'] as Map<String, dynamic>;
      expect(lastMeta['name'], name1);

      // Renommer localement via métadonnées, puis re-push
      final meta = await SaveManagerAdapter.getSaveMetadataById(id);
      expect(meta, isNotNull);
      final updated = SaveMetadata(
        id: meta!.id,
        name: name2,
        creationDate: meta.creationDate,
        lastModified: DateTime.now(),
        version: meta.version,
        gameMode: meta.gameMode,
        displayData: meta.displayData,
        isRestored: meta.isRestored,
      );
      expect(await SaveManagerAdapter.updateSaveMetadataById(id, updated), isTrue);

      await GamePersistenceOrchestrator.instance.pushCloudFromSaveId(partieId: id, playerId: 'player-test');
      lastMeta = port.pushes.last['metadata'] as Map<String, dynamic>;
      expect(lastMeta['name'], name2);
    });
  });
}
