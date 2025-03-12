import 'package:flutter/material.dart';
import 'package:paperclip2/models/event_system.dart';
import 'package:paperclip2/main.dart' show navigatorKey;
import 'notification_interface.dart';
import 'notification_storage.dart';

/// Implémentation du service de notification
class NotificationService implements NotificationInterface {
  final NotificationStorage _storage;
  final Map<String, DateTime> _lastShownTimes = {};
  static const Duration _minimumInterval = Duration(seconds: 30);
  
  /// Stream pour les notifications
  final ValueNotifier<NotificationEvent?> notificationStream = ValueNotifier(null);
  
  /// Constructeur
  NotificationService({NotificationStorage? storage}) : _storage = storage ?? NotificationStorage();
  
  @override
  Future<void> showNotification(NotificationEvent notification) async {
    // Vérifier si la notification peut être affichée (intervalle minimum)
    final now = DateTime.now();
    final lastShown = _lastShownTimes[notification.groupId];
    
    if (lastShown != null && now.difference(lastShown) < _minimumInterval) {
      debugPrint('Notification ignorée (intervalle minimum): ${notification.title}');
      return;
    }
    
    // Mettre à jour le temps de dernière affichage
    _lastShownTimes[notification.groupId ?? notification.id] = now;
    
    // Sauvegarder la notification
    await _storage.saveNotification(notification);
    
    // Émettre la notification dans le stream
    notificationStream.value = notification;
    
    // Afficher la notification dans l'UI si le contexte est disponible
    final context = navigatorKey.currentContext;
    if (context != null) {
      _showSnackBar(context, notification);
    }
  }
  
  /// Affiche une notification sous forme de SnackBar
  void _showSnackBar(BuildContext context, NotificationEvent notification) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(notification.description),
          ],
        ),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
  
  @override
  Future<void> saveImportantNotification(NotificationEvent notification) async {
    await _storage.saveNotification(notification);
  }
  
  @override
  Future<List<NotificationEvent>> getImportantNotifications() async {
    final allNotifications = await _storage.getAllNotifications();
    return allNotifications
        .where((notification) => 
            notification.priority == NotificationPriority.HIGH || 
            notification.priority == NotificationPriority.CRITICAL)
        .toList();
  }
  
  @override
  Future<void> markAsRead(String notificationId) async {
    await _storage.markAsRead(notificationId);
  }
  
  @override
  Future<bool> isRead(String notificationId) async {
    return await _storage.isRead(notificationId);
  }
  
  @override
  Future<void> deleteNotification(String notificationId) async {
    await _storage.deleteNotification(notificationId);
  }
  
  @override
  Future<void> clearAllNotifications() async {
    await _storage.clearAllNotifications();
  }
  
  @override
  Future<int> getUnreadCount() async {
    return await _storage.getUnreadCount();
  }
  
  @override
  Future<List<NotificationEvent>> getAllNotifications() async {
    return await _storage.getAllNotifications();
  }
  
  @override
  Future<List<NotificationEvent>> filterNotificationsByType(EventType type) async {
    final allNotifications = await _storage.getAllNotifications();
    return allNotifications
        .where((notification) => notification.type == type)
        .toList();
  }
  
  @override
  Future<List<NotificationEvent>> filterNotificationsByPriority(NotificationPriority priority) async {
    final allNotifications = await _storage.getAllNotifications();
    return allNotifications
        .where((notification) => notification.priority == priority)
        .toList();
  }
  
  @override
  Future<List<NotificationEvent>> groupSimilarNotifications() async {
    final allNotifications = await _storage.getAllNotifications();
    final Map<String, NotificationEvent> groupedNotifications = {};
    
    for (final notification in allNotifications) {
      final groupId = notification.groupId ?? notification.id;
      
      if (groupedNotifications.containsKey(groupId)) {
        // Incrémenter le compteur d'occurrences
        groupedNotifications[groupId]!.incrementOccurrences();
      } else {
        groupedNotifications[groupId] = notification;
      }
    }
    
    return groupedNotifications.values.toList();
  }
} 