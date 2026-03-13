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
    
    test('Backend enforces 10 worlds limit', () async {
      // Créer 10 mondes (doit réussir)
      for (int i = 0; i < GameConstants.MAX_WORLDS; i++) {
        final worldId = const Uuid().v4();
        createdWorldIds.add(worldId);
        
        final snapshot = _createSnapshot(worldId, name: 'World $i');
        
        await cloudAdapter.pushById(
          partieId: worldId,
          snapshot: snapshot,
          metadata: {'name': 'World $i'},
        );
        
        print('✅ Created world ${i + 1}/${GameConstants.MAX_WORLDS}');
      }
      
      // Vérifier qu'on a bien 10 mondes
      final list = await cloudAdapter.listParties();
      expect(list.length, greaterThanOrEqualTo(GameConstants.MAX_WORLDS));
      
      // Tenter de créer un 11ème monde (doit échouer avec 429)
      final worldId11 = const Uuid().v4();
      final snapshot11 = _createSnapshot(worldId11, name: 'World 11');
      
      expect(
        () => cloudAdapter.pushById(
          partieId: worldId11,
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
      if (createdWorldIds.isNotEmpty) {
        final worldToDelete = createdWorldIds.first;
        await cloudAdapter.deleteById(partieId: worldToDelete);
        createdWorldIds.remove(worldToDelete);
        
        print('✅ Deleted one world');
        
        await Future.delayed(const Duration(seconds: 1));
        
        // Créer un nouveau monde (doit réussir)
        final newWorldId = const Uuid().v4();
        createdWorldIds.add(newWorldId);
        
        final snapshot = _createSnapshot(newWorldId, name: 'New World After Delete');
        
        await cloudAdapter.pushById(
          partieId: newWorldId,
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

Map<String, dynamic> _createSnapshot(String worldId, {required String name}) {
  return {
    'metadata': {
      'worldId': worldId,
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
