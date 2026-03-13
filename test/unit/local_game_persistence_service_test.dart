import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:paperclip2/services/persistence/local_game_persistence.dart';
import 'package:paperclip2/services/persistence/game_snapshot.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalGamePersistenceService - snapshot save/load', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('saveSnapshot then loadSnapshot returns normalized snapshot', () async {
      const service = LocalGamePersistenceService();
      final partieId = 'world-123';

      final snapshot = GameSnapshot(
        metadata: {
          // Deliberately missing worldId/createdAt to test normalization
        },
        core: <String, dynamic>{'paperclips': 42},
        market: const <String, dynamic>{},
        production: const <String, dynamic>{},
        stats: const <String, dynamic>{},
      );

      await service.saveSnapshot(snapshot, slotId: partieId);

      final loaded = await service.loadSnapshot(slotId: partieId);
      expect(loaded, isNotNull);

      final md = loaded!.metadata;
      expect(md['worldId'], equals(partieId));
      expect(md['createdAt'], isA<String>());
      expect(md['updatedAt'], isA<String>());
      expect(md['gameVersion'], isA<String>());
    });
  });
}
