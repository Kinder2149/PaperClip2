import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/services/cloud/cloud_persistence_port.dart';
import 'package:paperclip2/services/persistence/game_persistence_orchestrator.dart';
import 'package:paperclip2/services/save_system/save_manager_adapter.dart';
import '../../../../test/helpers/in_memory_save_manager.dart';

class _MemPort implements CloudPersistencePort {
  final Map<String, Map<String, dynamic>> store = {};

  @override
  Future<void> pushById({required String partieId, required Map<String, dynamic> snapshot, required Map<String, dynamic> metadata}) async {
    store[partieId] = {'snapshot': snapshot, 'metadata': metadata};
  }

  @override
  Future<Map<String, dynamic>?> pullById({required String partieId}) async {
    return store[partieId];
  }

  @override
  Future<CloudStatus> statusById({required String partieId}) async => CloudStatus(partieId: partieId, syncState: 'unknown');

  @override
  Future<List<CloudIndexEntry>> listParties() async {
    return store.keys.map((id) => CloudIndexEntry(partieId: id)).toList();
  }

  @override
  Future<void> deleteById({required String partieId}) async {
    store.remove(partieId);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Anti-doublons étendus (ID-first)', () {
    setUp(() {
      SaveManagerAdapter.setSaveManagerForTesting(InMemorySaveGameManager());
      GamePersistenceOrchestrator.instance.resetForTesting();
    });

    tearDown(() {
      SaveManagerAdapter.resetForTesting();
      GamePersistenceOrchestrator.instance.resetForTesting();
    });

    test('Deux parties locales distinctes restent distinctes après union local+cloud', () async {
      final port = _MemPort();
      GamePersistenceOrchestrator.instance.setCloudPort(port);
      GamePersistenceOrchestrator.instance.setPlayerIdProvider(() async => 'player-test');

      // Créer deux sauvegardes locales distinctes par ID
      final mem = InMemorySaveGameManager();
      final s1 = await mem.createNewSave(name: 'Campagne A');
      final s2 = await mem.createNewSave(name: 'Campagne B');
      await SaveManagerAdapter.saveGame(s1.copyWith(id: 'id-A', name: 'Campagne A'));
      await SaveManagerAdapter.saveGame(s2.copyWith(id: 'id-B', name: 'Campagne B'));

      // Côté cloud: une entrée pour id-A avec un nom différent (cloud gagne sur ce slot)
      port.store['id-A'] = {
        'snapshot': {
          'metadata': {'schemaVersion': 1},
          'core': {'money': 1},
          'stats': {}
        },
        'metadata': {'name': 'Campagne A (Cloud)'}
      };
      // Côté cloud: une entrée tierce id-C inexistante localement
      port.store['id-C'] = {
        'snapshot': {
          'metadata': {'schemaVersion': 1},
          'core': {'money': 0},
          'stats': {}
        },
        'metadata': {'name': 'Campagne C (Cloud)'}
      };

      await GamePersistenceOrchestrator.instance.onPlayerConnected(playerId: 'player-test');

      final metas = await SaveManagerAdapter.listSaves();
      // Les deux IDs locaux restent présents
      expect(metas.any((m) => m.id == 'id-A'), isTrue);
      expect(metas.any((m) => m.id == 'id-B'), isTrue);
      // Le cloud-only id-C est matérialisé sans écraser id-B
      expect(metas.any((m) => m.id == 'id-C'), isTrue);
      // Sur le slot commun id-A, le nom devient celui du cloud (cloud gagne), pas d’écrasement d’un autre ID
      final aMeta = metas.firstWhere((m) => m.id == 'id-A');
      expect(aMeta.name, 'Campagne A (Cloud)');
    });

    test('Renommage local ne provoque pas d’écrasement croisé entre IDs différents', () async {
      final port = _MemPort();
      GamePersistenceOrchestrator.instance.setCloudPort(port);
      GamePersistenceOrchestrator.instance.setPlayerIdProvider(() async => 'player-test');

      final mem = InMemorySaveGameManager();
      final s1 = await mem.createNewSave(name: 'Nom Initial');
      final s2 = await mem.createNewSave(name: 'Autre Partie');
      await SaveManagerAdapter.saveGame(s1.copyWith(id: 'id-1', name: 'Nom Initial'));
      await SaveManagerAdapter.saveGame(s2.copyWith(id: 'id-2', name: 'Autre Partie'));

      // Renommage local de id-2 pour avoir le même nom que le cloud d'id-1
      await SaveManagerAdapter.updateSaveMetadataById('id-2', (await SaveManagerAdapter.getSaveMetadataById('id-2'))!.copyWith(name: 'Nom Cloud'));

      // Cloud: id-1 avec nom "Nom Cloud"
      port.store['id-1'] = {
        'snapshot': {
          'metadata': {'schemaVersion': 1},
          'core': {'money': 0},
          'stats': {}
        },
        'metadata': {'name': 'Nom Cloud'}
      };

      await GamePersistenceOrchestrator.instance.onPlayerConnected(playerId: 'player-test');

      final metas = await SaveManagerAdapter.listSaves();
      // Les deux IDs restent distincts, aucune fusion par nom
      expect(metas.any((m) => m.id == 'id-1'), isTrue);
      expect(metas.any((m) => m.id == 'id-2'), isTrue);
      // id-1 prend le nom cloud, id-2 garde son nom renommé (identique mais ID distinct)
      final id1 = metas.firstWhere((m) => m.id == 'id-1');
      final id2 = metas.firstWhere((m) => m.id == 'id-2');
      expect(id1.name, 'Nom Cloud');
      expect(id2.name, 'Nom Cloud');
    });
  });
}
