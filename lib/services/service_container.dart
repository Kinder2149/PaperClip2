import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'interfaces/interfaces.dart';
import 'implementations/implementations.dart';

final getIt = GetIt.instance;

Future<void> initializeServices() async {
  // Services
  final prefs = await SharedPreferences.getInstance();
  
  // Enregistrement des services
  getIt.registerSingleton<ISaveService>(SaveService(prefs));
  getIt.registerSingleton<INotificationService>(NotificationService());
  getIt.registerSingleton<IAchievementService>(AchievementService(prefs));
  getIt.registerSingleton<ILeaderboardService>(LeaderboardService(prefs));
  getIt.registerSingleton<IAnalyticsService>(AnalyticsService());

  // Initialisation des services
  await getIt<ISaveService>().initialize();
  await getIt<INotificationService>().initialize();
  await getIt<IAchievementService>().initialize();
  await getIt<ILeaderboardService>().initialize();
  await getIt<IAnalyticsService>().initialize();
}

// Getters pour accéder aux services
ISaveService get saveService => getIt<ISaveService>();
INotificationService get notificationService => getIt<INotificationService>();
IAchievementService get achievementService => getIt<IAchievementService>();
ILeaderboardService get leaderboardService => getIt<ILeaderboardService>();
IAnalyticsService get analyticsService => getIt<IAnalyticsService>(); 