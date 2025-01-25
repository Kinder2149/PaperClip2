// lib/models/event_system.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'game_config.dart';
import 'game_state_interfaces.dart';
import '../main.dart' show navigatorKey;
import 'package:flutter/foundation.dart';
import 'package:paperclip2/screens/event_log_screen.dart';

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
  final ValueNotifier<NotificationEvent?> notificationStream = ValueNotifier(null);
  final List<NotificationEvent> _notifications = [];
  final Set<String> _unreadNotificationIds = {};


  final ValueNotifier<NotificationEvent?> _notificationController = ValueNotifier(null);
  final List<GameEvent> _events = [];
  final Map<String, DateTime> _lastNotifications = {}; // Ajout de cette ligne


  List<NotificationEvent> get notifications => List.unmodifiable(_notifications);

  EventManager._internal();
  final Map<String, DateTime> _lastShownTimes = {};
  // Durée minimale entre deux notifications similaires
  static const Duration _minimumInterval = Duration(minutes: 1);


  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  void addNotification(NotificationEvent newNotification) {
    try {
      var existingNotification = _notifications.reversed.firstWhere(
            (n) => n.isSimilarTo(newNotification) &&
            DateTime.now().difference(n.timestamp) < _minimumInterval,
      );

      existingNotification.incrementOccurrences();
      var updatedNotification = NotificationEvent(
        title: existingNotification.title,
        description: '${existingNotification.description} (${existingNotification.occurrences}x)',
        icon: existingNotification.icon,
        priority: existingNotification.priority,
        type: existingNotification.type,
        groupId: existingNotification.groupId,
      );
      _notifications.remove(existingNotification);
      _notifications.add(updatedNotification);
      _unreadNotificationIds.add(updatedNotification.id); // Marquer comme non lue
      unreadCount.value = _unreadNotificationIds.length;
      showNotification(updatedNotification);

    } catch (e) {
      _notifications.add(newNotification);
      _unreadNotificationIds.add(newNotification.id); // Marquer comme non lue
      unreadCount.value = _unreadNotificationIds.length;
      showNotification(newNotification);
    }

    _cleanOldEvents();
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

  void addEvent(
      EventType type,
      String title, {
        required String description,
        String? detailedDescription,
        required EventImportance importance,
        Map<String, dynamic>? additionalData,
      }) {
    if (type == EventType.LEVEL_UP && additionalData?['unlockedFeature'] != null) {
      final unlockDetails = _getUnlockDetails(additionalData!['unlockedFeature'] as UnlockableFeature);
      if (unlockDetails != null) {
        // Supprimer cette ligne qui cause l'erreur
        // detailedDescription = _formatUnlockDescription(unlockDetails);

        additionalData = {
          ...additionalData,
          'Fonctionnalité': unlockDetails.name,
          'Comment utiliser': unlockDetails.howToUse,
          'Avantages': unlockDetails.benefits.join('\n'),
          'Conseils': unlockDetails.tips.join('\n'),
        };

        // On garde cette partie qui formate déjà la description correctement
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
      icon: type == EventType.LEVEL_UP && additionalData?['unlockedFeature'] != null
          ? _getUnlockFeatureIcon(additionalData!['unlockedFeature'] as UnlockableFeature)
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

  UnlockDetails _getUnlockDetails(UnlockableFeature feature) {
    switch (feature) {
      case UnlockableFeature.MANUAL_PRODUCTION:
        return UnlockDetails(
          name: 'Production Manuelle',
          description: 'Démarrez votre empire de trombones en produisant manuellement !',
          howToUse: '''
1. Cliquez sur le bouton de production dans l'écran principal
2. Chaque clic transforme du métal en trombone
3. Surveillez votre stock de métal pour une production continue''',
          benefits: [
            'Production immédiate de trombones',
            'Gain d\'expérience à chaque production',
            'Contrôle total sur la production',
            'Apprentissage des mécaniques de base'
          ],
          tips: [
            'Maintenez un stock de métal suffisant',
            'Produisez régulièrement pour gagner de l\'expérience',
            'Observez l\'évolution de votre efficacité'
          ],
          icon: Icons.touch_app,
        );

      case UnlockableFeature.METAL_PURCHASE:
        return UnlockDetails(
          name: 'Achat de Métal',
          description: 'Accédez au marché des matières premières pour acheter du métal !',
          howToUse: '''
1. Ouvrez l'onglet Marché
2. Consultez les prix actuels du métal
3. Achetez quand les prix sont avantageux''',
          benefits: [
            'Approvisionnement constant en matières premières',
            'Possibilité de stocker pour les moments opportuns',
            'Gestion stratégique des ressources',
            'Optimisation des coûts de production'
          ],
          tips: [
            'Achetez en grande quantité quand les prix sont bas',
            'Surveillez les tendances du marché',
            'Maintenez une réserve de sécurité',
            'Calculez votre retour sur investissement'
          ],
          icon: Icons.shopping_cart,
        );

      case UnlockableFeature.MARKET_SALES:
        return UnlockDetails(
          name: 'Ventes sur le Marché',
          description: 'Vendez vos trombones sur le marché mondial !',
          howToUse: '''
1. Accédez à l'interface de vente dans l'onglet Marché
2. Définissez votre prix de vente
3. Suivez vos statistiques de vente''',
          benefits: [
            'Génération de revenus passifs',
            'Accès aux statistiques de vente',
            'Influence sur les prix du marché',
            'Optimisation des profits'
          ],
          tips: [
            'Adaptez vos prix à la demande',
            'Surveillez la satisfaction client',
            'Équilibrez production et ventes',
            'Analysez les tendances du marché'
          ],
          icon: Icons.store,
        );

      case UnlockableFeature.MARKET_SCREEN:
        return UnlockDetails(
          name: 'Écran de Marché',
          description: 'Accédez à des outils avancés d\'analyse de marché !',
          howToUse: '''
1. Naviguez vers l'onglet Marché
2. Explorez les différents graphiques et statistiques
3. Utilisez les données pour optimiser vos stratégies''',
          benefits: [
            'Visualisation détaillée des tendances',
            'Analyse approfondie du marché',
            'Prévisions de demande',
            'Optimisation des stratégies de prix'
          ],
          tips: [
            'Consultez régulièrement les rapports',
            'Utilisez les graphiques pour anticiper',
            'Ajustez votre stratégie selon les données',
            'Surveillez la concurrence'
          ],
          icon: Icons.analytics,
        );

      case UnlockableFeature.AUTOCLIPPERS:
        return UnlockDetails(
          name: 'Autoclippeuses',
          description: 'Automatisez votre production avec des machines intelligentes !',
          howToUse: '''
1. Achetez des autoclippeuses dans la section Améliorations
2. Gérez leur maintenance et leur efficacité
3. Surveillez leur consommation de ressources''',
          benefits: [
            'Production automatique continue',
            'Augmentation significative de la production',
            'Libération de temps pour la stratégie',
            'Production même hors ligne'
          ],
          tips: [
            'Équilibrez le nombre avec vos ressources',
            'Maintenez-les régulièrement',
            'Surveillez leur consommation de métal',
            'Optimisez leur placement'
          ],
          icon: Icons.precision_manufacturing,
        );

      case UnlockableFeature.UPGRADES:
        return UnlockDetails(
          name: 'Système d\'Améliorations',
          description: 'Accédez à un vaste système d\'améliorations pour optimiser votre production !',
          howToUse: '''
1. Explorez l'onglet Améliorations
2. Choisissez les améliorations stratégiques
3. Combinez les effets pour maximiser les bénéfices''',
          benefits: [
            'Personnalisation de votre stratégie',
            'Améliorations permanentes',
            'Déblocage de nouvelles fonctionnalités',
            'Optimisation globale de la production'
          ],
          tips: [
            'Planifiez vos achats d\'amélioration',
            'Lisez attentivement les effets',
            'Privilégiez les synergies',
            'Gardez des ressources pour les urgences'
          ],
          icon: Icons.upgrade,
        );
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