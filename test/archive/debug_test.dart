import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:paperclip2/services/api/api_services.dart';
import 'package:paperclip2/services/social/user_stats_service.dart';
import 'package:paperclip2/models/social/user_stats_model.dart';
import 'package:paperclip2/services/user/user_manager.dart';
import 'package:paperclip2/models/user_profile.dart';

// Mock pour SocialService
class MockSocialService implements SocialService {
  final Map<String, dynamic> _responses = {};

  void setResponse(String method, dynamic response) {
    _responses[method] = response;
  }

  @override
  Future<List<Map<String, dynamic>>> getLeaderboardEntries({
    required String leaderboardId,
    int limit = 100,
    int offset = 0,
    bool friendsOnly = false,
  }) async {
    if (_responses.containsKey('getLeaderboardEntries')) {
      final response = _responses['getLeaderboardEntries'];
      if (response is Map<String, dynamic> && response.containsKey('data')) {
        final List entries = response['data'] as List;
        return entries.map((entry) => entry as Map<String, dynamic>).toList();
      }
    }
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

// Mock pour AnalyticsService
class MockAnalyticsService implements AnalyticsService {
  @override
  Future<void> logEvent(String eventName, {Map<String, dynamic>? parameters, String? userId}) async {}

  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace stack, {
    String? reason,
    Map<String, dynamic>? metadata,
    String? userId,
    bool fatal = false,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

// Mock pour UserManager
class MockUserManager implements UserManager {
  final String? _userId;
  final ValueNotifier<UserProfile?> profileChanged = ValueNotifier<UserProfile?>(null);
  
  MockUserManager({String? userId}) : _userId = userId {
    if (_userId != null) {
      profileChanged.value = UserProfile(
        userId: _userId!, 
        displayName: 'Test User', 
        email: 'test@example.com',
      );
    }
  }
  
  @override
  String? getCurrentUserId() {
    return _userId;
  }
  
  @override
  UserProfile? getCurrentUserProfile() {
    return profileChanged.value;
  }
  
  @override
  bool get isLoggedIn => _userId != null;
  
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Test de UserStatsService', () {
    late MockSocialService mockSocialService;
    late MockAnalyticsService mockAnalyticsService;
    late MockUserManager mockUserManager;
    late UserStatsService userStatsService;
    
    setUp(() {
      mockSocialService = MockSocialService();
      mockAnalyticsService = MockAnalyticsService();
      mockUserManager = MockUserManager(userId: 'user123');
      
      userStatsService = UserStatsService(
        userId: 'user123',
        socialService: mockSocialService,
        analyticsService: mockAnalyticsService,
        userManager: mockUserManager,
      );
    });
    
    test('Récupération du classement des amis', () async {
      // Configuration du mock pour le classement
      final leaderboardData = [
        {
          'userId': 'friend1',
          'displayName': 'Friend One',
          'profileImageUrl': 'https://example.com/friend1.jpg',
          'level': 6,
          'totalPaperclips': 1500,
          'money': 7500.0,
          'bestScore': 3500,
          'efficiency': 0.90,
          'upgradesBought': 15,
          'lastUpdated': '2025-06-01T15:30:00Z'
        },
        {
          'userId': 'user123',
          'displayName': 'Test User',
          'profileImageUrl': 'https://example.com/profile.jpg',
          'level': 5,
          'totalPaperclips': 1000,
          'money': 5000.0,
          'bestScore': 2500,
          'efficiency': 0.85,
          'upgradesBought': 10,
          'lastUpdated': '2025-06-01T15:30:00Z'
        }
      ];
      
      // Format de réponse correcte pour SocialService.getLeaderboardEntries
      mockSocialService.setResponse('getLeaderboardEntries', {
        'success': true,
        'data': leaderboardData
      });
      
      // Appel de la méthode à tester
      final leaderboard = await userStatsService.getFriendsLeaderboard();
      
      // Vérifications
      expect(leaderboard.length, 2);
      expect(leaderboard[0].userId, 'friend1');
      expect(leaderboard[0].totalPaperclips, 1500);
      expect(leaderboard[1].userId, 'user123');
      expect(leaderboard[1].totalPaperclips, 1000);
    });
  });
}
