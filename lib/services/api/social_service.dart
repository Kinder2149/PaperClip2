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
  Future<Map<String, dynamic>> sendFriendRequest(String receiverId) async {
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
  Future<List<Map<String, dynamic>>> getReceivedFriendRequests() async {
    try {
      final data = await _apiClient.get('/social/friends/requests/received');
      
      return List<Map<String, dynamic>>.from(data['requests'] ?? []);
    } catch (e) {
      debugPrint('Erreur lors de la récupération des demandes d\'amitié reçues: $e');
      return [];
    }
  }
  
  /// Récupération des demandes d'amitié envoyées
  Future<List<Map<String, dynamic>>> getSentFriendRequests() async {
    try {
      final data = await _apiClient.get('/social/friends/requests/sent');
      
      return List<Map<String, dynamic>>.from(data['requests'] ?? []);
    } catch (e) {
      debugPrint('Erreur lors de la récupération des demandes d\'amitié envoyées: $e');
      return [];
    }
  }
  
  /// Récupération de la liste d'amis
  Future<List<Map<String, dynamic>>> getFriends() async {
    try {
      final data = await _apiClient.get('/social/friends');
      
      return List<Map<String, dynamic>>.from(data['friends'] ?? []);
    } catch (e) {
      debugPrint('Erreur lors de la récupération de la liste d\'amis: $e');
      return [];
    }
  }
  
  /// Suppression d'un ami
  Future<bool> removeFriend(String friendId) async {
    try {
      await _apiClient.delete('/social/friends/$friendId');
      
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la suppression de l\'ami: $e');
      return false;
    }
  }
  
  /// Recherche d'utilisateurs
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final data = await _apiClient.get(
        '/social/users/search',
        queryParams: {'query': query},
      );
      
      return List<Map<String, dynamic>>.from(data['users'] ?? []);
    } catch (e) {
      debugPrint('Erreur lors de la recherche d\'utilisateurs: $e');
      return [];
    }
  }
  
  // ======== GESTION DES CLASSEMENTS ========
  
  /// Récupération des classements disponibles
  Future<List<Map<String, dynamic>>> getLeaderboards() async {
    try {
      final data = await _apiClient.get('/social/leaderboards');
      
      return List<Map<String, dynamic>>.from(data['leaderboards'] ?? []);
    } catch (e) {
      debugPrint('Erreur lors de la récupération des classements: $e');
      return [];
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
  Future<List<Map<String, dynamic>>> getLeaderboardEntries(
    String leaderboardId, {
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
  
  // ======== GESTION DES SUCCÈS ========
  
  /// Récupération des succès disponibles
  Future<List<Map<String, dynamic>>> getAchievements() async {
    try {
      final data = await _apiClient.get('/social/achievements');
      
      return List<Map<String, dynamic>>.from(data['achievements'] ?? []);
    } catch (e) {
      debugPrint('Erreur lors de la récupération des succès: $e');
      return [];
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
  Future<List<Map<String, dynamic>>> getUserAchievements() async {
    try {
      final data = await _apiClient.get('/social/user/achievements');
      
      return List<Map<String, dynamic>>.from(data['achievements'] ?? []);
    } catch (e) {
      debugPrint('Erreur lors de la récupération des succès de l\'utilisateur: $e');
      return [];
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
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final data = await _apiClient.get('/social/users/$userId/stats');
      
      return data['stats'] ?? {};
    } catch (e) {
      debugPrint('Erreur lors de la récupération des statistiques de l\'utilisateur: $e');
      return {};
    }
  }
  
  /// Mise à jour des statistiques de l'utilisateur
  Future<Map<String, dynamic>> updateUserStats(String userId, Map<String, dynamic> stats) async {
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
