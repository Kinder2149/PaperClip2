import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:paperclip2/main.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/services/background_music.dart';
import 'package:paperclip2/services/theme_service.dart';
import 'package:paperclip2/models/event_system.dart';

void main() {
  testWidgets('MyApp se construit avec les providers requis', (WidgetTester tester) async {
    // Préparer des instances locales pour le test
    final gameState = GameState();
    gameState.initialize();

    final backgroundMusicService = BackgroundMusicService();
    final themeService = ThemeService();
    await themeService.initialize();

    // Construire l'application avec les mêmes providers que dans main.dart
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: gameState),
          Provider<BackgroundMusicService>.value(value: backgroundMusicService),
          ChangeNotifierProvider.value(value: themeService),
          ChangeNotifierProvider.value(value: EventManager.instance),
        ],
        child: const MyApp(),
      ),
    );

    // Vérifier simplement que l'arbre se construit et contient un MaterialApp
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
