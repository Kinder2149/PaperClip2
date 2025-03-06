// lib/app/router.dart
import 'package:flutter/material.dart';

// Screens
import '../presentation/screens/start_screen.dart';
import '../presentation/screens/save_load_screen.dart';
import '../presentation/screens/main_screen.dart';
import '../presentation/screens/production_screen.dart';
import '../presentation/screens/market_screen.dart';
import '../presentation/screens/upgrades_screen.dart';
import '../presentation/screens/statistics_screen.dart';

class AppRouter {
  // Routes nommées
  static const String startRoute = '/';
  static const String mainRoute = '/main';
  static const String saveLoadRoute = '/save-load';
  static const String productionRoute = '/production';
  static const String marketRoute = '/market';
  static const String upgradesRoute = '/upgrades';
  static const String statisticsRoute = '/statistics';

  // Générateur de routes
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case startRoute:
        return _buildRoute(const StartScreen());

      case mainRoute:
        return _buildRoute(const MainScreen());

      case saveLoadRoute:
        return _buildRoute(const SaveLoadScreen());

      case productionRoute:
        return _buildRoute(const ProductionScreen());

      case marketRoute:
        return _buildRoute(const MarketScreen());

      case upgradesRoute:
        return _buildRoute(const UpgradesScreen());

      case statisticsRoute:
        return _buildRoute(const StatisticsScreen());

      default:
        return _buildErrorRoute(settings.name);
    }
  }

  // Méthode de construction de route standard
  static MaterialPageRoute _buildRoute(Widget screen, {RouteSettings? settings}) {
    return MaterialPageRoute(
      builder: (_) => screen,
      settings: settings,
    );
  }

  // Route d'erreur personnalisée
  static MaterialPageRoute _buildErrorRoute(String? routeName) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Erreur de Navigation'),
          backgroundColor: Colors.red,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 100
              ),
              const SizedBox(height: 20),
              Text(
                'Route inconnue : $routeName',
                style: const TextStyle(
                    fontSize: 18,
                    color: Colors.black87
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                    startRoute,
                        (route) => false
                ),
                child: const Text('Retour à l\'accueil'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Méthode utilitaire pour la navigation
  static void navigateTo(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.of(context).pushNamed(routeName, arguments: arguments);
  }

  // Méthode utilitaire pour le remplacement de route
  static void replaceWith(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.of(context).pushReplacementNamed(routeName, arguments: arguments);
  }
}