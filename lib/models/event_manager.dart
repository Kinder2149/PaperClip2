import 'package:flutter/material.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/models/notification_manager.dart';
import 'package:paperclip2/models/constants.dart';
import 'package:paperclip2/models/level_system.dart'; // Pour les enums EventType et EventImportance
import 'package:flutter/material.dart';
import 'game_event.dart';
import 'notification_event.dart';
import 'game_enums.dart';

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
      String title,
      {
        String description = '',
        EventImportance importance = EventImportance.LOW,
        Map<String, dynamic> data = const {},
      }) {
    final event = GameEvent(
      type: type,
      title: title,
      description: description,
      importance: importance,
      data: data,
    );
    _events.add(event);

    // Notification automatique pour les événements importants
    if (importance >= EventImportance.HIGH) {
      triggerNotificationPopup(
        title: title,
        description: description,
        icon: _getIconForEventType(type),
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
      case EventType.LEVEL_UP:
        return Icons.upgrade;
      case EventType.MARKET_CHANGE:
        return Icons.trending_up;
      case EventType.RESOURCE_DEPLETION:
        return Icons.warning;
      case EventType.UPGRADE_AVAILABLE:
        return Icons.new_releases;
      case EventType.SPECIAL_ACHIEVEMENT:
        return Icons.stars;
      case EventType.XP_BOOST:
        return Icons.speed;
      default:
        return Icons.info_outline;
    }
  }

  static void removeOldEvents(Duration maxAge) {
    final now = DateTime.now();
    _events = _events.where((event) {
      return now.difference(event.timestamp) <= maxAge;
    }).toList();
  }
}