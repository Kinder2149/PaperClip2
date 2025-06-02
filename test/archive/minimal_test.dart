import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:paperclip2/services/user/user_profile.dart';
import 'package:mockito/mockito.dart';
import 'package:paperclip2/services/api/api_services.dart';
import 'package:paperclip2/services/user/user_manager.dart';
import 'package:paperclip2/services/social/friends_service.dart';

// Classes de mock manuelles qui évitent les problèmes de Mockito avec les signatures nullsafe
class ManualMockSocialService implements SocialService {
  final Map<String, dynamic> _responses = {};
  final List<Map<String, dynamic>> _calls = [];

  void setResponse(String method, dynamic response) {
    _responses[method] = response;
  }

  List<Map<String, dynamic>> getCalls(String method) {
    return _calls.where((call) => call['method'] == method).toList();
  }

  // Implémentation des méthodes nécessaires
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
  
  // Implémentations des autres méthodes requises
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class ManualMockAnalyticsService implements AnalyticsService {
  final List<Map<String, dynamic>> events = [];

  @override
  Future<void> logEvent(String eventName, {Map<String, dynamic>? parameters, String? userId}) async {
    events.add({
      'eventName': eventName,
      'parameters': parameters,
      'userId': userId
    });
  }
  
  @override
  Future<void> recordError(dynamic exception, StackTrace? stack, {Map<String, dynamic>? metadata, bool fatal = false}) async {
    // Implémentation simplifiée
    return;
  }
  
  // Implémentations des autres méthodes requises
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class ManualMockUserManager implements UserManager {
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
  
  // Implémentations des autres méthodes requises
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

void main() {
  // Initialisation du binding Flutter pour éviter les erreurs
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Tests de base', () {
    test('Test de création de UserProfile', () {
      final profile = UserProfile(
        userId: 'test123',
        displayName: 'Test User',
        profileImageUrl: 'https://example.com/profile.jpg'
      );
      
      expect(profile.userId, equals('test123'));
      expect(profile.displayName, equals('Test User'));
      expect(profile.profileImageUrl, equals('https://example.com/profile.jpg'));
    });
    
    test('Test de mise à jour des statistiques', () {
      final profile = UserProfile(
        userId: 'test123',
        displayName: 'Test User',
        profileImageUrl: 'https://example.com/profile.jpg'
      );
      
      final updated = profile.updateGlobalStats({
        'score': 100,
        'level': 5
      });
      
      expect(updated.globalStats['score'], equals(100));
      expect(updated.globalStats['level'], equals(5));
    });
  });
  
  group('Tests avec mocks manuels', () {
    late ManualMockSocialService mockSocialService;
    late ManualMockAnalyticsService mockAnalyticsService;
    late ManualMockUserManager mockUserManager;
    late FriendsService friendsService;

    setUp(() {
      mockSocialService = ManualMockSocialService();
      mockAnalyticsService = ManualMockAnalyticsService();
      mockUserManager = ManualMockUserManager();

      // Configuration du UserManager avec un profil de test
      final testProfile = UserProfile(
        userId: 'user123',
        displayName: 'Test User',
        profileImageUrl: 'https://example.com/profile.jpg'
      );
      mockUserManager.setCurrentProfile(testProfile);

      // Initialisation du service avec les mocks
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
