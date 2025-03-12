import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paperclip2/models/event_system.dart';
import 'package:flutter/material.dart';

/// Classe pour le stockage des notifications
class NotificationStorage {
  static const String _notificationsKey = 'notifications';
  static const String _readNotificationsKey = 'read_notifications';
  static const int _maxNotifications = 100;
  
  /// Sauvegarde une notification
  Future<void> saveNotification(NotificationEvent notification) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> savedNotifications = prefs.getStringList(_notificationsKey) ?? [];
      
      // Convertir la notification en JSON
      final notificationJson = notification.toJson();
      savedNotifications.add(jsonEncode(notificationJson));
      
      // Limiter le nombre de notifications
      if (savedNotifications.length > _maxNotifications) {
        savedNotifications.removeRange(0, savedNotifications.length - _maxNotifications);
      }
      
      await prefs.setStringList(_notificationsKey, savedNotifications);
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde de la notification: $e');
    }
  }
  
  /// Récupère toutes les notifications
  Future<List<NotificationEvent>> getAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> savedNotifications = prefs.getStringList(_notificationsKey) ?? [];
      
      return savedNotifications.map((jsonStr) {
        final Map<String, dynamic> json = jsonDecode(jsonStr);
        return NotificationEvent.fromJson(json);
      }).toList();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des notifications: $e');
      return [];
    }
  }
  
  /// Marque une notification comme lue
  Future<void> markAsRead(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Set<String> readNotifications = Set<String>.from(prefs.getStringList(_readNotificationsKey) ?? []);
      
      readNotifications.add(notificationId);
      
      await prefs.setStringList(_readNotificationsKey, readNotifications.toList());
    } catch (e) {
      debugPrint('Erreur lors du marquage de la notification comme lue: $e');
    }
  }
  
  /// Vérifie si une notification est lue
  Future<bool> isRead(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Set<String> readNotifications = Set<String>.from(prefs.getStringList(_readNotificationsKey) ?? []);
      
      return readNotifications.contains(notificationId);
    } catch (e) {
      debugPrint('Erreur lors de la vérification si la notification est lue: $e');
      return false;
    }
  }
  
  /// Supprime une notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> savedNotifications = prefs.getStringList(_notificationsKey) ?? [];
      
      // Filtrer les notifications pour supprimer celle avec l'ID spécifié
      final updatedNotifications = savedNotifications.where((jsonStr) {
        final Map<String, dynamic> json = jsonDecode(jsonStr);
        return json['id'] != notificationId;
      }).toList();
      
      await prefs.setStringList(_notificationsKey, updatedNotifications);
      
      // Supprimer également de la liste des notifications lues
      final Set<String> readNotifications = Set<String>.from(prefs.getStringList(_readNotificationsKey) ?? []);
      readNotifications.remove(notificationId);
      await prefs.setStringList(_readNotificationsKey, readNotifications.toList());
    } catch (e) {
      debugPrint('Erreur lors de la suppression de la notification: $e');
    }
  }
  
  /// Supprime toutes les notifications
  Future<void> clearAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_notificationsKey);
      await prefs.remove(_readNotificationsKey);
    } catch (e) {
      debugPrint('Erreur lors de la suppression de toutes les notifications: $e');
    }
  }
  
  /// Récupère le nombre de notifications non lues
  Future<int> getUnreadCount() async {
    try {
      final allNotifications = await getAllNotifications();
      final prefs = await SharedPreferences.getInstance();
      final Set<String> readNotifications = Set<String>.from(prefs.getStringList(_readNotificationsKey) ?? []);
      
      return allNotifications.where((notification) => !readNotifications.contains(notification.id)).length;
    } catch (e) {
      debugPrint('Erreur lors du calcul du nombre de notifications non lues: $e');
      return 0;
    }
  }
} 