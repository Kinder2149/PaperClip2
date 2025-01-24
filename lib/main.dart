// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';

// Imports des écrans
import './screens/start_screen.dart';
import './screens/main_screen.dart';
import './screens/save_load_screen.dart';
import './screens/production_screen.dart';
import './screens/market_screen.dart';
import './screens/upgrades_screen.dart';
import './screens/event_log_screen.dart';
import 'screens/introduction_screen.dart';

// Imports des modèles
import './models/game_state.dart';
import './models/game_config.dart';
import './models/event_system.dart';
import './models/progression_system.dart';

// Imports des services et utils
import './services/save_manager.dart';
import './services/background_music.dart';
import './utils/update_manager.dart';

// Imports des widgets
import './widgets/notification_widgets.dart';

// Export du navigatorKey
export 'package:paperclip2/main.dart' show navigatorKey;

// Clé globale pour la navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameState()),
        Provider<BackgroundMusicService>(
          create: (_) => BackgroundMusicService(),
          dispose: (_, service) => service.dispose(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'PaperClip Game',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Consumer<GameState>(
        builder: (context, gameState, child) {
          print('GameState initialized: ${gameState.isInitialized}'); // Pour le debug
          return gameState.isInitialized
              ? const MainScreen()
              : const StartScreen();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}