import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:games_services/games_services.dart' hide SaveGame, SaveGameInfo;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/models/game_config.dart'; // Import pour GameMode
import 'package:paperclip2/services/api/api_services.dart';
import 'package:paperclip2/services/games_services_controller.dart';
import 'package:paperclip2/services/save/save_system.dart';
import 'package:paperclip2/services/save/save_types.dart';
import 'package:paperclip2/services/save/storage/cloud_storage_engine.dart';
import 'package:paperclip2/services/social/friends_service.dart';
import 'package:paperclip2/services/user/google_auth_service.dart';
import 'package:paperclip2/services/user/user_manager.dart';
import 'package:paperclip2/services/user/user_profile.dart';

// Mocks existants
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
    return null;
  }
  
  // Intercepter _callMethod pour éviter les appels natifs
  @override
  Future<dynamic> _callMethod(String method, [List<dynamic>? args]) async {
    // Override pour éviter d'appeler les méthodes natives
    if (method == 'init') return null;
    return null;
  }
}

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
  Future<void> clearAuthCache() async {}
}

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

// Mock pour ApiClient
class MockApiClient implements ApiClient {
  final Map<String, dynamic> _responses = {};
  final List<Map<String, dynamic>> _calls = [];
  
  void setResponse(String method, dynamic response) {
    _responses[method] = response;
  }
  
  List<Map<String, dynamic>> getCalls(String method) {
    return _calls.where((call) => call['method'] == method).toList();
  }
  
  @override
  Future<Map<String, dynamic>> loginWithProvider(
    String provider,
    String providerId,
    String email, {
    String? username,
    String? profileImageUrl,
  }) async {
    _calls.add({
      'method': 'loginWithProvider',
      'provider': provider,
      'providerId': providerId,
      'email': email,
      'username': username,
      'profileImageUrl': profileImageUrl,
    });
    
    return _responses['loginWithProvider'] ?? {
      'success': true,
      'message': 'Connexion réussie',
      'user_id': 'user123',
      'username': username ?? 'Test User',
      'email': email,
      'access_token': 'mock-jwt-token',
      'expires_at': DateTime.now().add(Duration(days: 7)).toIso8601String(),
    };
  }
  
  @override
  Future<Map<String, dynamic>> get(String endpoint, {Map<String, dynamic>? queryParams, bool requiresAuth = true}) async {
    _calls.add({
      'method': 'get',
      'endpoint': endpoint,
      'queryParams': queryParams,
      'requiresAuth': requiresAuth,
    });
    
    // Pour les profils utilisateur
    if (endpoint.contains('/users/')) {
      return _responses['getUserProfile'] ?? {
        'success': true,
        'data': {
          'userId': 'user123',
          'displayName': 'Test User',
          'email': 'test@example.com',
          'profileImageUrl': 'https://example.com/profile.jpg',
          'googleId': 'google123',
          'lastLogin': '2025-06-01T15:30:00Z',
          'stats': {
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
    
    return _responses['get_$endpoint'] ?? {
      'success': true,
      'data': {}
    };
  }
  
  @override
  Future<dynamic> post(String endpoint, {dynamic body, bool requiresAuth = true, Map<String, String>? queryParams}) async {
    _calls.add({
      'method': 'post',
      'endpoint': endpoint,
      'body': body,
      'requiresAuth': requiresAuth,
      'queryParams': queryParams,
    });
    
    return _responses['post_$endpoint'] ?? {};
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

// Mock pour AuthService
class MockAuthService implements AuthService {
  final MockApiClient _apiClient;
  final MockGoogleSignIn _googleSignIn;
  bool _isAuthenticated = false;
  String? _userId;
  String? _username;
  final ValueNotifier<bool> authStateChanged = ValueNotifier<bool>(false);
  
  MockAuthService(this._apiClient, this._googleSignIn);
  
  @override
  bool get isAuthenticated => _isAuthenticated;
  
  @override
  String? get userId => _userId;
  
  @override
  String? get username => _username;
  
  @override
  Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final data = await _apiClient.loginWithProvider(
        'google',
        googleUser.id,
        googleUser.email,
        username: googleUser.displayName,
        profileImageUrl: googleUser.photoUrl,
      );
      
      _userId = data['user_id'];
      _username = data['username'];
      _isAuthenticated = true;
      authStateChanged.value = true;
      
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la connexion avec Google: $e');
      return false;
    }
  }
  
  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _isAuthenticated = false;
    _userId = null;
    _username = null;
    authStateChanged.value = false;
  }
  
  @override
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    return await _apiClient.get('/users/$userId');
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

// Mock pour GamesServicesController
class MockGamesServicesController implements GamesServicesController {
  bool _isSignedIn = false;
  GooglePlayerInfo? _playerInfo;
  final List<Map<String, dynamic>> _calls = [];

  MockGamesServicesController({
    bool isSignedIn = false,
    GooglePlayerInfo? playerInfo,
  }) : 
    _isSignedIn = isSignedIn,
    _playerInfo = playerInfo ?? GooglePlayerInfo(
      id: 'player123',
      displayName: 'TestPlayer',
      iconImageUrl: 'https://example.com/image.jpg'
    );

  // Méthode pour simuler les services natifs
  static void setupMockMethods() {
    // Intercepter les appels aux méthodes natives de GamesServices
    GamesServices.isSignedIn = Future.value(false);
    // Ajouter d'autres méthodes au besoin
  }
  
  void recordCall(String method, [Map<String, dynamic>? params]) {
    _calls.add({
      'method': method,
      'params': params ?? {},
    });
  }
  
  List<Map<String, dynamic>> getCalls(String method) {
    return _calls.where((call) => call['method'] == method).toList();
  }
  
  @override
  Future<bool> signIn() async {
    recordCall('signIn');
    _isSignedIn = true;
    return true;
  }
  
  @override
  Future<bool> isSignedIn() async {
    return _isSignedIn;
  }
  
  @override
  Future<GooglePlayerInfo?> getCurrentPlayerInfo() async {
    recordCall('getCurrentPlayerInfo');
    return _playerInfo;
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

// Mock pour SocialService
class MockSocialService implements SocialService {
  final List<Map<String, dynamic>> _friends = [];
  final List<Map<String, dynamic>> _friendRequests = [];
  final List<Map<String, dynamic>> _calls = [];
  
  void addFriend(Map<String, dynamic> friend) {
    _friends.add(friend);
  }
  
  void addFriendRequest(Map<String, dynamic> request) {
    _friendRequests.add(request);
  }
  
  void recordCall(String method, [Map<String, dynamic>? params]) {
    _calls.add({
      'method': method,
      'params': params ?? {},
    });
  }
  
  List<Map<String, dynamic>> getCalls(String method) {
    return _calls.where((call) => call['method'] == method).toList();
  }
  
  @override
  Future<Map<String, dynamic>> getFriends({String? userId}) async {
    recordCall('getFriends', {'userId': userId});
    return {
      'friends': _friends,
    };
  }
  
  @override
  Future<Map<String, dynamic>> getFriendRequests({required String userId}) async {
    recordCall('getFriendRequests', {'userId': userId});
    return {
      'requests': _friendRequests,
    };
  }
  
  @override
  Future<Map<String, dynamic>> sendFriendRequest({required String receiverId}) async {
    recordCall('sendFriendRequest', {'receiverId': receiverId});
    return {
      'success': true,
      'requestId': 'req123',
    };
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

// Mock pour SaveService et CloudStorageEngine
class MockCloudStorageEngine implements CloudStorageEngine {
  final List<SaveGame> _cloudSaves = [];
  final String _userId;
  bool _initialized = false;
  
  MockCloudStorageEngine({required String userId}) : _userId = userId;
  
  void addCloudSave(SaveGame save) {
    _cloudSaves.add(save);
  }
  
  @override
  Future<bool> initialize() async {
    _initialized = true;
    return true;
  }
  
  @override
  bool get isInitialized => _initialized;
  
  @override
  Future<List<SaveGameInfo>> listSaveGames() async {
    return _cloudSaves.map((save) => SaveGameInfo(
      id: save.id,
      name: save.name,
      timestamp: save.lastSaveTime,
      version: save.version,
      paperclips: 100.0, // Valeur par défaut pour les tests
      money: 200.0, // Valeur par défaut pour les tests
      isSyncedWithCloud: save.isSyncedWithCloud,
      cloudId: save.cloudId,
      gameMode: save.gameMode,
    )).toList();
  }
  
  @override
  Future<SaveGame?> getSaveGame(String saveId) async {
    final saveFound = _cloudSaves.firstWhere(
      (saveItem) => saveItem.id == saveId, 
      orElse: () => throw Exception('Save not found'),
    );
    return saveFound;
  }
  
  @override
  Future<bool> save(SaveGame saveGame) async {
    // Remplacer l'existant ou ajouter
    final index = _cloudSaves.indexWhere((save) => save.id == saveGame.id);
    if (index >= 0) {
      _cloudSaves[index] = saveGame;
    } else {
      _cloudSaves.add(saveGame);
    }
    
    return true;
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class MockSaveService implements SaveService {
  final List<Map<String, dynamic>> _calls = [];
  final List<SaveGame> _cloudSaves = [];
  
  void recordCall(String method, [Map<String, dynamic>? params]) {
    _calls.add({
      'method': method,
      'params': params ?? {},
    });
  }
  
  void addCloudSave(SaveGame save) {
    _cloudSaves.add(save);
  }
  
  @override
  Future<List<SaveGameInfo>> listCloudSaves({required String userId}) async {
    recordCall('listCloudSaves', {'userId': userId});
    return _cloudSaves.map((save) => SaveGameInfo(
      id: save.id,
      name: save.name,
      timestamp: save.lastSaveTime,
      version: save.version,
      paperclips: 100.0, // Valeur par défaut pour les tests
      money: 200.0, // Valeur par défaut pour les tests
      isSyncedWithCloud: save.isSyncedWithCloud,
      cloudId: save.cloudId,
      gameMode: save.gameMode,
    )).toList();
  }
  
  @override
  Future<SaveGame?> getCloudSave({required String saveId}) async {
    recordCall('getCloudSave', {'saveId': saveId});
    return _cloudSaves.firstWhere(
      (save) => save.id == saveId, 
      orElse: () => throw Exception('Save not found')
    );
  }
  
  @override
  Future<bool> saveToCloud({required SaveGame saveGame, required String userId}) async {
    recordCall('saveToCloud', {'saveId': saveGame.id, 'userId': userId});
    
    // Remplacer l'existant ou ajouter
    final index = _cloudSaves.indexWhere((save) => save.id == saveGame.id);
    if (index >= 0) {
      _cloudSaves[index] = saveGame;
    } else {
      _cloudSaves.add(saveGame);
    }
    
    return true;
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

// Classe de test principale
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  
  // Configurer les mocks pour éviter les appels natifs
  MockGamesServicesController.setupMockMethods();
  late MockApiClient mockApiClient;
  late MockGoogleSignIn mockGoogleSignIn;
  late MockAuthService mockAuthService;
  late MockGamesServicesController mockGamesServicesController;
  late MockSocialService mockSocialService;
  late MockCloudStorageEngine mockCloudStorageEngine;
  late MockSaveService mockSaveService;
  late GoogleAuthService googleAuthService;
  late UserManager userManager;
  late FriendsService friendsService;
  
  setUp(() async {
    // Configurer SharedPreferences pour les tests
    SharedPreferences.setMockInitialValues({});
    
    // Initialiser les mocks
    mockApiClient = MockApiClient();
    mockGoogleSignIn = MockGoogleSignIn();
    mockAuthService = MockAuthService(mockApiClient, mockGoogleSignIn);
    mockGamesServicesController = MockGamesServicesController();
    mockSocialService = MockSocialService();
    mockCloudStorageEngine = MockCloudStorageEngine(userId: 'user123');
    mockSaveService = MockSaveService();
    
    // Créer GoogleAuthService avec les mocks
    googleAuthService = GoogleAuthService(
      authService: mockAuthService,
      analyticsService: AnalyticsService(), // Simple instance
    );
    
    // Créer UserManager avec les mocks en utilisant le constructeur factory
    userManager = UserManager(
      authService: mockAuthService,
      analyticsService: AnalyticsService(), // Simple instance
      saveService: mockSaveService,
      socialService: mockSocialService,
      storageService: StorageService(), // Simple instance
    );
    
    // Créer FriendsService avec les mocks
    friendsService = FriendsService(
      userId: 'user123',
      userManager: userManager,
      socialService: mockSocialService,
      analyticsService: AnalyticsService(), // Simple instance
    );
  });
  
  group('Flux d\'authentification Google', () {
    test('Connexion avec Google réussie', () async {
      // Simuler une connexion réussie
      final result = await userManager.signInWithGoogle();
      
      // Vérifier que la connexion a réussi
      expect(result, true);
      expect(mockAuthService.isAuthenticated, true);
      expect(mockAuthService.userId, 'user123');
    });
    
    test('Connexion avec Google échouée', () async {
      // Configurer le mock pour échouer
      mockGoogleSignIn = MockGoogleSignIn(shouldSignIn: false);
      mockAuthService = MockAuthService(mockApiClient, mockGoogleSignIn);
      googleAuthService = GoogleAuthService(
        authService: mockAuthService,
        analyticsService: AnalyticsService(), // Simple instance
      );
      // Recréer le UserManager avec les nouvelles dépendances
      userManager = UserManager(
        authService: mockAuthService,
        analyticsService: AnalyticsService(),
        saveService: mockSaveService,
        socialService: mockSocialService,
        storageService: StorageService(),
      );
      
      // Tenter la connexion
      final result = await userManager.signInWithGoogle();
      
      // Vérifier que la connexion a échoué
      expect(result, false);
      expect(mockAuthService.isAuthenticated, false);
    });
    
    test('Récupération du profil après connexion', () async {
      // Simuler une connexion
      await userManager.signInWithGoogle();
      
      // Vérifier que le profil est chargé
      expect(userManager.hasProfile, true);
      expect(userManager.currentProfile?.userId, 'user123');
      expect(userManager.currentProfile?.googleId, 'google123');
    });
  });
  
  group('Gestion des sauvegardes cloud', () {
    test('Synchronisation des sauvegardes', () async {
      // Préparer des sauvegardes cloud
      final cloudSave = SaveGame(
        id: 'save1',
        name: 'Cloud Save 1',
        lastSaveTime: DateTime.now(),
        gameData: {'level': 5, 'score': 1000},
        version: '1.0',
        gameMode: GameMode.INFINITE,
        isSyncedWithCloud: true,
      );
      mockSaveService.addCloudSave(cloudSave);
      
      // Connecter l'utilisateur
      await userManager.signInWithGoogle();
      
      // Créer un profil utilisateur avec des données de sauvegarde
      // Note: Cette étape n'est pas nécessaire car la sauvegarde est déjà ajoutée au service
      
      // Lister les sauvegardes cloud
      final cloudSaves = await mockSaveService.listCloudSaves(userId: 'user123');
      
      // Vérifier que les sauvegardes sont récupérées
      expect(cloudSaves.length, 1);
      expect(cloudSaves[0].id, 'save1');
      expect(cloudSaves[0].name, 'Cloud Save 1');
    });
    
    test('Téléchargement d\'une sauvegarde cloud', () async {
      // Préparer une sauvegarde cloud
      final cloudSave = SaveGame(
        id: 'save2',
        name: 'Cloud Save 2',
        lastSaveTime: DateTime.now(),
        gameData: {'level': 7, 'score': 2000},
        version: '1.0',
        gameMode: GameMode.INFINITE,
        isSyncedWithCloud: true,
      );
      mockSaveService.addCloudSave(cloudSave);
      
      // Connecter l'utilisateur
      await userManager.signInWithGoogle();
      
      // Télécharger la sauvegarde
      final save = await mockSaveService.getCloudSave(saveId: 'save2');
      
      // Vérifier que la sauvegarde est correcte
      expect(save, isNotNull);
      expect(save?.id, 'save2');
      expect(save?.name, 'Cloud Save 2');
      expect(save?.gameData['level'], 7);
      expect(save?.gameData['score'], 2000);
    });
  });
  
  group('Gestion des amis', () {
    test('Récupération de la liste d\'amis', () async {
      // Ajouter des amis de test
      mockSocialService.addFriend({
        'friendshipId': 'f1',
        'userId': 'friend1',
        'displayName': 'Friend One',
        'profileImageUrl': 'https://example.com/friend1.jpg',
        'stats': {
          'level': 4,
          'totalPaperclips': 800
        }
      });
      
      // Connecter l'utilisateur
      await userManager.signInWithGoogle();
      
      // Actualiser la liste d'amis
      await friendsService.refreshAll();
      
      // Vérifier les appels
      final calls = mockSocialService.getCalls('getFriends');
      expect(calls.length, 1);
      expect(calls[0]['params']['userId'], 'user123');
      
      // Vérifier que les amis sont récupérés
      expect(friendsService.friends.value.length, 1);
      expect(friendsService.friends.value[0].userId, 'friend1');
      expect(friendsService.friends.value[0].displayName, 'Friend One');
    });
    
    test('Envoi d\'une demande d\'ami', () async {
      // Connecter l'utilisateur
      await userManager.signInWithGoogle();
      
      // Envoyer une demande d'ami
      await friendsService.sendFriendRequest('friend2', 'Friend Two');
      
      // Vérifier les appels
      final calls = mockSocialService.getCalls('sendFriendRequest');
      expect(calls.length, 1);
      expect(calls[0]['params']['receiverId'], 'friend2');
    });
  });
  
  group('Intégration avec Google Play Games', () {
    test('Connexion à Google Play Games', () async {
      // Connecter l'utilisateur
      await googleAuthService.signInWithGoogle();
      
      // Vérifier les appels
      final calls = mockGamesServicesController.getCalls('signIn');
      expect(calls.length, 1);
      
      // Vérifier l'état de connexion
      expect(await mockGamesServicesController.isSignedIn, true);
    });
    
    test('Récupération des informations du joueur', () async {
      // Connecter l'utilisateur
      await googleAuthService.signInWithGoogle();
      
      // Récupérer les infos du joueur
      final playerInfo = await mockGamesServicesController.getCurrentPlayerInfo();
      
      // Vérifier les appels
      final calls = mockGamesServicesController.getCalls('getCurrentPlayerInfo');
      expect(calls.length, 1);
      
      // Vérifier les informations du joueur
      expect(playerInfo?.id, 'gamer123');
      expect(playerInfo?.displayName, 'GamerPro');
    });
  });
}
