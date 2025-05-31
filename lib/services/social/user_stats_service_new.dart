// lib/services/social/user_stats_service.dart
import 'package:flutter/foundation.dart';
import '../../models/social/user_stats_model.dart';
import '../../models/game_state.dart';
import '../user/user_manager.dart';

// Import des nouveaux services API
import '../api/api_services.dart';

class UserStatsService extends ChangeNotifier {
  final String _userId;
  final UserManager _userManager;
  
  // Services API
  final ApiClient _apiClient = ApiClient();
  final SocialService _socialService = SocialService();
  final AnalyticsService _analyticsService = AnalyticsService();

  // Durée minimale entre deux mises à jour de stats
  static const Duration _minUpdateInterval = Duration(minutes: 5);
  DateTime _lastUpdate = DateTime.now().subtract(Duration(minutes: 10));

  // Constructeur
  UserStatsService(this._userId, this._userManager);

  // Mettre à jour les statistiques publiques
  Future<bool> updatePublicStats(GameState gameState) async {
    try {
      // Vérifier l'intervalle de mise à jour
      final now = DateTime.now();
      if (now.difference(_lastUpdate) < _minUpdateInterval) {
        return false; // Trop tôt pour mettre à jour
      }

      _lastUpdate = now;

      // Récupérer le profile utilisateur
      final currentProfile = _userManager.currentProfile;
      if (currentProfile == null) {
        return false;
      }

      // Créer l'objet de statistiques
      final stats = UserStatsModel.fromGameState(
        _userId,
        currentProfile.displayName,
        gameState,
      );

      // Envoyer les statistiques au backend
      await _socialService.updateUserStats(stats.toJson());
      
      // Log événement
      _analyticsService.logEvent('stats_updated', parameters: {
        'total_paperclips': stats.totalPaperclips,
        'level': stats.level,
      });

      return true;
    } catch (e, stack) {
      debugPrint('Erreur lors de la mise à jour des statistiques: $e');
      _analyticsService.recordCrash(e, stack, reason: 'Error updating public stats');
      return false;
    }
  }

  // Obtenir les statistiques d'un ami
  Future<UserStatsModel?> getFriendStats(String friendId) async {
    try {
      // Récupérer les statistiques via l'API
      final statsData = await _socialService.getUserStats(friendId);
      
      if (statsData == null) {
        return null;
      }
      
      // Récupérer les informations du profil
      final userData = await _socialService.getUserProfile(friendId);
      
      if (userData == null) {
        return null;
      }

      return UserStatsModel(
        userId: friendId,
        displayName: userData.displayName,
        totalPaperclips: statsData['totalPaperclips'] ?? 0,
        level: statsData['level'] ?? 1,
        money: (statsData['money'] as num?)?.toDouble() ?? 0.0,
        bestScore: statsData['bestScore'] ?? 0,
        efficiency: (statsData['efficiency'] as num?)?.toDouble() ?? 0.0,
        upgradesBought: statsData['upgradesBought'] ?? 0,
        lastUpdated: DateTime.parse(statsData['lastUpdated'] ?? DateTime.now().toIso8601String()),
      );
    } catch (e, stack) {
      debugPrint('Erreur lors de la récupération des statistiques de l\'ami: $e');
      _analyticsService.recordCrash(e, stack, reason: 'Error getting friend stats');
      return null;
    }
  }

  // Comparer les statistiques avec un ami
  Future<Map<String, dynamic>?> compareWithFriend(String friendId, GameState gameState) async {
    try {
      // Récupérer les statistiques de l'ami
      final friendStats = await getFriendStats(friendId);
      if (friendStats == null) {
        return null;
      }

      // Récupérer le profile utilisateur
      final currentProfile = _userManager.currentProfile;
      if (currentProfile == null) {
        return null;
      }

      // Créer nos statistiques
      final myStats = UserStatsModel.fromGameState(
        _userId,
        currentProfile.displayName,
        gameState,
      );

      // Effectuer la comparaison
      final comparison = myStats.compareWith(friendStats);
      
      // Log événement
      _analyticsService.logEvent('stats_compared', parameters: {
        'friend_id': friendId,
      });

      return {
        'me': {
          'userId': _userId,
          'displayName': currentProfile.displayName,
          'photoUrl': currentProfile.profileImageUrl,
        },
        'friend': {
          'userId': friendId,
          'displayName': friendStats.displayName,
        },
        'comparison': comparison,
      };
    } catch (e, stack) {
      debugPrint('Erreur lors de la comparaison avec l\'ami: $e');
      _analyticsService.recordCrash(e, stack, reason: 'Error comparing with friend');
      return null;
    }
  }
  
  // Obtenir le classement des amis
  Future<List<UserStatsModel>> getFriendsLeaderboard() async {
    try {
      // Récupérer le classement via l'API
      return await _socialService.getFriendsLeaderboard();
    } catch (e, stack) {
      debugPrint('Erreur lors de la récupération du classement des amis: $e');
      _analyticsService.recordCrash(e, stack, reason: 'Error getting friends leaderboard');
      return [];
    }
  }
  
  // Obtenir le classement global
  Future<List<UserStatsModel>> getGlobalLeaderboard() async {
    try {
      // Récupérer le classement via l'API
      return await _socialService.getGlobalLeaderboard();
    } catch (e, stack) {
      debugPrint('Erreur lors de la récupération du classement global: $e');
      _analyticsService.recordCrash(e, stack, reason: 'Error getting global leaderboard');
      return [];
    }
  }
  
  // Obtenir les succès de l'utilisateur
  Future<List<Map<String, dynamic>>> getUserAchievements() async {
    try {
      // Récupérer les succès via l'API
      return await _socialService.getUserAchievements();
    } catch (e, stack) {
      debugPrint('Erreur lors de la récupération des succès: $e');
      _analyticsService.recordCrash(e, stack, reason: 'Error getting user achievements');
      return [];
    }
  }
}
