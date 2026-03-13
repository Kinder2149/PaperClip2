// lib/models/save_metadata.dart
// Modèle riche pour les métadonnées des sauvegardes

import 'package:flutter/foundation.dart';
import 'package:paperclip2/constants/game_config.dart';

/// Classe représentant les métadonnées d'une sauvegarde.
/// 
/// Ces métadonnées fournissent des informations sur la sauvegarde
/// sans nécessiter le chargement complet des données de jeu.
class SaveMetadata {
  /// Identifiant unique de la sauvegarde
  final String id;
  
  /// Nom de la sauvegarde défini par l'utilisateur
  final String name;
  
  /// Description optionnelle de la sauvegarde
  final String? description;
  
  /// Date de création de la sauvegarde
  final DateTime creationDate;
  
  /// Date de dernière modification
  final DateTime lastModified;
  
  /// Version du format de sauvegarde
  final String version;
  
  /// Mode de jeu (infini, scénario, etc.)
  final GameMode gameMode;
  
  /// Données d'affichage pour l'interface utilisateur
  /// Peut contenir des statistiques, une miniature, etc.
  final Map<String, dynamic> displayData;
  
  /// Indique si cette sauvegarde a été restaurée depuis un backup
  final bool isRestored;

  /// Crée une instance de métadonnées de sauvegarde.
  SaveMetadata({
    required this.id,
    required this.name,
    this.description,
    required this.creationDate,
    required this.lastModified,
    required this.version,
    required this.gameMode,
    Map<String, dynamic>? displayData,
    this.isRestored = false,
  }) : this.displayData = displayData ?? {};

  /// Crée une copie de cette instance avec des champs modifiés
  SaveMetadata copyWith({
    String? name,
    String? description,
    DateTime? lastModified,
    GameMode? gameMode,
    Map<String, dynamic>? displayData,
    bool? isRestored,
  }) {
    return SaveMetadata(
      id: this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      creationDate: this.creationDate,
      lastModified: lastModified ?? this.lastModified,
      version: this.version,
      gameMode: gameMode ?? this.gameMode,
      displayData: displayData ?? Map<String, dynamic>.from(this.displayData),
      isRestored: isRestored ?? this.isRestored,
    );
  }

  /// Convertit les métadonnées en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'creationDate': creationDate.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'version': version,
      'gameMode': gameMode.index,
      'displayData': displayData,
      'isRestored': isRestored,
    };
  }

  /// Crée une instance à partir d'un JSON
  factory SaveMetadata.fromJson(Map<String, dynamic> json) {
    return SaveMetadata(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      creationDate: DateTime.parse(json['creationDate'] as String),
      lastModified: DateTime.parse(json['lastModified'] as String),
      version: json['version'] as String,
      gameMode: GameMode.values[json['gameMode'] as int],
      displayData: json['displayData'] as Map<String, dynamic>? ?? {},
      isRestored: json['isRestored'] as bool? ?? false,
    );
  }

  /// Crée une instance avec des valeurs par défaut pour une nouvelle sauvegarde
  factory SaveMetadata.createNew({
    required String id,
    String? name,
    GameMode gameMode = GameMode.INFINITE,
    bool isRestored = false,
  }) {
    final now = DateTime.now();
    return SaveMetadata(
      id: id,
      name: name ?? 'Sauvegarde ${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}',
      description: null,
      creationDate: now,
      lastModified: now,
      version: '2.0', // Version actuelle du format
      gameMode: gameMode,
      displayData: {
        'paperclips': 0,
        'money': 0,
        'level': 1,
      },
      isRestored: isRestored,
    );
  }
  
  // Getters pour rétrocompatibilité avec l'ancien code
  DateTime get lastModifiedAt => lastModified;
  String get gameVersion => version;
  // Getter de compatibilité: certains anciens appels utilisent metadata.timestamp
  DateTime get timestamp => lastModified;
  
  @override
  String toString() => 'SaveMetadata(id: $id, name: $name, version: $version)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SaveMetadata && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}
