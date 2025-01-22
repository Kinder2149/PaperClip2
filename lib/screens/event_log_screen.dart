import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/level_system.dart'; // Assurez-vous que ce fichier contient EventManager et les enums

class EventLogScreen extends StatefulWidget {
  const EventLogScreen({Key? key}) : super(key: key);

  @override
  EventLogScreenState createState() => EventLogScreenState();
}

class EventLogScreenState extends State<EventLogScreen> {
  List<GameEvent> events = [];

  @override
  void initState() {
    super.initState();
    loadEvents();
  }

  void loadEvents() {
    setState(() {
      events = EventManager.getEvents().reversed.toList();
    });
  }

  // Méthode pour obtenir la couleur en fonction de l'importance de l'événement
  Color getColorForImportance(EventImportance importance) {
    switch (importance) {
      case EventImportance.LOW:
        return Colors.grey;
      case EventImportance.MEDIUM:
        return Colors.blue;
      case EventImportance.HIGH:
        return Colors.orange;
      case EventImportance.CRITICAL:
        return Colors.red;
    }
  }

  // Méthode pour obtenir l'icône en fonction du type d'événement
  IconData getIconForEventType(EventType type) {
    switch (type) {
      case EventType.LEVEL_UP:
        return Icons.upgrade;
      case EventType.MARKET_CHANGE:
        return Icons.trending_up;
      case EventType.RESOURCE_DEPLETION:
        return Icons.warning;
      case EventType.UPGRADE_AVAILABLE:
        return Icons.new_releases;
      case EventType.SPECIAL_ACHIEVEMENT:
        return Icons.stars;
      case EventType.XP_BOOST:
        return Icons.speed; // ou Icons.exposure_plus_2 pour représenter le boost
      default:
        return Icons.event_note;
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
            onPressed: () {
              EventManager.clearEvents();
              loadEvents();
            },
            tooltip: 'Effacer tous les événements',
          )
        ],
      ),
      body: events.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, size: 100, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              'Aucun événement pour le moment',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            )
          ],
        ),
      )
          : ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return ListTile(
            leading: Icon(
              getIconForEventType(event.type),
              color: getColorForImportance(event.importance),
            ),
            title: Text(
              event.title,
              style: TextStyle(
                fontWeight: event.importance == EventImportance.CRITICAL
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: getColorForImportance(event.importance),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.description,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  _getNotificationDetails(event),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            trailing: Text(
              _formatEventTime(event.timestamp),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          );
        },
      ),
    );
  }

  String _formatEventTime(DateTime timestamp) {
    return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute}';
  }

  String _getNotificationDetails(GameEvent event) {
    switch (event.type) {
      case EventType.LEVEL_UP:
        return 'Nouveau niveau : ${event.data['level']}';
      case EventType.MARKET_CHANGE:
        return 'Prix du marché : ${event.data['price']}';
      case EventType.RESOURCE_DEPLETION:
        return 'Ressource épuisée : ${event.data['resource']}';
      case EventType.UPGRADE_AVAILABLE:
        return 'Amélioration disponible : ${event.data['upgrade']}';
      case EventType.SPECIAL_ACHIEVEMENT:
        return 'Réalisation spéciale : ${event.data['achievement']}';
      case EventType.XP_BOOST:
        return 'Multiplicateur : x${event.data['multiplier']} - Durée : ${event.data['duration']} minutes';
      default:
        return '';
    }
  }
}