import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/services/google/common/games_services_facade.dart';
import 'package:paperclip2/services/google/identity/games_services_play_games_identity_adapter.dart';

class _FakeFacade implements GamesServicesFacade {
  bool _signedIn = false;
  @override
  Future<String?> getPlayerId() async => _signedIn ? 'player-123' : null;
  @override
  Future<String?> getPlayerIconImage() async => null;
  @override
  Future<String?> getPlayerName() async => _signedIn ? 'Player' : null;
  @override
  Future<bool> isSignedIn() async => _signedIn;
  @override
  Future<void> signIn() async => _signedIn = true;
  @override
  Future<void> submitScore({required String androidLeaderboardId, required int value}) async {}
  @override
  Future<void> unlockAchievement({required String androidId}) async {}
}

void main() {
  group('GamesServicesPlayGamesIdentityAdapter', () {
    test('refresh/sign methods behave with facade (no platform needed)', () async {
      final adapter = GamesServicesPlayGamesIdentityAdapter(facade: _FakeFacade());

      expect(await adapter.isSignedIn(), isFalse);
      expect(await adapter.getPlayerId(), isNull);

      final ok = await adapter.signIn();
      expect(ok, isTrue);
      expect(await adapter.isSignedIn(), isTrue);
      expect(await adapter.getPlayerId(), isNotNull);

      await adapter.signOut(); // no-op, stays signed in from facade
      expect(await adapter.isSignedIn(), isTrue);
    });
  });
}
