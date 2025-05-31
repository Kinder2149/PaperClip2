// lib/services/api/auth_service.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  
  // Inscription avec email et mot de passe
  Future<bool> register(String email, String password, String username) async {
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
  
  // Connexion avec Google
  Future<bool> signInWithGoogle() async {
    try {
      // Déclencher le flux de connexion Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return false;
      }
      
      // Obtenir les informations d'authentification
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Connexion au backend avec les informations Google
      final data = await _apiClient.loginWithProvider(
        'google',
        googleUser.id,
        googleUser.email,
        username: googleUser.displayName,
        profileImageUrl: googleUser.photoUrl,
      );
      
      _userId = data['user_id'];
      _username = data['username'];
      _isAdmin = data['is_admin'] ?? false;
      
      authStateChanged.value = true;
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la connexion avec Google: $e');
      return false;
    }
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
