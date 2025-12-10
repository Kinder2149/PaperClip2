import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/services/persistence/game_snapshot.dart';
import 'package:paperclip2/services/persistence/local_game_persistence.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalGamePersistenceService', () {
    test('saveSnapshot puis loadSnapshot conservent les données essentielles', () async {
      const slotId = 'snapshot_test_slot';
      final service = const LocalGamePersistenceService();

      final original = GameSnapshot(
        metadata: {
          'saveFormatVersion': '2.0',
          'savedAt': '2025-01-01T12:00:00.000Z',
          'gameVersion': '1.0.0-test',
          'gameMode': 0,
          'gameName': 'snapshot-test',
        },
        core: {
          'playerManager': {
            'money': 99.9,
            'paperclips': 123,
          },
          'levelSystem': {
            'level': 3,
            'xp': 42,
          },
          'gameMode': 0,
        },
        market: {
          'currentPrice': 0.25,
        },
        production: {
          'totalProduced': 321,
        },
        stats: {
          'totalGameTimeSec': 180,
        },
      );

      await service.saveSnapshot(original, slotId: slotId);
      final loaded = await service.loadSnapshot(slotId: slotId);

      expect(loaded, isNotNull);
      expect(loaded!.metadata['gameName'], 'snapshot-test');
      expect(loaded.core['playerManager']['money'], 99.9);
      expect(loaded.core['levelSystem']['level'], 3);
      expect(loaded.market?['currentPrice'], 0.25);
    });
  });
}
