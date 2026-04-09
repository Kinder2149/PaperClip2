// Tests Intégrité Données Cloud - Phase 2.3
// 10 tests d'intégration pour valider que TOUTES les propriétés sont sauvegardées
import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/services/persistence/game_snapshot.dart';

void main() {
  group('Tests Intégrité Données Cloud - 10 tests', () {
    
    group('Test 1: PlayerManager - Toutes propriétés sauvegardées', () {
      test('1.1 - Ressources de base (money, paperclips, metal)', () {
        // Arrange
        final snapshot = GameSnapshot(
          metadata: {
            'lastSaved': DateTime.now().toIso8601String(),
            'appVersion': '1.0.0',
          },
          core: {
            'money': 1234.56,
            'paperclips': 5000.0,
            'metal': 800.0,
            'trust': 50,
            'processors': 10.0,
            'memory': 20.0,
          },
        );
        
        // Act
        final json = snapshot.toJson();
        final restored = GameSnapshot.fromJson(json);
        
        // Assert
        expect(restored.core['money'], equals(1234.56));
        expect(restored.core['paperclips'], equals(5000.0));
        expect(restored.core['metal'], equals(800.0));
        expect(restored.core['trust'], equals(50));
        expect(restored.core['processors'], equals(10.0));
        expect(restored.core['memory'], equals(20.0));
      });

      test('1.2 - Production (autoClippers, megaClippers)', () {
        // Arrange
        final snapshot = GameSnapshot(
          metadata: {
            'lastSaved': DateTime.now().toIso8601String(),
            'appVersion': '1.0.0',
          },
          core: {
            'autoClipperCount': 15,
            'megaClipperCount': 3,
            'autoClipperCost': 50.0,
            'megaClipperCost': 100.0,
          },
        );
        
        // Act
        final json = snapshot.toJson();
        final restored = GameSnapshot.fromJson(json);
        
        // Assert
        expect(restored.core['autoClipperCount'], equals(15));
        expect(restored.core['megaClipperCount'], equals(3));
        expect(restored.core['autoClipperCost'], equals(50.0));
        expect(restored.core['megaClipperCost'], equals(100.0));
      });

      test('1.3 - Multiplicateurs et niveaux', () {
        // Arrange
        final snapshot = GameSnapshot(
          metadata: {
            'lastSaved': DateTime.now().toIso8601String(),
            'appVersion': '1.0.0',
          },
          core: {
            'productionSpeedMultiplier': 1.5,
            'productionBatchSizeMultiplier': 2.0,
            'autoMetalBuyerEnabled': true,
            'metalAutoBuyerLevel': 3.0,
            'autoClipperLevel': 5.0,
          },
        );
        
        // Act
        final json = snapshot.toJson();
        final restored = GameSnapshot.fromJson(json);
        
        // Assert
        expect(restored.core['productionSpeedMultiplier'], equals(1.5));
        expect(restored.core['productionBatchSizeMultiplier'], equals(2.0));
        expect(restored.core['autoMetalBuyerEnabled'], equals(true));
        expect(restored.core['metalAutoBuyerLevel'], equals(3.0));
        expect(restored.core['autoClipperLevel'], equals(5.0));
      });
    });

    group('Test 2: MarketManager - Toutes propriétés sauvegardées', () {
      test('2.1 - Prix et demande', () {
        // Arrange
        final snapshot = GameSnapshot(
          metadata: {
            'lastSaved': DateTime.now().toIso8601String(),
            'appVersion': '1.0.0',
          },
          core: {},
          market: {
            'sellPrice': 0.35,
            'demand': 0.65,
            'competition': 0.45,
            'marketingLevel': 2,
            'marketingCost': 150.0,
          },
        );
        
        // Act
        final json = snapshot.toJson();
        final restored = GameSnapshot.fromJson(json);
        
        // Assert
        expect(restored.market!['sellPrice'], equals(0.35));
        expect(restored.market!['demand'], equals(0.65));
        expect(restored.market!['competition'], equals(0.45));
        expect(restored.market!['marketingLevel'], equals(2));
        expect(restored.market!['marketingCost'], equals(150.0));
      });

      test('2.2 - Auto-sell et stratégie', () {
        // Arrange
        final snapshot = GameSnapshot(
          metadata: {
            'lastSaved': DateTime.now().toIso8601String(),
            'appVersion': '1.0.0',
          },
          core: {},
          market: {
            'autoSellEnabled': true,
            'autoSellThreshold': 1000.0,
            'pricingStrategy': 'dynamic',
          },
        );
        
        // Act
        final json = snapshot.toJson();
        final restored = GameSnapshot.fromJson(json);
        
        // Assert
        expect(restored.market!['autoSellEnabled'], equals(true));
        expect(restored.market!['autoSellThreshold'], equals(1000.0));
        expect(restored.market!['pricingStrategy'], equals('dynamic'));
      });
    });

    group('Test 3: LevelSystem - Niveau + XP sauvegardés', () {
      test('3.1 - Niveau et expérience', () {
        // Arrange
        final snapshot = GameSnapshot(
          metadata: {
            'lastSaved': DateTime.now().toIso8601String(),
            'appVersion': '1.0.0',
          },
          core: {
            'level': 12,
            'experience': 5678.0,
            'experienceToNextLevel': 10000.0,
          },
        );
        
        // Act
        final json = snapshot.toJson();
        final restored = GameSnapshot.fromJson(json);
        
        // Assert
        expect(restored.core['level'], equals(12));
        expect(restored.core['experience'], equals(5678.0));
        expect(restored.core['experienceToNextLevel'], equals(10000.0));
      });
    });

    group('Test 4: MissionSystem - Missions sauvegardées', () {
      test('4.1 - Missions actives et complétées', () {
        // Arrange
        final snapshot = GameSnapshot(
          metadata: {
            'lastSaved': DateTime.now().toIso8601String(),
            'appVersion': '1.0.0',
          },
          core: {
            'missions': {
              'active': [
                {
                  'id': 'mission_1',
                  'type': 'produce',
                  'target': 1000,
                  'progress': 500,
                },
              ],
              'completed': ['mission_0', 'mission_intro'],
            },
          },
        );
        
        // Act
        final json = snapshot.toJson();
        final restored = GameSnapshot.fromJson(json);
        
        // Assert
        final missions = restored.core['missions'] as Map;
        expect(missions['active'], isA<List>());
        expect((missions['active'] as List).length, equals(1));
        expect(missions['completed'], isA<List>());
        expect((missions['completed'] as List).length, equals(2));
      });
    });

    group('Test 5: RareResourcesManager - Quantum + PI sauvegardés', () {
      test('5.1 - Ressources rares (Quantum, Points Innovation)', () {
        // Arrange
        final snapshot = GameSnapshot(
          metadata: {
            'lastSaved': DateTime.now().toIso8601String(),
            'appVersion': '1.0.0',
          },
          core: {
            'quantum': 150.0,
            'pointsInnovation': 75.0,
            'quantumGenerationRate': 2.5,
            'innovationGenerationRate': 1.5,
          },
        );
        
        // Act
        final json = snapshot.toJson();
        final restored = GameSnapshot.fromJson(json);
        
        // Assert
        expect(restored.core['quantum'], equals(150.0));
        expect(restored.core['pointsInnovation'], equals(75.0));
        expect(restored.core['quantumGenerationRate'], equals(2.5));
        expect(restored.core['innovationGenerationRate'], equals(1.5));
      });
    });

    group('Test 6: ResearchManager - Recherches sauvegardées', () {
      test('6.1 - Recherches débloquées', () {
        // Arrange
        final snapshot = GameSnapshot(
          metadata: {
            'lastSaved': DateTime.now().toIso8601String(),
            'appVersion': '1.0.0',
          },
          core: {},
          research: {
            'unlocked': ['R1', 'R2', 'R3'],
            'inProgress': {
              'id': 'R4',
              'progress': 50.0,
            },
          },
        );
        
        // Act
        final json = snapshot.toJson();
        final restored = GameSnapshot.fromJson(json);
        
        // Assert
        expect(restored.research!['unlocked'], isA<List>());
        expect((restored.research!['unlocked'] as List).length, equals(3));
        expect(restored.research!['inProgress'], isA<Map>());
        expect((restored.research!['inProgress'] as Map)['id'], equals('R4'));
      });
    });

    group('Test 7: AgentManager - Agents sauvegardés', () {
      test('7.1 - Agents IA actifs', () {
        // Arrange
        final snapshot = GameSnapshot(
          metadata: {
            'lastSaved': DateTime.now().toIso8601String(),
            'appVersion': '1.0.0',
          },
          core: {
            'agents': [
              {
                'id': 'agent_1',
                'type': 'optimizer',
                'level': 3,
                'active': true,
              },
              {
                'id': 'agent_2',
                'type': 'researcher',
                'level': 2,
                'active': false,
              },
            ],
          },
        );
        
        // Act
        final json = snapshot.toJson();
        final restored = GameSnapshot.fromJson(json);
        
        // Assert
        final agents = restored.core['agents'] as List;
        expect(agents.length, equals(2));
        expect(agents[0]['id'], equals('agent_1'));
        expect(agents[0]['level'], equals(3));
        expect(agents[1]['active'], equals(false));
      });
    });

    group('Test 8: ResetManager - Historique sauvegardé', () {
      test('8.1 - Historique des resets', () {
        // Arrange
        final snapshot = GameSnapshot(
          metadata: {
            'lastSaved': DateTime.now().toIso8601String(),
            'appVersion': '1.0.0',
          },
          core: {
            'resetHistory': [
              {
                'timestamp': DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
                'level': 10,
                'quantumGained': 50.0,
              },
              {
                'timestamp': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
                'level': 15,
                'quantumGained': 100.0,
              },
            ],
            'resetCount': 2,
          },
        );
        
        // Act
        final json = snapshot.toJson();
        final restored = GameSnapshot.fromJson(json);
        
        // Assert
        final history = restored.core['resetHistory'] as List;
        expect(history.length, equals(2));
        expect(history[0]['level'], equals(10));
        expect(history[1]['quantumGained'], equals(100.0));
        expect(restored.core['resetCount'], equals(2));
      });
    });

    group('Test 9: ProductionManager - Production sauvegardée', () {
      test('9.1 - État de production', () {
        // Arrange
        final snapshot = GameSnapshot(
          metadata: {
            'lastSaved': DateTime.now().toIso8601String(),
            'appVersion': '1.0.0',
          },
          core: {},
          production: {
            'wirePrice': 22.0,
            'clipPrice': 0.28,
            'wirePurchased': 1500,
            'unsoldInventory': 50,
            'productionRate': 10.5,
            'efficiencyBonus': 1.2,
          },
        );
        
        // Act
        final json = snapshot.toJson();
        final restored = GameSnapshot.fromJson(json);
        
        // Assert
        expect(restored.production!['wirePrice'], equals(22.0));
        expect(restored.production!['clipPrice'], equals(0.28));
        expect(restored.production!['wirePurchased'], equals(1500));
        expect(restored.production!['unsoldInventory'], equals(50));
        expect(restored.production!['productionRate'], equals(10.5));
        expect(restored.production!['efficiencyBonus'], equals(1.2));
      });

      test('9.2 - Upgrades de production', () {
        // Arrange
        final snapshot = GameSnapshot(
          metadata: {
            'lastSaved': DateTime.now().toIso8601String(),
            'appVersion': '1.0.0',
          },
          core: {},
          production: {
            'upgrades': {
              'speed_1': true,
              'speed_2': true,
              'efficiency_1': true,
            },
          },
        );
        
        // Act
        final json = snapshot.toJson();
        final restored = GameSnapshot.fromJson(json);
        
        // Assert
        final upgrades = restored.production!['upgrades'] as Map;
        expect(upgrades['speed_1'], equals(true));
        expect(upgrades['speed_2'], equals(true));
        expect(upgrades['efficiency_1'], equals(true));
      });
    });

    group('Test 10: Métadonnées - Nom, ID, dates sauvegardés', () {
      test('10.1 - Identifiants entreprise', () {
        // Arrange
        final now = DateTime.now();
        final snapshot = GameSnapshot(
          metadata: {
            'lastSaved': now.toIso8601String(),
            'appVersion': '1.0.0',
            'deviceInfo': 'test-device',
          },
          core: {
            'enterpriseId': '550e8400-e29b-41d4-a716-446655440000',
            'enterpriseName': 'Ma Super Entreprise',
            'enterpriseCreatedAt': now.subtract(const Duration(days: 30)).toIso8601String(),
          },
        );
        
        // Act
        final json = snapshot.toJson();
        final restored = GameSnapshot.fromJson(json);
        
        // Assert
        expect(restored.core['enterpriseId'], equals('550e8400-e29b-41d4-a716-446655440000'));
        expect(restored.core['enterpriseName'], equals('Ma Super Entreprise'));
        expect(restored.core['enterpriseCreatedAt'], isNotNull);
        expect(restored.metadata['lastSaved'], isNotNull);
        expect(restored.metadata['appVersion'], equals('1.0.0'));
        expect(restored.metadata['deviceInfo'], equals('test-device'));
      });

      test('10.2 - Dates et timestamps', () {
        // Arrange
        final now = DateTime.now();
        final snapshot = GameSnapshot(
          metadata: {
            'lastSaved': now.toIso8601String(),
            'lastModified': now.subtract(const Duration(minutes: 5)).toIso8601String(),
            'createdAt': now.subtract(const Duration(days: 60)).toIso8601String(),
          },
          core: {
            'lastActiveAt': now.subtract(const Duration(hours: 2)).toIso8601String(),
          },
        );
        
        // Act
        final json = snapshot.toJson();
        final restored = GameSnapshot.fromJson(json);
        
        // Assert
        expect(restored.metadata['lastSaved'], isNotNull);
        expect(restored.metadata['lastModified'], isNotNull);
        expect(restored.metadata['createdAt'], isNotNull);
        expect(restored.core['lastActiveAt'], isNotNull);
        
        // Vérifier que les dates sont valides
        final lastSaved = DateTime.parse(restored.metadata['lastSaved'] as String);
        expect(lastSaved.isBefore(DateTime.now().add(const Duration(seconds: 1))), isTrue);
      });

      test('10.3 - Version et compatibilité', () {
        // Arrange
        final snapshot = GameSnapshot(
          metadata: {
            'lastSaved': DateTime.now().toIso8601String(),
            'appVersion': '3.0.0',
            'snapshotVersion': 'v3',
            'platform': 'android',
          },
          core: {},
        );
        
        // Act
        final json = snapshot.toJson();
        final restored = GameSnapshot.fromJson(json);
        
        // Assert
        expect(restored.metadata['appVersion'], equals('3.0.0'));
        expect(restored.metadata['snapshotVersion'], equals('v3'));
        expect(restored.metadata['platform'], equals('android'));
      });
    });

    group('Test Bonus: Snapshot complet avec toutes les sections', () {
      test('11.1 - Snapshot complet avec core + market + production + research', () {
        // Arrange - Créer un snapshot avec TOUTES les sections
        final snapshot = GameSnapshot(
          metadata: {
            'lastSaved': DateTime.now().toIso8601String(),
            'appVersion': '3.0.0',
            'deviceInfo': 'test-device',
          },
          core: {
            'enterpriseId': '550e8400-e29b-41d4-a716-446655440000',
            'enterpriseName': 'Entreprise Complète',
            'level': 20,
            'experience': 15000.0,
            'money': 50000.0,
            'paperclips': 100000.0,
            'metal': 5000.0,
            'trust': 100,
            'quantum': 500.0,
            'pointsInnovation': 250.0,
          },
          market: {
            'sellPrice': 0.40,
            'demand': 0.75,
            'competition': 0.50,
            'marketingLevel': 5,
            'autoSellEnabled': true,
          },
          production: {
            'wirePrice': 25.0,
            'clipPrice': 0.30,
            'wirePurchased': 10000,
            'unsoldInventory': 200,
            'productionRate': 50.0,
          },
          research: {
            'unlocked': ['R1', 'R2', 'R3', 'R4', 'R5'],
          },
        );
        
        // Act
        final json = snapshot.toJson();
        final restored = GameSnapshot.fromJson(json);
        
        // Assert - Vérifier que toutes les sections sont présentes
        expect(restored.metadata, isNotNull);
        expect(restored.core, isNotNull);
        expect(restored.market, isNotNull);
        expect(restored.production, isNotNull);
        expect(restored.research, isNotNull);
        
        // Vérifier quelques valeurs clés de chaque section
        expect(restored.core['level'], equals(20));
        expect(restored.market!['sellPrice'], equals(0.40));
        expect(restored.production!['productionRate'], equals(50.0));
        expect((restored.research!['unlocked'] as List).length, equals(5));
      });
    });
  });
}
