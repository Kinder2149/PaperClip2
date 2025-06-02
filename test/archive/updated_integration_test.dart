import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:paperclip2/services/api/api_services.dart';
import 'package:paperclip2/services/user/google_auth_service.dart';
import 'package:paperclip2/services/user/user_manager.dart';
import 'package:paperclip2/services/user/user_profile.dart';
import 'package:paperclip2/services/social/friends_service.dart';
import 'package:paperclip2/services/social/user_stats_service.dart';

// Classes d'aide pour les tests
class UserStatsModel {
  final String userId;
  final String displayName;
  final String profileImageUrl;
  final int level;
  final int xp;
  final int totalGames;
  final int victories;
  
  UserStatsModel({
    required this.userId,
    required this.displayName,
    required this.profileImageUrl,
    required this.level,
    required this.xp,
    required this.totalGames,
    required this.victories,
  });
  
  factory UserStatsModel.fromJson(Map<String, dynamic> json) {
    return UserStatsModel(
      userId: json['userId'],
      displayName: json['displayName'],
      profileImageUrl: json['profileImageUrl'],
      level: json['level'],
      xp: json['xp'],
      totalGames: json['totalGames'],
      victories: json['victories'],
    );
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

// Mock manuel pour SocialService
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
  Future<Map<String, dynamic>> getUserProfile({required String userId}) async {
    _calls.add({
      'method': 'getUserProfile',
      'userId': userId,
    });
    return _responses['getUserProfile'] ?? {
      'success': true,
      'data': {
        'userId': userId,
        'displayName': 'Test User',
        'profileImageUrl': 'https://example.com/profile.jpg',
        'globalStats': {
          'level': 5,
          'xp': 1200,
          'totalGames': 25,
          'victories': 15
        }
      }
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
    if (_responses.containsKey('getLeaderboardEntries')) {
      final response = _responses['getLeaderboardEntries'];
      if (response is Map<String, dynamic> && response.containsKey('data')) {
        return List<Map<String, dynamic>>.from(response['data']);
      }
      return response as List<Map<String, dynamic>>;
    }
    return [];
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

// Mock manuel pour ConfigService
class MockConfigService implements ConfigService {
  final Map<String, dynamic> _values = {};
  final List<Map<String, dynamic>> _calls = [];

  void setValue(String key, dynamic value) {
    _values[key] = value;
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
  T getValue<T>(String key, T defaultValue) {
    _calls.add({
      'method': 'getValue',
      'key': key,
      'defaultValue': defaultValue,
    });
    return (_values[key] ?? defaultValue) as T;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

void main() {
  // Initialisation du binding Flutter pour éviter les erreurs
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Test d\'intégration - Parcours utilisateur complet', () {
    late MockAuthService mockAuthService;
    late MockAnalyticsService mockAnalyticsService;
    late MockUserManager mockUserManager;
    late MockSocialService mockSocialService;
    late MockConfigService mockConfigService;
    
    late GoogleAuthService googleAuthService;
    late FriendsService friendsService;
    late UserStatsService userStatsService;
    
    const String TEST_USER_ID = 'user123';
    const String TEST_AUTH_TOKEN = 'jwt-token-123';
    
    setUp(() {
      mockAuthService = MockAuthService();
      mockAnalyticsService = MockAnalyticsService();
      mockUserManager = MockUserManager();
      mockSocialService = MockSocialService();
      mockConfigService = MockConfigService();
      
      // Configuration du UserManager avec un profil de test
      final testProfile = UserProfile(
        userId: TEST_USER_ID,
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
      
      // Configuration de l'AuthService
      mockAuthService.setUserInfo(
        userId: TEST_USER_ID,
        username: 'Test User',
        email: 'test@example.com',
        photoUrl: 'https://example.com/profile.jpg'
      );
      
      // Initialisation des services avec les mocks
      googleAuthService = GoogleAuthService(
        authService: mockAuthService,
        analyticsService: mockAnalyticsService
      );
      
      friendsService = FriendsService(
        userId: TEST_USER_ID,
        socialService: mockSocialService,
        analyticsService: mockAnalyticsService,
        userManager: mockUserManager
      );
      
      userStatsService = UserStatsService(
        userId: TEST_USER_ID,
        socialService: mockSocialService,
        analyticsService: mockAnalyticsService,
        userManager: mockUserManager
      );
    });

    test('Parcours utilisateur complet - Connexion aux interactions sociales', () async {
      // Étape 1: Connexion Google
      print('1. Simulation de la connexion Google');
      
      mockAuthService.setResponse('signInWithGoogle', true);
      mockAuthService.setResponse('getIdToken', TEST_AUTH_TOKEN);
      
      final authResult = await googleAuthService.signInWithGoogle();
      
      expect(authResult, isTrue);
      
      // Mise à jour de l'état d'authentification
      mockAuthService.setIsAuthenticated(true);
      
      // Vérification de l'état d'authentification
      expect(googleAuthService.isSignedIn, isTrue);
      
      // Étape 2: Récupération du profil utilisateur
      print('2. Récupération du profil utilisateur');
      
      final userProfile = await mockUserManager.getCurrentProfile();
      
      expect(userProfile?.userId, TEST_USER_ID);
      expect(userProfile?.displayName, 'Test User');
      expect(userProfile?.globalStats['level'], 5);
      
      // Étape 3: Recherche d'utilisateurs
      print('3. Recherche d\'utilisateurs');
      
      final mockUsers = [
        {
          'userId': 'friend1',
          'displayName': 'Friend One',
          'profileImageUrl': 'https://example.com/friend1.jpg'
        },
        {
          'userId': 'friend2',
          'displayName': 'Friend Two',
          'profileImageUrl': 'https://example.com/friend2.jpg'
        }
      ];
      
      mockSocialService.setResponse('searchUsers', {
        'success': true,
        'message': 'Utilisateurs trouvés',
        'data': mockUsers
      });
      
      final searchResults = await friendsService.searchUsers('friend');
      
      expect(searchResults.length, 2);
      expect(searchResults[0].userId, 'friend1');
      expect(searchResults[0].displayName, 'Friend One');
      expect(searchResults[1].userId, 'friend2');
      expect(searchResults[1].displayName, 'Friend Two');
      
      // Étape 4: Envoi d'une demande d'ami
      print('4. Envoi d\'une demande d\'ami');
      
      mockSocialService.setResponse('sendFriendRequest', {
        'success': true,
        'message': 'Demande envoyée',
        'data': {'requestId': 'req123'}
      });
      
      final sendResult = await friendsService.sendFriendRequest('friend1', 'Friend One');
      
      expect(sendResult, isTrue);
      
      // Étape 5: Récupération du classement des amis
      print('5. Récupération du classement des amis');
      
      final leaderboardData = [
        {
          'userId': 'friend1',
          'displayName': 'Friend One',
          'profileImageUrl': 'https://example.com/friend1.jpg',
          'level': 6,
          'xp': 1500,
          'totalGames': 30,
          'victories': 20
        },
        {
          'userId': TEST_USER_ID,
          'displayName': 'Test User',
          'profileImageUrl': 'https://example.com/profile.jpg',
          'level': 5,
          'xp': 1200,
          'totalGames': 25,
          'victories': 15
        }
      ];
      
      mockSocialService.setResponse('getLeaderboardEntries', {
        'success': true,
        'data': leaderboardData
      });
      
      final leaderboard = await userStatsService.getFriendsLeaderboard();
      
      expect(leaderboard.length, 2);
      expect(leaderboard[0].userId, 'friend1');
      expect(leaderboard[0].level, 6);
      // Utiliser les champs disponibles dans UserStatsModel
      expect(leaderboard[0].totalGames, 30);
      expect(leaderboard[0].victories, 20);
      expect(leaderboard[1].userId, TEST_USER_ID);
      expect(leaderboard[1].level, 5);
      
      // Étape 6: Mise à jour des statistiques globales
      print('6. Mise à jour des statistiques globales');
      
      final newStats = {
        'level': 6,
        'xp': 1500,
        'totalGames': 30,
        'victories': 20
      };
      
      // Récupération du profil actuel
      final currentProfile = (await mockUserManager.getCurrentProfile()) as UserProfile;
      
      // Mise à jour des statistiques globales
      final updatedProfile = currentProfile.updateGlobalStats(newStats);
      
      // Vérification des nouvelles statistiques
      expect(updatedProfile.globalStats['level'], 6);
      expect(updatedProfile.globalStats['xp'], 1500);
      expect(updatedProfile.globalStats['totalGames'], 30);
      
      // Mise à jour du mock UserManager
      mockUserManager.setCurrentProfile(updatedProfile);
      
      // Vérification du profil mis à jour
      final finalProfile = await mockUserManager.getCurrentProfile();
      expect(finalProfile?.globalStats['level'], 6);
      
      // Étape 7: Déconnexion
      print('7. Déconnexion');
      
      await googleAuthService.signOut();
      
      mockAuthService.setIsAuthenticated(false);
      
      expect(googleAuthService.isSignedIn, isFalse);
      
      print('Test d\'intégration complet terminé avec succès !');
    });
  });
}
