// lib/core/error/error_handler.dart

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class AppErrorHandler {
  static final Logger _logger = Logger('AppErrorHandler');

  // Configuration globale de la gestion des erreurs
  static void initialize() {
    // Configuration du logger
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      print('${record.level.name}: ${record.time}: ${record.message}');
    });

    // Gestion des erreurs Flutter
    FlutterError.onError = (FlutterErrorDetails details) {
      // Log l'erreur
      _logger.severe('Flutter Error', details.exception, details.stack);

      // Peut être lié à Firebase Crashlytics ou autre service de tracking
      // FirebaseCrashlytics.instance.recordFlutterError(details);
    };
  }

  // Affiche une boîte de dialogue d'erreur
  static void showErrorDialog(BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: TextStyle(color: Colors.red[700])),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          if (onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              style: ElevatedButton.styleFrom(
                primary: Colors.blue,
              ),
              child: const Text('Réessayer'),
            ),
        ],
      ),
    );
  }

  // Gestion des erreurs spécifiques au jeu
  static void handleGameError(GameError error) {
    switch (error.type) {
      case GameErrorType.resourceInsufficient:
        _logger.warning('Ressources insuffisantes: ${error.message}');
        break;
      case GameErrorType.purchaseFailed:
        _logger.warning('Achat impossible: ${error.message}');
        break;
      case GameErrorType.gameStateCorrupted:
        _logger.severe('État de jeu corrompu: ${error.message}');
        break;
      default:
        _logger.warning('Erreur de jeu non gérée: ${error.message}');
    }
  }
}

// Types d'erreurs personnalisés
enum GameErrorType {
  resourceInsufficient,
  purchaseFailed,
  gameStateCorrupted,
  networkError,
  unknownError,
}

class GameError implements Exception {
  final GameErrorType type;
  final String message;
  final dynamic originalError;

  GameError({
    required this.type,
    required this.message,
    this.originalError,
  });

  @override
  String toString() => 'GameError[$type]: $message';
}

// Widget de gestion d'erreur global
class GlobalErrorWidget extends StatelessWidget {
  final FlutterErrorDetails errorDetails;

  const GlobalErrorWidget({
    Key? key,
    required this.errorDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        color: Colors.red[50],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              'Une erreur est survenue',
              style: Theme.of(context).textTheme.headline5?.copyWith(
                color: Colors.red[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                errorDetails.exception.toString(),
                style: TextStyle(color: Colors.red[800]),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // TODO: Implémenter la logique de redémarrage ou de récupération
              },
              style: ElevatedButton.styleFrom(
                primary: Colors.red[600],
              ),
              child: const Text('Redémarrer'),
            ),
          ],
        ),
      ),
    );
  }
}