// lib/services/notification_storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../models/event_system.dart';
import '../constants/game_config.dart'; // Ajout pour EventType
import '../utils/icon_helper.dart'; // Pour utiliser des icônes constantes (déplacé depuis utilities)

class NotificationStorageService {
  // Instance unique pour le pattern singleton
  static final NotificationStorageService _instance = NotificationStorageService._internal();
  
  // Constructeur factory qui retourne l'instance unique
  factory NotificationStorageService() {
    return _instance;
  }
  
  // Constructeur privé
  NotificationStorageService._internal();
  
  // Méthode d'instance pour ajouter un message
  Future<void> addMessage(String message, EventType type, {String gameName = 'default', NotificationPriority priority = NotificationPriority.MEDIUM}) async {
    final notification = NotificationEvent(
      title: 'Notification',
      description: message,
      icon: Icons.info, // Utilisation d'une icône par défaut
      priority: priority,
      type: type,
    );
    
    await saveImportantNotification(notification, gameName);
  }
  
  // Clé utilisée pour la rétrocompatibilité
  static const String _baseStorageKey = 'important_notifications';
  
  // Méthode pour générer une clé unique par sauvegarde
  static String _getStorageKey(String gameName) {
    return 'notifications_${gameName.trim()}';
  }

  static Future<void> saveImportantNotification(NotificationEvent notification, String gameName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String storageKey = _getStorageKey(gameName);
      final List<String> savedNotifications = prefs.getStringList(storageKey) ?? [];

      final notificationJson = {
        'id': notification.id,
        'title': notification.title,
        'description': notification.description,
        'timestamp': DateTime.now().toIso8601String(),
        'priority': notification.priority.toString(),
        'type': notification.type.toString(),
        'detailedDescription': notification.detailedDescription,
        'icon': notification.icon.codePoint, // Sauvegarde du code point de l'icône
        'gameName': gameName, // Ajout du nom de la partie
      };

      savedNotifications.add(jsonEncode(notificationJson));

      if (savedNotifications.length > 50) {
        savedNotifications.removeRange(0, savedNotifications.length - 50);
      }

      await prefs.setStringList(storageKey, savedNotifications);
    } catch (e) {
      print('Erreur lors de la sauvegarde de la notification: $e');
    }
  }

  // Méthode pour récupérer les notifications d'une partie spécifique
  static Future<List<NotificationEvent>> getNotificationsForGame(String gameName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String storageKey = _getStorageKey(gameName);
      final List<String> savedNotifications = prefs.getStringList(storageKey) ?? [];

      return _parseNotifications(savedNotifications);
    } catch (e) {
      print('Erreur lors de la récupération des notifications: $e');
      return [];
    }
  }

  // Méthode pour rétrocompatibilité avec l'ancien système
  static Future<List<NotificationEvent>> getImportantNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> savedNotifications = prefs.getStringList(_baseStorageKey) ?? [];

      return _parseNotifications(savedNotifications);
    } catch (e) {
      print('Erreur lors de la récupération des anciennes notifications: $e');
      return [];
    }
  }
  
  // Méthode utilitaire pour parser les notifications
  static List<NotificationEvent> _parseNotifications(List<String> jsonStrings) {
    return jsonStrings.map((jsonStr) {
      final Map<String, dynamic> json = jsonDecode(jsonStr);
      return NotificationEvent(
        title: json['title'] as String,
        description: json['description'] as String,
        detailedDescription: json['detailedDescription'] as String?,
        icon: IconHelper.getIconForCode(json['icon'] as int),
        priority: NotificationPriority.values.firstWhere(
                (e) => e.toString() == json['priority'],
            orElse: () => NotificationPriority.MEDIUM
        ),
        type: EventType.values.firstWhere(
                (e) => e.toString() == json['type'],
            orElse: () => EventType.INFO
        ),
      );
    }).toList();
  }
  
  // Méthode pour migrer les anciennes notifications vers une partie spécifique
  static Future<void> migrateOldNotifications(String gameName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> oldNotifications = prefs.getStringList(_baseStorageKey) ?? [];
      
      if (oldNotifications.isNotEmpty) {
        // Les transférer vers le nouveau système
        final String newKey = _getStorageKey(gameName);
        await prefs.setStringList(newKey, oldNotifications);
        
        // Optionnellement, nettoyer les anciennes notifications
        // await prefs.remove(_baseStorageKey);
        
        print('Migration des anciennes notifications réussie vers: $gameName');
      }
    } catch (e) {
      print('Erreur lors de la migration des notifications: $e');
    }
  }
  
  // Méthode pour obtenir le nombre de notifications pour une partie
  static Future<int> getNotificationCount(String gameName) async {
    try {
      final notifications = await getNotificationsForGame(gameName);
      return notifications.length;
    } catch (e) {
      print('Erreur lors du comptage des notifications: $e');
      return 0;
    }
  }
}