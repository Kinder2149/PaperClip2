// lib/services/api/auth_service.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../env_config.dart';
import '../../config/api_config.dart';
import 'api_client.dart';

/// Service d'authentification utilisant le backend personnalisé
/// Remplace les fonctionnalités de Firebase Auth
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  // Client API
  final ApiClient _apiClient = ApiClient();
  
  // Google Sign In
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  
  // État interne
  String? _userId;
  String? _username;
  bool _isAdmin = false;
  
  // Événements de changement
  final ValueNotifier<bool> authStateChanged = ValueNotifier<bool>(false);
  
  // Getters
  bool get isAuthenticated => _apiClient.isAuthenticated;
  String? get userId => _userId;
  String? get username => _username;
  bool get isAdmin => _isAdmin;
  
  // Getters supplémentaires pour la compatibilité avec Google Auth
  String? get email => null; // À remplacer par la valeur réelle quand disponible
  String? get photoUrl => null; // À remplacer par la valeur réelle quand disponible
  
  // Constructeur interne
  AuthService._internal();
  
  // Initialisation du service
  Future<void> initialize() async {
    await _apiClient.initialize();
    
    if (_apiClient.isAuthenticated) {
      await _loadUserInfo();
    }
    
    authStateChanged.value = _apiClient.isAuthenticated;
  }
  
  // Chargement des informations utilisateur
  Future<void> _loadUserInfo() async {
    try {
      final userData = await _apiClient.get('/auth/me');
      
      _userId = userData['id'];
      _username = userData['username'];
      _isAdmin = userData['is_admin'] ?? false;
    } catch (e) {
      debugPrint('Erreur lors du chargement des informations utilisateur: $e');
      await _apiClient.clearAuthToken();
    }
  }
  
  // Inscription avec email et mot de passe - méthode simplifiée
  Future<bool> registerSimple(String email, String password, String username) async {
    try {
      final data = await _apiClient.register(email, password, username);
      
      _userId = data['user_id'];
      _username = data['username'];
      _isAdmin = data['is_admin'] ?? false;
      
      authStateChanged.value = true;
      return true;
    } catch (e) {
      debugPrint('Erreur lors de l\'inscription: $e');
      return false;
    }
  }
  
  // Connexion avec email et mot de passe
  Future<bool> login(String email, String password) async {
    try {
      final data = await _apiClient.login(email, password);
      
      _userId = data['user_id'];
      _username = data['username'];
      _isAdmin = data['is_admin'] ?? false;
      
      authStateChanged.value = true;
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la connexion: $e');
      return false;
    }
  }
  
  /// Connexion avec Google
  Future<bool> signInWithGoogle() async {
    try {
      debugPrint('=== AUTHENTIFICATION GOOGLE VIA AUTH SERVICE ===');
      
      // Vérification de la configuration
      final googleClientId = EnvConfig.googleClientId;
      final apiBaseUrl = ApiConfig.apiBaseUrl;
      
      debugPrint('Config - Google Client ID: ${googleClientId ?? "NON DÉFINI"}');
      debugPrint('Config - API Base URL: ${apiBaseUrl ?? "NON DÉFINI"}');
      
      if (googleClientId == null || googleClientId.isEmpty) {
        debugPrint('ERREUR: Google Client ID manquant dans la configuration');
      }
      
      if (apiBaseUrl == null || apiBaseUrl.isEmpty) {
        debugPrint('ERREUR: API Base URL manquante dans la configuration');
      }
      
      // Récupérer un compte Google via GoogleSignIn
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        debugPrint('Aucun compte Google sélectionné');
        return false;
      }

      debugPrint('Compte Google obtenu: ${googleUser.displayName} (${googleUser.email})');
      
      // Obtenir les informations d'authentification
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Vérifier qu'on a bien un token
      if (googleAuth.accessToken == null) {
        debugPrint('ERREUR: Pas de token d\'accès Google');
        return false;
      }
      
      debugPrint('Token Google obtenu avec succès');

      // Envoyer les informations au backend
      debugPrint('Envoi des informations au backend...');
      try {
        final result = await _apiClient.loginWithProvider(
          'google',
          googleUser.id,
          googleUser.email,
          username: googleUser.displayName,
          profileImageUrl: googleUser.photoUrl,
        );
        
        debugPrint('Réponse du backend: $result');

        // Si la connexion réussit, stocker les informations
        if (result.containsKey('access_token') && result.containsKey('expires_at')) {
          _userId = result['user_id'];
          _username = result['username'];
          _isAdmin = result['is_admin'] ?? false;
          authStateChanged.value = true;
          debugPrint('Connexion réussie pour l\'utilisateur: $_username');
          return true;
        } else {
          debugPrint('Réponse du backend incorrecte: Token manquant');
          if (result.containsKey('error')) {
            debugPrint('Erreur du backend: ${result["error"]}');
          }
        }
      } catch (e) {
        debugPrint('Erreur lors de l\'appel au backend: $e');
        // On continue pour essayer une approche alternative
      }
      
      // Approche alternative pour le débogage - tenter d'utiliser directement le token
      try {
        debugPrint('Tentative directe avec le token Google...');
        final url = '$apiBaseUrl/auth/provider';
        final headers = {
          'Content-Type': 'application/json',
        };
        
        final body = json.encode({
          'provider': 'google',
          'token': googleAuth.accessToken,
          'id': googleUser.id,
          'email': googleUser.email,
          'username': googleUser.displayName,
          'profile_image_url': googleUser.photoUrl,
        });
        
        debugPrint('URL: $url');
        debugPrint('Body: $body');
        
        final response = await http.post(
          Uri.parse(url),
          headers: headers,
          body: body,
        );
        
        debugPrint('Statut de la réponse: ${response.statusCode}');
        debugPrint('Contenu de la réponse: ${response.body}');
        
        if (response.statusCode == 200) {
          final result = json.decode(response.body);
          if (result.containsKey('access_token') && result.containsKey('expires_at')) {
            _userId = result['user_id'];
            _username = result['username'];
            _isAdmin = result['is_admin'] ?? false;
            authStateChanged.value = true;
            debugPrint('Connexion alternative réussie');
            return true;
          }
        }
      } catch (e) {
        debugPrint('Erreur lors de la tentative alternative: $e');
      }

      return false;
    } catch (e, stack) {
      debugPrint('Erreur globale lors de la connexion Google: $e');
      debugPrint('Stack trace: $stack');
      return false;
    }
  }
  
  // Enregistrement d'un nouvel utilisateur avec plus d'options
  Future<Map<String, dynamic>> registerFull(String displayName, String? email, String? password) async {
    try {
      final data = await _apiClient.post(
        '/auth/register',
        body: {
          'username': displayName,
          'email': email ?? '',
          'password': password ?? '',
        },
      );
      
      if (data['access_token'] != null) {
        // Configurer l'authentification
        await _saveAuthToken(data['access_token'], DateTime.now().add(Duration(hours: 24)));
        
        _userId = data['user_id'];
        _username = data['username'];
        authStateChanged.value = true;
      }
      
      return data;
    } catch (e) {
      debugPrint('Erreur lors de l\'enregistrement: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
  
  // Mise à jour du profil utilisateur
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final data = await _apiClient.put(
        '/users/$_userId',
        body: profileData,
      );
      
      return data;
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour du profil: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
  
  // Récupération du profil utilisateur
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final data = await _apiClient.get('/users/$userId');
      return data;
    } catch (e) {
      debugPrint('Erreur lors de la récupération du profil: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
  
  // Mise à jour du profil utilisateur complet
  Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> profileData) async {
    return updateProfile(profileData);
  }
  
  // Lier le compte à Google
  Future<Map<String, dynamic>> linkWithGoogle() async {
    try {
      // Déclencher le flux de connexion Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return {'success': false, 'message': 'Google sign-in cancelled'};
      }
      
      // Obtenir les informations d'authentification
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Lier au backend avec les informations Google
      final data = await _apiClient.post(
        '/auth/link/google',
        body: {
          'google_id': googleUser.id,
          'email': googleUser.email,
          'display_name': googleUser.displayName,
          'profile_image_url': googleUser.photoUrl,
        },
      );
      
      return data;
    } catch (e) {
      debugPrint('Erreur lors de la liaison avec Google: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
  
  // Sauvegarder le token d'authentification
  Future<void> _saveAuthToken(String token, DateTime expiration) async {
    await _apiClient.setAuthToken(token, expiration);
  }
  
  // Récupérer le token d'authentification (pour compatibilité avec l'ancien code)
  Future<String?> getIdToken() async {
    return _apiClient.authToken;
  }
  
  // Déconnexion
  Future<void> logout() async {
    try {
      // Déconnexion du backend
      await _apiClient.logout();
      
      // Déconnexion de Google si connecté
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      debugPrint('Erreur lors de la déconnexion: $e');
    } finally {
      // Réinitialiser l'état local
      _userId = null;
      _username = null;
      _isAdmin = false;
      
      authStateChanged.value = false;
    }
  }
  
  // Changement de mot de passe
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      await _apiClient.post(
        '/auth/change-password',
        body: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
      
      return true;
    } catch (e) {
      debugPrint('Erreur lors du changement de mot de passe: $e');
      return false;
    }
  }
  
  // Demande de réinitialisation de mot de passe
  Future<bool> resetPasswordRequest(String email) async {
    try {
      await _apiClient.post(
        '/auth/reset-password',
        body: {'email': email},
        requiresAuth: false,
      );
      
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la demande de réinitialisation: $e');
      return false;
    }
  }
  
  // Confirmation de réinitialisation de mot de passe
  Future<bool> resetPasswordConfirm(String token, String newPassword) async {
    try {
      await _apiClient.post(
        '/auth/reset-password/confirm',
        body: {
          'token': token,
          'new_password': newPassword,
        },
        requiresAuth: false,
      );
      
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la confirmation de réinitialisation: $e');
      return false;
    }
  }
  
  // Vérification d'email
  Future<bool> verifyEmail(String token) async {
    try {
      await _apiClient.post(
        '/auth/verify-email/$token',
        requiresAuth: false,
      );
      
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la vérification d\'email: $e');
      return false;
    }
  }
}
