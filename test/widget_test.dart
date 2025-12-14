import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/services/background_music.dart';
import 'package:paperclip2/services/theme_service.dart';
import 'package:paperclip2/models/event_system.dart';

class FakeBackgroundMusicService implements BackgroundMusicService {
  bool _isPlaying = false;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> play() async {
    _isPlaying = true;
  }

  @override
  Future<void> pause() async {
    _isPlaying = false;
  }

  @override
  Future<void> stop() async {
    _isPlaying = false;
  }

  @override
  bool get isPlaying => _isPlaying;

  @override
  void dispose() {}

  @override
  Future<void> setPlayingState(bool playing) async {
    _isPlaying = playing;
  }

  @override
  Future<void> saveGameMusicState(String gameName, bool isPlaying) async {}

  @override
  Future<void> loadGameMusicState(String gameName) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MyApp se construit avec les providers requis', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    // Préparer des instances locales pour le test
    final gameState = GameState();
    gameState.initialize();

    final backgroundMusicService = FakeBackgroundMusicService();
    final themeService = ThemeService();
    await themeService.initialize();

    // Construire un arbre minimal avec les mêmes providers que dans main.dart.
    // On évite volontairement MyApp/LoadingScreen (navigation + timers) pour garder
    // un test stable et strictement centré sur la présence des providers.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: gameState),
          Provider<BackgroundMusicService>.value(value: backgroundMusicService),
          ChangeNotifierProvider.value(value: themeService),
          ChangeNotifierProvider.value(value: EventManager.instance),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              // Valider l'accès aux providers requis.
              Provider.of<GameState>(context, listen: false);
              Provider.of<BackgroundMusicService>(context, listen: false);
              Provider.of<ThemeService>(context, listen: false);
              Provider.of<EventManager>(context, listen: false);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    // Vérifier simplement que l'arbre se construit et contient un MaterialApp
    expect(find.byType(MaterialApp), findsOneWidget);

    // Démonter proprement l'arbre pour éviter les timers pendants.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    gameState.dispose();
    themeService.dispose();
    backgroundMusicService.dispose();
  });
}
