// lib/services/user/google_auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:games_services/games_services.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Service pour gérer l'authentification Google et l'obtention de tokens.
///
/// Cette classe permet de se connecter via Google, de vérifier l'état de connexion,
/// et d'obtenir des tokens d'accès pour les API Google.
class GoogleAuthService {
  // Instances privées des services d'authentification
  late final FirebaseAuth _auth;
  late final GoogleSignIn _googleSignIn;
  // Note: Nous ne stockons plus _gamesServices comme instance

  // Cache pour le token d'accès
  String? _cachedAccessToken;
  DateTime? _tokenExpirationTime;

  /// Constructeur avec injection de dépendances pour faciliter les tests.
  ///
  /// Utilise les instances par défaut si aucune dépendance n'est fournie.
  GoogleAuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  }) {
    _auth = auth ?? FirebaseAuth.instance;
    _googleSignIn = googleSignIn ?? GoogleSignIn(
      scopes: ['email', 'profile'],
    );
  }

  /// Vérifie si l'utilisateur est actuellement connecté à Google.
  ///
  /// Retourne `true` si l'utilisateur est connecté à Firebase Auth
  /// ou à Google Play Games, sinon `false`.
  Future<bool> isUserSignedIn() async {
    try {
      // Vérifier l'état de connexion Firebase
      final firebaseUser = _auth.currentUser;

      // Vérifier l'état de connexion Google Play Games
      // Accéder au getter statique directement via la classe
      final gamesSignedIn = await GamesServices.isSignedIn;

      return firebaseUser != null || gamesSignedIn;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la vérification de l\'état de connexion: $e');
      }
      return false;
    }
  }

  /// Obtient l'ID Google de l'utilisateur connecté.
  ///
  /// Retourne l'UID Firebase ou l'ID du joueur Google Play Games
  /// si disponible, sinon `null`.
  Future<String?> getGoogleId() async {
    try {
      // Essayer d'obtenir l'ID via Firebase d'abord
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        return firebaseUser.uid;
      }

      // Sinon, essayer via Google Sign-In
      final googleAccount = await _googleSignIn.signInSilently();
      if (googleAccount != null) {
        return googleAccount.id;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'obtention de l\'ID Google: $e');
      }
      return null;
    }
  }

  /// Obtient les informations de profil Google.
  ///
  /// Retourne un Map contenant les informations du profil si disponible,
  /// sinon `null`.
  Future<Map<String, dynamic>?> getGoogleProfileInfo() async {
    try {
      // Essayer d'obtenir les infos via Firebase d'abord
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        return {
          'id': firebaseUser.uid,
          'displayName': firebaseUser.displayName,
          'email': firebaseUser.email,
          'photoUrl': firebaseUser.photoURL,
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
      if (kDebugMode) {
        print('Erreur lors de l\'obtention des infos de profil: $e');
      }
      return null;
    }
  }

  /// Obtient un token d'accès pour les API Google.
  ///
  /// Ce token peut être utilisé pour les requêtes vers les API Google
  /// comme Google Drive. Utilise un cache pour éviter les requêtes inutiles.
  Future<String?> getGoogleAccessToken() async {
    try {
      // Vérifier si le token en cache est encore valide
      if (_cachedAccessToken != null && _tokenExpirationTime != null) {
        if (_tokenExpirationTime!.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
          // Token encore valide avec au moins 5 minutes de marge
          return _cachedAccessToken;
        }
      }

      // Token pas en cache ou expiré, en obtenir un nouveau
      if (_auth.currentUser != null) {
        // Obtenir le token via Firebase Auth
        final idToken = await _auth.currentUser!.getIdToken();
        _cachedAccessToken = idToken;
        // Estimer l'expiration (typiquement 1 heure)
        _tokenExpirationTime = DateTime.now().add(const Duration(minutes: 55));
        return _cachedAccessToken;
      }

      // Si l'utilisateur est connecté via Google Sign-In
      final googleAccount = await _googleSignIn.signInSilently();
      if (googleAccount != null) {
        final googleAuth = await googleAccount.authentication;
        _cachedAccessToken = googleAuth.accessToken;
        // Estimer l'expiration (typiquement 1 heure)
        _tokenExpirationTime = DateTime.now().add(const Duration(minutes: 55));
        return _cachedAccessToken;
      }

      // Réinitialiser le cache si on ne peut pas obtenir de token
      _cachedAccessToken = null;
      _tokenExpirationTime = null;
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'obtention du token Google: $e');
      }
      _cachedAccessToken = null;
      _tokenExpirationTime = null;
      return null;
    }
  }

  /// Se connecte avec Google en utilisant Firebase Auth ou Google Play Games.
  ///
  /// Retourne un Map contenant les informations de profil si la connexion réussit,
  /// sinon `null`.
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      // Essayer d'abord Google Play Games
      try {
        await GamesServices.signIn();
        final isPlayGamesSignedIn = await GamesServices.isSignedIn;

        // Si Google Play Games fonctionne, retourner ces infos
        if (isPlayGamesSignedIn) {
          return await getGoogleProfileInfo();
        }
      } catch (e) {
        if (kDebugMode) {
          print('Erreur de connexion Google Play Games: $e');
        }
        // Continuer avec Firebase Auth si Google Play Games échoue
      }

      // Sinon, essayer Firebase Auth
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) return null;

      return {
        'id': user.uid,
        'displayName': user.displayName,
        'email': user.email,
        'photoUrl': user.photoURL,
      };
    } catch (e, stack) {
      if (kDebugMode) {
        print('Erreur de connexion Google: $e');
        print('Stack: $stack');
      }

      // Enregistrer l'erreur dans Crashlytics si disponible
      try {
        FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Google sign-in error');
      } catch (_) {
        // Ignorer les erreurs Crashlytics
      }

      return null;
    }
  }

  /// Se déconnecte de Google.
  ///
  /// Déconnecte l'utilisateur de Firebase Auth et Google Sign-In.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      _cachedAccessToken = null;
      _tokenExpirationTime = null;
    } catch (e, stack) {
      if (kDebugMode) {
        print('Erreur de déconnexion: $e');
      }

      // Enregistrer l'erreur dans Crashlytics si disponible
      try {
        FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Google sign-out error');
      } catch (_) {
        // Ignorer les erreurs Crashlytics
      }
    }
  }
}