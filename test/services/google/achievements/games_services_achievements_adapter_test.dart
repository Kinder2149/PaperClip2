import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/services/google/achievements/games_services_achievements_adapter.dart';
import 'package:paperclip2/services/google/common/games_services_facade.dart';

class _FakeFacade implements GamesServicesFacade {
  @override
  Future<bool> isSignedIn() async => true;
  @override
  Future<void> signIn() async {}
  @override
  Future<String?> getPlayerId() async => 'player-123';
  @override
  Future<String?> getPlayerName() async => 'Player';
  @override
  Future<String?> getPlayerIconImage() async => null;
  @override
  Future<void> unlockAchievement({required String androidId}) async {}
  @override
  Future<void> submitScore({required String androidLeaderboardId, required int value}) async {}
}

void main() {
  group('GamesServicesAchievementsAdapter', () {
    test('isReady true with facade and unlock no-throw', () async {
      final adapter = GamesServicesAchievementsAdapter(
        androidAchievementIds: const {
          'ach_totalclips_10k': 'CgkXXXXXXXX',
        },
        facade: _FakeFacade(),
      );

      final ready = await adapter.isReady();
      expect(ready, isTrue);

      await adapter.unlock('ach_totalclips_10k');
      await adapter.unlock('unknown_key');
    });
  });
}
