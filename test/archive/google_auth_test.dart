import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:paperclip2/services/user/google_auth_service.dart';
import 'package:paperclip2/services/api/api_services.dart';

// Mocks pour les services externes
class MockGoogleSignIn extends GoogleSignIn {
  bool _shouldReturnAccount = true;
  bool _shouldThrowError = false;
  
  void setShouldReturnAccount(bool value) {
    _shouldReturnAccount = value;
  }
  
  void setShouldThrowError(bool value) {
    _shouldThrowError = value;
  }
  
  @override
  Future<GoogleSignInAccount?> signIn() async {
    if (_shouldThrowError) {
      throw Exception('Erreur simulée Google Sign In');
    }
    
    if (!_shouldReturnAccount) {
      return null;
    }
    
    return MockGoogleSignInAccount();
  }
  
  @override
  Future<GoogleSignInAccount?> signInSilently({bool suppressErrors = false}) async {
    if (_shouldThrowError) {
      throw Exception('Erreur simulée Google Sign In');
    }
    
    if (!_shouldReturnAccount) {
      return null;
    }
    
    return MockGoogleSignInAccount();
  }
  
  @override
  Future<void> signOut() async {
    // Simulation de déconnexion
  }
}

class MockGoogleSignInAccount implements GoogleSignInAccount {
  @override
  String get id => 'mock_google_id_123';
  
  @override
  String get email => 'mock_user@example.com';
  
  @override
  String get displayName => 'Mock User';
  
  @override
  String? get photoUrl => 'https://example.com/mock_user.jpg';
  
  @override
  Future<GoogleSignInAuthentication> get authentication async {
    return MockGoogleSignInAuthentication();
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockGoogleSignInAuthentication implements GoogleSignInAuthentication {
  @override
  String? get accessToken => 'mock_access_token';
  
  @override
  String? get idToken => 'mock_id_token';
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAuthService implements AuthService {
  bool _isAuthenticated = false;
  bool _shouldAuthSucceed = true;
  String? _userId;
  String? _username;
  String? _email;
  String? _photoUrl;
  
  void setAuthenticationStatus(bool status, {String? userId, String? username, String? email, String? photoUrl}) {
    _isAuthenticated = status;
    _userId = userId;
    _username = username;
    _email = email;
    _photoUrl = photoUrl;
  }
  
  void setShouldAuthSucceed(bool value) {
    _shouldAuthSucceed = value;
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
  Future<bool> signInWithGoogle() async {
    if (_shouldAuthSucceed) {
      _isAuthenticated = true;
      _userId = 'mock_user_id_123';
      _username = 'Mock User';
      _email = 'mock_user@example.com';
      _photoUrl = 'https://example.com/mock_user.jpg';
      return true;
    }
    return false;
  }
  
  @override
  Future<void> logout() async {
    _isAuthenticated = false;
    _userId = null;
    _username = null;
    _email = null;
    _photoUrl = null;
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAnalyticsService implements AnalyticsService {
  List<Map<String, dynamic>> errors = [];
  List<Map<String, dynamic>> events = [];
  
  @override
  Future<void> logEvent(String eventName, {Map<String, dynamic>? parameters, String? userId}) async {
    events.add({
      'eventName': eventName,
      'parameters': parameters,
      'userId': userId
    });
  }
  
  @override
  Future<void> recordError(dynamic error, StackTrace stackTrace, {
    String? reason, 
    Map<String, dynamic>? metadata, 
    String? userId, 
    bool fatal = false
  }) async {
    errors.add({
      'error': error,
      'stackTrace': stackTrace,
      'reason': reason,
      'metadata': metadata,
      'userId': userId,
      'fatal': fatal
    });
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('GoogleAuthService Tests', () {
    late MockGoogleSignIn mockGoogleSignIn;
    late MockAuthService mockAuthService;
    late MockAnalyticsService mockAnalyticsService;
    late GoogleAuthService googleAuthService;
    
    setUp(() {
      mockGoogleSignIn = MockGoogleSignIn();
      mockAuthService = MockAuthService();
      mockAnalyticsService = MockAnalyticsService();
      
      googleAuthService = GoogleAuthService(
        googleSignIn: mockGoogleSignIn,
        authService: mockAuthService,
        analyticsService: mockAnalyticsService,
      );
    });
    
    test('signInWithGoogle - devrait réussir quand AuthService réussit', () async {
      // Arrange
      mockAuthService.setShouldAuthSucceed(true);
      mockGoogleSignIn.setShouldReturnAccount(true);
      
      // Act
      final result = await googleAuthService.signInWithGoogle();
      
      // Assert
      expect(result, isNotNull);
      expect(result?['id'], 'mock_user_id_123');
      expect(result?['displayName'], 'Mock User');
      expect(result?['email'], 'mock_user@example.com');
      expect(result?['photoUrl'], 'https://example.com/mock_user.jpg');
      expect(googleAuthService.isSignedIn, isTrue);
    });
    
    test('signInWithGoogle - devrait échouer quand AuthService échoue', () async {
      // Arrange
      mockAuthService.setShouldAuthSucceed(false);
      mockGoogleSignIn.setShouldReturnAccount(true);
      
      // Act
      final result = await googleAuthService.signInWithGoogle();
      
      // Assert
      expect(result, isNull);
      expect(googleAuthService.isSignedIn, isFalse);
    });
    
    test('signInWithGoogle - devrait échouer quand GoogleSignIn retourne null', () async {
      // Arrange
      mockAuthService.setShouldAuthSucceed(true);
      mockGoogleSignIn.setShouldReturnAccount(false);
      
      // Act
      final result = await googleAuthService.signInWithGoogle();
      
      // Assert
      expect(result, isNull);
      expect(googleAuthService.isSignedIn, isFalse);
    });
    
    test('signInWithGoogle - devrait gérer les erreurs de GoogleSignIn', () async {
      // Arrange
      mockAuthService.setShouldAuthSucceed(true);
      mockGoogleSignIn.setShouldThrowError(true);
      
      // Act
      final result = await googleAuthService.signInWithGoogle();
      
      // Assert
      expect(result, isNull);
      expect(mockAnalyticsService.errors.isNotEmpty, isTrue);
      expect(mockAnalyticsService.errors.first['reason'], 'Google sign-in error');
      expect(googleAuthService.isSignedIn, isFalse);
    });
    
    test('signOut - devrait se déconnecter correctement', () async {
      // Arrange - Connecter d'abord l'utilisateur
      mockAuthService.setAuthenticationStatus(true, 
        userId: 'mock_user_id_123', 
        username: 'Mock User'
      );
      
      // Act
      await googleAuthService.signOut();
      
      // Assert
      expect(googleAuthService.isSignedIn, isFalse);
      expect(mockAuthService.userId, isNull);
      expect(mockAuthService.username, isNull);
    });
    
    test('getGoogleProfileInfo - devrait récupérer les infos utilisateur', () async {
      // Arrange
      mockAuthService.setAuthenticationStatus(true, 
        userId: 'mock_user_id_123', 
        username: 'Mock User',
        email: 'mock_user@example.com',
        photoUrl: 'https://example.com/mock_user.jpg'
      );
      
      // Act
      final profileInfo = await googleAuthService.getGoogleProfileInfo();
      
      // Assert
      expect(profileInfo, isNotNull);
      expect(profileInfo?['id'], 'mock_user_id_123');
      expect(profileInfo?['displayName'], 'Mock User');
      expect(profileInfo?['email'], 'mock_user@example.com');
      expect(profileInfo?['photoUrl'], 'https://example.com/mock_user.jpg');
    });
  });
}
