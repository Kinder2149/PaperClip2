import 'package:flutter/material.dart';
import 'package:paperclip2/models/event_system.dart';
import 'package:paperclip2/models/game_config.dart';
import 'notification_service.dart';

/// Adaptateur pour assurer la compatibilité avec l'ancien code
class NotificationAdapter {
  final NotificationService _notificationService;
  
  /// Constructeur
  NotificationAdapter(this._notificationService);
  
  /// Affiche une notification de jeu (compatible avec l'ancien code)
  void showGameNotification(BuildContext context, {required NotificationEvent event}) {
    _notificationService.showNotification(event);
  }
  
  /// Sauvegarde une notification importante (compatible avec l'ancien code)
  Future<void> saveImportantNotification(NotificationEvent notification) async {
    await _notificationService.saveImportantNotification(notification);
  }
  
  /// Récupère les notifications importantes (compatible avec l'ancien code)
  Future<List<NotificationEvent>> getImportantNotifications() async {
    return await _notificationService.getImportantNotifications();
  }
  
  /// Crée une notification à partir d'un événement de jeu (compatible avec l'ancien code)
  NotificationEvent createNotificationFromGameEvent(GameEvent event) {
    NotificationPriority priority;
    
    // Convertir l'importance de l'événement en priorité de notification
    switch (event.importance) {
      case EventImportance.LOW:
        priority = NotificationPriority.LOW;
        break;
      case EventImportance.MEDIUM:
        priority = NotificationPriority.MEDIUM;
        break;
      case EventImportance.HIGH:
        priority = NotificationPriority.HIGH;
        break;
      case EventImportance.CRITICAL:
        priority = NotificationPriority.CRITICAL;
        break;
    }
    
    return NotificationEvent(
      title: event.title,
      description: event.description,
      icon: event.typeIcon,
      priority: priority,
      type: event.type,
    );
  }
  
  /// Crée une notification pour un déverrouillage de fonctionnalité (compatible avec l'ancien code)
  NotificationEvent createUnlockNotification(UnlockableFeature feature, String name, String description) {
    return NotificationEvent(
      title: 'Nouvelle fonctionnalité déverrouillée : $name',
      description: description,
      icon: Icons.lock_open,
      priority: NotificationPriority.HIGH,
      type: EventType.SPECIAL_ACHIEVEMENT,
      additionalData: {'feature': feature.index},
    );
  }
  
  /// Crée une notification pour un changement de marché (compatible avec l'ancien code)
  NotificationEvent createMarketChangeNotification(String title, String description) {
    return NotificationEvent(
      title: title,
      description: description,
      icon: Icons.trending_up,
      priority: NotificationPriority.MEDIUM,
      type: EventType.MARKET_CHANGE,
    );
  }
  
  /// Crée une notification pour une pénurie de ressources (compatible avec l'ancien code)
  NotificationEvent createResourceDepletionNotification(String title, String description) {
    return NotificationEvent(
      title: title,
      description: description,
      icon: Icons.warning,
      priority: NotificationPriority.HIGH,
      type: EventType.RESOURCE_DEPLETION,
    );
  }
  
  /// Crée une notification pour une amélioration disponible (compatible avec l'ancien code)
  NotificationEvent createUpgradeAvailableNotification(String title, String description) {
    return NotificationEvent(
      title: title,
      description: description,
      icon: Icons.new_releases,
      priority: NotificationPriority.MEDIUM,
      type: EventType.UPGRADE_AVAILABLE,
    );
  }
  
  /// Crée une notification pour une montée de niveau (compatible avec l'ancien code)
  NotificationEvent createLevelUpNotification(int level, String description) {
    return NotificationEvent(
      title: 'Niveau $level atteint !',
      description: description,
      icon: Icons.upgrade,
      priority: NotificationPriority.HIGH,
      type: EventType.LEVEL_UP,
      additionalData: {'level': level},
    );
  }
  
  /// Crée une notification pour un boost d'XP (compatible avec l'ancien code)
  NotificationEvent createXpBoostNotification(String title, String description) {
    return NotificationEvent(
      title: title,
      description: description,
      icon: Icons.speed,
      priority: NotificationPriority.MEDIUM,
      type: EventType.XP_BOOST,
    );
  }
  
  /// Crée une notification pour un mode de crise (compatible avec l'ancien code)
  NotificationEvent createCrisisModeNotification(String title, String description) {
    return NotificationEvent(
      title: title,
      description: description,
      icon: Icons.emergency,
      priority: NotificationPriority.CRITICAL,
      type: EventType.CRISIS_MODE,
    );
  }
  
  /// Crée une notification pour un changement d'interface (compatible avec l'ancien code)
  NotificationEvent createUiChangeNotification(String title, String description) {
    return NotificationEvent(
      title: title,
      description: description,
      icon: Icons.switch_access_shortcut,
      priority: NotificationPriority.LOW,
      type: EventType.UI_CHANGE,
    );
  }
  
  /// Crée une notification d'information (compatible avec l'ancien code)
  NotificationEvent createInfoNotification(String title, String description) {
    return NotificationEvent(
      title: title,
      description: description,
      icon: Icons.info_outline,
      priority: NotificationPriority.LOW,
      type: EventType.INFO,
    );
  }
} 