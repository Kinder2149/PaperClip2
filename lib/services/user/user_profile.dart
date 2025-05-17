// lib/services/user/user_profile.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/game_config.dart'; // Import de GameMode depuis game_config.dart

class UserProfile {
  final String userId;
  final String displayName;
  final String? googleId;
  final String? profileImageUrl;
  final String? profileImagePath;
  final Map<String, dynamic> privacySettings;
  final String? customAvatarPath;
  final Map<String, dynamic> globalStats;
  final List<String> competitiveSaveIds;
  final List<String> infiniteSaveIds;
  final DateTime lastLogin;

  UserProfile({
    required this.userId,
    required this.displayName,
    this.googleId,
    this.profileImageUrl,
    this.profileImagePath,
    this.customAvatarPath,
    Map<String, dynamic>? privacySettings,
    Map<String, dynamic>? globalStats,
    List<String>? competitiveSaveIds,
    List<String>? infiniteSaveIds,
    DateTime? lastLogin,
  })  : this.privacySettings = privacySettings ?? {},
        this.globalStats = globalStats ?? {},
        this.competitiveSaveIds = competitiveSaveIds ?? [],
        this.infiniteSaveIds = infiniteSaveIds ?? [],
        this.lastLogin = lastLogin ?? DateTime.now();

  // Modification de l'URL de l'image de profil
  void updateProfileImageUrl(String url) {
    _profileImageUrl = url;
  }

  // Variable privée pour updater l'URL
  String? _profileImageUrl;

  // Mettre à jour la date de dernière connexion
  void updateLastLogin() {
    _lastLogin = DateTime.now();
  }

  // Variable privée pour la dernière connexion
  DateTime _lastLogin = DateTime.now();

  // Ajouter un ID de sauvegarde
  void addSaveId(String saveId, GameMode mode) {
    if (mode == GameMode.COMPETITIVE) {
      if (!competitiveSaveIds.contains(saveId)) {
        _competitiveSaveIds.add(saveId);
      }
    } else {
      if (!infiniteSaveIds.contains(saveId)) {
        _infiniteSaveIds.add(saveId);
      }
    }
  }

  // Variables privées pour les IDs de sauvegarde
  List<String> _competitiveSaveIds = [];
  List<String> _infiniteSaveIds = [];

  // Supprimer un ID de sauvegarde
  void removeSaveId(String saveId) {
    _competitiveSaveIds.remove(saveId);
    _infiniteSaveIds.remove(saveId);
  }

  // Vérifier si l'utilisateur peut créer une sauvegarde compétitive
  bool canCreateCompetitiveSave() {
    return competitiveSaveIds.length < 3;
  }

  // Mettre à jour les statistiques globales
  void updateGlobalStats(Map<String, dynamic> newStats) {
    _globalStats.addAll(newStats);
  }

  // Variable privée pour les stats globales
  Map<String, dynamic> _globalStats = {};

  // Conversion en Map pour la sérialisation
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'googleId': googleId,
      'profileImageUrl': _profileImageUrl ?? profileImageUrl,
      'profileImagePath': profileImagePath,
      'customAvatarPath': customAvatarPath,
      'privacySettings': privacySettings,
      'globalStats': globalStats,
      'competitiveSaveIds': competitiveSaveIds,
      'infiniteSaveIds': infiniteSaveIds,
      'lastLogin': _lastLogin.toIso8601String(),
    };
  }

  // Création à partir d'une Map
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] ?? '',
      displayName: json['displayName'] ?? '',
      googleId: json['googleId'],
      profileImageUrl: json['profileImageUrl'],
      profileImagePath: json['profileImagePath'],
      customAvatarPath: json['customAvatarPath'],
      privacySettings: json['privacySettings'] != null
          ? Map<String, dynamic>.from(json['privacySettings'])
          : <String, dynamic>{},
      globalStats: json['globalStats'] != null
          ? Map<String, dynamic>.from(json['globalStats'])
          : <String, dynamic>{},
      competitiveSaveIds: json['competitiveSaveIds'] != null
          ? List<String>.from(json['competitiveSaveIds'])
          : <String>[],
      infiniteSaveIds: json['infiniteSaveIds'] != null
          ? List<String>.from(json['infiniteSaveIds'])
          : <String>[],
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'])
          : DateTime.now(),
    );
  }

  // Méthode copyWith pour créer une copie modifiée
  UserProfile copyWith({
    String? userId,
    String? displayName,
    String? googleId,
    String? profileImageUrl,
    String? profileImagePath,
    String? customAvatarPath,
    Map<String, dynamic>? privacySettings,
    Map<String, dynamic>? globalStats,
    List<String>? competitiveSaveIds,
    List<String>? infiniteSaveIds,
    DateTime? lastLogin,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      googleId: googleId ?? this.googleId,
      profileImageUrl: profileImageUrl ?? this._profileImageUrl ?? this.profileImageUrl,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      customAvatarPath: customAvatarPath ?? this.customAvatarPath,
      privacySettings: privacySettings ?? this.privacySettings,
      globalStats: globalStats ?? this.globalStats,
      competitiveSaveIds: competitiveSaveIds ?? this._competitiveSaveIds,
      infiniteSaveIds: infiniteSaveIds ?? this._infiniteSaveIds,
      lastLogin: lastLogin ?? this._lastLogin,
    );
  }
}