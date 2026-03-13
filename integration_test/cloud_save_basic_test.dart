import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paperclip2/services/cloud/cloud_persistence_adapter.dart';
import 'package:paperclip2/constants/game_constants.dart';
import 'package:uuid/uuid.dart';
import 'test_config.dart';

/// Tests E2E basiques pour la sauvegarde cloud
/// 
/// Ces tests vérifient les opérations CRUD de base sur les mondes cloud.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Cloud Save - Basic Operations', () {
    late CloudPersistenceAdapter cloudAdapter;
    final createdWorldIds = <String>[];
    
    setUpAll(() async {
      await TestConfig.initialize();
      cloudAdapter = CloudPersistenceAdapter(base: TestConfig.functionsApiBase);
    });
    
    tearDownAll(() async {
      // Cleanup tous les mondes créés
      for (final worldId in createdWorldIds) {
        try {
          await cloudAdapter.deleteById(partieId: worldId);
        } catch (_) {}
      }
    });
    
    test('Push and Pull world snapshot', () async {
      final worldId = const Uuid().v4();
      createdWorldIds.add(worldId);
      
      final snapshot = _createSnapshot(worldId, clips: 100);
      final metadata = {
        'name': 'Test World Basic',
        'game_version': '1.0.0',
      };
      
      // Push
      await cloudAdapter.pushById(
        partieId: worldId,
        snapshot: snapshot,
        metadata: metadata,
      );
      
      // Pull
      final pulledSnapshot = await cloudAdapter.pullById(partieId: worldId);
      
      expect(pulledSnapshot, isNotNull);
      expect(pulledSnapshot!['core']['clips'], 100);
      expect(pulledSnapshot['metadata']['worldId'], worldId);
    });
    
    test('List worlds returns pushed world', () async {
      final worldId = const Uuid().v4();
      createdWorldIds.add(worldId);
      
      final snapshot = _createSnapshot(worldId, clips: 50);
      final metadata = {'name': 'Test World List'};
      
      await cloudAdapter.pushById(
        partieId: worldId,
        snapshot: snapshot,
        metadata: metadata,
      );
      
      final worlds = await cloudAdapter.listParties();
      
      expect(worlds.any((w) => w.partieId == worldId), isTrue);
    });
    
    test('Delete world removes it from cloud', () async {
      final worldId = const Uuid().v4();
      createdWorldIds.add(worldId);
      
      final snapshot = _createSnapshot(worldId, clips: 25);
      await cloudAdapter.pushById(
        partieId: worldId,
        snapshot: snapshot,
        metadata: {},
      );
      
      // Delete
      await cloudAdapter.deleteById(partieId: worldId);
      
      // Verify deleted
      final pulledSnapshot = await cloudAdapter.pullById(partieId: worldId);
      expect(pulledSnapshot, isNull);
    });
    
    test('Status returns correct cloud state', () async {
      final worldId = const Uuid().v4();
      createdWorldIds.add(worldId);
      
      // Before push
      final statusBefore = await cloudAdapter.statusById(partieId: worldId);
      expect(statusBefore.exists, isFalse);
      
      // Push
      final snapshot = _createSnapshot(worldId, clips: 75);
      await cloudAdapter.pushById(
        partieId: worldId,
        snapshot: snapshot,
        metadata: {'name': 'Test Status'},
      );
      
      // After push
      final statusAfter = await cloudAdapter.statusById(partieId: worldId);
      expect(statusAfter.exists, isTrue);
      expect(statusAfter.lastSavedAt, isNotNull);
    });
  });
}

Map<String, dynamic> _createSnapshot(String worldId, {required int clips}) {
  return {
    'metadata': {
      'worldId': worldId,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
      'gameVersion': '1.0.0',
    },
    'core': {
      'clips': clips,
      'money': 0.0,
    },
    'stats': {
      'totalClips': clips,
    },
  };
}
