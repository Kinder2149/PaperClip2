import 'package:flutter/material.dart';
import 'package:paperclip2/models/event_system.dart';

/// Interface pour les services de notification
abstract class NotificationInterface {
  /// Affiche une notification
  Future<void> showNotification(NotificationEvent notification);
  
  /// Enregistre une notification importante
  Future<void> saveImportantNotification(NotificationEvent notification);
  
  /// Récupère toutes les notifications importantes
  Future<List<NotificationEvent>> getImportantNotifications();
  
  /// Marque une notification comme lue
  Future<void> markAsRead(String notificationId);
  
  /// Vérifie si une notification est lue
  Future<bool> isRead(String notificationId);
  
  /// Supprime une notification
  Future<void> deleteNotification(String notificationId);
  
  /// Supprime toutes les notifications
  Future<void> clearAllNotifications();
  
  /// Récupère le nombre de notifications non lues
  Future<int> getUnreadCount();
  
  /// Récupère toutes les notifications
  Future<List<NotificationEvent>> getAllNotifications();
  
  /// Filtre les notifications par type
  Future<List<NotificationEvent>> filterNotificationsByType(EventType type);
  
  /// Filtre les notifications par priorité
  Future<List<NotificationEvent>> filterNotificationsByPriority(NotificationPriority priority);
  
  /// Groupe les notifications similaires
  Future<List<NotificationEvent>> groupSimilarNotifications();
} 