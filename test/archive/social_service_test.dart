import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:paperclip2/services/social/friends_service.dart';
import 'package:paperclip2/services/social/user_stats_service.dart';
import 'package:paperclip2/services/user/user_profile.dart';
import 'package:paperclip2/services/user/user_manager.dart';

// Mocks simples sans Mockito
class MockHttpClient implements http.Client {
  final Map<Uri, http.Response> responses = {};
  List<Map<String, dynamic>> calls = [];
  
  void addResponse(Uri uri, http.Response response) {
    responses[uri] = response;
  }
  
  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    calls.add({
      'url': url.toString(),
      'headers': headers,
    });
    
    if (responses.containsKey(url)) {
      return responses[url]!;
    }
    // Fallback pour toutes les URLs non spécifiées
    return http.Response('{"success":false,"message":"Mock response not set"}', 404);
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockSocialService {
  final Map<String, dynamic> responses = {};
  List<Map<String, dynamic>> calls = [];
  
  void addResponse(String method, dynamic response) {
    responses[method] = response;
  }
  
  void recordCall(String method, Map<String, dynamic> params) {
    calls.add({
      'method': method,
      'params': params,
    });
  }
  
  Future<dynamic> searchUsers({required String query}) async {
    recordCall('searchUsers', {'query': query});
    return responses['searchUsers'] ?? {'success': false, 'message': 'Mock not set'};
  }
  
  Future<dynamic> sendFriendRequest({required String fromUserId, required String toUserId}) async {
    recordCall('sendFriendRequest', {'fromUserId': fromUserId, 'toUserId': toUserId});
    return responses['sendFriendRequest'] ?? {'success': false, 'message': 'Mock not set'};
  }
  
  Future<dynamic> acceptFriendRequest({required String userId, required String requestId}) async {
    recordCall('acceptFriendRequest', {'userId': userId, 'requestId': requestId});
    return responses['acceptFriendRequest'] ?? {'success': false, 'message': 'Mock not set'};
  }
  
  Future<dynamic> declineFriendRequest({required String userId, required String requestId}) async {
    recordCall('declineFriendRequest', {'userId': userId, 'requestId': requestId});
    return responses['declineFriendRequest'] ?? {'success': false, 'message': 'Mock not set'};
  }
  
  Future<dynamic> removeFriend({required String userId, required String friendId}) async {
    recordCall('removeFriend', {'userId': userId, 'friendId': friendId});
    return responses['removeFriend'] ?? {'success': false, 'message': 'Mock not set'};
  }
  
  // Méthodes supplémentaires pour UserStatsService
  Future<dynamic> getLeaderboardEntries({required String leaderboardId, bool? friendsOnly}) async {
    recordCall('getLeaderboardEntries', {'leaderboardId': leaderboardId, 'friendsOnly': friendsOnly});
    return responses['getLeaderboardEntries'] ?? {'success': false, 'message': 'Mock not set'};
  }
  
  Future<dynamic> updateUserStats({required String userId, required Map<String, dynamic> stats}) async {
    recordCall('updateUserStats', {'userId': userId, 'stats': stats});
    return responses['updateUserStats'] ?? {'success': false, 'message': 'Mock not set'};
  }
  
  Future<dynamic> getUserStats({required String userId}) async {
    recordCall('getUserStats', {'userId': userId});
    return responses['getUserStats'] ?? {'success': false, 'message': 'Mock not set'};
  }
  
  Future<dynamic> getUserProfile({required String userId}) async {
    recordCall('getUserProfile', {'userId': userId});
    return responses['getUserProfile'] ?? {'success': false, 'message': 'Mock not set'};
  }
  
  Future<dynamic> getUserAchievements() async {
    recordCall('getUserAchievements', {});
    return responses['getUserAchievements'] ?? {'success': false, 'message': 'Mock not set'};
  }
}

class MockAnalyticsService {
  List<Map<String, dynamic>> errors = [];
  List<Map<String, dynamic>> events = [];
  
  void logEvent({required String eventName, Map<String, dynamic>? parameters}) {
    events.add({
      'eventName': eventName,
      'parameters': parameters,
    });
  }
  
  void recordError(dynamic error, StackTrace? stackTrace) {
    errors.add({
      'error': error,
      'stackTrace': stackTrace,
    });
  }
}

// Classe pour mocker UserManager
class MockUserManager extends UserManager {
  ValueNotifier<UserProfile?> _profileNotifier = ValueNotifier<UserProfile?>(null);
  UserProfile? _profile;
  
  MockUserManager() : super(googleAuthService: null, analyticsService: null, apiService: null);
  
  @override
  ValueNotifier<UserProfile?> get profileChanged => _profileNotifier;
  
  @override
  UserProfile? get currentProfile => _profile;
  
  void setCurrentProfile(UserProfile profile) {
    _profile = profile;
    _profileNotifier.value = profile;
  }
}

void main() {
  group('FriendsService Tests', () {
    late MockSocialService mockSocialService;
    late MockAnalyticsService mockAnalyticsService;
    late FriendsService friendsService;
    
    setUp(() {
      mockSocialService = MockSocialService();
      mockAnalyticsService = MockAnalyticsService();
      
      // Configuration du service à tester
      friendsService = FriendsService(
        userId: 'user123',
        socialService: mockSocialService,
        analyticsService: mockAnalyticsService,
      );
    });

    test('acceptFriendRequest - devrait gérer correctement les réponses API', () async {
      // Arrange - Configure la réponse simulée du service social
      mockSocialService.addResponse('acceptFriendRequest', {
        'success': true,
        'message': 'Demande acceptée avec succès',
        'data': {
          'friendId': 'friendship123',
        }
      });

      // Act - Exécute la méthode à tester
      final result = await friendsService.acceptFriendRequest('request123');

      // Assert - Vérifie que le résultat est celui attendu
      expect(result, isTrue);
      expect(mockSocialService.calls.any((call) => 
        call['method'] == 'acceptFriendRequest' && 
        call['params']['userId'] == 'user123' && 
        call['params']['requestId'] == 'request123'), isTrue);
    });

    test('acceptFriendRequest - devrait gérer les erreurs API', () async {
      // Arrange - Configure une réponse d'erreur
      mockSocialService.addResponse('acceptFriendRequest', {
        'success': false,
        'message': 'Erreur lors de l\'acceptation de la demande',
      });

      // Act - Exécute la méthode à tester
      final result = await friendsService.acceptFriendRequest('request123');

      // Assert - Vérifie que le résultat est celui attendu
      expect(result, isFalse);
      expect(mockAnalyticsService.errors.isNotEmpty, isTrue);
    });

    test('removeFriend - devrait gérer correctement les réponses API', () async {
      // Arrange
      mockSocialService.addResponse('removeFriend', {
        'success': true,
        'message': 'Ami supprimé avec succès',
      });

      // Act
      final result = await friendsService.removeFriend('friend123');

      // Assert
      expect(result, isTrue);
      expect(mockSocialService.calls.any((call) => 
        call['method'] == 'removeFriend' && 
        call['params']['userId'] == 'user123' && 
        call['params']['friendId'] == 'friend123'), isTrue);
    });

    test('removeFriend - devrait gérer les erreurs API', () async {
      // Arrange
      mockSocialService.addResponse('removeFriend', {
        'success': false,
        'message': 'Erreur lors de la suppression de l\'ami',
      });

      // Act
      final result = await friendsService.removeFriend('friend123');

      // Assert
      expect(result, isFalse);
      expect(mockAnalyticsService.errors.isNotEmpty, isTrue);
    });
  });

  group('UserStatsService Tests', () {
    late MockSocialService mockSocialService;
    late MockAnalyticsService mockAnalyticsService;
    late MockUserManager mockUserManager;
    late UserStatsService userStatsService;
    
    setUp(() {
      mockSocialService = MockSocialService();
      mockAnalyticsService = MockAnalyticsService();
      mockUserManager = MockUserManager();
      
      userStatsService = UserStatsService(
        socialService: mockSocialService,
        analyticsService: mockAnalyticsService,
        userManager: mockUserManager,
        userId: 'user123',
      );
    });

    test('getFriendsLeaderboard - devrait parser correctement les réponses API', () async {
      // Arrange - Configurer la réponse simulée
      mockSocialService.addResponse('getLeaderboardEntries', {
        'success': true,
        'message': 'Leaderboard récupéré avec succès',
        'data': [
          {
            'userId': 'user123',
            'displayName': 'User One',
            'profileImageUrl': 'https://example.com/user1.jpg',
            'level': 5,
            'score': 1200,  // totalPaperclips dans le modèle
            'money': 5000.0,
            'bestScore': 1500,
            'efficiency': 2.5,
            'upgradesBought': 12,
            'lastUpdated': DateTime.now().toIso8601String(),
          },
          {
            'userId': 'friend456',
            'displayName': 'Friend Two',
            'profileImageUrl': 'https://example.com/friend2.jpg',
            'level': 4,
            'score': 900,
            'money': 3000.0,
            'bestScore': 1000,
            'efficiency': 2.0,
            'upgradesBought': 8,
            'lastUpdated': DateTime.now().toIso8601String(),
          }
        ]
      });

      // Act - Appeler la méthode à tester
      final leaderboard = await userStatsService.getFriendsLeaderboard();

      // Assert - Vérifier les résultats
      expect(leaderboard.length, 2);
      expect(leaderboard[0].userId, 'user123');
      expect(leaderboard[0].level, 5);
      expect(leaderboard[1].userId, 'friend456');
      expect(leaderboard[1].level, 4);
      
      // Vérifier que la méthode a été appelée avec les bons paramètres
      expect(mockSocialService.calls.any((call) =>
        call['method'] == 'getLeaderboardEntries' &&
        call['params']['leaderboardId'] == 'friends' &&
        call['params']['friendsOnly'] == true
      ), isTrue);
    });

    test('getFriendsLeaderboard - devrait gérer les erreurs API', () async {
      // Arrange - Configurer une réponse d'erreur
      mockSocialService.addResponse('getLeaderboardEntries', {
        'success': false,
        'message': 'Échec de récupération du leaderboard',
        'data': null
      });

      // Act - Appeler la méthode à tester
      final leaderboard = await userStatsService.getFriendsLeaderboard();

      // Assert - Vérifier les résultats
      expect(leaderboard, isEmpty);
      expect(mockAnalyticsService.errors.isEmpty, isTrue); // Note: l'erreur est seulement loguée, pas enregistrée
    });
  });
}
