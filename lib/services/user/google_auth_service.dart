// lib/services/user/google_auth_service.dart

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:games_services/games_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_services.dart';

/// Service pour gérer l'authentification Google et l'obtention de tokens.
/// Cette classe est maintenue pour compatibilité avec le code existant,
/// mais délègue la plupart de ses fonctionnalités au nouveau AuthService.
class GoogleAuthService extends ChangeNotifier {
  // Instance du service d'authentification API
  final AuthService _authService;
  
  // Instance de Google Sign In
  final GoogleSignIn _googleSignIn;
  
  // Instance du service d'analytique
  final AnalyticsService _analyticsService;

  // Clés pour les préférences partagées
  static const String _playerInfoKey = 'google_player_info';
  static const String _lastSignInKey = 'last_google_signin';

  // Accesseurs
  bool get isSignedIn => _authService.isAuthenticated;
  String? get userId => _authService.userId;
  String? get username => _authService.username;

  /// Constructeur avec injection de dépendances pour faciliter les tests.
  GoogleAuthService({
    AuthService? authService,
    GoogleSignIn? googleSignIn,
    AnalyticsService? analyticsService,
  }) : 
        _authService = authService ?? AuthService(),
        _googleSignIn = googleSignIn ?? GoogleSignIn(
          scopes: ['email', 'profile'],
        ),
        _analyticsService = analyticsService ?? AnalyticsService() {
    // Vérifier l'état d'authentification au démarrage
    _checkAuthStatus();
  }

  /// Vérifie l'état d'authentification actuel
  Future<void> _checkAuthStatus() async {
    try {
      // Vérifier si l'utilisateur est authentifié via le service API
      if (_authService.isAuthenticated) {
        notifyListeners();
        return;
      }

      // Ensuite vérifier Google Play Games
      final isPlayGamesSignedIn = await GamesServices.isSignedIn;
      if (isPlayGamesSignedIn) {
        notifyListeners();
        return;
      }

      // Enfin, vérifier le cache local
      final prefs = await SharedPreferences.getInstance();
      final lastSignInTimeStr = prefs.getString(_lastSignInKey);

      if (lastSignInTimeStr != null) {
        final lastSignIn = DateTime.parse(lastSignInTimeStr);
        // Si la dernière connexion date de moins de 7 jours, considérer comme connecté
        if (DateTime.now().difference(lastSignIn).inDays < 7) {
          notifyListeners();
          return;
        }
      }

      notifyListeners();
    } catch (e, stack) {
      debugPrint('Erreur lors de la vérification de l\'état de connexion: $e');
      _analyticsService.recordError(e, stack, reason: 'Auth status check error');
      notifyListeners();
    }
  }

  /// Vérifie si l'utilisateur est actuellement connecté à Google.
  Future<bool> isUserSignedIn() async {
    return _isSignedIn;
  }

  /// Obtient l'ID Google de l'utilisateur connecté.
  Future<String?> getGoogleId() async {
    try {
      // Essayer d'obtenir l'ID via AuthService
      final userId = _authService.userId;
      if (userId != null) {
        return userId;
      }

      // Sinon, essayer via Google Sign-In
      final googleAccount = await _googleSignIn.signInSilently();
      if (googleAccount != null) {
        return googleAccount.id;
      }

      return null;
    } catch (e) {
      debugPrint('Erreur lors de l\'obtention de l\'ID Google: $e');
      return null;
    }
  }

  /// Obtient les informations de profil Google.
  Future<Map<String, dynamic>?> getGoogleProfileInfo() async {
    try {
      // Essayer d'obtenir les infos via AuthService
      final userId = _authService.userId;
      final username = _authService.username;
      final email = _authService.email;
      final photoUrl = _authService.photoUrl;
      
      if (userId != null) {
        return {
          'id': userId,
          'displayName': username,
          'email': email,
          'photoUrl': photoUrl,
        };
      }

      // Sinon, essayer via Google Sign-In
      final googleAccount = await _googleSignIn.signInSilently();
      if (googleAccount != null) {
        final googleAuth = await googleAccount.authentication;
        return {
          'id': googleAccount.id,
          'displayName': googleAccount.displayName,
          'email': googleAccount.email,
          'photoUrl': googleAccount.photoUrl,
          'accessToken': googleAuth.accessToken,
        };
      }

      return null;
    } catch (e) {
      debugPrint('Erreur lors de l\'obtention des infos de profil: $e');
      return null;
    }
  }

  /// Obtient un token d'accès pour les API Google.
  Future<String?> getGoogleAccessToken() async {
    try {
      // Vérifier si le token en cache est encore valide
      if (_cachedAccessToken != null && _tokenExpirationTime != null) {
        if (_tokenExpirationTime!.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
          return _cachedAccessToken;
        }
      }

      // Token pas en cache ou expiré, en obtenir un nouveau
      if (_auth.currentUser != null) {
        final idToken = await _auth.currentUser!.getIdToken();
        _cachedAccessToken = idToken;
        _tokenExpirationTime = DateTime.now().add(const Duration(minutes: 55));
        return _cachedAccessToken;
      }

      // Si l'utilisateur est connecté via Google Sign-In
      final googleAccount = await _googleSignIn.signInSilently();
      if (googleAccount != null) {
        final googleAuth = await googleAccount.authentication;
        _cachedAccessToken = googleAuth.accessToken;
        _tokenExpirationTime = DateTime.now().add(const Duration(minutes: 55));
        return _cachedAccessToken;
      }

      _cachedAccessToken = null;
      _tokenExpirationTime = null;
      return null;
    } catch (e) {
      debugPrint('Erreur lors de l\'obtention du token Google: $e');
      _cachedAccessToken = null;
      _tokenExpirationTime = null;
      return null;
    }
  }

  /// Se connecte avec Google en utilisant AuthService ou Google Play Games.
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      debugPrint('Démarrage du processus de connexion Google');

      // Essayer d'abord Google Play Games
      try {
        debugPrint('Tentative avec Google Play Games...');
        await GamesServices.signIn();
        final isPlayGamesSignedIn = await GamesServices.isSignedIn;

        if (isPlayGamesSignedIn) {
          debugPrint('Connexion réussie via Google Play Games');

          // Marquer comme connecté
          _isSignedIn = true;
          notifyListeners();

          // Sauvegarder le timestamp de connexion
          _saveLastSignInTime();

          // Quand on utilise Games Services, nous n'avons pas toutes les infos
          // Donc on crée un objet avec des infos minimales
          return {
            'id': 'gps_${DateTime.now().millisecondsSinceEpoch}', // ID unique
            'displayName': 'Joueur Google',
            'email': null,
            'photoUrl': null,
          };
        }
      } catch (e) {
        debugPrint('Échec Google Play Games : $e');
        // Continuer avec AuthService
      }

      // Sinon, essayer AuthService
      debugPrint('Tentative avec AuthService...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('L\'utilisateur a annulé la connexion Google');
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Utiliser AuthService pour se connecter avec Google
      final success = await _authService.signInWithGoogle();
      
      if (!success) {
        debugPrint('AuthService n\'a pas réussi à authentifier l\'utilisateur');
        return null;
      }

      // Marquer comme connecté
      _isSignedIn = true;
      notifyListeners();

      // Sauvegarder le timestamp de connexion
      _saveLastSignInTime();

      // Récupérer les informations utilisateur depuis AuthService
      final userId = _authService.userId;
      final username = _authService.username;
      
      debugPrint('Connexion réussie via AuthService: $username');
      return {
        'id': userId,
        'displayName': username,
        'email': googleUser.email,
        'photoUrl': googleUser.photoUrl,
      };
    } catch (e, stack) {
      debugPrint('Erreur détaillée de connexion Google: $e');
      debugPrint('Stack trace: $stack');

      // Enregistrer l'erreur dans AnalyticsService
      _analyticsService.recordError(e, stack, reason: 'Google sign-in error');

      return null;
    }
  }

  /// Se déconnecte de Google.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      _cachedAccessToken = null;
      _tokenExpirationTime = null;

      // Enlever le timestamp de dernière connexion
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastSignInKey);

      _isSignedIn = false;
      notifyListeners();
    } catch (e, stack) {
      debugPrint('Erreur de déconnexion: $e');
      _analyticsService.recordError(e, stack, reason: 'Google sign-out error');
    }
  }

  /// Sauvegarde l'heure de la dernière connexion
  Future<void> _saveLastSignInTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSignInKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde de la date de connexion: $e');
    }
  }
}