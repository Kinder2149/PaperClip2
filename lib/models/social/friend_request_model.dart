// lib/models/social/friend_request_model.dart
import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'friend_request_model.g.dart';

@JsonEnum()
enum FriendRequestStatus {
  pending,
  accepted,
  declined
}

@JsonSerializable(explicitToJson: true)
class FriendRequestModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String senderName;
  final String? senderPhotoUrl;
  final FriendRequestStatus status;
  final DateTime timestamp;

  FriendRequestModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.status,
    DateTime? timestamp,
  }) : this.timestamp = timestamp ?? DateTime.now();

  // Cette méthode est maintenant gérée par json_serializable
  // Mais nous la conservons pour la compatibilité avec le code existant
  static FriendRequestStatus _parseStatus(String? status) {
    switch (status) {
      case 'accepted':
        return FriendRequestStatus.accepted;
      case 'declined':
        return FriendRequestStatus.declined;
      case 'pending':
      default:
        return FriendRequestStatus.pending;
    }
  }

  // Méthodes générées automatiquement pour la sérialisation JSON
  factory FriendRequestModel.fromJson(Map<String, dynamic> json) => _$FriendRequestModelFromJson(json);
  Map<String, dynamic> toJson() => _$FriendRequestModelToJson(this);

  // Création d'une copie avec un statut modifié
  FriendRequestModel withStatus(FriendRequestStatus newStatus) {
    return FriendRequestModel(
      id: id,
      senderId: senderId,
      receiverId: receiverId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      status: newStatus,
      timestamp: timestamp,
    );
  }
}