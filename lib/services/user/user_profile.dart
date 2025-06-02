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
  final String? customAvatarPath;
  final Map<String, dynamic> privacySettings;
  final Map<String, dynamic> globalStats;
  final List<String> competitiveSaveIds;
  final List<String> infiniteSaveIds;
  final DateTime lastLogin;

  // Pas besoin de définir une date constante statique
  // Nous allons utiliser DateTime.now() directement dans le constructeur
  
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
  })  : this.privacySettings = privacySettings ?? const {},
        this.globalStats = globalStats ?? const {},
        this.competitiveSaveIds = competitiveSaveIds ?? const [],
        this.infiniteSaveIds = infiniteSaveIds ?? const [],
        this.lastLogin = lastLogin ?? DateTime.now();

  // Modification de l'URL de l'image de profil - renvoie un nouveau profil
  UserProfile updateProfileImageUrl(String url) {
    return this.copyWith(profileImageUrl: url);
  }

  // Mettre à jour la date de dernière connexion - renvoie un nouveau profil
  UserProfile updateLastLogin() {
    return this.copyWith(lastLogin: DateTime.now());
  }

  // Ajouter un ID de sauvegarde - renvoie un nouveau profil
  UserProfile addSaveId(String saveId, GameMode mode) {
    if (mode == GameMode.COMPETITIVE) {
      if (!competitiveSaveIds.contains(saveId)) {
        List<String> newIds = List.from(competitiveSaveIds)..add(saveId);
        return this.copyWith(competitiveSaveIds: newIds);
      }
    } else {
      if (!infiniteSaveIds.contains(saveId)) {
        List<String> newIds = List.from(infiniteSaveIds)..add(saveId);
        return this.copyWith(infiniteSaveIds: newIds);
      }
    }
    return this; // Aucun changement nécessaire
  }

  // Supprimer un ID de sauvegarde - renvoie un nouveau profil
  UserProfile removeSaveId(String saveId) {
    List<String> newCompetitiveIds = List.from(competitiveSaveIds)..remove(saveId);
    List<String> newInfiniteIds = List.from(infiniteSaveIds)..remove(saveId);
    return this.copyWith(
      competitiveSaveIds: newCompetitiveIds,
      infiniteSaveIds: newInfiniteIds,
    );
  }

  // Vérifier si l'utilisateur peut créer une sauvegarde compétitive
  bool canCreateCompetitiveSave() {
    return competitiveSaveIds.length < 3;
  }

  // Mettre à jour les statistiques globales - renvoie un nouveau profil
  UserProfile updateGlobalStats(Map<String, dynamic> newStats) {
    Map<String, dynamic> updatedStats = Map.from(globalStats)..addAll(newStats);
    return this.copyWith(globalStats: updatedStats);
  }

  // Conversion en Map pour la sérialisation
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'googleId': googleId,
      'profileImageUrl': profileImageUrl,
      'profileImagePath': profileImagePath,
      'customAvatarPath': customAvatarPath,
      'privacySettings': privacySettings,
      'globalStats': globalStats,
      'competitiveSaveIds': competitiveSaveIds,
      'infiniteSaveIds': infiniteSaveIds,
      'lastLogin': lastLogin.toIso8601String(),
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
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      customAvatarPath: customAvatarPath ?? this.customAvatarPath,
      privacySettings: privacySettings ?? this.privacySettings,
      globalStats: globalStats ?? this.globalStats,
      competitiveSaveIds: competitiveSaveIds ?? this.competitiveSaveIds,
      infiniteSaveIds: infiniteSaveIds ?? this.infiniteSaveIds,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
