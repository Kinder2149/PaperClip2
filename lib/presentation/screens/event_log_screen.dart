// lib/presentation/screens/event_log_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/services/event_manager_service.dart';
import '../../core/constants/imports.dart';
import '../widgets/notification_widgets.dart';

class EventLogScreen extends StatefulWidget {
  const EventLogScreen({Key? key}) : super(key: key);

  @override
  State<EventLogScreen> createState() => _EventLogScreenState();
}

class _EventLogScreenState extends State<EventLogScreen> {
  late EventManager _eventManager;
  List<GameEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _eventManager = Provider.of<EventManager>(context, listen: false);

    // Marquer toutes les notifications comme lues lorsque l'écran est ouvert
    _eventManager.markAllNotificationsAsRead();

    // Récupérer l'historique des événements récents
    _loadEvents();

    // Écouter les nouveaux événements
    _eventManager.eventStream.listen((event) {
      setState(() {
        _events.insert(0, event);
        if (_events.length > GameConstants.MAX_STORED_EVENTS) {
          _events.removeLast();
        }
      });
    });
  }

  void _loadEvents() {
    // Dans une implémentation réelle, les événements pourraient être chargés depuis un stockage
    // Pour l'instant, nous utilisons uniquement les événements qui arrivent via le stream
    setState(() {
      _events = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Journal d\'événements'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_sweep),
            onPressed: () {
              setState(() {
                _events = [];
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Journal effacé')),
              );
            },
            tooltip: 'Effacer le journal',
          ),
        ],
      ),
      body: _events.isEmpty
          ? _buildEmptyState()
          : _buildEventList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_note,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Aucun événement',
            style: Theme.of(context).textTheme.headline6?.copyWith(
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Les événements importants du jeu seront affichés ici',
            style: Theme.of(context).textTheme.bodyText2?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _events.length,
      itemBuilder: (context, index) {
        final event = _events[index];
        final isNewEvent = index == 0 && _events.length > 1;

        return EventLogItem(
          event: event,
          isNewEvent: isNewEvent,
        );
      },
    );
  }
}