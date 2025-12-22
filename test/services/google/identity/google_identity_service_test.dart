import 'package:flutter_test/flutter_test.dart';

import 'package:paperclip2/services/google/identity/google_identity_service.dart';
import 'package:paperclip2/services/google/identity/identity_status.dart';
import 'package:paperclip2/services/google/identity/play_games_identity_adapter.dart';

class _FakeSignedOutAdapter implements PlayGamesIdentityAdapter {
  @override
  Future<String?> getPlayerId() async => null;
  @override
  Future<bool> isSignedIn() async => false;
  @override
  Future<bool> signIn() async => false;
  @override
  Future<void> signOut() async {}
  @override
  Future<String?> getDisplayName() async => null;
  @override
  Future<String?> getAvatarUrl() async => null;
}

class _FakeSignedInAdapter implements PlayGamesIdentityAdapter {
  final String id;
  _FakeSignedInAdapter(this.id);
  @override
  Future<String?> getPlayerId() async => id;
  @override
  Future<bool> isSignedIn() async => true;
  @override
  Future<bool> signIn() async => true;
  @override
  Future<void> signOut() async {}
  @override
  Future<String?> getDisplayName() async => 'Player';
  @override
  Future<String?> getAvatarUrl() async => null;
}

void main() {
  group('GoogleIdentityService', () {
    test('refresh reflect anonymous when adapter signed out', () async {
      final svc = GoogleIdentityService(adapter: _FakeSignedOutAdapter());
      final st = await svc.refresh();
      expect(st, IdentityStatus.anonymous);
      expect(svc.playerId, isNull);
    });

    test('signIn populates playerId and signedIn', () async {
      final svc = GoogleIdentityService(adapter: _FakeSignedInAdapter('P123'));
      final st = await svc.signIn();
      expect(st, IdentityStatus.signedIn);
      expect(svc.playerId, 'P123');
    });

    test('signOut resets to anonymous', () async {
      final svc = GoogleIdentityService(adapter: _FakeSignedInAdapter('P999'));
      await svc.signIn();
      await svc.signOut();
      expect(svc.status, IdentityStatus.anonymous);
      expect(svc.playerId, isNull);
    });
  });
}
