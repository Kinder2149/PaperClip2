import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/event_system.dart';

class EventLogScreen extends StatefulWidget {
  const EventLogScreen({Key? key}) : super(key: key);

  @override
  EventLogScreenState createState() => EventLogScreenState();
}

class EventLogScreenState extends State<EventLogScreen> {
  late final EventManager eventManager;
  List<NotificationEvent> notifications = [];

  @override
  void initState() {
    super.initState();
    eventManager = EventManager.instance;
    eventManager.notificationStream.addListener(_handleNewNotification);
    _loadNotifications(); // Charge les notifications au démarrage
  }

  void _handleNewNotification() {
    _loadNotifications(); // Recharge les notifications quand une nouvelle arrive
  }

  void _loadNotifications() {
    setState(() {
      // Utiliser directement les notifications de l'EventManager
      notifications = List.from(eventManager.notifications);
      _groupSimilarNotifications();
    });
  }

  // Nouvelle méthode pour grouper les notifications similaires
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

  void _showDetailedNotification(BuildContext context, NotificationEvent event) {
    // Marquer la notification comme lue
    EventManager.instance.markAsRead(event.id);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              event.icon,
              color: _getPriorityColor(event.priority),
              size: 28,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(event.title),
                  Text(
                    _formatEventTime(event.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
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
              const SizedBox(height: 16),
              if (event.detailedDescription != null) ...[
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Détails supplémentaires :',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(event.detailedDescription!),
              ],
              if (event.occurrences > 1) ...[
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Fréquence :',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Text('Cet événement s\'est produit ${event.occurrences} fois'),
              ],
              if (event.additionalData != null &&
                  event.additionalData!.isNotEmpty) ...[
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Informations complémentaires :',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                ...event.additionalData!.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${e.key} :',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(e.value.toString()),
                      ),
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
        title: const Text('Journal des Événements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: notifications.isEmpty ? null : _clearNotifications,
            tooltip: 'Effacer toutes les notifications',
          )
        ],
      ),
      body: notifications.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Aucune notification pour le moment',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            )
          ],
        ),
      )
          : ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }
}