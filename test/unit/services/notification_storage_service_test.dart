import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/models/event_system.dart';
import 'package:paperclip2/services/notification_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationStorageService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('saveImportantNotification puis getNotificationsForGame roundtrip (1 notification)',
        () async {
      const gameName = 'demo';

      final notification = NotificationEvent(
        title: 'Notification',
        description: 'Hello',
        icon: Icons.info,
        priority: NotificationPriority.HIGH,
        type: EventType.INFO,
      );

      await NotificationStorageService.saveImportantNotification(notification, gameName);

      final loaded =
          await NotificationStorageService.getNotificationsForGame(gameName);

      expect(loaded.length, 1);
      expect(loaded.first.title, 'Notification');
      expect(loaded.first.description, 'Hello');
      expect(loaded.first.priority, NotificationPriority.HIGH);
      expect(loaded.first.type, EventType.INFO);
    });

    test('gameName trim: "  demo  " et "demo" utilisent la même clé', () async {
      const rawName = '  demo  ';
      const trimmedName = 'demo';

      final notification = NotificationEvent(
        title: 'Notification',
        description: 'Trim',
        icon: Icons.info,
        priority: NotificationPriority.MEDIUM,
        type: EventType.INFO,
      );

      await NotificationStorageService.saveImportantNotification(notification, rawName);

      final loaded =
          await NotificationStorageService.getNotificationsForGame(trimmedName);

      expect(loaded.length, 1);
      expect(loaded.first.description, 'Trim');
    });

    test('cap 50: après 51 sauvegardes, le count retourne 50', () async {
      const gameName = 'cap-test';

      for (var i = 0; i < 51; i++) {
        final notification = NotificationEvent(
          title: 'Notification',
          description: 'N$i',
          icon: Icons.info,
          priority: NotificationPriority.LOW,
          type: EventType.INFO,
        );

        await NotificationStorageService.saveImportantNotification(notification, gameName);
      }

      final count = await NotificationStorageService.getNotificationCount(gameName);
      expect(count, 50);
    });

    test('migrateOldNotifications copie important_notifications vers notifications_<game>',
        () async {
      const gameName = 'migrated';

      final prefs = await SharedPreferences.getInstance();

      final legacyJson = {
        'id': 'legacy-id',
        'title': 'Notification',
        'description': 'Legacy',
        'timestamp': DateTime(2020, 1, 1).toIso8601String(),
        'priority': NotificationPriority.MEDIUM.toString(),
        'type': EventType.INFO.toString(),
        'detailedDescription': null,
        'icon': Icons.info.codePoint,
        'gameName': 'legacy',
      };

      await prefs.setStringList(
        'important_notifications',
        [jsonEncode(legacyJson)],
      );

      await NotificationStorageService.migrateOldNotifications(gameName);

      final loaded =
          await NotificationStorageService.getNotificationsForGame(gameName);

      expect(loaded.length, 1);
      expect(loaded.first.description, 'Legacy');
    });

    test('parse: fallback priority/type si valeurs inconnues', () async {
      const gameName = 'fallback';

      final prefs = await SharedPreferences.getInstance();

      final badJson = {
        'id': 'bad-id',
        'title': 'Notification',
        'description': 'Bad enums',
        'timestamp': DateTime(2020, 1, 1).toIso8601String(),
        'priority': 'UnknownPriority',
        'type': 'UnknownType',
        'detailedDescription': null,
        'icon': Icons.info.codePoint,
        'gameName': gameName,
      };

      await prefs.setStringList(
        'notifications_$gameName',
        [jsonEncode(badJson)],
      );

      final loaded =
          await NotificationStorageService.getNotificationsForGame(gameName);

      expect(loaded.length, 1);
      expect(loaded.first.priority, NotificationPriority.MEDIUM);
      expect(loaded.first.type, EventType.INFO);
    });
  });
}
