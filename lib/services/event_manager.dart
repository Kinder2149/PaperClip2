import 'package:flutter/foundation.dart';

class EventManager with ChangeNotifier {
  // Singleton
  static final EventManager _instance = EventManager._internal();
  static EventManager get instance => _instance;

  EventManager._internal();
  
  // Listes d'événements
  final List<NotificationEvent> _notifications = [];
  final List<bool> _interfaceTransitions = [];
  
  // Getters
  List<NotificationEvent> get notifications => List.unmodifiable(_notifications);
  
  // Ajouter une notification
  void addNotification(NotificationEvent event) {
    _notifications.add(event);
    if (kDebugMode) {
      print('Notification ajoutée: ${event.message}');
    }
    notifyListeners();
  }
  
  // Supprimer une notification
  void removeNotification(NotificationEvent event) {
    _notifications.remove(event);
    notifyListeners();
  }
  
  // Effacer toutes les notifications
  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }
  
  // Enregistrer une transition d'interface
  void addInterfaceTransitionEvent(bool isShowingCrisisView) {
    _interfaceTransitions.add(isShowingCrisisView);
    notifyListeners();
  }
  
  // Réinitialiser l'EventManager
  void reset() {
    _notifications.clear();
    _interfaceTransitions.clear();
    notifyListeners();
  }
}

class NotificationEvent {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final NotificationPriority priority;
  final Duration duration;
  
  NotificationEvent({
    required this.message,
    this.actionLabel,
    this.onAction,
    this.priority = NotificationPriority.NORMAL,
    this.duration = const Duration(seconds: 5),
  });
}

enum NotificationPriority {
  LOW,
  NORMAL,
  HIGH,
}
