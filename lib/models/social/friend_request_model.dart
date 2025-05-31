// lib/models/social/friend_request_model.dart
import 'package:flutter/foundation.dart';

enum FriendRequestStatus {
  pending,
  accepted,
  declined
}

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

  factory FriendRequestModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return FriendRequestModel(
      id: id ?? json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      senderName: json['senderName'] ?? 'Utilisateur inconnu',
      senderPhotoUrl: json['senderPhotoUrl'],
      status: _parseStatus(json['status']),
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
    );
  }

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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'status': status.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
    };
  }

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