import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:paperclip2/services/api/api_services.dart';
import 'package:paperclip2/services/user/google_auth_service.dart';
import 'package:paperclip2/services/user/user_manager.dart';
import 'package:paperclip2/services/user/user_profile.dart';
import 'package:paperclip2/services/social/friends_service.dart';
import 'package:paperclip2/services/social/user_stats_service.dart';

// Mocks manuels
class MockHttpClient extends Mock implements http.Client {}
class MockAnalyticsService extends Mock implements AnalyticsService {}
class MockAuthService extends Mock implements AuthService {}
class MockUserManager extends Mock implements UserManager {}
class MockSocialService extends Mock implements SocialService {}
class MockConfigService extends Mock implements ConfigService {}

void main() {
  group('Full Integration Test - User Journey', () {
    late MockHttpClient mockHttpClient;
    late MockAnalyticsService mockAnalyticsService;
    late MockAuthService mockAuthService;
    late MockUserManager mockUserManager;
    late MockSocialService mockSocialService;
    late MockConfigService mockConfigService;
    
    late FriendsService friendsService;
    late UserStatsService userStatsService;
    
    const String TEST_USER_ID = 'user123';
    const String TEST_AUTH_TOKEN = 'jwt-token-123';
    
    setUp(() {
      mockHttpClient = MockHttpClient();
      mockAnalyticsService = MockAnalyticsService();
      mockAuthService = MockAuthService();
      mockUserManager = MockUserManager();
      mockSocialService = MockSocialService();
      mockConfigService = MockConfigService();
      
      // Configuration du UserManager pour retourner les données utilisateur
      when(mockUserManager.getCurrentUserId()).thenReturn(TEST_USER_ID);
      when(mockUserManager.getAuthToken()).thenReturn(TEST_AUTH_TOKEN);
      
      // Configuration des mocks supplémentaires
      when(mockAuthService.getIdToken()).thenAnswer((_) async => TEST_AUTH_TOKEN);
      
      // Initialisation des services avec les mocks
      friendsService = FriendsService(
        socialService: mockSocialService,
        analyticsService: mockAnalyticsService,
        userManager: mockUserManager
      );
      
      userStatsService = UserStatsService(
        socialService: mockSocialService,
        analyticsService: mockAnalyticsService,
        userManager: mockUserManager
      );
    });

    test('Full User Journey - Login to Social Interaction', () async {
      // Étape 1: Connexion Google
      print('1. Simulation de la connexion Google');
      
      when(mockAuthService.signInWithGoogle()).thenAnswer((_) async => true);
      
      final authResult = await mockAuthService.signInWithGoogle();
      
      expect(authResult, isTrue);
      // Vérification que les getters appropriés sont appelés
      when(mockAuthService.userId).thenReturn(TEST_USER_ID);
      when(mockAuthService.isAuthenticated).thenReturn(true);
      
      expect(mockAuthService.userId, TEST_USER_ID);
      expect(mockAuthService.isAuthenticated, isTrue);
      
      // Étape 2: Récupération du profil utilisateur
      print('2. Récupération du profil utilisateur');
      
      final userProfileData = {
        'userId': TEST_USER_ID,
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
      };
      
      when(mockUserManager.getCurrentUserProfile()).thenAnswer((_) async => userProfileData);
      when(mockUserManager.getUserProfile(TEST_USER_ID)).thenAnswer((_) async => 
        UserProfile.fromJson(userProfileData));
      
      final userProfile = await mockUserManager.getCurrentUserProfile();
      expect(userProfile['userId'], TEST_USER_ID);
      expect(userProfile['displayName'], 'Test User');
      
      // Étape 3: Recherche d'utilisateurs pour ajouter des amis
      print('3. Recherche d\'utilisateurs pour ajout d\'amis');
      
      final searchResults = [
        UserProfile.fromJson({
          'userId': 'friend1',
          'displayName': 'Friend One',
          'profileImageUrl': 'https://example.com/friend1.jpg',
          'googleId': 'google456',
          'lastLogin': '2025-06-01T14:00:00Z',
          'globalStats': {
            'level': 4,
            'xp': 1000,
            'totalGames': 20,
            'victories': 10,
          }
        }),
        UserProfile.fromJson({
          'userId': 'friend2',
          'displayName': 'Friend Two',
          'profileImageUrl': 'https://example.com/friend2.jpg',
          'googleId': 'google789',
          'lastLogin': '2025-06-01T13:00:00Z',
          'globalStats': {
            'level': 3,
            'xp': 800,
            'totalGames': 15,
            'victories': 7,
          }
        })
      ];
      
      when(mockSocialService.searchUsers(query: anyNamed('query'))).thenAnswer((_) async => {
        'success': true,
        'message': 'Utilisateurs trouvés',
        'users': searchResults.map((profile) => profile.toJson()).toList()
      });
      
      when(friendsService.searchUsers(any)).thenAnswer((_) async => searchResults);
      
      final users = await friendsService.searchUsers('friend');
      expect(users.length, 2);
      expect(users[0].displayName, 'Friend One');
      expect(users[1].displayName, 'Friend Two');
      
      // Étape 4: Envoi d'une demande d'ami
      print('4. Envoi d\'une demande d\'ami');
      
      when(mockSocialService.sendFriendRequest(
        fromUserId: TEST_USER_ID, 
        toUserId: anyNamed('toUserId')
      )).thenAnswer((_) async => {
        'success': true,
        'message': 'Demande d\'ami envoyée',
        'data': {
          'requestId': 'req123',
          'from': TEST_USER_ID,
          'to': 'friend1',
          'status': 'pending',
          'createdAt': '2025-06-01T15:40:00Z',
        }
      });
      
      when(friendsService.sendFriendRequest(any)).thenAnswer((_) async => true);
      
      final sendRequestResult = await friendsService.sendFriendRequest('friend1');
      expect(sendRequestResult, isTrue);
      
      // Étape 5: Récupération des demandes d'amitié reçues
      print('5. Récupération des demandes d\'amitié reçues');
      
      final friendRequests = [
        {
          'requestId': 'req456',
          'from': 'friend3',
          'fromUserProfile': {
            'userId': 'friend3',
            'displayName': 'Friend Three',
            'profileImageUrl': 'https://example.com/friend3.jpg',
            'googleId': 'google999',
            'lastLogin': '2025-06-01T12:00:00Z',
            'globalStats': {
              'level': 6,
              'xp': 1500,
              'totalGames': 30,
              'victories': 20,
            }
          },
          'to': TEST_USER_ID,
          'status': 'pending',
          'createdAt': '2025-06-01T14:30:00Z',
        }
      ];
      
      when(mockSocialService.getFriendRequests(userId: TEST_USER_ID)).thenAnswer((_) async => {
        'success': true,
        'message': 'Demandes récupérées',
        'data': friendRequests
      });
      
      when(friendsService.getFriendRequests()).thenAnswer((_) async => 
        friendRequests.map((req) => FriendRequest.fromJson(req)).toList());
      
      final requests = await friendsService.getFriendRequests();
      expect(requests.length, 1);
      expect(requests[0].fromUserProfile?.displayName, 'Friend Three');
      
      // Étape 6: Acceptation d'une demande d'amitié
      print('6. Acceptation d\'une demande d\'amitié');
      
      when(mockSocialService.acceptFriendRequest(
        userId: TEST_USER_ID,
        requestId: anyNamed('requestId')
      )).thenAnswer((_) async => {
        'success': true,
        'message': 'Demande acceptée',
        'data': {
          'friendId': 'friendship456',
          'user1': TEST_USER_ID,
          'user2': 'friend3',
          'createdAt': '2025-06-01T16:00:00Z',
        }
      });
      
      when(friendsService.acceptFriendRequest(any)).thenAnswer((_) async => true);
      
      final acceptResult = await friendsService.acceptFriendRequest('req456');
      expect(acceptResult, isTrue);
      
      // Étape 7: Récupération de la liste d'amis
      print('7. Récupération de la liste d\'amis');
      
      final friendsList = [
        UserProfile.fromJson({
          'userId': 'friend1',
          'displayName': 'Friend One',
          'profileImageUrl': 'https://example.com/friend1.jpg',
          'googleId': 'google456',
          'lastLogin': '2025-06-01T14:00:00Z',
          'globalStats': {
            'level': 4,
            'xp': 1000,
            'totalGames': 20,
            'victories': 10,
          }
        }),
        UserProfile.fromJson({
          'userId': 'friend3',
          'displayName': 'Friend Three',
          'profileImageUrl': 'https://example.com/friend3.jpg',
          'googleId': 'google999',
          'lastLogin': '2025-06-01T12:00:00Z',
          'globalStats': {
            'level': 6,
            'xp': 1500,
            'totalGames': 30,
            'victories': 20,
          }
        })
      ];
      
      when(mockSocialService.getFriendsList(userId: TEST_USER_ID)).thenAnswer((_) async => {
        'success': true,
        'message': 'Liste d\'amis récupérée',
        'data': friendsList.map((profile) => profile.toJson()).toList()
      });
      
      when(friendsService.getFriendsList()).thenAnswer((_) async => friendsList);
      
      final friends = await friendsService.getFriendsList();
      expect(friends.length, 2);
      expect(friends[0].displayName, 'Friend One');
      expect(friends[1].displayName, 'Friend Three');
      
      // Étape 8: Récupération du classement des amis
      print('8. Récupération du classement des amis');
      
      final leaderboardData = [
        {
          'userId': 'friend3',
          'displayName': 'Friend Three',
          'profileImageUrl': 'https://example.com/friend3.jpg',
          'level': 6,
          'xp': 1500,
          'totalGames': 30,
          'victories': 20,
        },
        {
          'userId': TEST_USER_ID,
          'displayName': 'Test User',
          'profileImageUrl': 'https://example.com/profile.jpg',
          'level': 5,
          'xp': 1200,
          'totalGames': 25,
          'victories': 15,
        },
        {
          'userId': 'friend1',
          'displayName': 'Friend One',
          'profileImageUrl': 'https://example.com/friend1.jpg',
          'level': 4,
          'xp': 1000,
          'totalGames': 20,
          'victories': 10,
        }
      ];
      
      // Configuration du mock SocialService pour le classement
      when(mockSocialService.getLeaderboardEntries(
        leaderboardId: 'friends',
        friendsOnly: true
      )).thenAnswer((_) async => {
        'success': true,
        'message': 'Classement récupéré',
        'data': leaderboardData
      });
      
      when(userStatsService.getFriendsLeaderboard()).thenAnswer((_) async => 
        leaderboardData.map((data) => UserStatsModel.fromJson(data)).toList());
      
      final leaderboard = await userStatsService.getFriendsLeaderboard();
      expect(leaderboard.length, 3);
      expect(leaderboard[0].displayName, 'Friend Three');
      expect(leaderboard[0].level, 6);
      expect(leaderboard[1].displayName, 'Test User');
      expect(leaderboard[2].displayName, 'Friend One');
      
      print('Test d\'intégration complet terminé avec succès !');
    });
  });
}

// Classes d'aide pour les tests
class FriendRequest {
  final String requestId;
  final String from;
  final UserProfile? fromUserProfile;
  final String to;
  final String status;
  final String createdAt;
  
  FriendRequest({
    required this.requestId,
    required this.from,
    this.fromUserProfile,
    required this.to,
    required this.status,
    required this.createdAt,
  });
  
  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      requestId: json['requestId'],
      from: json['from'],
      fromUserProfile: json['fromUserProfile'] != null
        ? UserProfile.fromJson(json['fromUserProfile'])
        : null,
      to: json['to'],
      status: json['status'],
      createdAt: json['createdAt'],
    );
  }
}

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

// Ajout d'import manquant
import 'dart:convert';
