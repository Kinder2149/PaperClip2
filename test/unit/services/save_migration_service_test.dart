import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/models/save_game.dart';
import 'package:paperclip2/services/persistence/local_game_persistence.dart';
import 'package:paperclip2/services/save_migration_service.dart';
import 'package:paperclip2/services/save_system/save_manager_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SaveMigrationService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      SaveManagerAdapter.resetForTesting();
    });

    test('migrateData 1.0 -> 1.5 ajoute id/timestamp et convertit wire->metal', () async {
      final old = <String, dynamic>{
        'version': '1.0',
        'playerManager': <String, dynamic>{
          'wire': 12.5,
        },
      };

      final migrated = await SaveMigrationService.migrateData(old, '1.0', '1.5');

      expect(migrated['version'], '1.5');
      expect(migrated['id'], isA<String>());
      expect(migrated['timestamp'], isA<String>());

      final player = migrated['playerManager'] as Map<String, dynamic>;
      expect(player['metal'], 12.5);
    });

    test('migrateData 1.5 -> 2.0 crée gameData et déplace les sections', () async {
      final old = <String, dynamic>{
        'version': '1.5',
        'timestamp': DateTime(2025, 1, 1).toIso8601String(),
        'id': 'abc',
        'playerManager': <String, dynamic>{'money': 1.0, 'metal': 0.0, 'paperclips': 0.0, 'sellPrice': 0.05},
        'marketManager': <String, dynamic>{'marketMetalStock': 100.0},
        'gameMode': 0,
        'totalTimePlayedInSeconds': 42,
      };

      final migrated = await SaveMigrationService.migrateData(old, '1.5', '2.0');

      expect(migrated['version'], '2.0');
      expect(migrated.containsKey('gameData'), isTrue);

      final gameData = migrated['gameData'] as Map<String, dynamic>;
      expect(gameData.containsKey('playerManager'), isTrue);
      expect(gameData.containsKey('marketManager'), isTrue);
      expect(gameData['gameMode'], 0);
      expect(gameData['totalTimePlayedInSeconds'], 42);

      // Les clés déplacées ne doivent plus être à la racine.
      expect(migrated.containsKey('playerManager'), isFalse);
      expect(migrated.containsKey('marketManager'), isFalse);
    });

    test('migrateData échoue si aucun chemin de migration', () async {
      final old = <String, dynamic>{'version': '0.9'};

      expect(
        () => SaveMigrationService.migrateData(old, '0.9', '2.0'),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('compactAllSaves retire les champs legacy du gameData et du snapshot metadata', () async {
      await SaveManagerAdapter.ensureInitialized();

      const slotId = 'compact_test_slot';
      const saveId = 'compact_test_id';

      final snapshotKey = LocalGamePersistenceService.snapshotKey;
      final gameData = <String, dynamic>{
        'statistics': <String, dynamic>{
          'totalGameTimeSec': 100,
          'totalPaperclipsProduced': 200,
        },
        'totalTimePlayedInSeconds': 123,
        'totalPaperclipsProduced': 456,
        snapshotKey: <String, dynamic>{
          'metadata': <String, dynamic>{
            'gameId': slotId,
            'totalTimePlayedInSeconds': 999,
            'totalPaperclipsProduced': 888,
          },
          'core': <String, dynamic>{},
        },
      };

      await SaveManagerAdapter.saveGame(
        SaveGame(
          id: saveId,
          name: slotId,
          lastSaveTime: DateTime.now(),
          gameData: gameData,
          version: '2.0',
          gameMode: GameMode.INFINITE,
        ),
      );

      final before = await SaveManagerAdapter.loadGame(slotId);
      expect(before, isNotNull);
      expect(before!.gameData.containsKey('totalTimePlayedInSeconds'), isTrue);
      expect(before.gameData.containsKey('totalPaperclipsProduced'), isTrue);

      await SaveMigrationService.compactAllSaves();

      final after = await SaveManagerAdapter.loadGame(slotId);
      expect(after, isNotNull);
      expect(after!.gameData.containsKey('totalTimePlayedInSeconds'), isFalse);
      expect(after.gameData.containsKey('totalPaperclipsProduced'), isFalse);

      final rawSnapshot = after.gameData[snapshotKey];
      expect(rawSnapshot, isA<Map>());
      final snap = Map<String, dynamic>.from(rawSnapshot as Map);
      final meta = Map<String, dynamic>.from(snap['metadata'] as Map);
      expect(meta.containsKey('totalTimePlayedInSeconds'), isFalse);
      expect(meta.containsKey('totalPaperclipsProduced'), isFalse);
    });

    test('compactAllSaves est idempotente (flag): ne recompresse pas une 2e fois', () async {
      await SaveManagerAdapter.ensureInitialized();

      const slotId = 'compact_flag_slot';
      const saveId = 'compact_flag_id';

      // 1) première sauvegarde avec legacy
      await SaveManagerAdapter.saveGame(
        SaveGame(
          id: saveId,
          name: slotId,
          lastSaveTime: DateTime.now(),
          gameData: <String, dynamic>{
            'totalTimePlayedInSeconds': 1,
            'totalPaperclipsProduced': 2,
          },
          version: '2.0',
          gameMode: GameMode.INFINITE,
        ),
      );

      await SaveMigrationService.compactAllSaves();

      // 2) On réintroduit volontairement les clés legacy
      await SaveManagerAdapter.saveGame(
        SaveGame(
          id: saveId,
          name: slotId,
          lastSaveTime: DateTime.now(),
          gameData: <String, dynamic>{
            'totalTimePlayedInSeconds': 111,
            'totalPaperclipsProduced': 222,
          },
          version: '2.0',
          gameMode: GameMode.INFINITE,
        ),
      );

      // 3) La compaction ne doit plus s'appliquer
      await SaveMigrationService.compactAllSaves();

      final loaded = await SaveManagerAdapter.loadGame(slotId);
      expect(loaded, isNotNull);
      expect(loaded!.gameData['totalTimePlayedInSeconds'], 111);
      expect(loaded.gameData['totalPaperclipsProduced'], 222);
    });
  }, skip: true);
}
