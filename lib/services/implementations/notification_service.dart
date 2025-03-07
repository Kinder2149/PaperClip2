import 'package:flutter/material.dart';
import '../interfaces/i_notification_service.dart';

class NotificationService implements INotificationService {
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    try {
      _isInitialized = true;
    } catch (e) {
      print('Erreur lors de l\'initialisation du service de notifications: $e');
      rethrow;
    }
  }

  void _checkInitialization() {
    if (!_isInitialized) {
      throw StateError('Le service de notifications n\'est pas initialisé');
    }
  }

  @override
  Future<void> showNotification({
    required String title,
    required String message,
    IconData? icon,
    Duration? duration,
  }) async {
    _checkInitialization();
    
    if (title.isEmpty) {
      throw ArgumentError('Le titre ne peut pas être vide');
    }
    if (message.isEmpty) {
      throw ArgumentError('Le message ne peut pas être vide');
    }

    try {
      _scaffoldKey.currentState?.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              if (icon != null) Icon(icon),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          duration: duration ?? const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      print('Erreur lors de l\'affichage de la notification: $e');
      rethrow;
    }
  }

  @override
  Future<void> showAchievement(String title, String message) async {
    if (title.isEmpty) {
      throw ArgumentError('Le titre ne peut pas être vide');
    }
    if (message.isEmpty) {
      throw ArgumentError('Le message ne peut pas être vide');
    }

    try {
      await showNotification(
        title: '🏆 $title',
        message: message,
        icon: Icons.emoji_events,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      print('Erreur lors de l\'affichage du succès: $e');
      rethrow;
    }
  }

  @override
  Future<void> showLevelUp(int level, List<String> newFeatures) async {
    if (level <= 0) {
      throw ArgumentError('Le niveau doit être supérieur à 0');
    }
    if (newFeatures.isEmpty) {
      throw ArgumentError('La liste des nouvelles fonctionnalités ne peut pas être vide');
    }

    try {
      await showNotification(
        title: '🎉 Niveau $level atteint !',
        message: 'Nouvelles fonctionnalités débloquées :\n${newFeatures.join('\n')}',
        icon: Icons.star,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      print('Erreur lors de l\'affichage du niveau supérieur: $e');
      rethrow;
    }
  }

  @override
  Future<void> showError(String message) async {
    if (message.isEmpty) {
      throw ArgumentError('Le message d\'erreur ne peut pas être vide');
    }

    try {
      await showNotification(
        title: '❌ Erreur',
        message: message,
        icon: Icons.error,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      print('Erreur lors de l\'affichage de l\'erreur: $e');
      rethrow;
    }
  }

  @override
  Future<void> showWarning(String message) async {
    if (message.isEmpty) {
      throw ArgumentError('Le message d\'avertissement ne peut pas être vide');
    }

    try {
      await showNotification(
        title: '⚠️ Attention',
        message: message,
        icon: Icons.warning,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      print('Erreur lors de l\'affichage de l\'avertissement: $e');
      rethrow;
    }
  }

  @override
  Future<void> showSuccess(String message) async {
    if (message.isEmpty) {
      throw ArgumentError('Le message de succès ne peut pas être vide');
    }

    try {
      await showNotification(
        title: '✅ Succès',
        message: message,
        icon: Icons.check_circle,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      print('Erreur lors de l\'affichage du succès: $e');
      rethrow;
    }
  }

  @override
  Future<void> showProgress({
    required String title,
    required String message,
    required double progress,
  }) async {
    _checkInitialization();

    if (title.isEmpty) {
      throw ArgumentError('Le titre ne peut pas être vide');
    }
    if (message.isEmpty) {
      throw ArgumentError('Le message ne peut pas être vide');
    }
    if (progress < 0 || progress > 1) {
      throw ArgumentError('La progression doit être comprise entre 0 et 1');
    }

    try {
      _scaffoldKey.currentState?.showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1 ? Colors.green : Colors.blue,
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      print('Erreur lors de l\'affichage de la progression: $e');
      rethrow;
    }
  }

  @override
  Future<void> dismissAll() async {
    _checkInitialization();
    
    try {
      _scaffoldKey.currentState?.clearSnackBars();
    } catch (e) {
      print('Erreur lors de la fermeture des notifications: $e');
      rethrow;
    }
  }
} 