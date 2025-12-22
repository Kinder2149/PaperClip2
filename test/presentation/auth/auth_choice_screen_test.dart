import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:paperclip2/screens/auth_choice_screen.dart';
import 'package:paperclip2/services/google/google_bootstrap.dart';
import 'package:paperclip2/services/google/identity/google_identity_service.dart';
import 'package:paperclip2/services/google/identity/play_games_identity_adapter.dart';
import 'package:paperclip2/services/google/achievements/achievements_service.dart';
import 'package:paperclip2/services/google/achievements/achievements_adapter.dart';
import 'package:paperclip2/services/google/leaderboards/leaderboards_service.dart';
import 'package:paperclip2/services/google/leaderboards/leaderboards_adapter.dart';
import 'package:paperclip2/services/google/cloudsave/cloud_save_service.dart';
import 'package:paperclip2/services/google/cloudsave/noop_cloud_save_adapter.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/services/identity/email_identity_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeIdentityAdapter implements PlayGamesIdentityAdapter {
  bool signedIn = false;
  @override
  Future<bool> isSignedIn() async => signedIn;
  @override
  Future<bool> signIn() async {
    signedIn = true;
    return true;
  }
  @override
  Future<bool> signOut() async {
    signedIn = false;
    return true;
  }
  @override
  Future<String?> getPlayerId() async => signedIn ? 'test-player' : null;
  @override
  Future<String?> getDisplayName() async => signedIn ? 'Tester' : null;
  @override
  Future<String?> getAvatarUrl() async => null;
}

class _FakeGoogleServices extends GoogleServicesBundle {
  _FakeGoogleServices()
      : super(
          identity: GoogleIdentityService(adapter: _FakeIdentityAdapter()),
          achievements: AchievementsService(adapter: NoopAchievementsAdapter()),
          leaderboards: LeaderboardsService(adapter: NoopLeaderboardsAdapter()),
        );
}

class NoopAchievementsAdapter implements AchievementsAdapter {
  @override
  Future<bool> isReady() async => true;
  @override
  Future<void> unlock(String id) async {}
  @override
  Future<void> reveal(String id) async {}
}

class NoopLeaderboardsAdapter implements LeaderboardsAdapter {
  @override
  Future<bool> isReady() async => true;
  @override
  Future<void> submitScore(String leaderboardKey, int score) async {}
}

class _TestEmailService extends EmailIdentityService {
  _TestEmailService() : super(initializeOverride: () async {});
  @override
  Future<AuthResponse> signInWithEmail({required String email, required String password}) async {
    // Retourne un objet neutre pour le test
    return AuthResponse(session: null, user: null);
  }
}

void main() {
  testWidgets('AuthChoiceScreen - Connexion Google navigue vers GoogleControlCenter', (tester) async {
    final fakeGoogle = _FakeGoogleServices();
    final cloud = CloudSaveService(adapter: NoopCloudSaveAdapter());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => GameState()),
          Provider<GoogleServicesBundle>.value(value: fakeGoogle),
          Provider<CloudSaveService>.value(value: cloud),
        ],
        child: const MaterialApp(home: AuthChoiceScreen()),
      ),
    );

    // Taper sur "Se connecter avec Google"
    await tester.tap(find.text('Se connecter avec Google'));
    await tester.pumpAndSettle();

    // La page GoogleControlCenter doit s'ouvrir (vérifions le titre AppBar)
    expect(find.text('Centre Google'), findsOneWidget);
  });

  testWidgets('AuthChoiceScreen - Connexion Email utilise le service injecté', (tester) async {
    final fakeGoogle = _FakeGoogleServices();
    final cloud = CloudSaveService(adapter: NoopCloudSaveAdapter());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => GameState()),
          Provider<GoogleServicesBundle>.value(value: fakeGoogle),
          Provider<CloudSaveService>.value(value: cloud),
        ],
        child: MaterialApp(home: AuthChoiceScreen(emailService: _TestEmailService())),
      ),
    );

    await tester.tap(find.text('Se connecter avec Email'));
    await tester.pumpAndSettle();

    // Remplir le dialogue
    await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password');

    // Cliquer sur Se connecter
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    // Le dialogue doit être fermé
    expect(find.text('Connexion Email'), findsNothing);
  });
}
