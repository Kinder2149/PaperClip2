// lib/main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences.dart';
import 'data/repositories/upgrades_repository_impl.dart';
import 'domain/repositories/upgrades_repository.dart';
import 'presentation/viewmodels/upgrades_viewmodel.dart';
import 'presentation/screens/start_screen.dart';

import 'app/app.dart';
import 'core/constants/imports.dart';
import 'env_config.dart';
import 'firebase_options.dart';
import 'app/dependency_injection.dart';
import 'domain/services/daily_reward_service.dart';
import 'domain/services/notification_service.dart';

// Clé de navigation globale
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  try {
    // S'assurer que les bindings Flutter sont initialisés
    WidgetsFlutterBinding.ensureInitialized();

    // Journalisation des événements de débogage
    if (kDebugMode) {
      print('Initialisation de l\'application PaperClip Empire');
    }

    // Configuration de l'orientation de l'écran
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown
    ]);

    // Chargement de la configuration d'environnement
    await EnvConfig.load();

    // Initialisation de Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Configuration de Crashlytics
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        print('Erreur Flutter capturée : ${details.exception}');
      }
      FirebaseCrashlytics.instance.recordFlutterError(details);
    };

    // Gestion des erreurs de la plateforme
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        fatal: true,
        reason: 'Erreur globale de la plateforme',
      );
      return true;
    };

    // Configuration des dépendances
    await setupDependencies();

    final prefs = await SharedPreferences.getInstance();

    // Initialiser les services
    final notificationService = NotificationService();
    await notificationService.initialize();

    final dailyRewardService = DailyRewardService();
    await dailyRewardService.initialize();

    // Lancement de l'application
    runApp(MyApp(prefs: prefs));

  } catch (e, stackTrace) {
    // Gestion des erreurs critiques lors du démarrage
    if (kDebugMode) {
      print('Erreur critique lors du démarrage : $e');
      print('Trace de la pile : $stackTrace');
    }

    FirebaseCrashlytics.instance.recordError(
      e,
      stackTrace,
      reason: 'Erreur de démarrage de l\'application',
      fatal: true,
    );

    // En cas d'erreur critique, on peut afficher un écran d'erreur personnalisé
    runApp(ErrorApp(error: e));
  }
}

// Widget d'erreur personnalisé
class ErrorApp extends StatelessWidget {
  final dynamic error;

  const ErrorApp({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
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
              const Text(
                'Erreur de démarrage',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold
                ),
              ),
              const SizedBox(height: 10),
              Text(
                error.toString(),
                style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // TODO: Implémenter une logique de redémarrage ou de rapport d'erreur
                },
                child: const Text('Signaler l\'erreur'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({Key? key, required this.prefs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<UpgradesRepository>(
          create: (_) => UpgradesRepositoryImpl(prefs),
        ),
        ChangeNotifierProvider<UpgradesViewModel>(
          create: (context) => UpgradesViewModel(
            playerRepository: context.read<PlayerRepository>(),
            upgradesRepository: context.read<UpgradesRepository>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Paperclip Factory',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const StartScreen(),
      ),
    );
  }
}