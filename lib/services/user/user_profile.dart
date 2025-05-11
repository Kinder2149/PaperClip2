// lib/services/user/user_profile.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';

// Essayons d'abord avec l'import relatif
import '../../models/game_config.dart';

class UserProfile {
  final String userId;          // ID unique du profil
  final String displayName;     // Nom d'affichage
  final String? googleId;       // ID Google associé (optionnel)
  final DateTime createdAt;     // Date de création
  DateTime lastLogin;           // Dernière connexion
  final List<String> infiniteSaveIds; // IDs des parties infinies
  final List<String> competitiveSaveIds; // IDs des parties compétitives
  final Map<String, dynamic> globalStats; // Statistiques globales
  String? profileImagePath;     // Chemin de l'image de profil (local)
  String? profileImageUrl;      // URL de l'image de profil (cloud)

  UserProfile({
    required this.userId,
    required this.displayName,
    this.googleId,
    DateTime? createdAt,
    DateTime? lastLogin,
    List<String>? infiniteSaveIds,
    List<String>? competitiveSaveIds,
    Map<String, dynamic>? globalStats,
    this.profileImagePath,
    this.profileImageUrl,
  }) :
        this.createdAt = createdAt ?? DateTime.now(),
        this.lastLogin = lastLogin ?? DateTime.now(),
        this.infiniteSaveIds = infiniteSaveIds ?? [],
        this.competitiveSaveIds = competitiveSaveIds ?? [],
        this.globalStats = globalStats ?? {};

  // Mise à jour du login
  void updateLastLogin() {
    lastLogin = DateTime.now();
  }

  // Vérifier si l'utilisateur peut créer une partie compétitive
  bool canCreateCompetitiveSave() {
    return competitiveSaveIds.length < 3;
  }

  // Ajouter une sauvegarde
  void addSaveId(String saveId, GameMode mode) {
    if (mode == GameMode.COMPETITIVE) {
      if (canCreateCompetitiveSave()) {
        competitiveSaveIds.add(saveId);
      } else {
        throw Exception("Limite de parties compétitives atteinte (3 maximum)");
      }
    } else {
      infiniteSaveIds.add(saveId);
    }
  }

  // Supprimer une sauvegarde
  void removeSaveId(String saveId) {
    infiniteSaveIds.remove(saveId);
    competitiveSaveIds.remove(saveId);
  }

  // Mise à jour du chemin de l'image de profil
  void updateProfileImagePath(String path) {
    profileImagePath = path;
  }

  // Mise à jour de l'URL de l'image de profil
  void updateProfileImageUrl(String url) {
    profileImageUrl = url;
  }

  // Mise à jour des statistiques globales
  void updateGlobalStats(Map<String, dynamic> newStats) {
    // Fusion des statistiques existantes avec les nouvelles
    globalStats.addAll(newStats);
  }

  // Sérialisation vers JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'googleId': googleId,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
      'infiniteSaveIds': infiniteSaveIds,
      'competitiveSaveIds': competitiveSaveIds,
      'globalStats': globalStats,
      'profileImagePath': profileImagePath,
      'profileImageUrl': profileImageUrl,
    };
  }

  // Désérialisation depuis JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'],
      displayName: json['displayName'],
      googleId: json['googleId'],
      createdAt: DateTime.parse(json['createdAt']),
      lastLogin: DateTime.parse(json['lastLogin']),
      infiniteSaveIds: List<String>.from(json['infiniteSaveIds'] ?? []),
      competitiveSaveIds: List<String>.from(json['competitiveSaveIds'] ?? []),
      globalStats: json['globalStats'] ?? {},
      profileImagePath: json['profileImagePath'],
      profileImageUrl: json['profileImageUrl'],
    );
  }

  // Copie avec modifications potentielles
  UserProfile copyWith({
    String? displayName,
    String? googleId,
    String? profileImagePath,
    String? profileImageUrl,
  }) {
    return UserProfile(
      userId: this.userId,
      displayName: displayName ?? this.displayName,
      googleId: googleId ?? this.googleId,
      createdAt: this.createdAt,
      lastLogin: this.lastLogin,
      infiniteSaveIds: List.from(this.infiniteSaveIds),
      competitiveSaveIds: List.from(this.competitiveSaveIds),
      globalStats: Map.from(this.globalStats),
      profileImagePath: profileImagePath ?? this.profileImagePath,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}