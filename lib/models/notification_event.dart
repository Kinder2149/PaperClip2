import 'package:flutter/material.dart';

enum NotificationPriority {
  LOW,
  MEDIUM,
  HIGH,
  CRITICAL
}

class NotificationEvent {
  final String title;
  final String description;
  final String? detailedDescription;  // Nouveau
  final IconData icon;
  final DateTime timestamp;
  final NotificationPriority priority;  // Nouveau
  final Map<String, dynamic>? additionalData;  // Nouveau
  final bool canBeSuppressed;  // Nouveau
  final Duration? suppressionDuration;  // Nouveau

  NotificationEvent({
    required this.title,
    required this.description,
    this.detailedDescription,
    required this.icon,
    DateTime? timestamp,
    this.priority = NotificationPriority.MEDIUM,
    this.additionalData,
    this.canBeSuppressed = true,
    this.suppressionDuration = const Duration(minutes: 5),
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'detailedDescription': detailedDescription,
    'icon': icon.codePoint,
    'timestamp': timestamp.toIso8601String(),
    'priority': priority.index,
    'additionalData': additionalData,
    'canBeSuppressed': canBeSuppressed,
    'suppressionDuration': suppressionDuration?.inSeconds,
  };

  factory NotificationEvent.fromJson(Map<String, dynamic> json) {
    return NotificationEvent(
      title: json['title'] as String,
      description: json['description'] as String,
      detailedDescription: json['detailedDescription'] as String?,
      icon: IconData(json['icon'] as int, fontFamily: 'MaterialIcons'),
      timestamp: DateTime.parse(json['timestamp'] as String),
      priority: NotificationPriority.values[json['priority'] as int],
      additionalData: json['additionalData'] as Map<String, dynamic>?,
      canBeSuppressed: json['canBeSuppressed'] as bool? ?? true,
      suppressionDuration: json['suppressionDuration'] != null
          ? Duration(seconds: json['suppressionDuration'] as int)
          : const Duration(minutes: 5),
    );
  }
}