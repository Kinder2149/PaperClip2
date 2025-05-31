// lib/models/social/friend_model.dart
import 'package:flutter/foundation.dart';

class FriendModel {
  final String id;
  final String userId;
  final String displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastActive;

  FriendModel({
    required this.id,
    required this.userId,
    required this.displayName,
    this.photoUrl,
    DateTime? createdAt,
    DateTime? lastActive,
  }) :
        this.createdAt = createdAt ?? DateTime.now(),
        this.lastActive = lastActive ?? DateTime.now();

  // Création depuis un JSON
  factory FriendModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return FriendModel(
      id: id ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      displayName: json['displayName'] ?? 'Utilisateur inconnu',
      photoUrl: json['photoUrl'],
      createdAt: json['createdAt'] != null ? 
          DateTime.parse(json['createdAt']) : 
          DateTime.now(),
      lastActive: json['lastActive'] != null ? 
          DateTime.parse(json['lastActive']) : 
          DateTime.now(),
    );
  }

  // Création depuis un UserProfile
  factory FriendModel.fromUserProfile(Map<String, dynamic> profile) {
    return FriendModel(
      id: profile['friendshipId'] ?? '',
      userId: profile['userId'] ?? '',
      displayName: profile['displayName'] ?? 'Utilisateur inconnu',
      photoUrl: profile['profileImageUrl'],
      createdAt: profile['createdAt'] != null ?
      DateTime.parse(profile['createdAt']) :
      DateTime.now(),
      lastActive: profile['lastLogin'] != null ?
      DateTime.parse(profile['lastLogin']) :
      DateTime.now(),
    );
  }

  // Conversion en Map
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
    };
  }

  // Copie avec modifications
  FriendModel copyWith({
    String? id,
    String? userId,
    String? displayName,
    String? photoUrl,
    DateTime? lastActive,
  }) {
    return FriendModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: this.createdAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}