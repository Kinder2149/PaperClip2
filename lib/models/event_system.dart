import 'package:flutter/material.dart';
import 'dart:async';
import 'game_config.dart';

abstract class GameEvent {
  final DateTime timestamp;
  final String message;

  GameEvent(this.message) : timestamp = DateTime.now();
}

class LevelUpEvent extends GameEvent {
  final int newLevel;
  final List<UnlockableFeature> unlockedFeatures;

  LevelUpEvent(this.newLevel, this.unlockedFeatures)
      : super('Niveau $newLevel atteint !');
}

class MarketEvent extends GameEvent {
  final MarketEventType type;
  final double value;

  MarketEvent(this.type, this.value, String message) : super(message);
}

class NotificationEvent extends GameEvent {
  final String title;
  final IconData icon;
  final NotificationPriority priority;

  NotificationEvent({
    required this.title,
    required String description,
    required this.icon,
    this.priority = NotificationPriority.MEDIUM,
  }) : super(description);
}

class AchievementEvent extends GameEvent {
  final Achievement achievement;

  AchievementEvent(this.achievement)
      : super('Achievement débloqué : ${achievement.title}');
}

class InterfaceTransitionEvent extends GameEvent {
  final bool showCrisisView;

  InterfaceTransitionEvent(this.showCrisisView)
      : super('Transition interface : ${showCrisisView ? 'Mode Crise' : 'Mode Normal'}');
}

class EventManager {
  static final EventManager _instance = EventManager._internal();
  static EventManager get instance => _instance;

  final StreamController<GameEvent> _eventController = StreamController<GameEvent>.broadcast();
  final List<GameEvent> _eventHistory = [];
  final Map<Type, List<Function(GameEvent)>> _listeners = {};

  Stream<GameEvent> get eventStream => _eventController.stream;
  List<GameEvent> get eventHistory => List.unmodifiable(_eventHistory);

  EventManager._internal();

  void addListener(void Function(GameEvent) listener) {
    _eventController.stream.listen(listener);
  }

  void addTypedListener<T extends GameEvent>(void Function(T) listener) {
    if (!_listeners.containsKey(T)) {
      _listeners[T] = [];
    }
    _listeners[T]!.add((event) {
      if (event is T) {
        listener(event);
      }
    });
  }

  void removeTypedListener<T extends GameEvent>(void Function(T) listener) {
    if (_listeners.containsKey(T)) {
      _listeners[T]!.remove(listener);
    }
  }

  void addEvent(GameEvent event) {
    _eventHistory.add(event);
    _eventController.add(event);

    // Notifier les listeners typés
    if (_listeners.containsKey(event.runtimeType)) {
      for (var listener in _listeners[event.runtimeType]!) {
        listener(event);
      }
    }

    // Limiter la taille de l'historique
    if (_eventHistory.length > 100) {
      _eventHistory.removeAt(0);
    }
  }

  void addLevelUpEvent(int newLevel, List<UnlockableFeature> unlockedFeatures) {
    addEvent(LevelUpEvent(newLevel, unlockedFeatures));
  }

  void addMarketEvent(MarketEventType type, double value, String message) {
    addEvent(MarketEvent(type, value, message));
  }

  void addNotification({
    required String title,
    required String description,
    required IconData icon,
    NotificationPriority priority = NotificationPriority.MEDIUM,
  }) {
    addEvent(NotificationEvent(
      title: title,
      description: description,
      icon: icon,
      priority: priority,
    ));
  }

  void addAchievementEvent(Achievement achievement) {
    addEvent(AchievementEvent(achievement));
  }

  void addInterfaceTransitionEvent(bool showCrisisView) {
    addEvent(InterfaceTransitionEvent(showCrisisView));
  }

  List<GameEvent> getRecentEvents({int limit = 10}) {
    return _eventHistory.reversed.take(limit).toList();
  }

  List<T> getEventsByType<T extends GameEvent>() {
    return _eventHistory.whereType<T>().toList();
  }

  void clearHistory() {
    _eventHistory.clear();
  }

  void dispose() {
    _eventController.close();
    _listeners.clear();
  }

  // Méthodes de sérialisation
  List<Map<String, dynamic>> serializeHistory() {
    return _eventHistory.map((event) => _serializeEvent(event)).toList();
  }

  Map<String, dynamic> _serializeEvent(GameEvent event) {
    final Map<String, dynamic> base = {
      'type': event.runtimeType.toString(),
      'timestamp': event.timestamp.toIso8601String(),
      'message': event.message,
    };

    if (event is LevelUpEvent) {
      base['newLevel'] = event.newLevel;
      base['unlockedFeatures'] = event.unlockedFeatures.map((f) => {
        'name': f.name,
        'description': f.description,
        'type': f.type.index,
      }).toList();
    } else if (event is MarketEvent) {
      base['eventType'] = event.type.index;
      base['value'] = event.value;
    } else if (event is NotificationEvent) {
      base['title'] = event.title;
      base['icon'] = event.icon.codePoint;
      base['priority'] = event.priority.index;
    } else if (event is AchievementEvent) {
      base['achievement'] = {
        'id': event.achievement.id,
        'title': event.achievement.title,
        'description': event.achievement.description,
        'type': event.achievement.type.index,
      };
    } else if (event is InterfaceTransitionEvent) {
      base['showCrisisView'] = event.showCrisisView;
    }

    return base;
  }

  void loadHistory(List<Map<String, dynamic>> serializedHistory) {
    _eventHistory.clear();
    for (var eventData in serializedHistory) {
      final event = _deserializeEvent(eventData);
      if (event != null) {
        _eventHistory.add(event);
      }
    }
  }

  GameEvent? _deserializeEvent(Map<String, dynamic> data) {
    final type = data['type'] as String;
    final timestamp = DateTime.parse(data['timestamp'] as String);
    final message = data['message'] as String;

    switch (type) {
      case 'LevelUpEvent':
        return LevelUpEvent(
          data['newLevel'] as int,
          (data['unlockedFeatures'] as List).map((f) => UnlockableFeature(
            f['name'] as String,
            f['description'] as String,
            FeatureType.values[f['type'] as int],
          )).toList(),
        );

      case 'MarketEvent':
        return MarketEvent(
          MarketEventType.values[data['eventType'] as int],
          data['value'] as double,
          message,
        );

      case 'NotificationEvent':
        return NotificationEvent(
          title: data['title'] as String,
          description: message,
          icon: IconData(data['icon'] as int, fontFamily: 'MaterialIcons'),
          priority: NotificationPriority.values[data['priority'] as int],
        );

      case 'AchievementEvent':
        final achievementData = data['achievement'] as Map<String, dynamic>;
        return AchievementEvent(Achievement(
          id: achievementData['id'] as String,
          title: achievementData['title'] as String,
          description: achievementData['description'] as String,
          requiredValue: achievementData['requiredValue'] as int,
          type: AchievementType.values[achievementData['type'] as int],
        ));

      case 'InterfaceTransitionEvent':
        return InterfaceTransitionEvent(data['showCrisisView'] as bool);

      default:
        print('Type d\'événement inconnu: $type');
        return null;
    }
  }
} 