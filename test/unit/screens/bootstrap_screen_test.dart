import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:paperclip2/screens/bootstrap_screen.dart';
import 'package:paperclip2/services/app_bootstrap_controller.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/services/background_music.dart';
import 'package:paperclip2/services/lifecycle/app_lifecycle_handler.dart';
import 'package:paperclip2/services/theme_service.dart';
import 'package:paperclip2/services/ui/game_ui_port.dart';
import 'package:paperclip2/services/audio/game_audio_port.dart';

class _FakeUiPort implements GameUiPort {
  @override
  void showLeaderboardUnavailable(String message) {}

  @override
  void showPriceExcessiveWarning({
    required String title,
    required String description,
    required String? detailedDescription,
  }) {}

  @override
  void showUnlockNotification(String message) {}

  @override
  void showCompetitiveResult(CompetitiveResultData data) {}
}

class _FakeAudioPort implements GameAudioPort {
  @override
  Future<void> loadGameMusicState(String gameName) async {}
  @override
  Future<void> setBgmEnabled(bool enabled) async {}
  @override
  Future<void> playSfx(String cue) async {}
  @override
  Future<void> setVolume(double volume) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget _buildTestApp({
    required AppBootstrapController controller,
    required WidgetBuilder startBuilder,
  }) {
    return ChangeNotifierProvider<AppBootstrapController>.value(
      value: controller,
      child: MaterialApp(
        home: BootstrapScreen(startScreenBuilder: startBuilder),
      ),
    );
  }

  testWidgets('BootstrapScreen ne navigue pas tant que bootstrap n\'est pas ready', (tester) async {
    final controller = AppBootstrapController(
      gameState: GameState()..initialize(),
      uiPort: _FakeUiPort(),
      audioPort: _FakeAudioPort(),
      backgroundMusicService: BackgroundMusicService(),
      themeService: ThemeService(),
      lifecycleHandler: AppLifecycleHandler(),
      envConfigLoad: () async {},
      persistenceBackupCheck: () async {},
      wireUiAudioPorts: () async {},
      registerLifecycle: () async {},
      themeInit: () async {},
      backgroundMusicInit: () async {},
      backgroundMusicPreferences: () async {},
    );

    await tester.pumpWidget(
      _buildTestApp(
        controller: controller,
        startBuilder: (_) => const SizedBox(key: Key('start-destination')),
      ),
    );

    // Laisse passer le post-frame callback qui démarre bootstrap()
    await tester.pump();

    // Tant que bootstrap n'est pas ready, BootstrapScreen affiche un loader.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Initialisation…'), findsOneWidget);

    // La destination ne doit pas être affichée tant qu'on n'est pas ready.
    expect(find.byKey(const Key('start-destination')), findsNothing);

    // Pas de StartScreen injecté ici; on valide juste qu'on n'a pas trigger de navigation
    // (dans ce test, on ne peut pas facilement observer Navigator sans observer).
  });

  testWidgets('BootstrapScreen navigue vers StartScreen quand bootstrap passe à ready', (tester) async {
    final controller = AppBootstrapController(
      gameState: GameState()..initialize(),
      uiPort: _FakeUiPort(),
      audioPort: _FakeAudioPort(),
      backgroundMusicService: BackgroundMusicService(),
      themeService: ThemeService(),
      lifecycleHandler: AppLifecycleHandler(),
      envConfigLoad: () async {},
      persistenceBackupCheck: () async {},
      wireUiAudioPorts: () async {},
      registerLifecycle: () async {},
      themeInit: () async {},
      backgroundMusicInit: () async {},
      backgroundMusicPreferences: () async {},
    );

    await tester.pumpWidget(
      _buildTestApp(
        controller: controller,
        startBuilder: (_) => const Scaffold(body: Text('DESTINATION_OK')),
      ),
    );

    // Déclenche bootstrap()
    await tester.pump();

    // Laisse terminer les futures (bootstrap steps vides)
    await tester.pumpAndSettle();

    // La destination devrait être présente après navigation.
    expect(find.text('DESTINATION_OK'), findsOneWidget);
  });
}
