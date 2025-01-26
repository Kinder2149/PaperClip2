import 'package:flutter/material.dart';
import '../models/event_system.dart';

class EventLogScreen extends StatefulWidget {
  const EventLogScreen({Key? key}) : super(key: key);

  @override
  EventLogScreenState createState() => EventLogScreenState();
}

class EventLogScreenState extends State<EventLogScreen> {
  late final EventManager eventManager;
  List<NotificationEvent> notifications = [];
  NotificationEvent? currentNotification;

  @override
  void initState() {
    super.initState();
    eventManager = EventManager.instance;
    eventManager.notificationStream.addListener(_handleNewNotification);
    _loadNotifications();
  }

  void _handleNewNotification() {
    final notification = eventManager.notificationStream.value;
    if (notification != null) {
      setState(() {
        currentNotification = notification;
      });
      _loadNotifications();
    }
  }

  void _dismissNotification() {
    setState(() {
      currentNotification = null;
      eventManager.markAsRead(currentNotification!.id);
    });
  }

  void _loadNotifications() {
    setState(() {
      notifications = List.from(eventManager.notifications);
      _groupSimilarNotifications();
    });
  }

  void _groupSimilarNotifications() {
    final Map<String, NotificationEvent> groupedNotifications = {};

    for (var notification in notifications.reversed) {
      String groupKey = '${notification.type}_${notification.title}';
      if (groupedNotifications.containsKey(groupKey)) {
        var existing = groupedNotifications[groupKey]!;
        existing.occurrences++;
      } else {
        groupedNotifications[groupKey] = notification;
      }
    }

    notifications = groupedNotifications.values.toList();
    notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  void _clearNotifications() {
    setState(() {
      notifications.clear();
      eventManager.clearEvents();
    });
  }

  @override
  void dispose() {
    eventManager.notificationStream.removeListener(_handleNewNotification);
    super.dispose();
  }

  Color _getPriorityColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.LOW:
        return Colors.grey;
      case NotificationPriority.MEDIUM:
        return Colors.blue;
      case NotificationPriority.HIGH:
        return Colors.orange;
      case NotificationPriority.CRITICAL:
        return Colors.red;
    }
  }

  String _formatEventTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Hier ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: notifications.isEmpty ? null : _clearNotifications,
            tooltip: 'Effacer toutes les notifications',
          )
        ],
      ),
      body: Column(
        children: [
          if (currentNotification != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                color: _getPriorityColor(currentNotification!.priority),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(currentNotification!.icon, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          currentNotification!.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _dismissNotification,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationCard(notification);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationEvent notification) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Badge(
          label: notification.occurrences > 1
              ? Text(notification.occurrences.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 12))
              : null,
          child: Icon(
            notification.icon,
            color: _getPriorityColor(notification.priority),
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.priority == NotificationPriority.CRITICAL
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.description),
            Row(
              children: [
                Text(
                  _formatEventTime(notification.timestamp),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                if (notification.occurrences > 1) ...[
                  const SizedBox(width: 8),
                  Text(
                    '(${notification.occurrences}x)',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        onTap: () => _showDetailedNotification(context, notification),
      ),
    );
  }

  void _showDetailedNotification(BuildContext context, NotificationEvent event) {
    eventManager.markAsRead(event.id);
    // Display detailed notification
  }
}