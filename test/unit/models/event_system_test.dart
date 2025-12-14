import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/models/event_system.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Évite les MissingPluginException si une dépendance appelle SharedPreferences via MethodChannel.
  const MethodChannel sharedPreferencesChannel = MethodChannel(
    'plugins.flutter.io/shared_preferences',
  );

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(sharedPreferencesChannel, (call) async {
    switch (call.method) {
      case 'getAll':
        return <String, Object?>{};
      case 'setBool':
      case 'setDouble':
      case 'setInt':
      case 'setString':
      case 'setStringList':
      case 'remove':
      case 'clear':
      case 'commit':
        return true;
      default:
        return null;
    }
  });

  group('EventManager (models/event_system.dart)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      // clearAllEvents() ne vide pas _lastShownTimes, ce qui rend les tests flaky
      // (throttle _minimumInterval sur les tests suivants).
      EventManager.instance.clearNotifications();
      EventManager.instance.clearAllEvents();
    });

    test('addNotification: ajoute une notification et incrémente unreadCount', () async {
      final manager = EventManager.instance;

      final notification = NotificationEvent(
        title: 'Info',
        description: 'Hello',
        icon: manager.getGuideForCrisis(MarketEvent.MARKET_CRASH)?.icon ?? Icons.info,
        priority: NotificationPriority.MEDIUM,
        type: EventType.INFO,
      );

      await manager.addNotification(notification);

      expect(manager.notifications.length, 1);
      expect(manager.unreadCount.value, 1);
      expect(manager.isUnread(notification.id), true);
      expect(manager.notificationStream.value?.id, notification.id);
    });

    test('addNotification: deuxième notification similaire est ignorée dans la fenêtre _minimumInterval',
        () async {
      final manager = EventManager.instance;

      final n1 = NotificationEvent(
        title: 'Same',
        description: 'A',
        icon: Icons.info,
        priority: NotificationPriority.MEDIUM,
        type: EventType.INFO,
        groupId: 'group_same',
      );

      final n2 = NotificationEvent(
        title: 'Same',
        description: 'B',
        icon: Icons.info,
        priority: NotificationPriority.MEDIUM,
        type: EventType.INFO,
        groupId: 'group_same',
      );

      await manager.addNotification(n1);
      await manager.addNotification(n2);

      // La 2e est ignorée (throttle 30s)
      expect(manager.notifications.length, 1);
      expect(manager.notifications.first.description, 'A');
    });

    test('addNotification: LEVEL_UP bypass _minimumInterval et ajoute toujours une nouvelle entrée',
        () async {
      final manager = EventManager.instance;

      final n1 = NotificationEvent(
        title: 'Level up 1',
        description: 'L2',
        icon: Icons.info,
        priority: NotificationPriority.HIGH,
        type: EventType.LEVEL_UP,
      );

      final n2 = NotificationEvent(
        title: 'Level up 2',
        description: 'L3',
        icon: Icons.info,
        priority: NotificationPriority.HIGH,
        type: EventType.LEVEL_UP,
      );

      await manager.addNotification(n1);
      await manager.addNotification(n2);

      expect(manager.notifications.length, 2);
      expect(manager.unreadCount.value, 2);
    });

    test('markAsRead / markAllAsRead: met à jour unreadCount', () async {
      final manager = EventManager.instance;

      final n1 = NotificationEvent(
        title: 'N1',
        description: '1',
        icon: Icons.info,
        priority: NotificationPriority.MEDIUM,
        type: EventType.INFO,
      );
      final n2 = NotificationEvent(
        title: 'N2',
        description: '2',
        icon: Icons.info,
        priority: NotificationPriority.MEDIUM,
        type: EventType.INFO,
      );

      await manager.addNotification(n1);
      await manager.addNotification(n2);

      manager.markAsRead(n1.id);
      expect(manager.unreadCount.value, 1);
      expect(manager.isUnread(n1.id), false);

      manager.markAllAsRead();
      expect(manager.unreadCount.value, 0);
      expect(manager.isUnread(n2.id), false);
    });

    test('clearNotifications: vide notifications et unreadCount', () async {
      final manager = EventManager.instance;

      final n1 = NotificationEvent(
        title: 'N1',
        description: '1',
        icon: Icons.info,
        priority: NotificationPriority.MEDIUM,
        type: EventType.INFO,
      );

      await manager.addNotification(n1);
      expect(manager.notifications, isNotEmpty);

      manager.clearNotifications();

      expect(manager.notifications, isEmpty);
      expect(manager.unreadCount.value, 0);
      expect(manager.notificationStream.value, isNull);
    });

    test('fromJson recharge notifications + unread et met à jour unreadCount', () {
      final manager = EventManager.instance;

      final json = {
        'notifications': [
          {
            'id': 'n1',
            'title': 'T',
            'description': 'D',
            'detailedDescription': null,
            'icon': 0xe88f,
            'timestamp': DateTime(2020, 1, 1).toIso8601String(),
            'priority': NotificationPriority.MEDIUM.index,
            'additionalData': null,
            'canBeSuppressed': true,
            'suppressionDuration': 60,
            'occurrences': 1,
            'groupId': 'g',
            'unread': true,
          }
        ],
        'events': [],
      };

      manager.fromJson(json);

      expect(manager.notifications.length, 1);
      expect(manager.unreadCount.value, 1);
    });
  });
}
