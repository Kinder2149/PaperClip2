// lib/app/dependency_injection.dart
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Core
import '../core/constants/imports.dart';

// Datasources
import '../data/datasources/local/player_data_source.dart';
import '../data/datasources/local/player_data_source_impl.dart';
import '../data/datasources/local/market_data_source.dart';
import '../data/datasources/local/market_data_source_impl.dart';
import '../data/datasources/local/game_data_source.dart';
import '../data/datasources/local/game_data_source_impl.dart';

// Repositories
import '../domain/repositories/player_repository.dart';
import '../domain/repositories/market_repository.dart';
import '../domain/repositories/game_repository.dart';
import '../data/repositories/player_repository_impl.dart';
import '../data/repositories/market_repository_impl.dart';
import '../data/repositories/game_repository_impl.dart';

// UseCases
import '../domain/usecases/production/produce_paperclip_usecase.dart';
import '../domain/usecases/production/buy_autoclipper_usecase.dart';
import '../domain/usecases/market/buy_metal_usecase.dart';
import '../domain/usecases/game/save_game_usecase.dart';
import '../domain/usecases/game/load_game_usecase.dart';

// ViewModels
import '../presentation/viewmodels/production_viewmodel.dart';
import '../presentation/viewmodels/market_viewmodel.dart';
import '../presentation/viewmodels/upgrades_viewmodel.dart';
import '../presentation/viewmodels/game_viewmodel.dart';

// Services
import '../domain/services/config_service.dart';
import '../domain/services/logger_service.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // Shared Preferences
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);

  // Services
  getIt.registerLazySingleton<ConfigService>(
        () => ConfigService(getIt<SharedPreferences>()),
  );
  getIt.registerLazySingleton<LoggerService>(() => LoggerService());

  // DataSources
  getIt.registerLazySingleton<PlayerDataSource>(
        () => PlayerDataSourceImpl(getIt<SharedPreferences>()),
  );
  getIt.registerLazySingleton<MarketDataSource>(
        () => MarketDataSourceImpl(getIt<SharedPreferences>()),
  );
  getIt.registerLazySingleton<GameDataSource>(
        () => GameDataSourceImpl(getIt<SharedPreferences>()),
  );

  // Repositories
  getIt.registerLazySingleton<PlayerRepository>(
        () => PlayerRepositoryImpl(getIt<PlayerDataSource>()),
  );
  getIt.registerLazySingleton<MarketRepository>(
        () => MarketRepositoryImpl(getIt<MarketDataSource>()),
  );
  getIt.registerLazySingleton<GameRepository>(
        () => GameRepositoryImpl(getIt<GameDataSource>()),
  );

  // UseCases
  getIt.registerFactory<ProducePaperclipUseCase>(
        () => ProducePaperclipUseCase(playerRepository: getIt<PlayerRepository>()),
  );
  getIt.registerFactory<BuyAutoclipperUseCase>(
        () => BuyAutoclipperUseCase(playerRepository: getIt<PlayerRepository>()),
  );
  getIt.registerFactory<BuyMetalUseCase>(
        () => BuyMetalUseCase(
      playerRepository: getIt<PlayerRepository>(),
      marketRepository: getIt<MarketRepository>(),
    ),
  );
  getIt.registerFactory<SaveGameUseCase>(
        () => SaveGameUseCase(
      gameRepository: getIt<GameRepository>(),
    ),
  );
  getIt.registerFactory<LoadGameUseCase>(
        () => LoadGameUseCase(
      gameRepository: getIt<GameRepository>(),
    ),
  );

  // ViewModels
  getIt.registerFactory<ProductionViewModel>(
        () => ProductionViewModel(
      producePaperclipUseCase: getIt<ProducePaperclipUseCase>(),
      buyAutoclipperUseCase: getIt<BuyAutoclipperUseCase>(),
      playerRepository: getIt<PlayerRepository>(),
    ),
  );
  getIt.registerFactory<MarketViewModel>(
        () => MarketViewModel(
      buyMetalUseCase: getIt<BuyMetalUseCase>(),
      marketRepository: getIt<MarketRepository>(),
    ),
  );
  getIt.registerFactory<UpgradesViewModel>(
        () => UpgradesViewModel(
      playerRepository: getIt<PlayerRepository>(),
    ),
  );
  getIt.registerFactory<GameViewModel>(
        () => GameViewModel(
      saveGameUseCase: getIt<SaveGameUseCase>(),
      loadGameUseCase: getIt<LoadGameUseCase>(),
      gameRepository: getIt<GameRepository>(),
    ),
  );
}