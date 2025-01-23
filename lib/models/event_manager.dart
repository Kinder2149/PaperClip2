import 'package:flutter/material.dart';
import 'game_enums.dart';
import 'game_event.dart';
import 'notification_event.dart';
import 'notification_manager.dart';
import 'package:paperclip2/main.dart';

// Supprimez l'import de level_system.dart s'il existe
class EventManager {
  static List<GameEvent> _events = [];
  static final ValueNotifier<NotificationEvent?> _notificationController =
  ValueNotifier<NotificationEvent?>(null);

  static ValueNotifier<NotificationEvent?> get notificationStream => _notificationController;

  static List<GameEvent> getEvents() {
    return List.from(_events);
  }

  static void addEvent(
      EventType type,
      String title, {
        required String description,
        required EventImportance importance
      }) {
    final notification = NotificationEvent(
      title: title,
      description: description,
      icon: _getIconForEventType(type),
      priority: _convertImportanceToNotificationPriority(importance),
      canBeSuppressed: importance != EventImportance.CRITICAL,
    );

    if (navigatorKey.currentContext != null) {
      NotificationManager.showGameNotification(
        navigatorKey.currentContext!,
        event: notification,
      );
    }
  }


  static void clearEvents() {
    _events.clear();
  }

  static void triggerNotificationPopup({
    required String title,
    required String description,
    required IconData icon,
  }) {
    _notificationController.value = NotificationEvent(
      title: title,
      description: description,
      icon: icon,
      timestamp: DateTime.now(),
    );
  }

  static List<GameEvent> getEventsByImportance(EventImportance minImportance) {
    return _events.where((event) => event.importance >= minImportance).toList();
  }

  static IconData _getIconForEventType(EventType type) {
    switch (type) {
      case EventType.MARKET_CHANGE:
        return Icons.trending_up;
      case EventType.RESOURCE_DEPLETION:
        return Icons.warning;
      case EventType.LEVEL_UP:
        return Icons.star;
      default:
        return Icons.info;
    }
  }
  static NotificationPriority _convertImportanceToNotificationPriority(EventImportance importance) {
    switch (importance) {
      case EventImportance.LOW:
        return NotificationPriority.LOW;
      case EventImportance.MEDIUM:
        return NotificationPriority.MEDIUM;
      case EventImportance.HIGH:
        return NotificationPriority.HIGH;
      case EventImportance.CRITICAL:
        return NotificationPriority.CRITICAL;
    }
  }

  static void removeOldEvents(Duration maxAge) {
    final now = DateTime.now();
    _events = _events.where((event) {
      return now.difference(event.timestamp) <= maxAge;
    }).toList();
  }
}