// lib/utils/notification_manager.dart

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import '../models/game_config.dart';

class NotificationEvent {
  final String title;
  final String description;
  final IconData icon;
  final NotificationPriority priority;
  final DateTime timestamp;

  NotificationEvent({
    required this.title,
    required this.description,
    required this.icon,
    this.priority = NotificationPriority.MEDIUM,
  }) : timestamp = DateTime.now();
}

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  static NotificationManager get instance => _instance;

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final List<NotificationEvent> _eventHistory = [];
  final StreamController<NotificationEvent> _eventController = StreamController<NotificationEvent>.broadcast();

  bool _isInitialized = false;
  bool _notificationsEnabled = true;

  Stream<NotificationEvent> get eventStream => _eventController.stream;
  List<NotificationEvent> get eventHistory => List.unmodifiable(_eventHistory);
  bool get notificationsEnabled => _notificationsEnabled;

  NotificationManager._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Gérer le tap sur la notification
    print('Notification tapped: ${response.payload}');
  }

  Future<void> showNotification(NotificationEvent event) async {
    if (!_notificationsEnabled) return;

    const androidDetails = AndroidNotificationDetails(
      'game_notifications',
      'Game Notifications',
      channelDescription: 'Notifications du jeu PaperClip2',
      importance: Importance.high,
      priority: Priority.high,
      enableLights: true,
      enableVibration: true,
    );

    const iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _notifications.show(
      _eventHistory.length,
      event.title,
      event.description,
      notificationDetails,
    );

    _addToHistory(event);
  }

  void _addToHistory(NotificationEvent event) {
    _eventHistory.add(event);
    _eventController.add(event);

    // Limiter la taille de l'historique
    if (_eventHistory.length > 100) {
      _eventHistory.removeAt(0);
    }
  }

  Future<void> scheduleNotification({
    required String title,
    required String description,
    required DateTime scheduledDate,
    NotificationPriority priority = NotificationPriority.MEDIUM,
  }) async {
    if (!_notificationsEnabled) return;

    const androidDetails = AndroidNotificationDetails(
      'scheduled_notifications',
      'Scheduled Notifications',
      channelDescription: 'Notifications programmées du jeu PaperClip2',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iOSDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _notifications.zonedSchedule(
      _eventHistory.length,
      title,
      description,
      scheduledDate as TZDateTime,
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  void toggleNotifications() {
    _notificationsEnabled = !_notificationsEnabled;
  }

  void clearHistory() {
    _eventHistory.clear();
  }

  Future<void> requestPermissions() async {
    final platform = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (platform != null) {
      await platform.requestPermission();
    }

    final iOSPlatform = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iOSPlatform != null) {
      await iOSPlatform.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  List<NotificationEvent> getRecentNotifications({int limit = 10}) {
    return _eventHistory.reversed.take(limit).toList();
  }

  List<NotificationEvent> getNotificationsByPriority(NotificationPriority priority) {
    return _eventHistory.where((event) => event.priority == priority).toList();
  }

  void dispose() {
    _eventController.close();
  }
} 