import 'package:flutter/material.dart';

class UpgradeCategory {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  const UpgradeCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });

  factory UpgradeCategory.fromJson(Map<String, dynamic> json) {
    return UpgradeCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: IconData(json['iconCodePoint'] as int, fontFamily: 'MaterialIcons'),
      color: Color(json['colorValue'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconCodePoint': icon.codePoint,
      'colorValue': color.value,
    };
  }
} 