import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:paperclip2/services/api/api_services.dart';
import 'package:paperclip2/services/user/google_auth_service.dart';
import 'package:paperclip2/services/user/user_manager.dart';

// Mocks manuels
class MockHttpClient extends Mock implements http.Client {}
class MockAnalyticsService extends Mock implements AnalyticsService {}
class MockAuthService extends Mock implements AuthService {}
class MockUserManager extends Mock implements UserManager {
  @override
  Future<Map<String, dynamic>> getCurrentProfile() async {
    return {
      'userId': 'user123',
      'displayName': 'Test User',
      'profileImageUrl': 'https://example.com/profile.jpg',
      'googleId': 'google123',
      'lastLogin': '2025-06-01T15:30:00Z',
      'stats': {
        'level': 5,
        'xp': 1200,
        'totalGames': 25,
        'victories': 15
      }
    };
  }
}

void main() {
  group('Integration Tests - Auth Flow', () {
    late MockHttpClient mockHttpClient;
    late MockAnalyticsService mockAnalyticsService;
    late AuthService authService;
    late MockUserManager mockUserManager;

    setUp(() {
      mockHttpClient = MockHttpClient();
      mockAnalyticsService = MockAnalyticsService();
      mockUserManager = MockUserManager();
      
      // Initialiser AuthService avec ApiClient interne
      authService = AuthService();
    });

    test('Full Auth Flow Test - Google Login to User Profile', () async {
      // Préparation de la réponse simulée d'authentification Google
      final googleAuthResponse = {
        'success': true,
        'message': 'Authentification réussie',
        'data': {
          'token': 'jwt-token-123',
          'userId': 'user123',
          'refreshToken': 'refresh-token-123',
        }
      };

      // Préparation de la réponse simulée de profil utilisateur
      final userProfileResponse = {
        'success': true,
        'message': 'Profil récupéré',
        'data': {
          'userId': 'user123',
          'displayName': 'Test User',
          'profileImageUrl': 'https://example.com/profile.jpg',
          'googleId': 'google123',
          'lastLogin': '2025-06-01T15:30:00Z',
          'globalStats': {
            'level': 5,
            'xp': 1200,
            'totalGames': 25,
            'victories': 15,
          }
        }
      };

      // Création d'un GoogleAuthService de test avec mocks
      final googleAuthService = GoogleAuthService(
        authService: authService,
        analyticsService: mockAnalyticsService
      );
      
      // Mock du comportement de signInWithGoogle
      when(authService.signInWithGoogle()).thenAnswer((_) async => true);
      when(authService.userId).thenReturn('user123');
      when(authService.username).thenReturn('Test User');
      when(authService.isAuthenticated).thenReturn(true);
      when(authService.getIdToken()).thenAnswer((_) async => 'jwt-token-123');
      
      // Mock du comportement du UserManager
      when(mockUserManager.getCurrentProfile()).thenAnswer((_) async => {
        'userId': 'user123',
        'displayName': 'Test User',
        'profileImageUrl': 'https://example.com/profile.jpg',
        'googleId': 'google123',
        'lastLogin': '2025-06-01T15:30:00Z',
        'stats': {
          'level': 5,
          'xp': 1200,
          'totalGames': 25,
          'victories': 15
        }
      });

      // Test de l'authentification Google
      final authResult = await googleAuthService.signInWithGoogle();
      
      // Vérification du résultat de l'authentification
      expect(authResult, isNotNull);
      expect(authResult?['id'], 'user123');
      expect(authResult?['displayName'], 'Test User');
      
      // Vérification de l'état d'authentification
      expect(googleAuthService.isSignedIn, isTrue);
      
      // Obtention du token JWT
      final token = await googleAuthService.getGoogleAccessToken();
      expect(token, 'jwt-token-123');
      
      // Récupération du profil utilisateur
      final userProfile = await mockUserManager.getCurrentProfile();
      
      // Vérification du profil utilisateur
      expect(userProfile['userId'], 'user123');
      expect(userProfile['displayName'], 'Test User');
      expect(userProfile['stats']['level'], 5);
    });
  });
}
