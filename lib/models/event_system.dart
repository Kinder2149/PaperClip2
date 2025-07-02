// lib/models/event_system.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'game_config.dart';
import 'game_state.dart'; // Importer GameState
import 'game_state_interfaces.dart';
import 'json_loadable.dart';
import '../main.dart' show navigatorKey;
import 'package:flutter/foundation.dart';
import 'package:paperclip2/screens/event_log_screen.dart';
import 'progression_system.dart';


import 'package:paperclip2/services/notification_storage_service.dart';

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
  })
      : timestamp = DateTime.now(),
        this.data = data ?? {};

  Map<String, dynamic> toJson() =>
      {
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
    if (minImportance != null && importance.value < minImportance.value)
      return false;
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
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp
          .minute}';
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
        return Icons.emoji_events;
      case EventType.XP_BOOST:
        return Icons.speed;
      case EventType.INFO:
        return Icons.info_outline;
      case EventType.CRISIS_MODE:
        return Icons.emergency;
      case EventType.UI_CHANGE:
        return Icons.switch_access_shortcut; // ou Icons.swap_horiz
      case EventType.SYSTEM:
        return Icons.system_update; // Icône pour les événements système
    }
  }
}

/// Gestionnaire principal des événements
class EventManager extends ChangeNotifier implements JsonLoadable {
  static final EventManager _instance = EventManager._internal();

  // Référence vers GameState pour accéder au nom de la partie
  GameState? _gameState;

  static EventManager get instance => _instance;
  final ValueNotifier<NotificationEvent?> notificationStream = ValueNotifier(null);
  final List<NotificationEvent> _notifications = [];
  final Set<String> _unreadNotificationIds = {};
  final Set<String> _sentResourceNotifications = {};
  final GameFeatureUnlocker _featureUnlocker = GameFeatureUnlocker();

  final Map<String, DateTime> _lastShownTimes = {};

  static const Duration _minimumInterval = Duration(seconds: 30);
  static const int _maxNotifications = 100;

  // Getter pour le nom de la partie actuelle
  String get _currentGameName => _gameState?.gameName ?? 'default';

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
  
  // Méthode pour définir la référence vers GameState
  void setGameState(GameState gameState) {
    _gameState = gameState;
  }
  void addCrisisEvent(String title, String description) {
    addEvent(
      EventType.CRISIS_MODE,
      title,
      description: description,
      importance: EventImportance.CRITICAL,
    );
  }
  void addInterfaceTransitionEvent(bool showingCrisisView) {
    addEvent(
      EventType.UI_CHANGE,
      "Changement de vue",
      description: showingCrisisView
          ? "Mode Production activé"
          : "Mode Normal activé",
      importance: EventImportance.LOW,
    );
  }






  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  Future<void> addNotification(NotificationEvent newNotification) async {
    // Sauvegarder les notifications importantes avec le nom de la partie
    if (newNotification.priority == NotificationPriority.HIGH ||
        newNotification.priority == NotificationPriority.CRITICAL ||
        newNotification.type == EventType.LEVEL_UP) {
      await NotificationStorageService.saveImportantNotification(newNotification, _currentGameName);
    }

    // Vérifier si une notification similaire a été montrée récemment
    final lastShownTime = _lastShownTimes[newNotification.groupId ?? newNotification.title];
    if (lastShownTime != null &&
        DateTime.now().difference(lastShownTime) < _minimumInterval &&
        newNotification.type != EventType.LEVEL_UP) {  // Ne pas appliquer l'intervalle minimum pour les montées de niveau
      return;
    }

    // Mettre à jour le temps de dernière apparition
    _lastShownTimes[newNotification.groupId ?? newNotification.title] = DateTime.now();

    try {
      // Pour les notifications de niveau, toujours ajouter une nouvelle entrée
      if (newNotification.type == EventType.LEVEL_UP) {
        _notifications.add(newNotification);
        _unreadNotificationIds.add(newNotification.id);
      } else {
        // Pour les autres types, chercher une notification similaire existante
        var existingIndex = _notifications.indexWhere((n) => n.isSimilarTo(newNotification));

        if (existingIndex != -1) {
          // Mettre à jour la notification existante
          var existing = _notifications[existingIndex];
          existing.incrementOccurrences();
          _notifications.removeAt(existingIndex);
          _notifications.add(existing);
        } else {
          // Ajouter la nouvelle notification
          _notifications.add(newNotification);
        }
      }

      // Limiter le nombre de notifications
      if (_notifications.length > _maxNotifications) {
        _notifications.removeRange(0, _notifications.length - _maxNotifications);
      }

      // Marquer comme non lue
      _unreadNotificationIds.add(newNotification.id);
      unreadCount.value = _unreadNotificationIds.length;

      // Mettre à jour le compteur
      notifyListeners();

      // Afficher la notification
      notificationStream.value = newNotification;

      // Programmer la disparition de la notification
      Future.delayed(const Duration(seconds: 3), () {
        if (notificationStream.value?.id == newNotification.id) {
          notificationStream.value = null;
        }
      });

    } catch (e) {
      print('Erreur lors de l\'ajout de la notification: $e');
    }
  }

  void removeNotification(String notificationId) {
    _notifications.removeWhere((notification) => notification.id == notificationId);
    _unreadNotificationIds.remove(notificationId);
    unreadCount.value = _unreadNotificationIds.length;  // Modification ici
    notifyListeners();
  }

  void clearNotifications() {
    _notifications.clear();
    _lastShownTimes.clear();
    notificationStream.value = null;
    markAllAsRead(); // Utiliser la nouvelle méthode au lieu de _unreadNotificationIds.clear()
    notifyListeners();
  }

  Future<void> loadNotificationsForGame(String gameName) async {
    try {
      // Vider les notifications existantes
      _notifications.clear();
      _unreadNotificationIds.clear();
      
      // Charger les nouvelles notifications
      final notifications = await NotificationStorageService.getNotificationsForGame(gameName);
      _notifications.addAll(notifications);
      
      // Marquer comme non lues
      for (var notification in notifications) {
        _unreadNotificationIds.add(notification.id);
      }
      
      unreadCount.value = _unreadNotificationIds.length;
      notifyListeners();
      
      print('Chargé ${notifications.length} notifications pour la partie: $gameName');
    } catch (e) {
      print('Erreur lors du chargement des notifications: $e');
    }
  }
  
  // Pour rétrocompatibilité avec l'ancien système
  Future<void> loadImportantNotifications() async {
    final notifications = await NotificationStorageService.getImportantNotifications();
    _notifications.addAll(notifications);
    notifyListeners();
  }

  void resetResourceNotifications() {
    _sentResourceNotifications.clear();
  }

  void markAsRead(String notificationId) {
    _unreadNotificationIds.remove(notificationId);
    unreadCount.value = _unreadNotificationIds.length;
  }
  void markAllAsRead() {
    // Vider la liste des notifications non lues
    _unreadNotificationIds.clear();

    // Mettre à jour le compteur de notifications non lues
    unreadCount.value = 0;

    // Notifier les écouteurs du changement
    notifyListeners();
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
  }
  
  @override
  void fromJson(Map<String, dynamic> json) {
    try {
      print('Loading event manager data: $json');
      _notifications.clear();
      _unreadNotificationIds.clear();
      _events.clear();
      
      // Charger les notifications
      final notificationsJson = json['notifications'] as List<dynamic>? ?? [];
      for (final notificationJson in notificationsJson) {
        try {
          final notification = NotificationEvent.fromJson(
              notificationJson as Map<String, dynamic>);
          _notifications.add(notification);
          
          // Si marqué comme non lu
          if (notificationJson['unread'] == true) {
            _unreadNotificationIds.add(notification.id);
          }
        } catch (e) {
          print('Erreur lors du chargement d\'une notification: $e');
        }
      }
      
      // Charger les événements
      final eventsJson = json['events'] as List<dynamic>? ?? [];
      for (final eventJson in eventsJson) {
        try {
          final event = GameEvent(
            type: EventType.values[(eventJson['type'] as num?)?.toInt() ?? 0],
            title: eventJson['title'] as String? ?? 'Événement',
            description: eventJson['description'] as String? ?? 'Sans description',
            importance: EventImportance.values[(eventJson['importance'] as num?)?.toInt() ?? 0],
            data: eventJson['data'] as Map<String, dynamic>? ?? {},
          );
          _events.add(event);
        } catch (e) {
          print('Erreur lors du chargement d\'un événement: $e');
        }
      }
      
      unreadCount.value = _unreadNotificationIds.length;
      notifyListeners();
    } catch (e, stack) {
      print('Error loading event manager: $e');
      print('Stack trace: $stack');
      // Réinitialisation des données
      _notifications.clear();
      _unreadNotificationIds.clear();
      _events.clear();
      unreadCount.value = 0;
    }
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
  final Map<MarketEvent, CrisisGuide> _crisisGuides = {
    MarketEvent.MARKET_CRASH: CrisisGuide(
      title: "Guide : Gérer un Krach du Marché",
      description: "Le marché s'effondre, voici comment réagir",
      steps: [
        "1. Réduisez votre production de 50%",
        "2. Conservez vos ressources",
        "3. Attendez que les prix remontent",
        "4. Profitez des bas prix pour stocker"
      ],
      icon: Icons.trending_down,
      color: Colors.red.shade700,
    ),
    MarketEvent.PRICE_WAR: CrisisGuide(
      title: "Guide : Survivre à une Guerre des Prix",
      description: "Les concurrents baissent agressivement leurs prix",
      steps: [
        "1. Maintenez des prix compétitifs",
        "2. Focalisez sur l'efficacité",
        "3. Améliorez votre marketing",
        "4. Surveillez vos concurrents"
      ],
      icon: Icons.currency_exchange,
      color: Colors.orange.shade800,
    ),
    MarketEvent.DEMAND_SPIKE: CrisisGuide(
      title: "Guide : Profiter d'un Pic de Demande",
      description: "La demande explose soudainement",
      steps: [
        "1. Augmentez votre production",
        "2. Ajustez vos prix à la hausse",
        "3. Constituez des stocks",
        "4. Optimisez vos ventes"
      ],
      icon: Icons.trending_up,
      color: Colors.green.shade700,
    ),
    MarketEvent.QUALITY_CONCERNS: CrisisGuide(
      title: "Guide : Résoudre les Problèmes de Qualité",
      description: "La qualité de vos produits est remise en question",
      steps: [
        "1. Investissez dans la qualité",
        "2. Baissez temporairement les prix",
        "3. Améliorez votre réputation",
        "4. Communiquez sur vos améliorations"
      ],
      icon: Icons.warning,
      color: Colors.purple.shade700,
    ),
  };

  CrisisGuide? getGuideForCrisis(MarketEvent event) {
    return _crisisGuides[event];
  }

  void addCrisisNotification(MarketEvent event) {
    final guide = _crisisGuides[event];
    if (guide == null) return;

    final notification = NotificationEvent(
      title: guide.title,
      description: guide.description,
      detailedDescription: guide.steps.join('\n'),
      icon: guide.icon,
      priority: NotificationPriority.HIGH,
      type: EventType.MARKET_CHANGE,
      additionalData: {'crisisEvent': event.index},
      canBeSuppressed: false,
    );

    addNotification(notification);
  }
}



class CrisisGuide {
  final String title;
  final String description;
  final List<String> steps;
  final IconData icon;
  final Color color;

  const CrisisGuide({
    required this.title,
    required this.description,
    required this.steps,
    required this.icon,
    required this.color,
  });
}


