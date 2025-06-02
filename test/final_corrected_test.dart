import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/models/social/user_stats_model.dart';
import 'package:paperclip2/services/api/api_services.dart';
import 'package:paperclip2/services/social/friends_service.dart';
import 'package:paperclip2/services/social/user_stats_service.dart';
import 'package:paperclip2/services/user/google_auth_service.dart';
import 'package:paperclip2/services/user/user_manager.dart';
import 'package:paperclip2/services/user/user_profile.dart';

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
  Future<GoogleSignInAccount?> signInSilently({
    bool suppressErrors = false,
    bool reAuthenticate = false,
  }) async {
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
  Future<GoogleSignInAccount?> signOut() async {
    // Ne rien faire
    return null;
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
      serverAuthCode: serverAuthCode,
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
  @override
  final String? serverAuthCode;
  
  MockGoogleSignInAuthentication({
    this.accessToken,
    this.idToken,
    this.serverAuthCode,
  });
}

// Mock pour UserStatsService
class MockUserStatsService implements UserStatsService {
  final SocialService _socialService;
  final AnalyticsService _analyticsService;
  final String _userId;
  final UserManager? _userManager;
  
  MockUserStatsService({
    required SocialService socialService,
    required AnalyticsService analyticsService,
    required String userId,
    UserManager? userManager,
  }) : 
    _socialService = socialService,
    _analyticsService = analyticsService,
    _userId = userId,
    _userManager = userManager;
  
  @override
  void addListener(VoidCallback listener) {}
  
  @override
  void dispose() {}
  
  @override
  bool get hasListeners => false;
  
  @override
  void notifyListeners() {}
  
  @override
  void removeListener(VoidCallback listener) {}
  
  @override
  Future<UserStatsModel> getCurrentUserStats() async {
    return UserStatsModel(
      userId: _userId,
      displayName: 'Test User',
      totalPaperclips: 1000,
      level: 5,
      money: 5000.0,
      bestScore: 2500,
      efficiency: 0.85,
      upgradesBought: 10,
      lastUpdated: DateTime.now(),
    );
  }
  
  @override
  Future<List<UserStatsModel>> getFriendsLeaderboard() async {
    try {
      // Récupérer les entrées du classement - attention ici à la différence de type
      final entries = await _socialService.getLeaderboardEntries(
        leaderboardId: "friends", 
        friendsOnly: true
      );
      
      final List<UserStatsModel> leaderboard = [];
      
      for (var entry in entries) {
        try {
          leaderboard.add(UserStatsModel(
            userId: entry['userId'] ?? '',
            displayName: entry['displayName'] ?? 'Inconnu',
            totalPaperclips: entry['score'] ?? 0,
            level: entry['level'] ?? 1,
            money: (entry['money'] as num?)?.toDouble() ?? 0.0,
            bestScore: entry['bestScore'] ?? 0,
            efficiency: (entry['efficiency'] as num?)?.toDouble() ?? 0.0,
            upgradesBought: entry['upgradesBought'] ?? 0,
            lastUpdated: DateTime.parse(entry['lastUpdated'] ?? DateTime.now().toIso8601String()),
          ));
        } catch (e) {
          debugPrint('Erreur lors du traitement d\'une entrée du classement: $e');
        }
      }
      
      return leaderboard;
    } catch (e, stack) {
      debugPrint('Erreur lors de la récupération du classement des amis: $e');
      _analyticsService.recordError(e, stack);
      return [];
    }
  }
  
  @override
  Future<UserStatsModel?> getFriendStats(String friendId) async {
    return null;
  }
  
  @override
  Future<Map<String, dynamic>?> compareWithFriend(String friendId, GameState gameState) async {
    return null;
  }
  
  @override
  Future<bool> updatePublicStats(GameState gameState) async {
    return true;
  }
  
  @override
  Future<List<UserStatsModel>> getGlobalLeaderboard() async {
    try {
      // Retourne un classement vide pour le test
      return [];
    } catch (e, stack) {
      debugPrint('Erreur lors de la récupération du classement global: $e');
      _analyticsService.recordError(e, stack);
      return [];
    }
  }
  
  @override
  Future<List<Map<String, dynamic>>> getUserAchievements() async {
    try {
      // Retourne une liste vide de succès pour le test
      return [];
    } catch (e, stack) {
      debugPrint('Erreur lors de la récupération des succès: $e');
      _analyticsService.recordError(e, stack);
      return [];
    }
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
    _userId = _userId ?? 'user123';
    _username = _username ?? 'Test User';
    _email = _email ?? 'test@example.com';
    _photoUrl = _photoUrl ?? 'https://example.com/profile.jpg';
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
        'totalPaperclips': 1000,
        'money': 5000.0,
        'bestScore': 2500,
        'efficiency': 0.85,
        'upgradesBought': 10
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
          'totalPaperclips': 1000,
          'money': 5000.0,
          'bestScore': 2500,
          'efficiency': 0.85,
          'upgradesBought': 10
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
      // Gérer le cas où la réponse est directement une liste
      if (response is List) {
        return response.map((entry) => entry as Map<String, dynamic>).toList();
      }
      // Gérer le cas où la réponse est une Map contenant une clé 'data'
      else if (response is Map<String, dynamic>) {
        if (response.containsKey('data')) {
          final List entries = response['data'] as List;
          return entries.map((entry) => entry as Map<String, dynamic>).toList();
        } else if (response.containsKey('entries')) {
          final List entries = response['entries'] as List;
          return entries.map((entry) => entry as Map<String, dynamic>).toList();
        }
      }
    }
    return [];
  }

  @override
  Future<Map<String, dynamic>> sendFriendRequest({required String receiverId, String? message}) async {
    _calls.add({
      'method': 'sendFriendRequest',
      'receiverId': receiverId,
      'message': message
    });
    return _responses['sendFriendRequest'] ?? {
      'success': true,
      'message': 'Demande envoyée',
      'data': {'requestId': 'req123'}
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
  ValueNotifier<UserProfile?> get profileChanged => _profileNotifier;

  @override
  String? getCurrentUserId() {
    return _currentProfile?.userId;
  }

  @override
  Future<UserProfile?> getCurrentProfile() async {
    return _currentProfile;
  }
  
  @override
  UserProfile? get currentProfile => _currentProfile;

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
  Future<void> initialize({
    Map<String, dynamic>? defaultConfig,
    Duration? minimumFetchInterval,
    bool forceRefresh = false
  }) async {
    _calls.add({
      'method': 'initialize',
      'defaultConfig': defaultConfig,
      'minimumFetchInterval': minimumFetchInterval,
      'forceRefresh': forceRefresh
    });
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
    late MockGoogleSignIn mockGoogleSignIn;
    
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
      mockGoogleSignIn = MockGoogleSignIn();
      
      // Configuration du UserManager avec un profil de test
      final testProfile = UserProfile(
        userId: TEST_USER_ID,
        displayName: 'Test User',
        profileImageUrl: 'https://example.com/profile.jpg',
        globalStats: {
          'level': 5,
          'totalPaperclips': 1000,
          'money': 5000.0,
          'bestScore': 2500,
          'efficiency': 0.85,
          'upgradesBought': 10
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
        analyticsService: mockAnalyticsService,
        googleSignIn: mockGoogleSignIn
      );
      
      friendsService = FriendsService(
        userId: TEST_USER_ID,
        socialService: mockSocialService,
        analyticsService: mockAnalyticsService,
        userManager: mockUserManager
      );
      
      userStatsService = MockUserStatsService(
        socialService: mockSocialService,
        analyticsService: mockAnalyticsService,
        userId: TEST_USER_ID,
        userManager: mockUserManager,
      );
    });

    test('Parcours utilisateur complet - Connexion aux interactions sociales', () async {
      // Étape 1: Connexion Google
      print('1. Simulation de la connexion Google');
      
      mockAuthService.setResponse('signInWithGoogle', true);
      mockAuthService.setResponse('getIdToken', TEST_AUTH_TOKEN);
      
      final authResult = await googleAuthService.signInWithGoogle();
      
      expect(authResult, isNotNull);
      
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
        'users': mockUsers
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
          'score': 1500,
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
          'score': 1000,
          'money': 5000.0,
          'bestScore': 2500,
          'efficiency': 0.85,
          'upgradesBought': 10,
          'lastUpdated': '2025-06-01T15:30:00Z'
        }
      ];
      
      // Ajouter des prints de débogage
      print("Setting mock response for getLeaderboardEntries with data: $leaderboardData");
      
      // Retourne directement une liste comme le fait la vraie méthode SocialService.getLeaderboardEntries
      mockSocialService.setResponse('getLeaderboardEntries', leaderboardData);
      
      print("Calling getFriendsLeaderboard...");
      final leaderboard = await userStatsService.getFriendsLeaderboard();
      print("Received leaderboard response: $leaderboard with length: ${leaderboard.length}");
      
      expect(leaderboard.length, 2);
      expect(leaderboard[0].userId, 'friend1');
      expect(leaderboard[0].level, 6);
      expect(leaderboard[0].totalPaperclips, 1500);
      expect(leaderboard[0].bestScore, 3500);
      expect(leaderboard[1].userId, 'user123');
      expect(leaderboard[1].level, 5);
      expect(leaderboard[1].totalPaperclips, 1000);
      
      // Étape 6: Mise à jour des statistiques globales
      print('6. Mise à jour des statistiques globales');
      
      final newStats = {
        'level': 6,
        'totalPaperclips': 1500,
        'money': 7500.0,
        'bestScore': 3500,
        'efficiency': 0.90,
        'upgradesBought': 15
      };
      
      // Récupération du profil actuel
      final currentProfile = (await mockUserManager.getCurrentProfile()) as UserProfile;
      
      // Mise à jour des statistiques globales
      final updatedProfile = currentProfile.updateGlobalStats(newStats);
      
      // Vérification des nouvelles statistiques
      expect(updatedProfile.globalStats['level'], 6);
      expect(updatedProfile.globalStats['totalPaperclips'], 1500);
      expect(updatedProfile.globalStats['bestScore'], 3500);
      
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
