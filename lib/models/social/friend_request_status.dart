// lib/models/social/friend_request_status.dart

/// Énumération représentant les différents statuts possibles d'une demande d'amitié
enum FriendRequestStatus {
  /// La demande est en attente de réponse
  pending,
  
  /// La demande a été acceptée
  accepted,
  
  /// La demande a été refusée
  declined,
  
  /// La demande a expiré (après un certain temps sans réponse)
  expired,
  
  /// La demande a été annulée par l'expéditeur
  cancelled,
}

/// Extension pour ajouter des fonctionnalités à l'énumération FriendRequestStatus
extension FriendRequestStatusExtension on FriendRequestStatus {
  /// Convertit une chaîne de caractères en FriendRequestStatus
  static FriendRequestStatus fromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'accepted':
        return FriendRequestStatus.accepted;
      case 'declined':
        return FriendRequestStatus.declined;
      case 'expired':
        return FriendRequestStatus.expired;
      case 'cancelled':
        return FriendRequestStatus.cancelled;
      case 'pending':
      default:
        return FriendRequestStatus.pending;
    }
  }
  
  /// Convertit un FriendRequestStatus en chaîne de caractères
  String toShortString() {
    return toString().split('.').last;
  }
}
