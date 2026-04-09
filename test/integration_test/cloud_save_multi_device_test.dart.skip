import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paperclip2/services/cloud/cloud_persistence_adapter.dart';
import 'package:uuid/uuid.dart';
import 'test_config.dart';

/// Tests E2E pour la synchronisation multi-appareils
/// 
/// Ces tests simulent plusieurs appareils accédant au même monde cloud.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Cloud Save - Multi-Device Sync', () {
    late CloudPersistenceAdapter device1;
    late CloudPersistenceAdapter device2;
    final createdEnterpriseIds = <String>[];
    
    setUpAll(() async {
      await TestConfig.initialize();
      device1 = CloudPersistenceAdapter(base: TestConfig.functionsApiBase);
      device2 = CloudPersistenceAdapter(base: TestConfig.functionsApiBase);
    });
    
    tearDownAll(() async {
      for (final enterpriseId in createdEnterpriseIds) {
        try {
          await device1.deleteById(enterpriseId: enterpriseId);
        } catch (_) {}
      }
    });
    
    test('Device 1 creates, Device 2 pulls, Device 1 pulls updates', () async {
      final enterpriseId = const Uuid().v4();
      createdEnterpriseIds.add(enterpriseId);
      final worldName = 'Multi-Device Test ${DateTime.now().millisecondsSinceEpoch}';
      
      // === DEVICE 1: Create and push ===
      print('📱 Device 1: Creating world...');
      
      final snapshot1 = _createSnapshot(enterpriseId, clips: 100);
      final metadata1 = {'name': worldName, 'game_version': '1.0.0'};
      
      await device1.pushById(
        enterpriseId: enterpriseId,
        snapshot: snapshot1,
        metadata: metadata1,
      );
      
      print('✅ Device 1: World pushed to cloud');
      
      // Attendre propagation
      await Future.delayed(const Duration(seconds: 2));
      
      // === DEVICE 2: Pull ===
      print('📱 Device 2: Pulling world...');
      
      final pulledData = await device2.pullById(enterpriseId: enterpriseId);
      expect(pulledData, isNotNull);
      expect(pulledData!['core']['clips'], 100);
      
      print('✅ Device 2: World pulled successfully');
      
      // === DEVICE 2: Modify and push ===
      print('📱 Device 2: Modifying world...');
      
      final snapshot2 = Map<String, dynamic>.from(pulledData);
      snapshot2['core']['clips'] = 200; // Progression
      snapshot2['metadata']['updatedAt'] = DateTime.now().toIso8601String();
      
      await device2.pushById(
        enterpriseId: enterpriseId,
        snapshot: snapshot2,
        metadata: {'name': worldName, 'game_version': '1.0.0'},
      );
      
      print('✅ Device 2: Modified world pushed');
      
      // Attendre propagation
      await Future.delayed(const Duration(seconds: 2));
      
      // === DEVICE 1: Pull updates ===
      print('📱 Device 1: Pulling updates...');
      
      final updatedData = await device1.pullById(enterpriseId: enterpriseId);
      expect(updatedData, isNotNull);
      expect(updatedData!['core']['clips'], 200);
      
      print('✅ Device 1: Updates pulled successfully');
      print('✅ Multi-device sync validated!');
    });
    
    test('Conflict resolution: last-write-wins', () async {
      final enterpriseId = const Uuid().v4();
      createdEnterpriseIds.add(enterpriseId);
      
      // Device 1 et Device 2 modifient simultanément (offline)
      final snapshot1 = _createSnapshot(enterpriseId, clips: 100);
      final snapshot2 = _createSnapshot(enterpriseId, clips: 200);
      
      // Device 1 push en premier
      await device1.pushById(
        enterpriseId: enterpriseId,
        snapshot: snapshot1,
        metadata: {'name': 'Conflict Test'},
      );
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Device 2 push ensuite (écrase)
      await device2.pushById(
        enterpriseId: enterpriseId,
        snapshot: snapshot2,
        metadata: {'name': 'Conflict Test'},
      );
      
      await Future.delayed(const Duration(seconds: 1));
      
      // Vérifier: Device 2 a gagné (last-write-wins)
      final result = await device1.pullById(enterpriseId: enterpriseId);
      expect(result!['core']['clips'], 200);
    });
    
    test('Multiple devices can list same worlds', () async {
      final enterpriseId = const Uuid().v4();
      createdEnterpriseIds.add(enterpriseId);
      
      // Device 1 crée un monde
      final snapshot = _createSnapshot(enterpriseId, clips: 50);
      await device1.pushById(
        enterpriseId: enterpriseId,
        snapshot: snapshot,
        metadata: {'name': 'Shared World'},
      );
      
      await Future.delayed(const Duration(seconds: 1));
      
      // Device 1 et Device 2 listent les mondes
      final list1 = await device1.listParties();
      final list2 = await device2.listParties();
      
      // Les deux doivent voir le monde
      expect(list1.any((w) => w.enterpriseId == enterpriseId), isTrue);
      expect(list2.any((w) => w.enterpriseId == enterpriseId), isTrue);
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
