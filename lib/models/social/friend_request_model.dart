// lib/models/friend_request_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
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

  factory FriendRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return FriendRequestModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      senderName: data['senderName'] ?? 'Utilisateur inconnu',
      senderPhotoUrl: data['senderPhotoUrl'],
      status: _parseStatus(data['status']),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
      'senderId': senderId,
      'receiverId': receiverId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'status': status.toString().split('.').last,
      'timestamp': FieldValue.serverTimestamp(),
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