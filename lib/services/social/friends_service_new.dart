// lib/services/social/friends_service.dart
import 'package:flutter/foundation.dart';
import '../../models/social/friend_model.dart';
import '../../models/social/friend_request_model.dart';
import '../../models/social/user_stats_model.dart';
import '../user/user_profile.dart';
import '../user/user_manager.dart';

// Import des nouveaux services API
import '../api/api_services.dart';

class FriendsService extends ChangeNotifier {
  final String _userId;
  final UserManager _userManager;
  
  // Services API
  final ApiClient _apiClient = ApiClient();
  final SocialService _socialService = SocialService();
  final AnalyticsService _analyticsService = AnalyticsService();
  
  // Streams pour les données
  final ValueNotifier<List<FriendModel>> friends = ValueNotifier<List<FriendModel>>([]);
  final ValueNotifier<List<FriendRequestModel>> receivedRequests = ValueNotifier<List<FriendRequestModel>>([]);
  final ValueNotifier<List<FriendRequestModel>> sentRequests = ValueNotifier<List<FriendRequestModel>>([]);

  // Constructeur
  FriendsService(this._userId, this._userManager) {
    _initStreams();
  }
  
  // Initialiser les streams
  void _initStreams() {
    _refreshFriends();
    _refreshReceivedRequests();
    _refreshSentRequests();
  }
  
  // Rafraîchir les données des amis
  Future<void> _refreshFriends() async {
    try {
      final friendsList = await _socialService.getFriends();
      friends.value = friendsList;
    } catch (e, stack) {
      debugPrint('Erreur lors du chargement des amis: $e');
      _analyticsService.recordCrash(e, stack, reason: 'Error loading friends');
    }
  }
  
  // Rafraîchir les demandes reçues
  Future<void> _refreshReceivedRequests() async {
    try {
      final requests = await _socialService.getReceivedFriendRequests();
      receivedRequests.value = requests;
    } catch (e, stack) {
      debugPrint('Erreur lors du chargement des demandes reçues: $e');
      _analyticsService.recordCrash(e, stack, reason: 'Error loading received requests');
    }
  }
  
  // Rafraîchir les demandes envoyées
  Future<void> _refreshSentRequests() async {
    try {
      final requests = await _socialService.getSentFriendRequests();
      sentRequests.value = requests;
    } catch (e, stack) {
      debugPrint('Erreur lors du chargement des demandes envoyées: $e');
      _analyticsService.recordCrash(e, stack, reason: 'Error loading sent requests');
    }
  }

  // Stream pour les amis (pour compatibilité avec le code existant)
  Stream<List<FriendModel>> friendsStream() {
    _refreshFriends();
    return friends.stream;
  }

  // Stream pour les demandes d'amitié reçues
  Stream<List<FriendRequestModel>> receivedRequestsStream() {
    _refreshReceivedRequests();
    return receivedRequests.stream;
  }

  // Stream pour les demandes d'amitié envoyées
  Stream<List<FriendRequestModel>> sentRequestsStream() {
    _refreshSentRequests();
    return sentRequests.stream;
  }

  // Rechercher des utilisateurs
  Future<List<UserProfile>> searchUsers(String query) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      final results = await _socialService.searchUsers(query);
      
      // Filtrer pour exclure l'utilisateur actuel
      return results.where((profile) => profile.userId != _userId).toList();
    } catch (e, stack) {
      debugPrint('Erreur lors de la recherche d\'utilisateurs: $e');
      _analyticsService.recordCrash(e, stack, reason: 'Error searching users');
      return [];
    }
  }

  // Trouver un utilisateur par ID
  Future<UserProfile?> findUserById(String userId) async {
    if (userId.isEmpty) {
      return null;
    }

    try {
      return await _socialService.getUserProfile(userId);
    } catch (e, stack) {
      debugPrint('Erreur lors de la recherche de l\'utilisateur: $e');
      _analyticsService.recordCrash(e, stack, reason: 'Error finding user by ID');
      return null;
    }
  }

  // Obtenir des suggestions d'amis
  Future<List<UserProfile>> getSuggestedUsers() async {
    try {
      // Récupérer les suggestions depuis le backend
      final suggestions = await _socialService.getSuggestedFriends();
      
      // Filtrer pour exclure les amis existants et les demandes en cours
      final currentFriendIds = friends.value.map((friend) => friend.userId).toSet();
      final pendingRequestIds = sentRequests.value.map((req) => req.receiverId).toSet();
      
      return suggestions.where((profile) => 
        profile.userId != _userId && 
        !currentFriendIds.contains(profile.userId) &&
        !pendingRequestIds.contains(profile.userId)
      ).toList();
    } catch (e, stack) {
      debugPrint('Erreur lors de la récupération des suggestions d\'amis: $e');
      _analyticsService.recordCrash(e, stack, reason: 'Error getting suggested users');
      return [];
    }
  }

  // Envoyer une demande d'amitié
  Future<bool> sendFriendRequest(String targetUserId, String targetName) async {
    try {
      // Vérifier si une demande existe déjà
      final existingRequests = sentRequests.value;
      if (existingRequests.any((req) => req.receiverId == targetUserId)) {
        return false; // Demande déjà envoyée
      }
      
      // Récupérer les infos du profil actuel
      final currentProfile = _userManager.currentProfile;
      if (currentProfile == null) {
        return false;
      }
      
      // Envoyer la demande via l'API
      final success = await _socialService.sendFriendRequest(targetUserId);
      
      if (success) {
        // Rafraîchir les demandes envoyées
        await _refreshSentRequests();
        
        // Log événement
        _analyticsService.logEvent('friend_request_sent', parameters: {
          'target_user_id': targetUserId,
        });
      }
      
      return success;
    } catch (e, stack) {
      debugPrint('Erreur lors de l\'envoi de la demande d\'amitié: $e');
      _analyticsService.recordCrash(e, stack, reason: 'Error sending friend request');
      return false;
    }
  }

  // Accepter une demande d'amitié
  Future<bool> acceptFriendRequest(String requestId) async {
    try {
      // Accepter la demande via l'API
      final success = await _socialService.acceptFriendRequest(requestId);
      
      if (success) {
        // Rafraîchir les données
        await _refreshFriends();
        await _refreshReceivedRequests();
        
        // Log événement
        _analyticsService.logEvent('friend_request_accepted', parameters: {
          'request_id': requestId,
        });
        
        notifyListeners();
      }
      
      return success;
    } catch (e, stack) {
      debugPrint('Erreur lors de l\'acceptation de la demande d\'amitié: $e');
      _analyticsService.recordCrash(e, stack, reason: 'Error accepting friend request');
      return false;
    }
  }

  // Refuser une demande d'amitié
  Future<bool> declineFriendRequest(String requestId) async {
    try {
      // Refuser la demande via l'API
      final success = await _socialService.declineFriendRequest(requestId);
      
      if (success) {
        // Rafraîchir les demandes reçues
        await _refreshReceivedRequests();
        
        notifyListeners();
      }
      
      return success;
    } catch (e, stack) {
      debugPrint('Erreur lors du refus de la demande d\'amitié: $e');
      _analyticsService.recordCrash(e, stack, reason: 'Error declining friend request');
      return false;
    }
  }

  // Supprimer un ami
  Future<bool> removeFriend(String friendshipId) async {
    try {
      // Supprimer l'ami via l'API
      final success = await _socialService.removeFriend(friendshipId);
      
      if (success) {
        // Rafraîchir la liste des amis
        await _refreshFriends();
        
        notifyListeners();
      }
      
      return success;
    } catch (e, stack) {
      debugPrint('Erreur lors de la suppression de l\'ami: $e');
      _analyticsService.recordCrash(e, stack, reason: 'Error removing friend');
      return false;
    }
  }

  // Vérifier si un utilisateur est ami
  Future<bool> isFriend(String userId) async {
    try {
      // Vérifier dans la liste des amis en mémoire
      final currentFriends = friends.value;
      if (currentFriends.any((friend) => friend.userId == userId)) {
        return true;
      }
      
      // Si pas trouvé, rafraîchir et vérifier à nouveau
      await _refreshFriends();
      return friends.value.any((friend) => friend.userId == userId);
    } catch (e, stack) {
      debugPrint('Erreur lors de la vérification de l\'amitié: $e');
      _analyticsService.recordCrash(e, stack, reason: 'Error checking friend status');
      return false;
    }
  }
  
  // Rafraîchir toutes les données
  Future<void> refreshAll() async {
    await _refreshFriends();
    await _refreshReceivedRequests();
    await _refreshSentRequests();
    notifyListeners();
  }
}
