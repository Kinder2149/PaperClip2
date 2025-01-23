import 'package:flutter/material.dart';
import 'game_enums.dart';
class GameEvent {
  final EventType type;
  final String title;
  final String description;
  final EventImportance importance;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  GameEvent({
    required this.type,
    required this.title,
    required this.description,
    this.importance = EventImportance.LOW,
    Map<String, dynamic>? data,
  }) : timestamp = DateTime.now(),
        data = data ?? {};

  // Pour la sérialisation
  Map<String, dynamic> toJson() => {
    'type': type.index,
    'title': title,
    'description': description,
    'importance': importance.index,
    'timestamp': timestamp.toIso8601String(),
    'data': data,
  };

  // Pour la désérialisation
  factory GameEvent.fromJson(Map<String, dynamic> json) {
    return GameEvent(
      type: EventType.values[json['type'] as int],
      title: json['title'] as String,
      description: json['description'] as String,
      importance: EventImportance.values[json['importance'] as int],
      data: json['data'] as Map<String, dynamic>,
    );
  }

  // Pour comparer deux événements
  bool equals(GameEvent other) {
    return type == other.type &&
        title == other.title &&
        description == other.description &&
        importance == other.importance;
  }

  // Pour le filtrage des événements
  bool matchesFilter(EventType? typeFilter, EventImportance? minImportance) {
    if (typeFilter != null && type != typeFilter) return false;
    if (minImportance != null && importance.value < minImportance.value) return false;
    return true;
  }

  // Pour l'affichage formaté de l'horodatage
  String get formattedTimestamp {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours}h';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute}';
    }
  }

  // Pour obtenir la couleur associée à l'importance
  Color get importanceColor {
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

  // Pour obtenir l'icône associée au type d'événement
  IconData get typeIcon {
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
        return Icons.speed;
    }
  }
}