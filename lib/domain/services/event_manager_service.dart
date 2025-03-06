// lib/domain/services/event_manager_service.dart
import 'dart:async';
import '../../core/constants/imports.dart';

class EventManager {
  // Singleton
  static final EventManager _instance = EventManager._internal();
  factory EventManager() => _instance;
  EventManager._internal();

  // Flux d'événements
  final _eventController = StreamController<GameEvent>.broadcast();
  final _notificationController = StreamController<NotificationEvent>.broadcast();

  // Nombre de notifications non lues
  final ValueNotifier<int> unreadCount = ValueNotifier(0);

  // Flux de stream
  Stream<GameEvent> get eventStream => _eventController.stream;
  Stream<NotificationEvent> get notificationStream => _notificationController.stream;

  // Méthode pour ajouter un événement de jeu
  void addGameEvent(GameEvent event) {
    _eventController.add(event);
    _processGameEvent(event);
  }

  // Méthode pour ajouter une notification
  void addNotification(NotificationEvent notification) {
    _notificationController.add(notification);
    unreadCount.value++;
  }

  // Traitement des événements de jeu
  void _processGameEvent(GameEvent event) {
    switch (event.type) {
      case EventType.LEVEL_UP:
        _handleLevelUpEvent(event);
        break;
      case EventType.MARKET_CHANGE:
        _handleMarketChangeEvent(event);
        break;
      case EventType.RESOURCE_DEPLETION:
        _handleResourceDepletionEvent(event);
        break;
      default:
      // Événements génériques
        break;
    }
  }

  // Gestion spécifique des événements
  void _handleLevelUpEvent(GameEvent event) {
    addNotification(
      NotificationEvent(
        title: 'Niveau Supérieur !',
        message: 'Vous avez atteint le niveau ${event.data['level']}',
        type: NotificationPriority.HIGH,
      ),
    );
  }

  void _handleMarketChangeEvent(GameEvent event) {
    addNotification(
      NotificationEvent(
        title: 'Changement de Marché',
        message: 'Le marché a subi des modifications',
        type: NotificationPriority.MEDIUM,
      ),
    );
  }

  void _handleResourceDepletionEvent(GameEvent event) {
    addNotification(
      NotificationEvent(
        title: 'Ressources Critiques',
        message: 'Vos ressources sont presque épuisées',
        type: NotificationPriority.CRITICAL,
      ),
    );
  }

  // Marquer toutes les notifications comme lues
  void markAllNotificationsAsRead() {
    unreadCount.value = 0;
  }

  // Libération des ressources
  void dispose() {
    _eventController.close();
    _notificationController.close();
    unreadCount.dispose();
  }
}

// Classes d'événements
class GameEvent {
  final EventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final EventImportance importance;

  GameEvent({
    required this.type,
    this.data = const {},
    DateTime? timestamp,
    this.importance = EventImportance.LOW,
  }) : timestamp = timestamp ?? DateTime.now();
}

class NotificationEvent {
  final String title;
  final String message;
  final NotificationPriority type;
  final DateTime timestamp;

  NotificationEvent({
    required this.title,
    required this.message,
    this.type = NotificationPriority.LOW,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}