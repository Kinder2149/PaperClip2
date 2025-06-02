import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter/foundation.dart';
import 'package:paperclip2/services/api/api_services.dart';
import 'package:paperclip2/services/user/user_manager.dart';
import 'package:paperclip2/services/user/user_profile.dart';
import 'package:paperclip2/services/social/friends_service.dart';
import 'package:paperclip2/services/social/user_stats_service.dart';

// Classes de mock pour les tests
class MockSocialService extends Mock implements SocialService {
  final Map<String, dynamic> _responses = {};
  final List<Map<String, dynamic>> _calls = [];

  void setResponse(String method, Map<String, dynamic> response) {
    _responses[method] = response;
  }

  List<Map<String, dynamic>> getCalls(String method) {
    return _calls.where((call) => call['method'] == method).toList();
  }

  @override
  Future<dynamic> searchUsers({required String query}) async {
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
  Future<dynamic> getFriendsList({required String userId}) async {
    _calls.add({
      'method': 'getFriendsList',
      'userId': userId,
    });
    return _responses['getFriendsList'] ?? {
      'success': true,
      'message': 'Liste d\'amis récupérée',
      'data': []
    };
  }

  @override
  Future<dynamic> sendFriendRequest({
    required String fromUserId,
    required String toUserId,
  }) async {
    _calls.add({
      'method': 'sendFriendRequest',
      'fromUserId': fromUserId,
      'toUserId': toUserId,
    });
    return _responses['sendFriendRequest'] ?? {
      'success': true,
      'message': 'Demande d\'ami envoyée',
      'data': {'requestId': 'req123'}
    };
  }

  @override
  Future<dynamic> acceptFriendRequest({
    required String requestId,
    required String userId,
  }) async {
    _calls.add({
      'method': 'acceptFriendRequest',
      'requestId': requestId,
      'userId': userId,
    });
    return _responses['acceptFriendRequest'] ?? {
      'success': true,
      'message': 'Demande d\'ami acceptée',
      'data': {'status': 'accepted'}
    };
  }

  @override
  Future<dynamic> removeFriend({
    required String userId,
    required String friendId,
  }) async {
    _calls.add({
      'method': 'removeFriend',
      'userId': userId,
      'friendId': friendId,
    });
    return _responses['removeFriend'] ?? {
      'success': true,
      'message': 'Ami supprimé',
      'data': {'status': 'removed'}
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getLeaderboardEntries({
    required String leaderboardId,
    bool? friendsOnly,
    int? limit,
    int? offset,
  }) async {
    _calls.add({
      'method': 'getLeaderboardEntries',
      'leaderboardId': leaderboardId,
      'friendsOnly': friendsOnly,
      'limit': limit,
      'offset': offset,
    });
    return _responses['getLeaderboardEntries'] ?? {
      'success': true,
      'message': 'Classement récupéré',
      'data': []
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
      'message': 'Statistiques mises à jour',
      'data': stats
    };
  }
}

class MockAnalyticsService extends Mock implements AnalyticsService {
  final List<Map<String, dynamic>> events = [];
  final List<Map<String, dynamic>> errors = [];

  @override
  Future<void> logEvent(String eventName, {Map<String, dynamic>? parameters, String? userId}) async {
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
    errors.add({
      'error': exception,
      'stackTrace': stack,
      'reason': reason,
      'metadata': metadata,
      'userId': userId,
      'fatal': fatal
    });
  }
}

class MockUserManager extends Mock implements UserManager {
  ValueNotifier<UserProfile?> profileChanged = ValueNotifier(null);
  UserProfile? _currentProfile;

  void setCurrentProfile(UserProfile profile) {
    _currentProfile = profile;
    profileChanged.value = profile;
  }

  @override
  ValueNotifier<UserProfile?> get currentProfileChanged => profileChanged;

  @override
  Future<UserProfile?> getCurrentProfile() async {
    return _currentProfile;
  }

  @override
  String? getCurrentUserId() {
    return _currentProfile?.userId;
  }
}

void main() {
  // Initialisation du binding Flutter pour éviter les erreurs
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Social Features Tests', () {
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
      when(mockUserManager.getCurrentUserId()).thenReturn('user123');
      
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
      // Préparation des données de test
      final mockUsers = [
        {
          'userId': 'user1',
          'displayName': 'User One',
          'email': 'user1@example.com',
          'profileImageUrl': 'https://example.com/user1.jpg'
        },
        {
          'userId': 'user2',
          'displayName': 'User Two',
          'email': 'user2@example.com',
          'profileImageUrl': 'https://example.com/user2.jpg'
        }
      ];

      // Configuration du mock
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

    test('Envoi d\'une demande d\'ami', () async {
      // Configuration du mock
      mockSocialService.setResponse('sendFriendRequest', {
        'success': true,
        'message': 'Demande d\'ami envoyée',
        'data': {'requestId': 'req123'}
      });

      // Exécution de l'envoi de demande
      final result = await friendsService.sendFriendRequest('user456', 'User 456');

      // Vérifications
      expect(result, isTrue);

      // Vérification de l'appel au service
      final calls = mockSocialService.getCalls('sendFriendRequest');
      expect(calls.length, 1);
      expect(calls[0]['fromUserId'], 'user123');
      expect(calls[0]['toUserId'], 'user456');

      // Vérification de l'analytique
      expect(mockAnalyticsService.events.length, 1);
      expect(mockAnalyticsService.events[0]['eventName'], 'friend_request_sent');
    });

    test('Acceptation d\'une demande d\'ami', () async {
      // Configuration du mock
      mockSocialService.setResponse('acceptFriendRequest', {
        'success': true,
        'message': 'Demande d\'ami acceptée',
        'data': {'status': 'accepted'}
      });

      // Exécution de l'acceptation
      final result = await friendsService.acceptFriendRequest('req123');

      // Vérifications
      expect(result, isTrue);

      // Vérification de l'appel au service
      final calls = mockSocialService.getCalls('acceptFriendRequest');
      expect(calls.length, 1);
      expect(calls[0]['requestId'], 'req123');
      expect(calls[0]['userId'], 'user123');

      // Vérification de l'analytique
      expect(mockAnalyticsService.events.length, 1);
      expect(mockAnalyticsService.events[0]['eventName'], 'friend_request_accepted');
    });

    test('Suppression d\'un ami', () async {
      // Configuration du mock
      mockSocialService.setResponse('removeFriend', {
        'success': true,
        'message': 'Ami supprimé',
        'data': {'status': 'removed'}
      });

      // Exécution de la suppression
      final result = await friendsService.removeFriend('user456');

      // Vérifications
      expect(result, isTrue);

      // Vérification de l'appel au service
      final calls = mockSocialService.getCalls('removeFriend');
      expect(calls.length, 1);
      expect(calls[0]['userId'], 'user123');
      expect(calls[0]['friendId'], 'user456');

      // Vérification de l'analytique
      expect(mockAnalyticsService.events.length, 1);
      expect(mockAnalyticsService.events[0]['eventName'], 'friend_removed');
    });

    test('Récupération du classement des amis', () async {
      // Préparation des données de test
      final mockLeaderboard = [
        {
          'userId': 'user456',
          'displayName': 'Friend One',
          'score': 1500,
          'level': 6,
          'money': 5000.0,
          'bestScore': 2500,
          'efficiency': 0.85,
          'upgradesBought': 12,
          'lastUpdated': '2025-06-01T12:00:00Z'
        },
        {
          'userId': 'user123',
          'displayName': 'Test User',
          'score': 1200,
          'level': 5,
          'money': 3500.0,
          'bestScore': 2000,
          'efficiency': 0.75,
          'upgradesBought': 10,
          'lastUpdated': '2025-06-01T11:00:00Z'
        }
      ];

      // Configuration du mock
      mockSocialService.setResponse('getLeaderboardEntries', {
        'success': true,
        'message': 'Classement récupéré',
        'data': mockLeaderboard
      });

      // Exécution de la récupération
      final leaderboard = await userStatsService.getFriendsLeaderboard();

      // Vérifications
      expect(leaderboard.length, 2);
      expect(leaderboard[0].userId, 'user456');
      expect(leaderboard[0].displayName, 'Friend One');
      expect(leaderboard[0].totalPaperclips, 1500);
      expect(leaderboard[0].level, 6);
      expect(leaderboard[1].userId, 'user123');
      expect(leaderboard[1].displayName, 'Test User');

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
  });
}
