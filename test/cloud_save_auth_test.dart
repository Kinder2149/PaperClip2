// test/cloud_save_auth_test.dart

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:games_services/games_services.dart' hide SaveGame;
import 'package:http/http.dart' as http;

// Importation des services et managers à tester
import 'package:paperclip2/services/user/google_auth_service.dart';
import 'package:paperclip2/services/user/user_manager.dart';
import 'package:paperclip2/services/user/user_profile.dart';
import 'package:paperclip2/services/google_drive_service.dart';
import 'package:paperclip2/services/games_services_controller.dart';
import 'package:paperclip2/services/save_manager.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/models/game_config.dart';

// Générer les mocks pour les classes simples
@GenerateMocks([
  GoogleSignIn,
  GoogleSignInAccount,
  GoogleSignInAuthentication,
  http.Client,
  GameState
])
import 'cloud_save_auth_test.mocks.dart';

// Mocks manuels pour Firebase et GamesServicesController
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {
  @override
  String get uid => '12345';

  @override
  String? get displayName => 'Utilisateur Test';

  @override
  String? get email => 'test@example.com';

  @override
  String? get photoURL => null;

  @override
  Future<String> getIdToken([bool forceRefresh = false]) async => 'mock-id-token';
}

class MockGamesServicesController extends Mock implements GamesServicesController {
  @override
  Future<bool> isSignedIn() async => true;

  @override
  Future<bool> signIn() async => true; // Changé en Future<bool> pour correspondre à la signature dans GamesServicesController
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockGoogleSignIn mockGoogleSignIn;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockGamesServicesController mockGamesServices;
  late MockClient mockHttpClient;
  late UserManager userManager;
  late MockGameState mockGameState;
  late GoogleAuthService authService;
  late GoogleDriveService driveService;

  setUp(() async {
    // Initialiser les mocks
    mockGoogleSignIn = MockGoogleSignIn();
    mockFirebaseAuth = MockFirebaseAuth();
    mockGamesServices = MockGamesServicesController();
    mockHttpClient = MockClient();

    // Configurer SharedPreferences pour les tests
    SharedPreferences.setMockInitialValues({});

    // Initialiser le mockGameState
    mockGameState = MockGameState();

    // Créer les services avec dépendances injectées
    // Remarque: Utilisez seulement les paramètres qui existent réellement dans votre GoogleAuthService
    authService = GoogleAuthService(
      auth: mockFirebaseAuth,
      googleSignIn: mockGoogleSignIn,
      // Ne pas inclure gamesServices si ce paramètre n'existe pas
    );

    // Injecter manuellement _gamesServices
    injectGamesServices(authService, mockGamesServices);

    driveService = GoogleDriveService();
    userManager = UserManager();

    // Injecter les dépendances pour driveService
    injectHttpClient(driveService, mockHttpClient);
  });

  group('Tests d\'authentification Google', () {
    test('Obtention du token d\'accès', () async {
      // Configurer les mocks pour simuler une connexion Google
      final mockAccount = MockGoogleSignInAccount();
      final mockAuth = MockGoogleSignInAuthentication();
      final mockUser = MockUser();

      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockGoogleSignIn.signInSilently()).thenAnswer((_) async => mockAccount);
      when(mockAccount.authentication).thenAnswer((_) async => mockAuth);
      when(mockAuth.accessToken).thenReturn('mock-access-token');

      // Exécuter la méthode d'obtention du token
      final token = await authService.getGoogleAccessToken();

      // Vérifier le résultat
      expect(token, equals('mock-id-token'));

      // Vérifier les appels
      verify(mockFirebaseAuth.currentUser).called(1);
    });

    test('Vérification de la connexion', () async {
      // Configurer les mocks
      when(mockFirebaseAuth.currentUser).thenReturn(MockUser());

      // Exécuter la méthode
      final isSignedIn = await authService.isUserSignedIn();

      // Vérifier le résultat
      expect(isSignedIn, isTrue);

      // Vérifier les appels
      verify(mockFirebaseAuth.currentUser).called(1);
    });
  });

  group('Tests de sauvegarde cloud', () {
    test('Initialisation du service Drive', () async {
      // Configurer les mocks pour la réponse HTTP
      when(mockHttpClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
          jsonEncode({'id': 'folder-id'}),
          200
      ));

      // Configurer les mocks pour la réponse HTTP de recherche de dossier
      when(mockHttpClient.get(
        any,
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response(
          jsonEncode({
            'files': [
              {'id': 'folder-id', 'name': 'ClipFactoryEmpire'}
            ]
          }),
          200
      ));

      // Tester l'initialisation (qui créera/trouvera le dossier)
      final result = await driveService.initialize('mock-token');

      // Vérifier que l'initialisation s'est bien passée
      expect(result, isTrue);
    });
  });
}

// Helper pour injecter le client HTTP
void injectHttpClient(GoogleDriveService driveService, http.Client httpClient) {
  final field = (driveService as dynamic);
  field._httpClient = httpClient;
}

// Helper pour injecter le GamesServicesController
void injectGamesServices(GoogleAuthService authService, GamesServicesController controller) {
  final field = (authService as dynamic);
  field._gamesServices = controller;
}