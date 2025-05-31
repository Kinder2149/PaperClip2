// lib/services/user/google_auth_service_new.dart

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

  /// Vérifie si l'utilisateur est actuellement connecté.
  Future<bool> isUserSignedIn() async {
    return _authService.isAuthenticated;
  }

  /// Obtient l'ID Google de l'utilisateur connecté.
  Future<String?> getGoogleId() async {
    try {
      // Essayer d'obtenir l'ID via le service d'authentification
      if (_authService.isAuthenticated) {
        return _authService.userId;
      }

      // Sinon, essayer via Google Sign-In
      final googleAccount = await _googleSignIn.signInSilently();
      if (googleAccount != null) {
        return googleAccount.id;
      }

      return null;
    } catch (e, stack) {
      debugPrint('Erreur lors de l\'obtention de l\'ID Google: $e');
      _analyticsService.recordError(e, stack, reason: 'Google ID retrieval error');
      return null;
    }
  }

  /// Obtient les informations de profil Google.
  Future<Map<String, dynamic>?> getGoogleProfileInfo() async {
    try {
      // Essayer d'obtenir les infos via le service d'authentification
      if (_authService.isAuthenticated) {
        final userData = await _authService.getUserInfo();
        return {
          'id': userData['id'],
          'displayName': userData['username'],
          'email': userData['email'],
          'photoUrl': userData['profile_image_url'],
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
    } catch (e, stack) {
      debugPrint('Erreur lors de l\'obtention des infos de profil: $e');
      _analyticsService.recordError(e, stack, reason: 'Profile info retrieval error');
      return null;
    }
  }

  /// Obtient un token d'accès pour les API Google.
  Future<String?> getGoogleAccessToken() async {
    try {
      // Essayer via Google Sign-In
      final googleAccount = await _googleSignIn.signInSilently();
      if (googleAccount != null) {
        final googleAuth = await googleAccount.authentication;
        return googleAuth.accessToken;
      }

      return null;
    } catch (e, stack) {
      debugPrint('Erreur lors de l\'obtention du token Google: $e');
      _analyticsService.recordError(e, stack, reason: 'Google token retrieval error');
      return null;
    }
  }

  /// Se connecte avec Google en utilisant le service d'authentification API.
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
        // Continuer avec le service d'authentification API
      }

      // Sinon, essayer le service d'authentification API
      debugPrint('Tentative avec le service d\'authentification API...');
      final success = await _authService.signInWithGoogle();
      
      if (!success) {
        debugPrint('L\'utilisateur a annulé la connexion Google ou une erreur s\'est produite');
        return null;
      }

      // Sauvegarder le timestamp de connexion
      _saveLastSignInTime();
      
      // Récupérer les informations utilisateur
      final userData = await _authService.getUserInfo();
      
      // Notifier les écouteurs
      notifyListeners();
      
      return {
        'id': userData['id'],
        'displayName': userData['username'],
        'email': userData['email'],
        'photoUrl': userData['profile_image_url'],
      };
    } catch (e, stack) {
      debugPrint('Erreur lors de la connexion avec Google: $e');
      _analyticsService.recordError(e, stack, reason: 'Google sign-in error');
      return null;
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    try {
      // Déconnexion du service d'authentification API
      await _authService.logout();
      
      // Déconnexion de Google si connecté
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      
      // Déconnexion de Google Play Games si connecté
      if (await GamesServices.isSignedIn) {
        await GamesServices.signOut();
      }
      
      notifyListeners();
    } catch (e, stack) {
      debugPrint('Erreur lors de la déconnexion: $e');
      _analyticsService.recordError(e, stack, reason: 'Sign-out error');
    }
  }
  
  /// Sauvegarde le timestamp de la dernière connexion
  Future<void> _saveLastSignInTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSignInKey, DateTime.now().toIso8601String());
    } catch (e, stack) {
      debugPrint('Erreur lors de la sauvegarde du timestamp de connexion: $e');
      _analyticsService.recordError(e, stack, reason: 'Last sign-in time save error');
    }
  }
}
