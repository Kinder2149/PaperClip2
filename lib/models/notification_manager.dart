import 'package:flutter/material.dart';
import 'package:paperclip2/models/constants.dart';
import 'notification_event.dart';

class NotificationManager {
  static final Map<String, DateTime> _lastNotifications = {};

  static bool _canShowNotification(NotificationEvent event) {
    if (!event.canBeSuppressed) return true;

    final lastShown = _lastNotifications[event.title];
    if (lastShown == null) return true;

    return DateTime.now().difference(lastShown) >= (event.suppressionDuration ?? const Duration(minutes: 5));
  }

  static void showGameNotification(
      BuildContext context, {
        required NotificationEvent event,
        VoidCallback? onTap,
      }) {
    if (!_canShowNotification(event)) return;

    _lastNotifications[event.title] = DateTime.now();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: GestureDetector(
          onTap: () {
            if (event.detailedDescription != null) {
              _showDetailedNotification(context, event);
            }
            onTap?.call();
          },
          child: Row(
            children: [
              Icon(event.icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (event.description.isNotEmpty)
                      Text(
                        event.description,
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ),
              if (event.detailedDescription != null)
                Icon(Icons.info_outline, color: Colors.white70),
            ],
          ),
        ),
        duration: _getPriorityDuration(event.priority),
        backgroundColor: _getPriorityColor(event.priority),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  static void _showDetailedNotification(BuildContext context, NotificationEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(event.icon),
            const SizedBox(width: 8),
            Expanded(child: Text(event.title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(event.detailedDescription!),
              if (event.additionalData != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                ...event.additionalData!.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(e.value.toString()),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  static Color _getPriorityColor(NotificationPriority priority) {
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

  static Duration _getPriorityDuration(NotificationPriority priority) {
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
}