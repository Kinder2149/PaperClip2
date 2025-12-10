import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/models/game_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameState persistence integration', () {
    test('saveGame puis loadGame préservent les valeurs clés', () async {
      const saveName = 'integration-test-save';

      final original = GameState();
      original.initialize();

      // Simuler un état de jeu non trivial
      original.playerManager.updateMoney(123.45);
      original.playerManager.updatePaperclips(250);
      original.playerManager.updateMetal(10.0);
      original.levelSystem.addExperience(
        GameConstants.MANUAL_PRODUCTION_XP * 5,
        ExperienceType.PRODUCTION,
      );

      // Sauvegarde
      await original.saveGame(saveName);

      // Nouveau GameState pour le chargement
      final restored = GameState();
      restored.initialize();
      await restored.loadGame(saveName);

      expect(restored.playerManager.money, closeTo(123.45, 0.001));
      expect(restored.playerManager.paperclips, 250);
      expect(restored.playerManager.metal, closeTo(10.0, 0.001));
      expect(restored.levelSystem.level, original.levelSystem.level);
    });
  });
}
