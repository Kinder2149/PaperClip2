import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:paperclip2/services/api/api_services.dart';
import 'package:paperclip2/services/user/user_manager.dart';
import 'package:paperclip2/services/user/user_profile.dart';
import 'package:paperclip2/services/social/friends_service.dart';
import 'package:paperclip2/services/social/user_stats_service.dart';

// Mocks manuels pour éviter les problèmes avec Mockito
class MockSocialService implements SocialService {
  final Map<String, dynamic> _responses = {};
  final List<Map<String, dynamic>> _calls = [];

  void setResponse(String method, dynamic response) {
    _responses[method] = response;
  }

  List<Map<String, dynamic>> getCalls(String method) {
    return _calls.where((call) => call['method'] == method).toList();
  }

  @override
  Future<void> initialize() async {
    _calls.add({'method': 'initialize'});
    return Future.value();
  }

  @override
  Future<Map<String, dynamic>> sendFriendRequest({required String receiverId}) async {
    _calls.add({
      'method': 'sendFriendRequest',
      'receiverId': receiverId,
    });
    return _responses['sendFriendRequest'] ?? {
      'success': true,
      'message': 'Demande envoyée'
    };
  }

  @override
  Future<Map<String, dynamic>> respondToFriendRequest(String requestId, String status) async {
    _calls.add({
      'method': 'respondToFriendRequest',
      'requestId': requestId,
      'status': status,
    });
    return _responses['respondToFriendRequest'] ?? {
      'success': true,
      'message': 'Demande traitée'
    };
  }

  @override
  Future<Map<String, dynamic>> getReceivedFriendRequests({String? userId}) async {
    _calls.add({
      'method': 'getReceivedFriendRequests',
      'userId': userId,
    });
    return _responses['getReceivedFriendRequests'] ?? {
      'success': true,
      'data': []
    };
  }

  @override
  Future<Map<String, dynamic>> getSentFriendRequests({String? userId}) async {
    _calls.add({
      'method': 'getSentFriendRequests',
      'userId': userId,
    });
    return _responses['getSentFriendRequests'] ?? {
      'success': true,
      'data': []
    };
  }

  @override
  Future<Map<String, dynamic>> getFriends({String? userId}) async {
    _calls.add({
      'method': 'getFriends',
      'userId': userId,
    });
    return _responses['getFriends'] ?? {
      'success': true,
      'data': []
    };
  }

  @override
  Future<bool> removeFriend({required String friendId}) async {
    _calls.add({
      'method': 'removeFriend',
      'friendId': friendId,
    });
    return _responses['removeFriend'] ?? true;
  }

  @override
  Future<Map<String, dynamic>> searchUsers({required String query}) async {
    _calls.add({
      'method': 'searchUsers',
      'query': query,
    });
    return _responses['searchUsers'] ?? {
      'success': true,
      'message': 'Utilisateurs trouvés',
      'data': []
    };
  }

  @override
  Future<Map<String, dynamic>> getLeaderboards() async {
    _calls.add({'method': 'getLeaderboards'});
    return _responses['getLeaderboards'] ?? {
      'success': true,
      'data': []
    };
  }

  @override
  Future<Map<String, dynamic>> getLeaderboard(String leaderboardId) async {
    _calls.add({
      'method': 'getLeaderboard',
      'leaderboardId': leaderboardId,
    });
    return _responses['getLeaderboard'] ?? {
      'success': true,
      'data': {}
    };
  }

  @override
  Future<Map<String, dynamic>> submitScore(String leaderboardId, int score) async {
    _calls.add({
      'method': 'submitScore',
      'leaderboardId': leaderboardId,
      'score': score,
    });
    return _responses['submitScore'] ?? {
      'success': true,
      'message': 'Score soumis'
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getLeaderboardEntries({
    required String leaderboardId,
    int limit = 100,
    int offset = 0,
    bool friendsOnly = false,
  }) async {
    _calls.add({
      'method': 'getLeaderboardEntries',
      'leaderboardId': leaderboardId,
      'limit': limit,
      'offset': offset,
      'friendsOnly': friendsOnly,
    });
    return _responses['getLeaderboardEntries'] ?? [];
  }

  @override
  Future<Map<String, dynamic>> getUserRank(String leaderboardId) async {
    _calls.add({
      'method': 'getUserRank',
      'leaderboardId': leaderboardId,
    });
    return _responses['getUserRank'] ?? {
      'success': true,
      'data': {'rank': 0}
    };
  }

  @override
  Future<Map<String, dynamic>> getUserProfile({required String userId}) async {
    _calls.add({
      'method': 'getUserProfile',
      'userId': userId,
    });
    return _responses['getUserProfile'] ?? {
      'success': true,
      'data': {}
    };
  }

  @override
  Future<Map<String, dynamic>> acceptFriendRequest({required String requestId}) async {
    _calls.add({
      'method': 'acceptFriendRequest',
      'requestId': requestId,
    });
    return _responses['acceptFriendRequest'] ?? {
      'success': true,
      'message': 'Demande acceptée'
    };
  }

  @override
  Future<Map<String, dynamic>> declineFriendRequest({required String requestId}) async {
    _calls.add({
      'method': 'declineFriendRequest',
      'requestId': requestId,
    });
    return _responses['declineFriendRequest'] ?? {
      'success': true,
      'message': 'Demande refusée'
    };
  }

  @override
  Future<Map<String, dynamic>> getSuggestedFriends({String? userId}) async {
    _calls.add({
      'method': 'getSuggestedFriends',
      'userId': userId,
    });
    return _responses['getSuggestedFriends'] ?? {
      'success': true,
      'data': []
    };
  }

  @override
  Future<Map<String, dynamic>> getAchievements() async {
    _calls.add({'method': 'getAchievements'});
    return _responses['getAchievements'] ?? {
      'success': true,
      'data': []
    };
  }

  @override
  Future<Map<String, dynamic>> getAchievement(String achievementId) async {
    _calls.add({
      'method': 'getAchievement',
      'achievementId': achievementId,
    });
    return _responses['getAchievement'] ?? {
      'success': true,
      'data': {}
    };
  }

  @override
  Future<Map<String, dynamic>> getUserAchievements() async {
    _calls.add({'method': 'getUserAchievements'});
    return _responses['getUserAchievements'] ?? {
      'success': true,
      'data': []
    };
  }

  @override
  Future<Map<String, dynamic>> unlockAchievement(
    String achievementId, {
    Map<String, dynamic>? progress,
  }) async {
    _calls.add({
      'method': 'unlockAchievement',
      'achievementId': achievementId,
      'progress': progress,
    });
    return _responses['unlockAchievement'] ?? {
      'success': true,
      'message': 'Succès débloqué'
    };
  }

  @override
  Future<Map<String, dynamic>> updateAchievementProgress(
    String achievementId,
    Map<String, dynamic> progress,
  ) async {
    _calls.add({
      'method': 'updateAchievementProgress',
      'achievementId': achievementId,
      'progress': progress,
    });
    return _responses['updateAchievementProgress'] ?? {
      'success': true,
      'message': 'Progression mise à jour'
    };
  }

  @override
  Future<Map<String, dynamic>> getUserStats({required String userId}) async {
    _calls.add({
      'method': 'getUserStats',
      'userId': userId,
    });
    return _responses['getUserStats'] ?? {
      'success': true,
      'data': {}
    };
  }

  @override
  Future<Map<String, dynamic>> updateUserStats({
    required String userId,
    required Map<String, dynamic> stats,
  }) async {
    _calls.add({
      'method': 'updateUserStats',
      'userId': userId,
      'stats': stats,
    });
    return _responses['updateUserStats'] ?? {
      'success': true,
      'message': 'Statistiques mises à jour'
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class MockAnalyticsService implements AnalyticsService {
  final List<Map<String, dynamic>> events = [];
  int _eventCallCount = 0;

  int get eventCallCount => _eventCallCount;

  @override
  Future<void> logEvent(String eventName, {Map<String, dynamic>? parameters, String? userId}) async {
    _eventCallCount++;
    events.add({
      'eventName': eventName,
      'parameters': parameters,
      'userId': userId
    });
  }

  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace stack, {
    String? reason,
    Map<String, dynamic>? metadata,
    String? userId,
    bool fatal = false,
  }) async {
    _eventCallCount++;
    events.add({
      'eventName': 'error',
      'exception': exception.toString(),
      'stack': stack.toString(),
      'reason': reason,
      'metadata': metadata,
      'userId': userId,
      'fatal': fatal
    });
  }

  @override
  Future<void> initialize() async {
    return Future.value();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class MockUserManager implements UserManager {
  UserProfile? _currentProfile;
  final ValueNotifier<UserProfile?> _profileNotifier = ValueNotifier<UserProfile?>(null);

  void setCurrentProfile(UserProfile profile) {
    _currentProfile = profile;
    _profileNotifier.value = profile;
  }

  @override
  ValueNotifier<UserProfile?> get currentProfileChanged => _profileNotifier;

  @override
  String? getCurrentUserId() {
    return _currentProfile?.userId;
  }

  @override
  Future<UserProfile?> getCurrentProfile() async {
    return _currentProfile;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

void main() {
  // Initialisation du binding Flutter pour éviter les erreurs
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tests des fonctionnalités sociales', () {
    late MockSocialService mockSocialService;
    late MockAnalyticsService mockAnalyticsService;
    late MockUserManager mockUserManager;
    late FriendsService friendsService;
    late UserStatsService userStatsService;

    setUp(() {
      mockSocialService = MockSocialService();
      mockAnalyticsService = MockAnalyticsService();
      mockUserManager = MockUserManager();

      // Configuration du UserManager avec un profil de test
      final testProfile = UserProfile(
        userId: 'user123',
        displayName: 'Test User',
        profileImageUrl: 'https://example.com/profile.jpg'
      );
      mockUserManager.setCurrentProfile(testProfile);

      // Initialisation des services avec les mocks
      friendsService = FriendsService(
        userId: 'user123',
        socialService: mockSocialService,
        analyticsService: mockAnalyticsService,
        userManager: mockUserManager
      );

      userStatsService = UserStatsService(
        userId: 'user123',
        socialService: mockSocialService,
        analyticsService: mockAnalyticsService,
        userManager: mockUserManager
      );
    });

    test('Recherche d\'utilisateurs', () async {
      // Configuration du mock
      final mockUsers = [
        {
          'userId': 'user1',
          'displayName': 'User One',
          'profileImageUrl': 'https://example.com/user1.jpg'
        },
        {
          'userId': 'user2',
          'displayName': 'User Two',
          'profileImageUrl': 'https://example.com/user2.jpg'
        }
      ];

      mockSocialService.setResponse('searchUsers', {
        'success': true,
        'message': 'Utilisateurs trouvés',
        'data': mockUsers
      });

      // Exécution de la recherche
      final results = await friendsService.searchUsers('user');

      // Vérifications
      expect(results.length, 2);
      expect(results[0].userId, 'user1');
      expect(results[0].displayName, 'User One');
      expect(results[1].userId, 'user2');
      expect(results[1].displayName, 'User Two');

      // Vérification de l'appel au service
      final calls = mockSocialService.getCalls('searchUsers');
      expect(calls.length, 1);
      expect(calls[0]['query'], 'user');

      // Vérification de l'analytique
      expect(mockAnalyticsService.events.length, 1);
      expect(mockAnalyticsService.events[0]['eventName'], 'search_users');
    });

    test('Envoi de demande d\'ami', () async {
      // Configuration du mock
      mockSocialService.setResponse('sendFriendRequest', {
        'success': true,
        'message': 'Demande envoyée',
        'data': {'requestId': 'req123'}
      });

      // Exécution de l'envoi de demande
      final result = await friendsService.sendFriendRequest('user456', 'User 456');

      // Vérifications
      expect(result, true);

      // Vérification de l'appel au service
      final calls = mockSocialService.getCalls('sendFriendRequest');
      expect(calls.length, 1);
      expect(calls[0]['receiverId'], 'user456');

      // Vérification de l'analytique
      expect(mockAnalyticsService.events.length, 1);
      expect(mockAnalyticsService.events[0]['eventName'], 'send_friend_request');
    });

    test('Acceptation de demande d\'ami', () async {
      // Configuration du mock
      mockSocialService.setResponse('acceptFriendRequest', {
        'success': true,
        'message': 'Demande acceptée',
        'data': {'requestId': 'req123', 'status': 'accepted'}
      });

      // Exécution de l'acceptation
      final result = await friendsService.acceptFriendRequest('req123');

      // Vérifications
      expect(result, true);

      // Vérification de l'appel au service
      final calls = mockSocialService.getCalls('acceptFriendRequest');
      expect(calls.length, 1);
      expect(calls[0]['requestId'], 'req123');

      // Vérification de l'analytique
      expect(mockAnalyticsService.events.length, 1);
      expect(mockAnalyticsService.events[0]['eventName'], 'accept_friend_request');
    });

    test('Refus de demande d\'ami', () async {
      // Configuration du mock
      mockSocialService.setResponse('declineFriendRequest', {
        'success': true,
        'message': 'Demande refusée',
        'data': {'requestId': 'req123', 'status': 'declined'}
      });

      // Exécution du refus
      final result = await friendsService.declineFriendRequest('req123');

      // Vérifications
      expect(result, true);

      // Vérification de l'appel au service
      final calls = mockSocialService.getCalls('declineFriendRequest');
      expect(calls.length, 1);
      expect(calls[0]['requestId'], 'req123');

      // Vérification de l'analytique
      expect(mockAnalyticsService.events.length, 1);
      expect(mockAnalyticsService.events[0]['eventName'], 'decline_friend_request');
    });

    test('Suppression d\'ami', () async {
      // Configuration du mock
      mockSocialService.setResponse('removeFriend', true);

      // Exécution de la suppression
      final result = await friendsService.removeFriend('user456');

      // Vérifications
      expect(result, true);

      // Vérification de l'appel au service
      final calls = mockSocialService.getCalls('removeFriend');
      expect(calls.length, 1);
      expect(calls[0]['friendId'], 'user456');

      // Vérification de l'analytique
      expect(mockAnalyticsService.events.length, 1);
      expect(mockAnalyticsService.events[0]['eventName'], 'remove_friend');
    });

    test('Récupération du classement des amis', () async {
      // Configuration du mock
      final mockEntries = [
        {
          'userId': 'user1',
          'displayName': 'User One',
          'profileImageUrl': 'https://example.com/user1.jpg',
          'score': 1500,
          'rank': 1
        },
        {
          'userId': 'user2',
          'displayName': 'User Two',
          'profileImageUrl': 'https://example.com/user2.jpg',
          'score': 1200,
          'rank': 2
        }
      ];

      mockSocialService.setResponse('getLeaderboardEntries', mockEntries);

      // Exécution de la récupération
      final results = await userStatsService.getFriendsLeaderboard();

      // Vérifications
      expect(results.length, 2);
      expect(results[0].userId, 'user1');
      expect(results[0].level, 6);
      expect(results[0].xp, 1500);
      expect(results[1].userId, 'user2');
      expect(results[1].level, 5);
      expect(results[1].xp, 1200);

      // Vérification de l'appel au service
      final calls = mockSocialService.getCalls('getLeaderboardEntries');
      expect(calls.length, 1);
      expect(calls[0]['leaderboardId'], 'friends');
      expect(calls[0]['friendsOnly'], true);

      // Vérification de l'analytique
      expect(mockAnalyticsService.events.length, 1);
      expect(mockAnalyticsService.events[0]['eventName'], 'get_friends_leaderboard');
    });

    test('Mise à jour des statistiques globales dans le profil', () async {
      // Préparation des données de test
      final newStats = {
        'score': 1500,
        'level': 6,
        'money': 5000.0,
        'bestScore': 2500,
        'efficiency': 0.85,
        'upgradesBought': 12
      };
      
      // Récupération du profil actuel
      final currentProfile = (await mockUserManager.getCurrentProfile()) as UserProfile;
      
      // On vérifie que la méthode updateGlobalStats du UserProfile fonctionne
      final updatedProfile = currentProfile.updateGlobalStats(newStats);
      
      // Vérifications
      expect(updatedProfile.globalStats['score'], 1500);
      expect(updatedProfile.globalStats['level'], 6);
      expect(updatedProfile.globalStats['money'], 5000.0);
      
      // Mise à jour du mock UserManager
      mockUserManager.setCurrentProfile(updatedProfile);
      
      // Vérification du profil mis à jour
      expect(mockUserManager.getCurrentUserId(), 'user123');
      expect((await mockUserManager.getCurrentProfile())?.globalStats['level'], 6);
    });
  });
}
