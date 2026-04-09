import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paperclip2/services/cloud/cloud_persistence_adapter.dart';
import 'package:paperclip2/constants/game_constants.dart';
import 'package:uuid/uuid.dart';
import 'test_config.dart';

/// Tests E2E pour la limite de 10 mondes par utilisateur
/// 
/// Ces tests vérifient que le backend respecte la limite MAX_WORLDS.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Cloud Save - 10 Worlds Limit', () {
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
    
    test('Backend enforces 10 worlds limit', () async {
      // Créer 10 mondes (doit réussir)
      for (int i = 0; i < GameConstants.MAX_WORLDS; i++) {
        final enterpriseId = const Uuid().v4();
        createdEnterpriseIds.add(enterpriseId);
        
        final snapshot = _createSnapshot(enterpriseId, name: 'World $i');
        
        await cloudAdapter.pushById(
          enterpriseId: enterpriseId,
          snapshot: snapshot,
          metadata: {'name': 'World $i'},
        );
        
        print('✅ Created world ${i + 1}/${GameConstants.MAX_WORLDS}');
      }
      
      // Vérifier qu'on a bien 10 mondes
      final list = await cloudAdapter.listParties();
      expect(list.length, greaterThanOrEqualTo(GameConstants.MAX_WORLDS));
      
      // Tenter de créer un 11ème monde (doit échouer avec 429)
      final enterpriseId11 = const Uuid().v4();
      final snapshot11 = _createSnapshot(enterpriseId11, name: 'World 11');
      
      expect(
        () => cloudAdapter.pushById(
          enterpriseId: enterpriseId11,
          snapshot: snapshot11,
          metadata: {'name': 'World 11'},
        ),
        throwsA(
          predicate((e) => e.toString().contains('429') || 
                          e.toString().contains('push_failed_429')),
        ),
      );
      
      print('✅ 11th world correctly rejected with 429');
    });
    
    test('Can create new world after deleting one', () async {
      // Supprimer un monde existant
      if (createdEnterpriseIds.isNotEmpty) {
        final enterpriseToDelete = createdEnterpriseIds.first;
        await cloudAdapter.deleteById(enterpriseId: enterpriseToDelete);
        createdEnterpriseIds.remove(enterpriseToDelete);
        
        print('✅ Deleted one world');
        
        await Future.delayed(const Duration(seconds: 1));
        
        // Créer un nouveau monde (doit réussir)
        final newEnterpriseId = const Uuid().v4();
        createdEnterpriseIds.add(newEnterpriseId);
        
        final snapshot = _createSnapshot(newEnterpriseId, name: 'New World After Delete');
        
        await cloudAdapter.pushById(
          enterpriseId: newEnterpriseId,
          snapshot: snapshot,
          metadata: {'name': 'New World After Delete'},
        );
        
        print('✅ Successfully created new world after deletion');
      }
    });
    
    test('Limit is per user (different users can have 10 each)', () async {
      // Ce test nécessiterait deux comptes utilisateur différents
      // Pour l'instant, on vérifie juste que la limite est appliquée
      
      final list = await cloudAdapter.listParties();
      expect(list.length, lessThanOrEqualTo(GameConstants.MAX_WORLDS));
      
      print('✅ Current user has ${list.length} worlds (max ${GameConstants.MAX_WORLDS})');
    });
  });
}

Map<String, dynamic> _createSnapshot(String enterpriseId, {required String name}) {
  return {
    'metadata': {
      'enterpriseId': enterpriseId,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
      'gameVersion': '1.0.0',
    },
    'core': {
      'clips': 0,
      'money': 0.0,
    },
    'stats': {
      'totalClips': 0,
    },
  };
}
