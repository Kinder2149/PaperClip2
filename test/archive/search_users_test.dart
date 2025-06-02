import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter/foundation.dart';
import 'package:paperclip2/services/api/api_services.dart';
import 'package:paperclip2/services/user/user_manager.dart';
import 'package:paperclip2/services/user/user_profile.dart';
import 'package:paperclip2/services/social/friends_service.dart';

// Mocks
class MockSocialService extends Mock implements SocialService {
  final Map<String, dynamic> _responses = {};
  final List<Map<String, dynamic>> _calls = [];

  void setResponse(String method, dynamic response) {
    _responses[method] = response;
  }

  List<Map<String, dynamic>> getCalls(String method) {
    return _calls.where((call) => call['method'] == method).toList();
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
}

class MockAnalyticsService extends Mock implements AnalyticsService {
  final List<Map<String, dynamic>> events = [];

  @override
  Future<void> logEvent(String eventName, {Map<String, dynamic>? parameters, String? userId}) async {
    events.add({
      'eventName': eventName,
      'parameters': parameters,
      'userId': userId
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
  String? getCurrentUserId() {
    return _currentProfile?.userId;
  }
}

void main() {
  group('Recherche d\'utilisateurs', () {
    late MockSocialService mockSocialService;
    late MockAnalyticsService mockAnalyticsService;
    late MockUserManager mockUserManager;
    late FriendsService friendsService;

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
    });

    test('Recherche d\'utilisateurs', () async {
      // Préparation des données de test
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
  });
}
