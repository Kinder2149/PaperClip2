import 'package:flutter/material.dart';

class NotificationEvent {
  final String title;
  final String description;
  final IconData icon;
  final DateTime timestamp;

  NotificationEvent({
    required this.title,
    required this.description,
    required this.icon,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  // Pour la sérialisation
  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'icon': icon.codePoint,
    'timestamp': timestamp.toIso8601String(),
  };

  // Pour la désérialisation
  factory NotificationEvent.fromJson(Map<String, dynamic> json) {
    return NotificationEvent(
      title: json['title'] as String,
      description: json['description'] as String,
      icon: IconData(json['icon'] as int, fontFamily: 'MaterialIcons'),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}