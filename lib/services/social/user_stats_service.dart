// lib/services/social/user_stats_service.dart
import 'package:flutter/foundation.dart';
import '../../models/social/user_stats_model.dart';
import '../../models/game_state.dart';
import '../user/user_manager.dart';

// Import des nouveaux services API
import '../api/api_services.dart';

class UserStatsService extends ChangeNotifier {
  String _userId;
  
  // Services API
  final SocialService _socialService;
  final AnalyticsService _analyticsService;
  final UserManager _userManager;

  // Durée minimale entre deux mises à jour de stats
  static const Duration _minUpdateInterval = Duration(minutes: 5);
  DateTime _lastUpdate = DateTime.now().subtract(Duration(minutes: 10));

  // Constructeur
  UserStatsService({
    required String userId,
    required UserManager userManager,
    required SocialService socialService,
    required AnalyticsService analyticsService,
  }) : 
    _userId = userId,
    _userManager = userManager,
    _socialService = socialService,
    _analyticsService = analyticsService {
    
    // Si l'utilisateur change, mettre à jour l'ID
    _userManager.profileChanged.addListener(() {
      final profile = _userManager.profileChanged.value;
      if (profile != null && profile.userId != _userId) {
        _userId = profile.userId;
        notifyListeners();
      }
    });
  }

  // Mettre à jour les statistiques publiques
  Future<bool> updatePublicStats(GameState gameState) async {
    try {
      // Vérifier si l'ID utilisateur est valide
      if (_userId.isEmpty) {
        return false;
      }
      
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
      final response = await _socialService.updateUserStats(userId: _userId, stats: stats.toJson());
      
      if (response is! Map<String, dynamic> || response['success'] == false) {
        debugPrint('Échec de la mise à jour des statistiques: ${response['message'] ?? 'Erreur inconnue'}');
        return false;
      }
      
      // Log événement
      _analyticsService.logEvent('stats_updated', parameters: {
        'total_paperclips': stats.totalPaperclips,
        'level': stats.level,
      });

      return true;
    } catch (e, stack) {
      debugPrint('Erreur lors de la mise à jour des statistiques: $e');
      _analyticsService.recordError(e, stack);
      return false;
    }
  }

  // Obtenir les statistiques d'un ami
  Future<UserStatsModel?> getFriendStats(String friendId) async {
    try {
      // Récupérer les statistiques via l'API
      final statsResponse = await _socialService.getUserStats(userId: friendId);
      
      if (statsResponse is! Map<String, dynamic> || statsResponse['success'] == false) {
        debugPrint('Échec de la récupération des statistiques: ${statsResponse['message'] ?? 'Erreur inconnue'}');
        return null;
      }
      
      final statsData = statsResponse['stats'] ?? {};
      
      // Récupérer les informations du profil
      final userResponse = await _socialService.getUserProfile(userId: friendId);
      
      if (userResponse is! Map<String, dynamic> || userResponse['success'] == false) {
        debugPrint('Échec de la récupération du profil: ${userResponse['message'] ?? 'Erreur inconnue'}');
        return null;
      }
      
      final userData = userResponse['user'] ?? {};

      return UserStatsModel(
        userId: friendId,
        displayName: userData['displayName'] ?? 'Inconnu',
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
      _analyticsService.recordError(e, stack);
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
      _analyticsService.recordError(e, stack);
      return null;
    }
  }
  
  // Obtenir le classement des amis
  Future<List<UserStatsModel>> getFriendsLeaderboard() async {
    try {
      // Récupérer le classement via l'API
      final Map<String, dynamic> response = await _socialService.getLeaderboardEntries(
        leaderboardId: "friends", 
        friendsOnly: true
      ) as Map<String, dynamic>;
      
      if (response.isEmpty) {
        debugPrint('Échec de la récupération du classement des amis: réponse vide');
        return [];
      }
      
      // Vérifier le champ success dans la réponse
      if (!response.keys.contains('success')) {
        debugPrint('Échec de la récupération du classement des amis: champ success manquant');
        return [];
      }
      
      final dynamic successValue = response['success'];
      if (successValue is! bool || !successValue) {
        // Récupérer le message d'erreur s'il existe
        String message = 'Erreur inconnue';
        if (response.keys.contains('message')) {
          final dynamic msgValue = response['message'];
          if (msgValue is String) {
            message = msgValue;
          }
        }
        debugPrint('Échec de la récupération du classement des amis: $message');
        return [];
      }
      
      // Récupérer les données du classement
      if (!response.keys.contains('data')) {
        debugPrint('Échec de la récupération du classement: champ data manquant');
        return [];
      }
      
      // Utiliser un accès sûr avec cast explicite
      final dynamic entriesData = response['data'] as dynamic;
      if (entriesData == null) {
        debugPrint('Échec de la récupération du classement: aucune donnée');
        return [];
      }
      
      final List<dynamic> entries = entriesData is List ? entriesData : (entriesData['entries'] ?? []);
      final List<UserStatsModel> leaderboard = [];
      
      for (var entry in entries) {
        try {
          leaderboard.add(UserStatsModel(
            userId: entry['userId'] ?? '',
            displayName: entry['displayName'] ?? 'Inconnu',
            totalPaperclips: entry['score'] ?? 0,
            level: entry['level'] ?? 1,
            money: (entry['money'] as num?)?.toDouble() ?? 0.0,
            bestScore: entry['bestScore'] ?? 0,
            efficiency: (entry['efficiency'] as num?)?.toDouble() ?? 0.0,
            upgradesBought: entry['upgradesBought'] ?? 0,
            lastUpdated: DateTime.parse(entry['lastUpdated'] ?? DateTime.now().toIso8601String()),
          ));
        } catch (e) {
          debugPrint('Erreur lors du traitement d\'une entrée du classement: $e');
        }
      }
      
      return leaderboard;
    } catch (e, stack) {
      debugPrint('Erreur lors de la récupération du classement des amis: $e');
      _analyticsService.recordError(e, stack);
      return [];
    }
  }
  
  // Obtenir le classement global
  Future<List<UserStatsModel>> getGlobalLeaderboard() async {
    try {
      // Récupérer le classement via l'API
      final Map<String, dynamic> response = await _socialService.getLeaderboardEntries(
        leaderboardId: "global", 
        limit: 100,
        offset: 0,
        friendsOnly: false
      ) as Map<String, dynamic>;
      
      if (response.isEmpty) {
        debugPrint('Échec de la récupération du classement global: réponse vide');
        return [];
      }
      
      // Vérifier le champ success dans la réponse
      if (!response.keys.contains('success')) {
        debugPrint('Échec de la récupération du classement global: champ success manquant');
        return [];
      }
      
      final dynamic successValue = response['success'];
      if (successValue is! bool || !successValue) {
        // Récupérer le message d'erreur s'il existe
        String message = 'Erreur inconnue';
        if (response.keys.contains('message')) {
          final dynamic msgValue = response['message'];
          if (msgValue is String) {
            message = msgValue;
          }
        }
        debugPrint('Échec de la récupération du classement global: $message');
        return [];
      }
      
      // Récupérer les données du classement
      if (!response.keys.contains('data')) {
        debugPrint('Échec de la récupération du classement: champ data manquant');
        return [];
      }
      
      // Utiliser un accès sûr avec cast explicite
      final dynamic entriesData = response['data'] as dynamic;
      if (entriesData == null) {
        debugPrint('Échec de la récupération du classement: aucune donnée');
        return [];
      }
      
      final List<dynamic> entries = entriesData is List ? entriesData : (entriesData['entries'] ?? []);
      final List<UserStatsModel> leaderboard = [];
      
      for (var entry in entries) {
        try {
          leaderboard.add(UserStatsModel(
            userId: entry['userId'] ?? '',
            displayName: entry['displayName'] ?? 'Inconnu',
            totalPaperclips: entry['score'] ?? 0,
            level: entry['level'] ?? 1,
            money: (entry['money'] as num?)?.toDouble() ?? 0.0,
            bestScore: entry['bestScore'] ?? 0,
            efficiency: (entry['efficiency'] as num?)?.toDouble() ?? 0.0,
            upgradesBought: entry['upgradesBought'] ?? 0,
            lastUpdated: DateTime.parse(entry['lastUpdated'] ?? DateTime.now().toIso8601String()),
          ));
        } catch (e) {
          debugPrint('Erreur lors du traitement d\'une entrée du classement: $e');
        }
      }
      
      return leaderboard;
    } catch (e, stack) {
      debugPrint('Erreur lors de la récupération du classement global: $e');
      _analyticsService.recordError(e, stack);
      return [];
    }
  }
  
  // Obtenir les succès de l'utilisateur
  Future<List<Map<String, dynamic>>> getUserAchievements() async {
    try {
      // Récupérer les succès via l'API
      final response = await _socialService.getUserAchievements();
      
      // Traiter la réponse correctement
      if (response is! Map<String, dynamic>) {
        debugPrint('Format de réponse getUserAchievements invalide');
        return [];
      }
      
      final success = response['success'];
      if (success is bool && !success) {
        final message = response['message'];
        debugPrint('Échec de la récupération des succès: ${message is String ? message : 'Erreur inconnue'}');
        return [];
      }
      
      final dynamic achievementsData = response['data'];
      if (achievementsData == null) {
        debugPrint('Aucun succès trouvé');
        return [];
      }
      
      final List<Map<String, dynamic>> userAchievements = [];
      
      // Convertir les données en liste de Map<String, dynamic>
      if (achievementsData is List) {
        for (var achievement in achievementsData) {
          if (achievement is Map<String, dynamic>) {
            userAchievements.add(achievement);
          }
        }
      } else if (achievementsData is Map<String, dynamic>) {
        // Si c'est un seul objet, on l'ajoute directement
        userAchievements.add(achievementsData);
      }
      
      return userAchievements;
    } catch (e, stack) {
      debugPrint('Erreur lors de la récupération des succès: $e');
      _analyticsService.recordError(e, stack);
      return [];
    }
  }
}
