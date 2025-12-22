import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/services/google/leaderboards/games_services_leaderboards_adapter.dart';
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
  group('GamesServicesLeaderboardsAdapter', () {
    test('isReady true with facade and submitScore no-throw', () async {
      final adapter = GamesServicesLeaderboardsAdapter(
        androidLeaderboardIds: const {
          'lb_production_total_clips': 'CgkXXXXXXXX',
        },
        facade: _FakeFacade(),
      );

      final ready = await adapter.isReady();
      expect(ready, isTrue);

      await adapter.submitScore('lb_production_total_clips', 12345);
      await adapter.submitScore('unknown_key', 1);
    });
  });
}
