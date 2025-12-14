import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/services/persistence/game_persistence_orchestrator.dart';
import 'package:paperclip2/services/save_game.dart';

class _UninitializedGameState extends GameState {
  @override
  bool get isInitialized => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GamePersistenceOrchestrator', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('saveGame throw SaveError si GameState non initialisé', () async {
      final state = _UninitializedGameState();

      await expectLater(
        GamePersistenceOrchestrator.instance.saveGame(state, 'test-save'),
        throwsA(isA<SaveError>()),
      );

      state.dispose();
    });

    test('saveGame puis loadGame fonctionne (roundtrip minimal)', () async {
      final original = GameState();
      original.initialize();

      // État non-trivial
      original.playerManager.updateMoney(123.0);
      original.playerManager.updateMetal(10.0);
      original.playerManager.updatePaperclips(50);

      const name = 'orchestrator-roundtrip';

      await GamePersistenceOrchestrator.instance.saveGame(original, name);

      final restored = GameState();
      restored.initialize();

      await GamePersistenceOrchestrator.instance.loadGame(restored, name);

      expect(restored.playerManager.money, closeTo(123.0, 0.001));
      expect(restored.playerManager.metal, closeTo(10.0, 0.001));
      expect(restored.playerManager.paperclips, closeTo(50.0, 0.001));

      original.dispose();
      restored.dispose();
    });
  });
}
