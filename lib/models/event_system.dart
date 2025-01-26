// lib/models/event_system.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'game_config.dart';
import 'game_state_interfaces.dart';
import '../main.dart' show navigatorKey;
import 'package:flutter/foundation.dart';
import 'package:paperclip2/screens/event_log_screen.dart';
import 'progression_system.dart';

/// Définition des priorités de notification
enum NotificationPriority { LOW, MEDIUM, HIGH, CRITICAL }

class UnlockDetails {
  final String name;
  final String description;
  final String howToUse;
  final List<String> benefits;
  final List<String> tips;
  final IconData icon;

  UnlockDetails({
    required this.name,
    required this.description,
    required this.howToUse,
    required this.benefits,
    required this.tips,
    required this.icon,
  });
}

/// Classe représentant un événement de notification
class NotificationEvent {
  final String id;
  final String title;
  final String description;
  final String? detailedDescription;
  final IconData icon;
  final DateTime timestamp;
  final NotificationPriority priority;
  final Map<String, dynamic>? additionalData;
  final bool canBeSuppressed;
  final Duration? suppressionDuration;
  final EventType? type;
  int occurrences; // Pour compter les occurrences similaires
  String? groupId;


  NotificationEvent({
    required this.title,
    required this.description,
    this.detailedDescription,
    required this.icon,
    DateTime? timestamp,
    this.priority = NotificationPriority.MEDIUM,
    this.additionalData,
    this.canBeSuppressed = true,
    this.suppressionDuration = const Duration(minutes: 5),
    this.type,
    String? groupId,
    this.occurrences = 1,
  }) :
        this.id = '${DateTime.now().millisecondsSinceEpoch}_${title.hashCode}',
        this.timestamp = DateTime.now(),

        this.groupId = groupId ?? '${type}_${title.toLowerCase().replaceAll(' ', '_')}';

  // Méthode pour incrémenter le compteur d'occurrences
  void incrementOccurrences() {
    occurrences++;
  }
  bool isSimilarTo(NotificationEvent other) {
    return groupId == other.groupId;
  }




  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'detailedDescription': detailedDescription,
    'icon': icon.codePoint,
    'timestamp': timestamp.toIso8601String(),
    'priority': priority.index,
    'additionalData': additionalData,
    'canBeSuppressed': canBeSuppressed,
    'suppressionDuration': suppressionDuration?.inSeconds,
    'occurrences': occurrences,
    'groupId': groupId,
  };

  factory NotificationEvent.fromJson(Map<String, dynamic> json) {
    var notification = NotificationEvent(
      title: json['title'] as String,
      description: json['description'] as String,
      detailedDescription: json['detailedDescription'] as String?,
      icon: IconData(json['icon'] as int, fontFamily: 'MaterialIcons'),
      timestamp: DateTime.parse(json['timestamp'] as String),
      priority: NotificationPriority.values[json['priority'] as int],
      additionalData: json['additionalData'] as Map<String, dynamic>?,
      canBeSuppressed: json['canBeSuppressed'] as bool? ?? true,
      suppressionDuration: json['suppressionDuration'] != null
          ? Duration(seconds: json['suppressionDuration'] as int)
          : const Duration(minutes: 5),
      groupId: json['groupId'] as String?,
      occurrences: json['occurrences'] as int? ?? 1,
    );
    return notification;
  }
}

/// Classe représentant un événement du jeu
class GameEvent {
  final EventType type;
  final String title;
  final String description;
  final EventImportance importance;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  GameEvent({
    required this.type,
    required this.title,
    required this.description,
    this.importance = EventImportance.LOW,
    Map<String, dynamic>? data,
  }) : timestamp = DateTime.now(),
        this.data = data ?? {};

  Map<String, dynamic> toJson() => {
    'type': type.index,
    'title': title,
    'description': description,
    'importance': importance.index,
    'timestamp': timestamp.toIso8601String(),
    'data': data,
  };

  factory GameEvent.fromJson(Map<String, dynamic> json) {
    return GameEvent(
      type: EventType.values[json['type'] as int],
      title: json['title'] as String,
      description: json['description'] as String,
      importance: EventImportance.values[json['importance'] as int],
      data: json['data'] as Map<String, dynamic>,
    );
  }

  bool equals(GameEvent other) {
    return type == other.type &&
        title == other.title &&
        description == other.description &&
        importance == other.importance;
  }

  bool matchesFilter(EventType? typeFilter, EventImportance? minImportance) {
    if (typeFilter != null && type != typeFilter) return false;
    if (minImportance != null && importance.value < minImportance.value) return false;
    return true;
  }

  String get formattedTimestamp {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours}h';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute}';
    }
  }

  Color get importanceColor {
    switch (importance) {
      case EventImportance.LOW:
        return Colors.grey;
      case EventImportance.MEDIUM:
        return Colors.blue;
      case EventImportance.HIGH:
        return Colors.orange;
      case EventImportance.CRITICAL:
        return Colors.red;
    }
  }

  IconData get typeIcon {
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
    }
  }
}


/// Gestionnaire principal des événements
class EventManager {
  static final EventManager _instance = EventManager._internal();

  static EventManager get instance => _instance;
  final ValueNotifier<NotificationEvent?> notificationStream = ValueNotifier(
      null);
  final List<NotificationEvent> _notifications = [];
  final Set<String> _unreadNotificationIds = {};
  final Set<String> _sentResourceNotifications = {};
  final GameFeatureUnlocker _featureUnlocker = GameFeatureUnlocker();


  final ValueNotifier<
      NotificationEvent?> _notificationController = ValueNotifier(null);
  final List<GameEvent> _events = [];
  final Map<String, DateTime> _lastNotifications = {}; // Ajout de cette ligne

  final Map<UnlockableFeature, UnlockDetails> _unlockDetailsMap = {
    // Ajoutez les détails de déverrouillage ici
    UnlockableFeature.MANUAL_PRODUCTION: UnlockDetails(
      name: 'Production Manuelle',
      description: 'Démarrez votre empire de trombones en produisant manuellement !',
      howToUse: '1. Cliquez sur le bouton de production\n2. Chaque clic transforme du métal en trombone',
      benefits: ['Production immédiate', 'Gain d\'expérience'],
      tips: ['Maintenez un stock de métal'],
      icon: Icons.touch_app,
    ),
  };


  List<NotificationEvent> get notifications =>
      List.unmodifiable(_notifications);

  EventManager._internal();

  final Map<String, DateTime> _lastShownTimes = {};

  // Durée minimale entre deux notifications similaires
  static const Duration _minimumInterval = Duration(minutes: 1);


  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  void addNotification(NotificationEvent newNotification) {
// Gestion spéciale pour les notifications de déplétion de ressources
    if (newNotification.type == EventType.RESOURCE_DEPLETION) {
      final stockLevel = newNotification.additionalData?['stockLevel'];
      if (stockLevel != null) {
// Si c'est la notification de 50%, on l'ignore complètement
        if (stockLevel == '50') {
          return;
        }

// Vérifier si une notification similaire existe déjà
        bool exists = _notifications.any((n) =>
        n.type == EventType.RESOURCE_DEPLETION &&
            n.additionalData?['stockLevel'] == stockLevel
        );

// Si une notification similaire existe déjà, on l'ignore
        if (exists) {
          return;
        }

// Nettoyer les anciennes notifications de déplétion
        _notifications.removeWhere((n) =>
        n.type == EventType.RESOURCE_DEPLETION
        );

// Ajouter la nouvelle notification
        _notifications.add(newNotification);
        _unreadNotificationIds.add(newNotification.id);
        unreadCount.value = _unreadNotificationIds.length;
        showNotification(newNotification);
        return;
      }
    }

// Gestion des autres types de notifications
    try {
// Rechercher une notification similaire récente
      var existingNotification = _notifications.reversed.firstWhere(
            (n) =>
        n.isSimilarTo(newNotification) &&
            DateTime.now().difference(n.timestamp) < _minimumInterval,
      );

// Mettre à jour la notification existante
      existingNotification.incrementOccurrences();
      var updatedNotification = NotificationEvent(
        title: existingNotification.title,
        description: '${existingNotification
            .description} (${existingNotification.occurrences}x)',
        icon: existingNotification.icon,
        priority: existingNotification.priority,
        type: existingNotification.type,
        groupId: existingNotification.groupId,
        additionalData: existingNotification.additionalData,
      );

// Remplacer l'ancienne notification par la mise à jour
      _notifications.remove(existingNotification);
      _notifications.add(updatedNotification);
      _unreadNotificationIds.add(updatedNotification.id);
      unreadCount.value = _unreadNotificationIds.length;
      showNotification(updatedNotification);
    } catch (e) {
// Si aucune notification similaire n'existe, ajouter la nouvelle
      _notifications.add(newNotification);
      _unreadNotificationIds.add(newNotification.id);
      unreadCount.value = _unreadNotificationIds.length;
      showNotification(newNotification);
    }

// Nettoyer les anciennes notifications
    _cleanOldEvents();
  }





  void resetResourceNotifications() {
    _sentResourceNotifications.clear();
  }

  void markAsRead(String notificationId) {
    _unreadNotificationIds.remove(notificationId);
    unreadCount.value = _unreadNotificationIds.length;
  }

  // Vérifier si une notification est non lue
  bool isUnread(String notificationId) {
    return _unreadNotificationIds.contains(notificationId);
  }


  List<GameEvent> getEvents() => List.unmodifiable(_events);

  void addEvent(EventType type,
      String title, {
        required String description,
        String? detailedDescription,
        required EventImportance importance,
        Map<String, dynamic>? additionalData,
      }) {
    if (type == EventType.LEVEL_UP &&
        additionalData?['unlockedFeature'] != null) {
      // Use the method from LevelSystem
      final unlockDetails = LevelSystem.getUnlockDetails(
          additionalData!['unlockedFeature'] as UnlockableFeature);

      if (unlockDetails != null) {
        additionalData = {
          ...additionalData,
          'Fonctionnalité': unlockDetails.name,
          'Comment utiliser': unlockDetails.howToUse,
          'Avantages': unlockDetails.benefits.join('\n'),
          'Conseils': unlockDetails.tips.join('\n'),
        };

        detailedDescription = '''
${unlockDetails.description}

📋 Comment utiliser :
${unlockDetails.howToUse}

✨ Avantages :
${unlockDetails.benefits.map((b) => '• $b').join('\n')}

💡 Conseils :
${unlockDetails.tips.map((t) => '• $t').join('\n')}
''';
      }
    }

    final notification = NotificationEvent(
      title: title,
      description: description,
      detailedDescription: detailedDescription,
      icon: type == EventType.LEVEL_UP &&
          additionalData?['unlockedFeature'] != null
          ? _getUnlockFeatureIcon(
          additionalData!['unlockedFeature'] as UnlockableFeature)
          : _getEventTypeIcon(type),
      priority: _importanceToPriority(importance),
      additionalData: additionalData,
      type: type,
    );

    addNotification(notification);
  }

  IconData _getUnlockFeatureIcon(UnlockableFeature feature) {
    switch (feature) {
      case UnlockableFeature.MANUAL_PRODUCTION:
        return Icons.touch_app;
      case UnlockableFeature.METAL_PURCHASE:
        return Icons.shopping_cart;
      case UnlockableFeature.MARKET_SALES:
        return Icons.store;
      case UnlockableFeature.MARKET_SCREEN:
        return Icons.analytics;
      case UnlockableFeature.AUTOCLIPPERS:
        return Icons.precision_manufacturing;
      case UnlockableFeature.UPGRADES:
        return Icons.upgrade;
    }
  }










  IconData _getEventTypeIcon(EventType type) {
    switch (type) {
      case EventType.RESOURCE_DEPLETION:
        return Icons.warning;
      case EventType.MARKET_CHANGE:
        return Icons.trending_up;
      case EventType.SPECIAL_ACHIEVEMENT:
        return Icons.star;
      case EventType.XP_BOOST:
        return Icons.emoji_events;
      default:
        return Icons.notifications;
    }
  }

  NotificationPriority _importanceToPriority(EventImportance importance) {
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

  void showNotification(NotificationEvent notification) {
    if (_canShowNotification(notification)) {
      _lastNotifications[notification.title] = DateTime.now();
      _notificationController.value = notification;
    }
  }

  bool _canShowNotification(NotificationEvent event) {
    if (!event.canBeSuppressed) return true;

    final lastShown = _lastNotifications[event.title];
    if (lastShown == null) return true;

    return DateTime.now().difference(lastShown) >= (event.suppressionDuration ?? const Duration(minutes: 5));
  }

  NotificationPriority _convertImportanceToNotificationPriority(EventImportance importance) {
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

  void _cleanOldEvents() {
    final now = DateTime.now();
    _events.removeWhere((event) =>
    now.difference(event.timestamp) > GameConstants.EVENT_MAX_AGE);

    while (_events.length > GameConstants.MAX_STORED_EVENTS) {
      _events.removeAt(0);
    }
  }

  List<GameEvent> getEventsByImportance(EventImportance minImportance) {
    return _events.where((event) => event.importance >= minImportance).toList();
  }

  void clearEvents() {
    _notifications.clear();
    _notificationController.value = null;
  }

  static Duration getPriorityDuration(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.LOW:
        return const Duration(seconds: 3);
      case NotificationPriority.MEDIUM:
        return const Duration(seconds: 5);
      case NotificationPriority.HIGH:
        return const Duration(seconds: 7);
      case NotificationPriority.CRITICAL:
        return const Duration(seconds: 10);
    }
  }

  static Color getPriorityColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.LOW:
        return Colors.blue;
      case NotificationPriority.MEDIUM:
        return Colors.orange;
      case NotificationPriority.HIGH:
        return Colors.deepOrange;
      case NotificationPriority.CRITICAL:
        return Colors.red;
    }
  }
}