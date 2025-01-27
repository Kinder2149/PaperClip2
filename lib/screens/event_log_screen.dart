import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import '../models/game_config.dart';
import '../models/market.dart';
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
      return 'Aujourd\'hui ${timestamp.hour}:${timestamp.minute.toString()
          .padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Hier ${timestamp.hour}:${timestamp.minute.toString().padLeft(
          2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp
          .minute.toString().padLeft(2, '0')}';
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
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _removeNotification(notification);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          leading: Badge(
            label: notification.occurrences > 1
                ? Text(notification.occurrences.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12))
                : null,
            child: Icon(
              notification.icon,
              color: _getNotificationColor(notification),
            ),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight: _getNotificationFontWeight(notification),
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
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (notification.additionalData?['crisisEvent'] != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.help_outline,
                    color: _getNotificationColor(notification),
                    size: 20,
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _removeNotification(notification),
                tooltip: 'Supprimer cette notification',
              ),
            ],
          ),
          onTap: () => _showDetailedNotification(context, notification),
        ),
      ),
    );
  }

  void _showDetailedNotification(BuildContext context, NotificationEvent event) {
    eventManager.markAsRead(event.id);

    final isCrisisEvent = event.additionalData?['crisisEvent'] != null;
    final crisisGuide = isCrisisEvent
        ? EventManager.instance.getGuideForCrisis(
        MarketEvent.values[event.additionalData!['crisisEvent']])
        : null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              event.icon,
              color: isCrisisEvent && crisisGuide != null
                  ? crisisGuide.color
                  : _getPriorityColor(event.priority),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(event.title),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                event.description,
                style: const TextStyle(fontSize: 16),
              ),
              if (isCrisisEvent && crisisGuide != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Guide de résolution :',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: crisisGuide.color,
                  ),
                ),
                const SizedBox(height: 8),
                ...crisisGuide.steps.map((step) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    step,
                    style: const TextStyle(fontSize: 14),
                  ),
                )),
              ] else if (event.detailedDescription != null) ...[
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  event.detailedDescription!,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Reçu le ${_formatEventTime(event.timestamp)}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
  Color _getNotificationColor(NotificationEvent notification) {
    if (notification.additionalData?['crisisEvent'] != null) {
      final crisisEvent = MarketEvent.values[notification.additionalData!['crisisEvent']];
      final guide = EventManager.instance.getGuideForCrisis(crisisEvent);
      if (guide != null) {
        return guide.color;
      }
    }
    return _getPriorityColor(notification.priority);
  }
  void _removeNotification(NotificationEvent notification) {
    setState(() {
      notifications.remove(notification);
      // Mise à jour de l'état dans EventManager
      eventManager.removeNotification(notification.id);
    });
  }
  FontWeight _getNotificationFontWeight(NotificationEvent notification) {
    if (notification.additionalData?['crisisEvent'] != null ||
        notification.priority == NotificationPriority.CRITICAL) {
      return FontWeight.bold;
    }
    return FontWeight.normal;
  }
}
