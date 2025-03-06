// lib/app/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences.dart';

import '../app/router.dart';
import '../app/dependency_injection.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/imports.dart';

// ViewModels
import '../presentation/viewmodels/production_viewmodel.dart';
import '../presentation/viewmodels/market_viewmodel.dart';
import '../presentation/viewmodels/upgrades_viewmodel.dart';
import '../presentation/viewmodels/game_viewmodel.dart';

// Services
import '../domain/services/background_music_service.dart';
import '../domain/services/event_manager_service.dart';
import '../domain/services/daily_reward_service.dart';
import '../domain/services/notification_service.dart';
import '../domain/services/reward_service.dart';
import '../domain/services/event_service.dart';

// Repositories
import '../data/repositories/upgrades_repository_impl.dart';
import '../data/repositories/save_repository_impl.dart';
import '../domain/repositories/upgrades_repository.dart';
import '../domain/repositories/save_repository.dart';

class PaperClipApp extends StatelessWidget {
  final SharedPreferences prefs;

  const PaperClipApp({Key? key, required this.prefs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Repositories
        Provider<UpgradesRepository>(
          create: (_) => UpgradesRepositoryImpl(prefs),
        ),
        Provider<SaveRepository>(
          create: (_) => SaveRepositoryImpl(prefs, context.read<PlayerRepository>()),
        ),

        // ViewModels
        ChangeNotifierProvider(
          create: (_) => getIt<ProductionViewModel>(),
        ),
        ChangeNotifierProvider(
          create: (_) => getIt<MarketViewModel>(),
        ),
        ChangeNotifierProvider<UpgradesViewModel>(
          create: (context) => UpgradesViewModel(
            playerRepository: context.read<PlayerRepository>(),
            upgradesRepository: context.read<UpgradesRepository>(),
          ),
        ),
        ChangeNotifierProvider<GameViewModel>(
          create: (context) => GameViewModel(
            saveGameUseCase: getIt<SaveGameUseCase>(),
            loadGameUseCase: getIt<LoadGameUseCase>(),
            gameRepository: context.read<GameRepository>(),
            saveRepository: context.read<SaveRepository>(),
          ),
        ),

        // Services
        Provider<BackgroundMusicService>(
          create: (_) => BackgroundMusicService(),
        ),
        Provider<EventManager>(
          create: (_) => EventManager(),
        ),
        Provider<NotificationService>(
          create: (_) => NotificationService(),
        ),
        Provider<EventService>(
          create: (_) => EventService(),
        ),
        Provider<RewardService>(
          create: (_) => RewardService(),
        ),
        Provider<DailyRewardService>(
          create: (_) => DailyRewardService(),
        ),
      ],
      child: MaterialApp(
        title: 'ClipFactory Empire',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,

        // Navigation
        initialRoute: AppRouter.startRoute,
        onGenerateRoute: AppRouter.onGenerateRoute,

        // Gestion des erreurs
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaleFactor: 1.0,
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}