import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

enum EventType {
  SPECIAL_OFFER,
  ACHIEVEMENT,
  MILESTONE,
  DAILY_REWARD,
  WEEKLY_CHALLENGE,
}

class GameEvent {
  final String id;
  final String title;
  final String description;
  final EventType type;
  final DateTime startDate;
  final DateTime? endDate;
  final Map<String, dynamic> rewards;
  final bool isActive;
  final bool isCompleted;

  GameEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.startDate,
    this.endDate,
    required this.rewards,
    this.isActive = true,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'type': type.toString(),
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'rewards': rewards,
        'isActive': isActive,
        'isCompleted': isCompleted,
      };

  factory GameEvent.fromJson(Map<String, dynamic> json) => GameEvent(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        type: EventType.values.firstWhere(
          (e) => e.toString() == json['type'],
          orElse: () => EventType.SPECIAL_OFFER,
        ),
        startDate: DateTime.parse(json['startDate']),
        endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
        rewards: json['rewards'],
        isActive: json['isActive'] ?? true,
        isCompleted: json['isCompleted'] ?? false,
      );
}

class EventService {
  static final EventService _instance = EventService._internal();
  factory EventService() => _instance;
  EventService._internal();

  final NotificationService _notifications = NotificationService();
  final List<GameEvent> _activeEvents = [];
  Timer? _eventCheckTimer;
  static const String _eventsKey = 'game_events';

  List<GameEvent> get activeEvents => _activeEvents;

  Future<void> initialize() async {
    await _loadEvents();
    _startEventCheckTimer();
  }

  void _startEventCheckTimer() {
    _eventCheckTimer?.cancel();
    _eventCheckTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _checkEvents();
    });
  }

  Future<void> _loadEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getStringList(_eventsKey) ?? [];
      _activeEvents.clear();
      _activeEvents.addAll(
        eventsJson
            .map((json) => GameEvent.fromJson(json as Map<String, dynamic>))
            .where((event) => event.isActive),
      );
    } catch (e) {
      debugPrint('Erreur lors du chargement des événements: $e');
    }
  }

  Future<void> _saveEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _eventsKey,
        _activeEvents.map((event) => event.toJson().toString()).toList(),
      );
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde des événements: $e');
    }
  }

  Future<void> _checkEvents() async {
    final now = DateTime.now();
    for (var event in _activeEvents) {
      if (event.endDate != null && event.endDate!.isBefore(now)) {
        await _completeEvent(event);
      }
    }
  }

  Future<void> addEvent(GameEvent event) async {
    _activeEvents.add(event);
    await _saveEvents();
    await _notifyEvent(event);
  }

  Future<void> completeEvent(String eventId) async {
    final event = _activeEvents.firstWhere(
      (e) => e.id == eventId,
      orElse: () => throw Exception('Événement non trouvé'),
    );
    await _completeEvent(event);
  }

  Future<void> _completeEvent(GameEvent event) async {
    final index = _activeEvents.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _activeEvents[index] = GameEvent(
        id: event.id,
        title: event.title,
        description: event.description,
        type: event.type,
        startDate: event.startDate,
        endDate: event.endDate,
        rewards: event.rewards,
        isActive: false,
        isCompleted: true,
      );
      await _saveEvents();
    }
  }

  Future<void> _notifyEvent(GameEvent event) async {
    await _notifications.showNotification(
      title: event.title,
      body: event.description,
      payload: event.id,
    );
  }

  void dispose() {
    _eventCheckTimer?.cancel();
  }
} 