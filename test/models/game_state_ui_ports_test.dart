import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/services/ui/game_ui_port.dart';

class _FakeNotificationPort implements GameNotificationPort {
  int priceExcessiveCalls = 0;
  String? lastPriceTitle;
  String? lastPriceDescription;

  int unlockCalls = 0;
  String? lastUnlockMessage;

  int leaderboardUnavailableCalls = 0;
  String? lastLeaderboardMessage;

  @override
  void showPriceExcessiveWarning({
    required String title,
    required String description,
    required String? detailedDescription,
  }) {
    priceExcessiveCalls++;
    lastPriceTitle = title;
    lastPriceDescription = description;
  }

  @override
  void showUnlockNotification(String message) {
    unlockCalls++;
    lastUnlockMessage = message;
  }

  @override
  void showLeaderboardUnavailable(String message) {
    leaderboardUnavailableCalls++;
    lastLeaderboardMessage = message;
  }
}

class _FakeNavigationPort implements GameNavigationPort {
  int competitiveResultCalls = 0;
  CompetitiveResultData? lastData;

  @override
  void showCompetitiveResult(CompetitiveResultData data) {
    competitiveResultCalls++;
    lastData = data;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameState - ports UI (Option B)', () {
    test('setSellPrice déclenche le port notification en cas de prix excessif', () {
      final gameState = GameState();
      gameState.initialize();

      final notificationPort = _FakeNotificationPort();
      gameState.setNotificationPort(notificationPort);

      // Prix volontairement élevé pour déclencher le warning.
      gameState.setSellPrice(999999);

      expect(notificationPort.priceExcessiveCalls, 1);
      expect(notificationPort.lastPriceTitle, isNotNull);
      expect(notificationPort.lastPriceDescription, isNotNull);

      gameState.dispose();
    });

    test('handleCompetitiveGameEnd déclenche le port navigation en mode compétitif', () async {
      final gameState = GameState();
      gameState.initialize();

      final navigationPort = _FakeNavigationPort();
      gameState.setNavigationPort(navigationPort);

      // Préparer un état minimal pour calculer un score non-trivial.
      gameState.playerManager.updateMoney(123.0);
      gameState.playerManager.updatePaperclips(100);
      gameState.playerManager.updateMetal(GameConstants.METAL_PER_PAPERCLIP);

      await gameState.startNewGame('test_competitive', mode: GameMode.COMPETITIVE);

      gameState.handleCompetitiveGameEnd();

      expect(navigationPort.competitiveResultCalls, 1);
      expect(navigationPort.lastData, isNotNull);
      expect(navigationPort.lastData!.score, isA<int>());

      gameState.dispose();
    });
  });
}
