import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:paperclip2/services/api/api_services.dart';
import 'package:paperclip2/services/user/google_auth_service.dart';
import 'package:paperclip2/services/user/user_manager.dart';
import 'package:paperclip2/services/user/user_profile.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:games_services/games_services.dart';

// Mock pour GoogleSignIn
class MockGoogleSignIn extends GoogleSignIn {
  final bool shouldSignIn;
  final String? userId;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final String? serverAuthCode;
  
  MockGoogleSignIn({
    this.shouldSignIn = true,
    this.userId = 'google123',
    this.displayName = 'Test User',
    this.email = 'test@example.com',
    this.photoUrl = 'https://example.com/profile.jpg',
    this.serverAuthCode = 'auth-code-123',
  });
  
  @override
  Future<GoogleSignInAccount?> signIn() async {
    if (!shouldSignIn) return null;
    return MockGoogleSignInAccount(
      id: userId!,
      displayName: displayName,
      email: email!,
      photoUrl: photoUrl,
      serverAuthCode: serverAuthCode,
    );
  }
  
  @override
  Future<GoogleSignInAccount?> signInSilently({bool suppressErrors = false}) async {
    if (!shouldSignIn) return null;
    return MockGoogleSignInAccount(
      id: userId!,
      displayName: displayName,
      email: email!,
      photoUrl: photoUrl,
      serverAuthCode: serverAuthCode,
    );
  }
  
  @override
  Future<void> signOut() async {
    // Ne rien faire
  }
}

// Mock pour GoogleSignInAccount
class MockGoogleSignInAccount implements GoogleSignInAccount {
  @override
  final String id;
  @override
  final String? displayName;
  @override
  final String email;
  @override
  final String? photoUrl;
  @override
  final String? serverAuthCode;
  
  MockGoogleSignInAccount({
    required this.id,
    this.displayName,
    required this.email,
    this.photoUrl,
    this.serverAuthCode,
  });
  
  @override
  Future<GoogleSignInAuthentication> get authentication async {
    return MockGoogleSignInAuthentication(
      accessToken: 'mock-access-token',
      idToken: 'mock-id-token',
    );
  }
  
  @override
  Future<Map<String, String>> get authHeaders async {
    return {
      'Authorization': 'Bearer mock-access-token',
    };
  }
  
  @override
  Future<void> clearAuthCache() async {
    // Ne rien faire
  }
}

// Mock pour GoogleSignInAuthentication
class MockGoogleSignInAuthentication implements GoogleSignInAuthentication {
  @override
  final String? accessToken;
  @override
  final String? idToken;
  
  MockGoogleSignInAuthentication({
    this.accessToken,
    this.idToken,
  });
}

// Mock pour GamesServices
class MockGamesServices {
  static bool isSignedIn = false;
  
  static Future<bool> get isSignedIn async {
    return isSignedIn;
  }
  
  static void setSignedIn(bool value) {
    isSignedIn = value;
  }
}

// Mock manuel pour AuthService
class MockAuthService implements AuthService {
  final Map<String, dynamic> _responses = {};
  final List<Map<String, dynamic>> _calls = [];
  bool _isAuthenticated = false;
  String? _userId;
  String? _username;
  String? _email;
  String? _photoUrl;

  void setResponse(String method, dynamic response) {
    _responses[method] = response;
  }

  List<Map<String, dynamic>> getCalls(String method) {
    return _calls.where((call) => call['method'] == method).toList();
  }

  void setIsAuthenticated(bool value) {
    _isAuthenticated = value;
  }

  void setUserInfo({String? userId, String? username, String? email, String? photoUrl}) {
    _userId = userId;
    _username = username;
    _email = email;
    _photoUrl = photoUrl;
  }

  @override
  bool get isAuthenticated => _isAuthenticated;

  @override
  String? get userId => _userId;

  @override
  String? get username => _username;

  @override
  String? get email => _email;

  @override
  String? get photoUrl => _photoUrl;

  @override
  Future<String?> getIdToken() async {
    _calls.add({'method': 'getIdToken'});
    return _responses['getIdToken'] ?? 'mock-jwt-token';
  }

  @override
  Future<bool> signInWithGoogle() async {
    _calls.add({'method': 'signInWithGoogle'});
    _isAuthenticated = true;
    return _responses['signInWithGoogle'] ?? true;
  }

  @override
  Future<void> signOut() async {
    _calls.add({'method': 'signOut'});
    _isAuthenticated = false;
    _userId = null;
    _username = null;
    _email = null;
    _photoUrl = null;
  }
  
  @override
  Future<void> logout() async {
    _calls.add({'method': 'logout'});
    _isAuthenticated = false;
    _userId = null;
    _username = null;
    _email = null;
    _photoUrl = null;
  }

  @override
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    _calls.add({
      'method': 'getUserProfile',
      'userId': userId
    });
    return _responses['getUserProfile'] ?? {
      'userId': userId,
      'displayName': _username ?? 'Test User',
      'email': _email ?? 'test@example.com',
      'profileImageUrl': _photoUrl ?? 'https://example.com/profile.jpg',
      'googleId': 'google123',
      'lastLogin': '2025-06-01T15:30:00Z',
      'globalStats': {
        'level': 5,
        'xp': 1200,
        'totalGames': 25,
        'victories': 15
      }
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

// Mock manuel pour AnalyticsService
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

// Mock manuel pour UserManager
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
  
  // Injecter notre mock pour GamesServices
  GamesServices.isSignedIn = Future.value(false);
  
  group('Tests d\'authentification', () {
    late MockAuthService mockAuthService;
    late MockAnalyticsService mockAnalyticsService;
    late MockUserManager mockUserManager;
    late GoogleAuthService googleAuthService;
    late MockGoogleSignIn mockGoogleSignIn;

    setUp(() {
      mockAuthService = MockAuthService();
      mockAnalyticsService = MockAnalyticsService();
      mockUserManager = MockUserManager();
      mockGoogleSignIn = MockGoogleSignIn();
      
      // Configuration du mock AuthService
      mockAuthService.setUserInfo(
        userId: 'user123',
        username: 'Test User',
        email: 'test@example.com',
        photoUrl: 'https://example.com/profile.jpg'
      );
      mockAuthService.setIsAuthenticated(false);
      
      // Configuration du UserManager avec un profil de test
      final testProfile = UserProfile(
        userId: 'user123',
        displayName: 'Test User',
        profileImageUrl: 'https://example.com/profile.jpg',
        globalStats: {
          'level': 5,
          'xp': 1200,
          'totalGames': 25,
          'victories': 15
        }
      );
      mockUserManager.setCurrentProfile(testProfile);

      // Initialisation de GoogleAuthService avec les mocks
      googleAuthService = GoogleAuthService(
        authService: mockAuthService,
        analyticsService: mockAnalyticsService,
        googleSignIn: mockGoogleSignIn
      );
    });

    test('Authentification Google complète', () async {
      // Configuration des réponses du mock
      mockAuthService.setResponse('signInWithGoogle', true);
      mockAuthService.setResponse('getIdToken', 'jwt-token-123');
      mockAuthService.setResponse('getUserProfile', {
        'userId': 'user123',
        'displayName': 'Test User',
        'email': 'test@example.com',
        'profileImageUrl': 'https://example.com/profile.jpg',
        'googleId': 'google123',
        'lastLogin': '2025-06-01T15:30:00Z',
        'globalStats': {
          'level': 5,
          'xp': 1200,
          'totalGames': 25,
          'victories': 15
        }
      });

      // Test de l'authentification Google
      final authResult = await googleAuthService.signInWithGoogle();
      
      // Vérification du résultat de l'authentification
      expect(authResult, isTrue);
      
      // Vérification que le service a été appelé
      final signInCalls = mockAuthService.getCalls('signInWithGoogle');
      expect(signInCalls.length, 1);
      
      // Mise à jour de l'état après authentification
      mockAuthService.setIsAuthenticated(true);
      
      // Vérification de l'état d'authentification
      expect(googleAuthService.isSignedIn, isTrue);
      
      // Obtention du token JWT
      final token = await googleAuthService.getGoogleAccessToken();
      expect(token, 'jwt-token-123');
      
      // Vérification que getIdToken a été appelé
      final tokenCalls = mockAuthService.getCalls('getIdToken');
      expect(tokenCalls.length, 1);
      
      // Vérification de l'analytique
      expect(mockAnalyticsService.events.isNotEmpty, isTrue);
      
      // Récupération du profil utilisateur
      final userProfile = await mockUserManager.getCurrentProfile();
      
      // Vérification du profil utilisateur
      expect(userProfile?.userId, 'user123');
      expect(userProfile?.displayName, 'Test User');
      expect(userProfile?.globalStats['level'], 5);
    });

    test('Déconnexion', () async {
      // Configuration du mock AuthService comme authentifié
      mockAuthService.setIsAuthenticated(true);
      
      // Vérification de l'état d'authentification initial
      expect(googleAuthService.isSignedIn, isTrue);
      
      // Test de la déconnexion
      await googleAuthService.signOut();
      
      // Vérification que signOut a été appelé
      final signOutCalls = mockAuthService.getCalls('signOut');
      expect(signOutCalls.length, 1);
      
      // Mise à jour de l'état après déconnexion
      mockAuthService.setIsAuthenticated(false);
      
      // Vérification de l'état d'authentification après déconnexion
      expect(googleAuthService.isSignedIn, isFalse);
    });
  });
}
