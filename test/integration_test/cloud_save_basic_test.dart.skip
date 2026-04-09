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
    final createdEnterpriseIds = <String>[];
    
    setUpAll(() async {
      await TestConfig.initialize();
      cloudAdapter = CloudPersistenceAdapter(base: TestConfig.functionsApiBase);
    });
    
    tearDownAll(() async {
      // Cleanup tous les mondes créés
      for (final enterpriseId in createdEnterpriseIds) {
        try {
          await cloudAdapter.deleteById(enterpriseId: enterpriseId);
        } catch (_) {}
      }
    });
    
    test('Push and Pull world snapshot', () async {
      final enterpriseId = const Uuid().v4();
      createdEnterpriseIds.add(enterpriseId);
      
      final snapshot = _createSnapshot(enterpriseId, clips: 100);
      final metadata = {
        'name': 'Test World Basic',
        'game_version': '1.0.0',
      };
      
      // Push
      await cloudAdapter.pushById(
        enterpriseId: enterpriseId,
        snapshot: snapshot,
        metadata: metadata,
      );
      
      // Pull
      final pulledSnapshot = await cloudAdapter.pullById(enterpriseId: enterpriseId);
      
      expect(pulledSnapshot, isNotNull);
      expect(pulledSnapshot!['core']['clips'], 100);
      expect(pulledSnapshot['metadata']['enterpriseId'], enterpriseId);
    });
    
    test('List worlds returns pushed world', () async {
      final enterpriseId = const Uuid().v4();
      createdEnterpriseIds.add(enterpriseId);
      
      final snapshot = _createSnapshot(enterpriseId, clips: 50);
      final metadata = {'name': 'Test World List'};
      
      await cloudAdapter.pushById(
        enterpriseId: enterpriseId,
        snapshot: snapshot,
        metadata: metadata,
      );
      
      final worlds = await cloudAdapter.listParties();
      
      expect(worlds.any((w) => w.enterpriseId == enterpriseId), isTrue);
    });
    
    test('Delete world removes it from cloud', () async {
      final enterpriseId = const Uuid().v4();
      createdEnterpriseIds.add(enterpriseId);
      
      final snapshot = _createSnapshot(enterpriseId, clips: 25);
      await cloudAdapter.pushById(
        enterpriseId: enterpriseId,
        snapshot: snapshot,
        metadata: {},
      );
      
      // Delete
      await cloudAdapter.deleteById(enterpriseId: enterpriseId);
      
      // Verify deleted
      final pulledSnapshot = await cloudAdapter.pullById(enterpriseId: enterpriseId);
      expect(pulledSnapshot, isNull);
    });
    
    test('Status returns correct cloud state', () async {
      final enterpriseId = const Uuid().v4();
      createdEnterpriseIds.add(enterpriseId);
      
      // Before push
      final statusBefore = await cloudAdapter.statusById(enterpriseId: enterpriseId);
      expect(statusBefore.exists, isFalse);
      
      // Push
      final snapshot = _createSnapshot(enterpriseId, clips: 75);
      await cloudAdapter.pushById(
        enterpriseId: enterpriseId,
        snapshot: snapshot,
        metadata: {'name': 'Test Status'},
      );
      
      // After push
      final statusAfter = await cloudAdapter.statusById(enterpriseId: enterpriseId);
      expect(statusAfter.exists, isTrue);
      expect(statusAfter.lastSavedAt, isNotNull);
    });
  });
}

Map<String, dynamic> _createSnapshot(String enterpriseId, {required int clips}) {
  return {
    'metadata': {
      'enterpriseId': enterpriseId,
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
