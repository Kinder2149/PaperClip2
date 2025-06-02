// lib/services/api/social_service.dart

import 'package:flutter/material.dart';
import 'api_client.dart';

/// Service social utilisant le backend personnalisé
/// Remplace les fonctionnalités sociales de Firebase (amis, classements, succès)
class SocialService {
  static final SocialService _instance = SocialService._internal();
  factory SocialService() => _instance;

  // Client API
  final ApiClient _apiClient = ApiClient();
  
  // Constructeur interne
  SocialService._internal();
  
  /// Initialisation du service
  Future<void> initialize() async {
    // Aucune initialisation spécifique requise pour le moment
    debugPrint('SocialService initialisé');
  }
  
  // ======== GESTION DES AMIS ========
  
  /// Envoi d'une demande d'amitié
  Future<Map<String, dynamic>> sendFriendRequest({required String receiverId}) async {
    try {
      final data = await _apiClient.post(
        '/social/friends/requests',
        body: {'receiver_id': receiverId},
      );
      
      return data;
    } catch (e) {
      debugPrint('Erreur lors de l\'envoi de la demande d\'amitié: $e');
      rethrow;
    }
  }
  
  /// Réponse à une demande d'amitié
  Future<Map<String, dynamic>> respondToFriendRequest(String requestId, String status) async {
    try {
      final data = await _apiClient.put(
        '/social/friends/requests/$requestId',
        body: {'status': status},
      );
      
      return data;
    } catch (e) {
      debugPrint('Erreur lors de la réponse à la demande d\'amitié: $e');
      rethrow;
    }
  }
  
  /// Récupération des demandes d'amitié reçues
  Future<Map<String, dynamic>> getReceivedFriendRequests({String? userId}) async {
    try {
      final data = await _apiClient.get('/social/friends/requests/received');
      
      return {
        'success': true,
        'data': List<Map<String, dynamic>>.from(data['requests'] ?? [])
      };
    } catch (e) {
      debugPrint('Erreur lors de la récupération des demandes d\'amitié reçues: $e');
      return {
        'success': false,
        'message': e.toString(),
        'data': []
      };
    }
  }
  
  /// Récupération des demandes d'amitié envoyées
  Future<Map<String, dynamic>> getSentFriendRequests({String? userId}) async {
    try {
      final data = await _apiClient.get('/social/friends/requests/sent');
      
      return {
        'success': true,
        'data': List<Map<String, dynamic>>.from(data['requests'] ?? [])
      };
    } catch (e) {
      debugPrint('Erreur lors de la récupération des demandes d\'amitié envoyées: $e');
      return {
        'success': false,
        'message': e.toString(),
        'data': []
      };
    }
  }
  
  /// Récupération de la liste d'amis
  Future<Map<String, dynamic>> getFriends({String? userId}) async {
    try {
      final data = await _apiClient.get('/social/friends');
      
      return {
        'success': true,
        'data': List<Map<String, dynamic>>.from(data['friends'] ?? [])
      };
    } catch (e) {
      debugPrint('Erreur lors de la récupération de la liste d\'amis: $e');
      return {
        'success': false,
        'message': e.toString(),
        'data': []
      };
    }
  }
  
  /// Suppression d'un ami
  Future<bool> removeFriend({required String friendId}) async {
    try {
      await _apiClient.delete('/social/friends/$friendId');
      
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la suppression de l\'ami: $e');
      return false;
    }
  }
  
  /// Recherche d'utilisateurs
  Future<Map<String, dynamic>> searchUsers({required String query}) async {
    try {
      final data = await _apiClient.get(
        '/social/users/search',
        queryParams: {'query': query},
      );
      
      return {
        'success': true,
        'data': List<Map<String, dynamic>>.from(data['users'] ?? [])
      };
    } catch (e) {
      debugPrint('Erreur lors de la recherche d\'utilisateurs: $e');
      return {
        'success': false,
        'message': e.toString(),
        'data': []
      };
    }
  }
  
  // ======== GESTION DES CLASSEMENTS ========
  
  /// Récupération des classements disponibles
  Future<Map<String, dynamic>> getLeaderboards() async {
    try {
      final data = await _apiClient.get('/social/leaderboards');
      
      return {
        'success': true,
        'data': List<Map<String, dynamic>>.from(data['leaderboards'] ?? [])
      };
    } catch (e) {
      debugPrint('Erreur lors de la récupération des classements: $e');
      return {
        'success': false,
        'message': e.toString(),
        'data': []
      };
    }
  }
  
  /// Récupération d'un classement spécifique
  Future<Map<String, dynamic>> getLeaderboard(String leaderboardId) async {
    try {
      final data = await _apiClient.get('/social/leaderboards/$leaderboardId');
      
      return data;
    } catch (e) {
      debugPrint('Erreur lors de la récupération du classement: $e');
      rethrow;
    }
  }
  
  /// Soumission d'un score dans un classement
  Future<Map<String, dynamic>> submitScore(String leaderboardId, int score) async {
    try {
      final data = await _apiClient.post(
        '/social/leaderboards/$leaderboardId/entries',
        body: {'score': score},
      );
      
      return data;
    } catch (e) {
      debugPrint('Erreur lors de la soumission du score: $e');
      rethrow;
    }
  }
  
  /// Récupération des entrées d'un classement
  Future<List<Map<String, dynamic>>> getLeaderboardEntries({
    required String leaderboardId,
    int limit = 100,
    int offset = 0,
    bool friendsOnly = false,
  }) async {
    try {
      final queryParams = {
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      
      if (friendsOnly) {
        queryParams['friends_only'] = 'true';
      }
      
      final data = await _apiClient.get(
        '/social/leaderboards/$leaderboardId/entries',
        queryParams: queryParams,
      );
      
      return List<Map<String, dynamic>>.from(data['entries'] ?? []);
    } catch (e) {
      debugPrint('Erreur lors de la récupération des entrées du classement: $e');
      return [];
    }
  }
  
  /// Récupération du rang de l'utilisateur dans un classement
  Future<Map<String, dynamic>?> getUserRank(String leaderboardId) async {
    try {
      final data = await _apiClient.get('/social/leaderboards/$leaderboardId/user-rank');
      
      return data;
    } catch (e) {
      debugPrint('Erreur lors de la récupération du rang de l\'utilisateur: $e');
      return null;
    }
  }
  
  /// Récupération du profil d'un utilisateur
  Future<Map<String, dynamic>> getUserProfile({required String userId}) async {
    try {
      final data = await _apiClient.get('/social/users/$userId/profile');
      
      return data;
    } catch (e) {
      debugPrint('Erreur lors de la récupération du profil utilisateur: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Accepter une demande d'amitié
  Future<Map<String, dynamic>> acceptFriendRequest({required String requestId}) async {
    try {
      final data = await _apiClient.put(
        '/social/friends/requests/$requestId/accept',
      );
      
      return data;
    } catch (e) {
      debugPrint('Erreur lors de l\'acceptation de la demande d\'amitié: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Décliner une demande d'amitié
  Future<Map<String, dynamic>> declineFriendRequest({required String requestId}) async {
    try {
      final data = await _apiClient.put(
        '/social/friends/requests/$requestId/decline',
      );
      
      return data;
    } catch (e) {
      debugPrint('Erreur lors du refus de la demande d\'amitié: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Récupérer des suggestions d'amis
  Future<Map<String, dynamic>> getSuggestedFriends({String? userId}) async {
    try {
      final queryParams = userId != null ? {'user_id': userId} : <String, String>{};
      
      final data = await _apiClient.get(
        '/social/friends/suggestions',
        queryParams: queryParams,
      );
      
      return {
        'success': true,
        'data': List<Map<String, dynamic>>.from(data['users'] ?? [])
      };
    } catch (e) {
      debugPrint('Erreur lors de la récupération des suggestions d\'amis: $e');
      return {
        'success': false,
        'message': e.toString(),
        'data': []
      };
    }
  }

  // ======== GESTION DES SUCCÈS ========
  
  /// Récupération des succès disponibles
  Future<Map<String, dynamic>> getAchievements() async {
    try {
      final data = await _apiClient.get('/social/achievements');
      
      return {
        'success': true,
        'data': List<Map<String, dynamic>>.from(data['achievements'] ?? [])
      };
    } catch (e) {
      debugPrint('Erreur lors de la récupération des succès: $e');
      return {
        'success': false,
        'message': e.toString(),
        'data': []
      };
    }
  }
  
  /// Récupération d'un succès spécifique
  Future<Map<String, dynamic>> getAchievement(String achievementId) async {
    try {
      final data = await _apiClient.get('/social/achievements/$achievementId');
      
      return data;
    } catch (e) {
      debugPrint('Erreur lors de la récupération du succès: $e');
      rethrow;
    }
  }
  
  /// Récupération des succès de l'utilisateur
  Future<Map<String, dynamic>> getUserAchievements() async {
    try {
      final data = await _apiClient.get('/social/user/achievements');
      
      return {
        'success': true,
        'data': List<Map<String, dynamic>>.from(data['achievements'] ?? [])
      };
    } catch (e) {
      debugPrint('Erreur lors de la récupération des succès de l\'utilisateur: $e');
      return {
        'success': false,
        'message': e.toString(),
        'data': []
      };
    }
  }
  
  /// Déblocage d'un succès
  Future<Map<String, dynamic>> unlockAchievement(
    String achievementId, {
    Map<String, dynamic>? progress,
  }) async {
    try {
      final data = await _apiClient.post(
        '/social/achievements/$achievementId/unlock',
        body: progress != null ? {'progress': progress} : null,
      );
      
      return data;
    } catch (e) {
      debugPrint('Erreur lors du déblocage du succès: $e');
      rethrow;
    }
  }
  
  /// Mise à jour de la progression d'un succès
  Future<Map<String, dynamic>> updateAchievementProgress(
    String achievementId,
    Map<String, dynamic> progress,
  ) async {
    try {
      final data = await _apiClient.put(
        '/social/achievements/$achievementId/progress',
        body: {'progress': progress},
      );
      
      return data;
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de la progression du succès: $e');
      rethrow;
    }
  }
  
  // ======== GESTION DES STATISTIQUES UTILISATEUR ========
  
  /// Récupération des statistiques d'un utilisateur
  Future<Map<String, dynamic>> getUserStats({required String userId}) async {
    try {
      final data = await _apiClient.get('/social/users/$userId/stats');
      
      return {
        'success': true,
        'data': data['stats'] ?? {}
      };
    } catch (e) {
      debugPrint('Erreur lors de la récupération des statistiques de l\'utilisateur: $e');
      return {
        'success': false,
        'message': e.toString(),
        'data': {}
      };
    }
  }
  
  /// Mise à jour des statistiques de l'utilisateur
  Future<Map<String, dynamic>> updateUserStats({required String userId, required Map<String, dynamic> stats}) async {
    try {
      final data = await _apiClient.put(
        '/social/user/stats/$userId',
        body: {'stats': stats},
      );
      
      return data;
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour des statistiques de l\'utilisateur: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}
