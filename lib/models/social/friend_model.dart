// lib/models/social/friend_model.dart
import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'friend_model.g.dart';

@JsonSerializable(explicitToJson: true)
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

  // Méthodes générées automatiquement pour la sérialisation JSON
  factory FriendModel.fromJson(Map<String, dynamic> json) => _$FriendModelFromJson(json);
  Map<String, dynamic> toJson() => _$FriendModelToJson(this);

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