// lib/services/notification_storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event_system.dart';
import '../models/game_config.dart'; // Ajout pour EventType
import 'package:flutter/material.dart'; // Ajout pour Icons

class NotificationStorageService {
  static const String _storageKey = 'important_notifications';

  static Future<void> saveImportantNotification(NotificationEvent notification) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> savedNotifications = prefs.getStringList(_storageKey) ?? [];

      final notificationJson = {
        'id': notification.id,
        'title': notification.title,
        'description': notification.description,
        'timestamp': DateTime.now().toIso8601String(),
        'priority': notification.priority.toString(),
        'type': notification.type.toString(),
        'detailedDescription': notification.detailedDescription,
        'icon': notification.icon.codePoint, // Sauvegarde du code point de l'icône
      };

      savedNotifications.add(jsonEncode(notificationJson));

      if (savedNotifications.length > 50) {
        savedNotifications.removeRange(0, savedNotifications.length - 50);
      }

      await prefs.setStringList(_storageKey, savedNotifications);
    } catch (e) {
      print('Erreur lors de la sauvegarde de la notification: $e');
    }
  }

  static Future<List<NotificationEvent>> getImportantNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> savedNotifications = prefs.getStringList(_storageKey) ?? [];

      return savedNotifications.map((jsonStr) {
        final Map<String, dynamic> json = jsonDecode(jsonStr);
        return NotificationEvent(
          title: json['title'] as String,
          description: json['description'] as String,
          detailedDescription: json['detailedDescription'] as String?,
          icon: IconData(json['icon'] as int, fontFamily: 'MaterialIcons'),
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
    } catch (e) {
      print('Erreur lors de la récupération des notifications: $e');
      return [];
    }
  }
}