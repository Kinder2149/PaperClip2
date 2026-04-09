import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../utils/logger.dart';

class NotificationManager with ChangeNotifier {
  // Singleton
  static final NotificationManager _instance = NotificationManager._internal();
  static NotificationManager get instance => _instance;
  
  NotificationManager._internal();
  
  // Référence au contexte global pour afficher les SnackBars
  GlobalKey<ScaffoldMessengerState>? _scaffoldMessengerKey;
  
  // Liste des notifications en attente
  final List<GameNotification> _pendingNotifications = [];
  
  // Définir le contexte
  void setContext(BuildContext context) {
    // Conservé pour compatibilité (ne plus utiliser).
  }

  void setScaffoldMessengerKey(GlobalKey<ScaffoldMessengerState> key) {
    _scaffoldMessengerKey = key;
    _processPendingNotifications();
  }
  
  // Afficher une notification
  void showNotification({
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    NotificationLevel level = NotificationLevel.INFO,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (kDebugMode) {
      print('🔥🔥🔥 [NotificationManager] showNotification called | message="$message" level=$level 🔥🔥🔥');
    }
    
    final notification = GameNotification(
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      level: level,
      duration: duration,
    );
    
    final isKeyAvailable = _scaffoldMessengerKey?.currentState != null;
    if (kDebugMode) {
      print('🔥🔥🔥 [NotificationManager] ScaffoldMessengerKey available: $isKeyAvailable 🔥🔥🔥');
    }
    
    // Si le contexte n'est pas disponible, mettre en attente
    if (!isKeyAvailable) {
      _pendingNotifications.add(notification);
      if (kDebugMode) {
        print('🔥🔥🔥 [NotificationManager] Notification queued (${_pendingNotifications.length} in queue) | message="$message" 🔥🔥🔥');
        appLogger.debug('[STATE] Notification en attente: '+message);
      }
      return;
    }
    
    // Afficher la notification
    if (kDebugMode) {
      print('🔥🔥🔥 [NotificationManager] Displaying notification immediately | message="$message" 🔥🔥🔥');
    }
    _showSnackBar(notification);
  }
  
  // Traiter les notifications en attente
  void _processPendingNotifications() {
    if (_scaffoldMessengerKey?.currentState == null || _pendingNotifications.isEmpty) return;
    
    if (kDebugMode) {
      print('🔥🔥🔥 [NotificationManager] Processing ${_pendingNotifications.length} pending notifications 🔥🔥🔥');
    }
    
    // Afficher les notifications en attente
    for (var notification in List.from(_pendingNotifications)) {
      if (kDebugMode) {
        print('🔥🔥🔥 [NotificationManager] Displaying queued notification | message="${notification.message}" 🔥🔥🔥');
      }
      _showSnackBar(notification);
      _pendingNotifications.remove(notification);
    }
    
    if (kDebugMode) {
      print('🔥🔥🔥 [NotificationManager] All pending notifications processed 🔥🔥🔥');
    }
  }
  
  // Afficher une SnackBar
  void _showSnackBar(GameNotification notification) {
    final scaffoldMessenger = _scaffoldMessengerKey?.currentState;
    if (scaffoldMessenger == null) return;
    
    // Définir la couleur en fonction du niveau
    Color backgroundColor;
    switch (notification.level) {
      case NotificationLevel.SUCCESS:
        backgroundColor = Colors.green;
        break;
      case NotificationLevel.WARNING:
        backgroundColor = Colors.orange;
        break;
      case NotificationLevel.ERROR:
        backgroundColor = Colors.red;
        break;
      case NotificationLevel.INFO:
      default:
        backgroundColor = Colors.blue;
    }
    
    // Créer la SnackBar
    final snackBar = SnackBar(
      content: Text(
        notification.message,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: backgroundColor,
      duration: notification.duration,
      action: notification.actionLabel != null && notification.onAction != null
          ? SnackBarAction(
              label: notification.actionLabel!,
              textColor: Colors.white,
              onPressed: notification.onAction!,
            )
          : null,
    );
    
    // Afficher la SnackBar
    scaffoldMessenger.showSnackBar(snackBar);
  }
  
  /// Efface toutes les notifications en attente et ferme les notifications affichées
  void clearAll() {
    _pendingNotifications.clear();
    
    _scaffoldMessengerKey?.currentState?.clearSnackBars();
    
    if (kDebugMode) {
      appLogger.debug('[STATE] Toutes les notifications ont été effacées');
    }
  }
}

class GameNotification {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final NotificationLevel level;
  final Duration duration;
  
  GameNotification({
    required this.message,
    this.actionLabel,
    this.onAction,
    required this.level,
    required this.duration,
  });
}

enum NotificationLevel {
  INFO,
  SUCCESS,
  WARNING,
  ERROR,
}
