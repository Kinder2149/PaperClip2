// lib/services/social/friends_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/social/friend_model.dart';
import '../../models/social/friend_request_model.dart';
import '../../models/social/user_stats_model.dart';
import '../user/user_profile.dart';
import '../user/user_manager.dart';

// Import des nouveaux services API
import '../api/api_services.dart';

class FriendsService extends ChangeNotifier {
  late String _userId;
  
  // Services API
  final SocialService _socialService;
  final AnalyticsService _analyticsService;
  final UserManager _userManager;
  
  // Streams pour les données
  final ValueNotifier<List<FriendModel>> friends = ValueNotifier<List<FriendModel>>([]);
  final ValueNotifier<List<FriendRequestModel>> receivedRequests = ValueNotifier<List<FriendRequestModel>>([]);
  final ValueNotifier<List<FriendRequestModel>> sentRequests = ValueNotifier<List<FriendRequestModel>>([]);

  // Streams controllers pour compatibilité avec le code existant
  final _friendsStreamController = StreamController<List<FriendModel>>.broadcast();
  final _receivedRequestsStreamController = StreamController<List<FriendRequestModel>>.broadcast();
  final _sentRequestsStreamController = StreamController<List<FriendRequestModel>>.broadcast();

  // Constructeur
  FriendsService({
    required String userId,
    required UserManager userManager,
    required SocialService socialService,
    required AnalyticsService analyticsService,
  }) : 
    _userId = userId,
    _userManager = userManager,
    _socialService = socialService,
    _analyticsService = analyticsService {
    
    // Initialiser les streams
    _initStreams();
    
    // Si l'utilisateur change, mettre à jour l'ID
    _userManager.profileChanged.addListener(() {
      final profile = _userManager.profileChanged.value;
      if (profile != null && profile.userId != _userId) {
        _userId = profile.userId;
        _initStreams();
      }
    });
  }
  
  @override
  void dispose() {
    _friendsStreamController.close();
    _receivedRequestsStreamController.close();
    _sentRequestsStreamController.close();
    super.dispose();
  }
  
  // Initialiser les streams
  void _initStreams() {
    _refreshFriends();
    _refreshReceivedRequests();
    _refreshSentRequests();
    
    // Mettre à jour les StreamControllers lorsque les ValueNotifiers changent
    friends.addListener(() {
      _friendsStreamController.add(friends.value);
    });
    
    receivedRequests.addListener(() {
      _receivedRequestsStreamController.add(receivedRequests.value);
    });
    
    sentRequests.addListener(() {
      _sentRequestsStreamController.add(sentRequests.value);
    });
  }
  
  // Rafraîchir les données des amis
  Future<void> _refreshFriends() async {
    try {
      final response = await _socialService.getFriends(userId: _userId);
      
      // Vérifier si la réponse est dans le format enveloppé {success, message, data}
      if (response is Map<String, dynamic>) {
        if (response['success'] == false) {
          debugPrint('Erreur lors du chargement des amis: ${response['message'] ?? "Erreur inconnue"}');
          return;
        }
        
        // Si la réponse est un succès, récupérer les données
        final List<dynamic> friendsList = response['data'] ?? [];
        final List<FriendModel> friendModels = friendsList
            .where((friend) => friend is Map<String, dynamic>)
            .map((friend) => FriendModel.fromJson(friend as Map<String, dynamic>))
            .toList();
        
        friends.value = friendModels;
      } else {
        // Format de réponse non reconnu
        debugPrint('Format de réponse inattendu pour getFriends: $response');
      }
    } catch (e, stack) {
      debugPrint('Erreur lors du chargement des amis: $e');
      _analyticsService.recordError(e, stack);
    }
  }
  
  // Rafraîchir les demandes reçues
  Future<void> _refreshReceivedRequests() async {
    try {
      final response = await _socialService.getReceivedFriendRequests(userId: _userId);
      
      // Vérifier si la réponse est dans le format enveloppé {success, message, data}
      if (response is Map<String, dynamic>) {
        if (response['success'] == false) {
          debugPrint('Erreur lors du chargement des demandes reçues: ${response['message'] ?? "Erreur inconnue"}');
          return;
        }
        
        // Si la réponse est un succès, récupérer les données
        final List<dynamic> requestsList = response['data'] ?? [];
        final List<FriendRequestModel> requestModels = requestsList
            .where((request) => request is Map<String, dynamic>)
            .map((request) => FriendRequestModel.fromJson(request as Map<String, dynamic>))
            .toList();
        
        receivedRequests.value = requestModels;
      } else {
        // Format de réponse non reconnu
        debugPrint('Format de réponse inattendu pour getReceivedFriendRequests: $response');
      }
    } catch (e, stack) {
      debugPrint('Erreur lors du chargement des demandes reçues: $e');
      _analyticsService.recordError(e, stack);
    }
  }
  
  // Rafraîchir les demandes envoyées
  Future<void> _refreshSentRequests() async {
    try {
      final response = await _socialService.getSentFriendRequests(userId: _userId);
      
      // Vérifier si la réponse est dans le format enveloppé {success, message, data}
      if (response is Map<String, dynamic>) {
        if (response['success'] == false) {
          debugPrint('Erreur lors du chargement des demandes envoyées: ${response['message'] ?? "Erreur inconnue"}');
          return;
        }
        
        // Si la réponse est un succès, récupérer les données
        final List<dynamic> requestsList = response['data'] ?? [];
        final List<FriendRequestModel> requestModels = requestsList
            .where((request) => request is Map<String, dynamic>)
            .map((request) => FriendRequestModel.fromJson(request as Map<String, dynamic>))
            .toList();
        
        sentRequests.value = requestModels;
      } else {
        // Format de réponse non reconnu
        debugPrint('Format de réponse inattendu pour getSentFriendRequests: $response');
      }
    } catch (e, stack) {
      debugPrint('Erreur lors du chargement des demandes envoyées: $e');
      _analyticsService.recordError(e, stack);
    }
  }

  // Stream pour les amis (pour compatibilité avec le code existant)
  Stream<List<FriendModel>> friendsStream() {
    _refreshFriends();
    return _friendsStreamController.stream;
  }

  // Stream pour les demandes d'amitié reçues
  Stream<List<FriendRequestModel>> receivedRequestsStream() {
    _refreshReceivedRequests();
    return _receivedRequestsStreamController.stream;
  }

  // Stream pour les demandes d'amitié envoyées
  Stream<List<FriendRequestModel>> sentRequestsStream() {
    _refreshSentRequests();
    return _sentRequestsStreamController.stream;
  }

  // Rechercher des utilisateurs
  Future<List<UserProfile>> searchUsers(String query) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      final response = await _socialService.searchUsers(query: query);
      if (response is! Map<String, dynamic> || response['success'] == false) {
        debugPrint('Échec de la recherche d\'utilisateurs: ${response['message'] ?? 'Erreur inconnue'}');
        return [];
      }
      
      final List<dynamic> usersList = response['users'] ?? [];
      final List<UserProfile> userProfiles = usersList
          .map((user) => UserProfile.fromJson(user))
          .toList();
      
      // Filtrer pour exclure l'utilisateur actuel
      return userProfiles.where((profile) => profile.userId != _userId).toList();
    } catch (e, stack) {
      debugPrint('Erreur lors de la recherche d\'utilisateurs: $e');
      _analyticsService.recordError(e, stack);
      return [];
    }
  }

  // Trouver un utilisateur par ID
  Future<UserProfile?> findUserById(String userId) async {
    if (userId.isEmpty) {
      return null;
    }

    try {
      final response = await _socialService.getUserProfile(userId: userId);
      if (response is! Map<String, dynamic> || response['success'] == false) {
        debugPrint('Échec de la recherche de l\'utilisateur: ${response['message'] ?? 'Erreur inconnue'}');
        return null;
      }
      
      return UserProfile.fromJson(response['user']);
    } catch (e, stack) {
      debugPrint('Erreur lors de la recherche de l\'utilisateur: $e');
      _analyticsService.recordError(e, stack);
      return null;
    }
  }

  // Obtenir des suggestions d'amis
  Future<List<UserProfile>> getSuggestedUsers() async {
    try {
      final response = await _socialService.getSuggestedFriends(userId: _userId);
      if (response is! Map<String, dynamic> || response['success'] == false) {
        debugPrint('Échec de la récupération des suggestions d\'amis: ${response['message'] ?? 'Erreur inconnue'}');
        return [];
      }
      
      final List<dynamic> suggestionsList = response['suggestions'] ?? [];
      final List<UserProfile> userProfiles = suggestionsList
          .map((user) => UserProfile.fromJson(user))
          .toList();
      
      return userProfiles;
    } catch (e, stack) {
      debugPrint('Erreur lors de la récupération des suggestions d\'amis: $e');
      _analyticsService.recordError(e, stack);
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
      
      // Envoyer la demande via l'API
      final response = await _socialService.sendFriendRequest(
        receiverId: targetUserId
      );
      
      if (response is! Map<String, dynamic> || response['success'] == false) {
        debugPrint('Échec de l\'envoi de la demande d\'amitié: ${response['message'] ?? 'Erreur inconnue'}');
        return false;
      }
      
      // Rafraîchir les demandes envoyées
      await _refreshSentRequests();
      
      // Log événement
      _analyticsService.logEvent('friend_request_sent', parameters: {
        'target_user_id': targetUserId,
      });
      
      return true;
    } catch (e, stack) {
      debugPrint('Erreur lors de l\'envoi de la demande d\'amitié: $e');
      _analyticsService.recordError(e, stack);
      return false;
    }
  }

  // Accepter une demande d'amitié
  Future<bool> acceptFriendRequest(String requestId) async {
    try {
      // Accepter la demande via l'API
      final Map<String, dynamic> response = await _socialService.acceptFriendRequest(requestId: requestId) as Map<String, dynamic>;
      
      if (response.isEmpty) {
        debugPrint('Échec de l\'acceptation de la demande d\'amitié: réponse vide');
        return false;
      }
      
      // Vérifier le champ success dans la réponse
      if (response.keys.contains('success')) {
        final dynamic successValue = response['success'] as dynamic;
        if (successValue is bool && !successValue) {
          // Récupérer le message d'erreur s'il existe
          String message = 'Erreur inconnue';
          if (response.keys.contains('message')) {
            final dynamic msgValue = response['message'] as dynamic;
            if (msgValue is String) {
              message = msgValue;
            }
          }
          debugPrint('Échec de l\'acceptation de la demande d\'amitié: $message');
          return false;
        }
      }
      
      // Rafraîchir les données
      await _refreshFriends();
      await _refreshReceivedRequests();
      
      // Log événement
      _analyticsService.logEvent('friend_request_accepted', parameters: {
        'request_id': requestId,
      });
      
      notifyListeners();
      return true;
    } catch (e, stack) {
      debugPrint('Erreur lors de l\'acceptation de la demande d\'amitié: $e');
      _analyticsService.recordError(e, stack);
      return false;
    }
  }

  // Refuser une demande d'amitié
  Future<bool> declineFriendRequest(String requestId) async {
    try {
      // Refuser la demande via l'API
      final Map<String, dynamic> response = await _socialService.declineFriendRequest(requestId: requestId) as Map<String, dynamic>;
      
      if (response.isEmpty) {
        debugPrint('Échec du refus de la demande d\'amitié: réponse vide');
        return false;
      }
      
      // Vérifier le champ success dans la réponse
      if (response.keys.contains('success')) {
        final dynamic successValue = response['success'] as dynamic;
        if (successValue is bool && !successValue) {
          // Récupérer le message d'erreur s'il existe
          String message = 'Erreur inconnue';
          if (response.keys.contains('message')) {
            final dynamic msgValue = response['message'] as dynamic;
            if (msgValue is String) {
              message = msgValue;
            }
          }
          debugPrint('Échec du refus de la demande d\'amitié: $message');
          return false;
        }
      }
      
      // Rafraîchir les demandes reçues
      await _refreshReceivedRequests();
      
      notifyListeners();
      return true;
    } catch (e, stack) {
      debugPrint('Erreur lors du refus de la demande d\'amitié: $e');
      _analyticsService.recordError(e, stack);
      return false;
    }
  }

  // Supprimer un ami
  Future<bool> removeFriend(String friendshipId) async {
    try {
      // Supprimer l'ami via l'API
      final Map<String, dynamic> response = await _socialService.removeFriend(friendId: friendshipId) as Map<String, dynamic>;
      
      if (response.isEmpty) {
        debugPrint('Échec de la suppression de l\'ami: réponse vide');
        return false;
      }
      
      // Vérifier le champ success dans la réponse
      if (response.keys.contains('success')) {
        final dynamic successValue = response['success'] as dynamic;
        if (successValue is bool && !successValue) {
          // Récupérer le message d'erreur s'il existe
          String message = 'Erreur inconnue';
          if (response.keys.contains('message')) {
            final dynamic msgValue = response['message'] as dynamic;
            if (msgValue is String) {
              message = msgValue;
            }
          }
          debugPrint('Échec de la suppression de l\'ami: $message');
          return false;
        }
      } else {
        debugPrint('Échec de la suppression de l\'ami: Champ success manquant');
        return false;
      }
      
      // Rafraîchir la liste des amis
      await _refreshFriends();
      
      notifyListeners();
      return true;
    } catch (e, stack) {
      debugPrint('Erreur lors de la suppression de l\'ami: $e');
      _analyticsService.recordError(e, stack);
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
      _analyticsService.recordError(e, stack);
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
