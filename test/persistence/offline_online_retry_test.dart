import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:paperclip2/screens/save_load_screen.dart';
import 'package:paperclip2/models/save_game.dart';
import 'package:paperclip2/services/save_system/save_manager_adapter.dart';
import 'package:paperclip2/services/cloud/cloud_persistence_port.dart';
import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/services/persistence/game_persistence_orchestrator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:paperclip2/services/google/google_bootstrap.dart';
import 'package:paperclip2/services/google/identity/google_identity_service.dart';
import 'package:paperclip2/services/google/identity/play_games_identity_adapter.dart';

class _AlwaysSignedInAdapter implements PlayGamesIdentityAdapter {
  @override
  Future<bool> isSignedIn() async => true;
  @override
  Future<bool> signIn() async => true;
  @override
  Future<void> signOut() async {}
  @override
  Future<String?> getPlayerId() async => 'player-xyz';
  @override
  Future<String?> getDisplayName() async => 'Tester';
  @override
  Future<String?> getAvatarUrl() async => null;
}

class _FlakyPushPort implements CloudPersistencePort {
  bool fail = true;
  int pushAttempts = 0;
  @override
  Future<void> pushById({
    required String partieId,
    required Map<String, dynamic> snapshot,
    required Map<String, dynamic> metadata,
  }) async {
    pushAttempts++;
    if (fail) {
      throw Exception('network down');
    }
  }

  @override
  Future<Map<String, dynamic>?> pullById({required String partieId}) async => null;

  @override
  Future<CloudStatus> statusById({required String partieId}) async => CloudStatus(partieId: partieId, syncState: 'unknown');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('offline→online retry: pending flag triggers pushCloudFromSaveId and clears flag', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await dotenv.load(fileName: '.env', mergeWith: {
      'FEATURE_CLOUD_PER_PARTIE': 'true',
      'FEATURE_ADVANCED_CLOUD_UI': 'true',
    });

    final id = 'retry-partie-1';
    final save = SaveGame(
      id: id,
      name: 'Retry Partie',
      lastSaveTime: DateTime.now(),
      version: GameConstants.VERSION,
      gameMode: GameMode.INFINITE,
      gameData: {
        'gameSnapshot': {
          'metadata': {'partieId': id},
          'core': {'money': 0},
        }
      },
    );
    final ok = await SaveManagerAdapter.saveGame(save);
    expect(ok, isTrue);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pending_cloud_push_'+id, true);

    final port = _FlakyPushPort();
    GamePersistenceOrchestrator.instance.setCloudPort(port);

    final identity = GoogleIdentityService(adapter: _AlwaysSignedInAdapter());
    await identity.refresh();
    final bundle = GoogleServicesBundle(
      identity: identity,
      achievements: createGoogleServices().achievements,
      leaderboards: createGoogleServices().leaderboards,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<GoogleServicesBundle>.value(value: bundle),
        ],
        child: const MaterialApp(home: SaveLoadScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect((await SharedPreferences.getInstance()).getBool('pending_cloud_push_'+id), isTrue);

    port.fail = false;

    // Rafraîchir l'écran pour déclencher le retry
    await tester.tap(find.byTooltip('Actualiser'));
    await tester.pumpAndSettle();

    final after = await SharedPreferences.getInstance();
    expect(after.getBool('pending_cloud_push_'+id) ?? false, isFalse);
    expect(port.pushAttempts, greaterThanOrEqualTo(1));
  });
}
