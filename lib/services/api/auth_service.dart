// lib/services/api/auth_service.dart

import 'dart:convert';
import 'dart:math'; // Pour Random.secure()
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'api_client.dart';
import '../../config/api_config.dart'; // Ajout de l'import manquant
import '../../env_config.dart';

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
  String? _email;
  String? _photoUrl;
  bool _isAdmin = false;
  
  // Événements de changement
  final ValueNotifier<bool> authStateChanged = ValueNotifier<bool>(false);
  
  // Accesseurs publics
  bool get isAuthenticated => _apiClient.isAuthenticated;
  String? get userId => _userId;
  String? get username => _username;
  String? get email => _email;
  String? get photoUrl => _photoUrl;
  bool get isAdmin => _isAdmin;
  
  // Accesseurs pour la gestion des tokens JWT (utilisés pour le rafraîchissement)
  String? get currentJwtToken => _apiClient.authToken;
  DateTime? get tokenExpiration => _apiClient.tokenExpiration;
  
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
  
  /// Connexion avec Google - Implémentation robuste avec échange de token
/// Paramètre silent: si true, tente une connexion silencieuse sans interface utilisateur
  Future<bool> signInWithGoogle({bool silent = false}) async {
    try {
      debugPrint('=== AUTHENTIFICATION GOOGLE VIA AUTH SERVICE ===');
      
      // Vérification de la configuration
      final googleClientId = EnvConfig.googleClientId;
      final apiBaseUrl = EnvConfig.apiBaseUrl;
      
      debugPrint('Config - Google Client ID: ${googleClientId ?? "NON DÉFINI"}');
      debugPrint('Config - API Base URL: ${apiBaseUrl ?? "NON DÉFINI"}');
      
      if (googleClientId == null || googleClientId.isEmpty) {
        debugPrint('ERREUR: Google Client ID manquant dans la configuration');
      }
      
      if (apiBaseUrl == null || apiBaseUrl.isEmpty) {
        debugPrint('ERREUR: API Base URL manquante dans la configuration');
      }
      
      // Récupérer un compte Google via GoogleSignIn
    GoogleSignInAccount? googleUser;
    
    if (silent) {
      // En mode silencieux, essayer de récupérer la session actuelle sans UI
      googleUser = await GoogleSignIn().signInSilently();
      debugPrint('Tentative de connexion silencieuse: ${googleUser != null ? "réussie" : "échouée"}');
    } else {
      // En mode normal, afficher l'interface de sélection de compte Google
      googleUser = await GoogleSignIn().signIn();
    }
    
    if (googleUser == null) {
      debugPrint('Aucun compte Google sélectionné ou session expirée');
      return false;
    }

      debugPrint('Compte Google obtenu: ${googleUser.displayName} (${googleUser.email})');
      
      // Obtenir les informations d'authentification complètes
      // Nous avons besoin à la fois de l'accessToken et de l'idToken pour une authentification sécurisée
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // L'idToken est crucial pour la vérification côté serveur
      if (googleAuth.idToken == null) {
        debugPrint('ERREUR: Pas de ID token Google');
        return false;
      }
      
      if (googleAuth.accessToken == null) {
        debugPrint('ERREUR: Pas de token d\'accès Google');
        return false;
      }
      
      debugPrint('Tokens Google obtenus avec succès');

      // Étape 1: Authentifier avec le backend en utilisant les tokens Google
      try {
        final Map<String, dynamic> bodyData = {
          'id_token': googleAuth.idToken,
          'provider': 'google',
          'provider_id': googleUser.id,
          'email': googleUser.email,
          'display_name': googleUser.displayName,
          'profile_image_url': googleUser.photoUrl,
        };

        debugPrint('Échange du token Google contre un JWT avec le backend...');
        
        final uri = Uri.parse('$apiBaseUrl/auth/oauth/google');
        
        final response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode(bodyData),
        );
        
        debugPrint('Statut de la réponse: ${response.statusCode}');
        
        if (response.statusCode >= 200 && response.statusCode < 300) {
          final result = json.decode(response.body);
          
          if (result.containsKey('access_token') && result.containsKey('expires_at')) {
            // Enregistrer le token dans l'API client pour les futures requêtes
            final String token = result['access_token'];
            final DateTime expiration = DateTime.parse(result['expires_at']);
            
            // Sauvegarder dans l'ApiClient
            await _saveAuthToken(token, expiration);
            
            // Stocker les informations utilisateur
            _userId = result['user_id'] ?? googleUser.id;
            _username = result['username'] ?? googleUser.displayName;
            _isAdmin = result['is_admin'] ?? false;
            
            // Notifier du changement d'état
            authStateChanged.value = true;
            
            debugPrint('Authentification réussie pour l\'utilisateur: $_username');
            return true;
          } else {
            debugPrint('Format de réponse invalide: $result');
          }
        } 
        // Cas où l'endpoint /auth/oauth/google n'existe pas encore
        else if (response.statusCode == 404) {
          debugPrint('Endpoint OAuth non disponible, fallback vers l\'ancienne méthode...');
          return await _legacyGoogleAuthentication(googleUser, googleAuth);
        }
        else {
          debugPrint('Erreur HTTP: ${response.statusCode}');
          debugPrint('Détails: ${response.body}');
          
          // On essaie la méthode de fallback si le nouvel endpoint échoue
          return await _legacyGoogleAuthentication(googleUser, googleAuth);
        }
      } catch (e) {
        debugPrint('Exception lors de l\'échange de token: $e');
        
        // En cas d'erreur, on essaie avec l'ancienne méthode
        return await _legacyGoogleAuthentication(googleUser, googleAuth);
      }

      return false;
    } catch (e, stack) {
      debugPrint('Erreur globale lors de la connexion Google: $e');
      debugPrint('Stack trace: $stack');
      return false;
    }
  }
  
  /// Tente de rafraîchir les tokens Google en cas d'expiration
  /// Cette méthode est remplacée par refreshGoogleToken() plus bas dans le code

  /// Méthode de secours qui tente de créer un compte utilisateur avec les données Google
  /// Utilisée quand toutes les autres méthodes d'authentification ont échoué
  Future<bool> _createGoogleAccountFallback(
    GoogleSignInAccount googleUser,
    GoogleSignInAuthentication googleAuth
  ) async {
    try {
      debugPrint('Tentative de création d\'un nouveau compte avec les données Google...');
      
      // Générer un mot de passe aléatoire sécurisé pour respecter les contraintes du backend
      final String randomPassword = _generateSecurePassword(16);
      
      // Créer le compte avec les infos Google
      final result = await registerFull(
        googleUser.displayName ?? 'Utilisateur Google',
        googleUser.email,
        randomPassword,
      );
      
      if (result.containsKey('access_token') && result.containsKey('user_id')) {
        debugPrint('Compte créé avec succès pour ${googleUser.email}');
        
        // Maintenant essayer de lier le compte Google
        try {
          await linkWithGoogle();
          debugPrint('Liaison du compte Google réussie');
        } catch (e) {
          // Même si la liaison échoue, on a au moins créé le compte
          debugPrint('La liaison du compte Google a échoué, mais le compte a été créé: $e');
        }
        
        return true;
      } else {
        debugPrint('Échec de création du compte: $result');
        return false;
      }
    } catch (e) {
      debugPrint('Erreur lors de la création du compte de secours: $e');
      return false;
    }
  }
  
  /// Génère un mot de passe sécurisé aléatoire
  String _generateSecurePassword(int length) {
    const String chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#%^&*()_-+=<>?';
    final rnd = Random.secure();
    return String.fromCharCodes(List.generate(
        length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }
  
  /// Méthode de repli pour l'authentification Google utilisant l'ancien endpoint
  Future<bool> _legacyGoogleAuthentication(
    GoogleSignInAccount googleUser,
    GoogleSignInAuthentication googleAuth
  ) async {
    try {
      debugPrint('Utilisation de la méthode d\'authentification Google de secours');
      
      // Vérifier que les tokens nécessaires sont bien présents
      if (googleAuth.idToken == null) {
        debugPrint('ERREUR FALLBACK: ID Token Google manquant');
        // Tentative de régénération du token en demandant de nouveau l'authentification
        final GoogleSignInAuthentication refreshedAuth = await googleUser.authentication;
        if (refreshedAuth.idToken == null) {
          debugPrint('ÉCHEC: Impossible d\'obtenir un ID Token Google même après nouvelle tentative');
          return false;
        }
        // Utiliser les nouveaux tokens pour la suite
        googleAuth = refreshedAuth;
        debugPrint('ID Token régénéré avec succès');
      }
      
      // Tenter de se connecter via l'API client standard
      final result = await _apiClient.loginWithProvider(
        'google',
        googleUser.id,
        googleUser.email,
        username: googleUser.displayName,
        profileImageUrl: googleUser.photoUrl,
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken, // Ajout explicite de l'ID Token
      );
      
      // Vérifier si la réponse contient bien les infos attendues
      if (result.containsKey('access_token') && result.containsKey('expires_at')) {
        _userId = result['user_id'] ?? googleUser.id;
        _username = result['username'] ?? googleUser.displayName;
        _isAdmin = result['is_admin'] ?? false;
        
        authStateChanged.value = true;
        debugPrint('Connexion de secours réussie pour: $_username');
        return true;
      }
      
      // Si ça échoue, essayer directement avec le token ID
      debugPrint('Deuxième tentative par requête HTTP directe...');
      
      final queryParams = {
        'provider': 'google',
        'provider_id': googleUser.id,
        'email': googleUser.email,
      };
      
      final headers = {
        'Content-Type': 'application/json',
        // Utiliser à la fois l'ID token et l'access token pour maximiser les chances
        'Authorization': 'Bearer ${googleAuth.accessToken}',
        'X-Google-IdToken': googleAuth.idToken,
      };
      
      final uri = Uri.parse('${EnvConfig.apiBaseUrl}/auth/provider').replace(
        queryParameters: queryParams,
      );
      
      final response = await http.post(
        uri,
        headers: headers.cast<String, String>(),
        body: json.encode({
          'username': googleUser.displayName,
          'profile_image_url': googleUser.photoUrl,
          'id_token': googleAuth.idToken, // Ajouter l'ID token dans le corps également
        }),
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data.containsKey('access_token') && data.containsKey('expires_at')) {
          final String token = data['access_token'];
          final DateTime expiration = DateTime.parse(data['expires_at']);
          
          // Sauvegarder le token
          await _saveAuthToken(token, expiration);
          
          _userId = data['user_id'] ?? googleUser.id;
          _username = data['username'] ?? googleUser.displayName;
          _isAdmin = data['is_admin'] ?? false;
          
          authStateChanged.value = true;
          debugPrint('Connexion directe réussie pour: $_username');
          return true;
        }
      } else {
        // Journaliser les détails de l'erreur pour le débogage
        debugPrint('Erreur HTTP lors de la tentative directe: ${response.statusCode}');
        debugPrint('Corps de la réponse: ${response.body}');
        
        // Dernière tentative - créer un compte si l'authentification échoue
        if (response.statusCode == 404 || response.statusCode == 422) {
          return _createGoogleAccountFallback(googleUser, googleAuth);
        }
      }
      
      return false;
    } catch (e, stack) {
      debugPrint('Erreur lors de l\'authentification Google de secours: $e');
      debugPrint('Stack trace: $stack');
      
      // Tentative de création de compte en cas d'échec complet
      return _createGoogleAccountFallback(googleUser, googleAuth);
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
  /// Lie le compte utilisateur actuel avec un compte Google
/// Transmet explicitement les tokens Google au backend pour une authentification sécurisée
Future<Map<String, dynamic>> linkWithGoogle() async {
  try {
    debugPrint('Démarrage du processus de liaison avec Google...');
    
    // Vérifier que l'utilisateur est bien authentifié
    if (!isAuthenticated) {
      debugPrint('Liaison impossible: utilisateur non authentifié');
      return {'success': false, 'message': 'User not authenticated'};
    }
    
    // Déclencher le flux de connexion Google
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    
    if (googleUser == null) {
      debugPrint('Liaison annulée par l\'utilisateur');
      return {'success': false, 'message': 'Google sign-in cancelled'};
    }
    
    debugPrint('Compte Google sélectionné: ${googleUser.displayName} (${googleUser.email})');
    
    // Obtenir les tokens d'authentification
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    
    // Vérifier la présence des tokens
    if (googleAuth.idToken == null) {
      debugPrint('Liaison impossible: ID Token Google manquant');
      return {'success': false, 'message': 'Missing Google ID Token'};
    }
    
    if (googleAuth.accessToken == null) {
      debugPrint('Liaison impossible: Access Token Google manquant');
      return {'success': false, 'message': 'Missing Google Access Token'};
    }
    
    debugPrint('Tokens Google obtenus avec succès');
    
    // Préparer les données complètes pour la liaison
    final Map<String, dynamic> bodyData = {
      'google_id': googleUser.id,
      'email': googleUser.email,
      'display_name': googleUser.displayName,
      'profile_image_url': googleUser.photoUrl,
      'id_token': googleAuth.idToken,       // Ajout explicite de l'ID Token
      'access_token': googleAuth.accessToken, // Ajout explicite de l'Access Token
    };
    
    debugPrint('Envoi de la requête de liaison au backend...');
    
    // Essayer d'abord l'endpoint moderne
    try {
      final modernData = await _apiClient.post(
        '/auth/link/google',
        body: bodyData,
      );
      
      if (modernData['success'] == true) {
        debugPrint('Liaison avec Google réussie via l\'endpoint moderne');
        return modernData;
      }
    } catch (e) {
      debugPrint('Endpoint moderne indisponible ou erreur: $e');
      // Continuer avec le fallback
    }
    
    // Méthode de secours - essayer un endpoint alternatif
    try {
      final fallbackData = await _apiClient.post(
        '/user/link/google',
        body: bodyData,
      );
      
      if (fallbackData['success'] == true) {
        debugPrint('Liaison avec Google réussie via l\'endpoint alternatif');
        return fallbackData;
      } else {
        debugPrint('Échec de la liaison: ${fallbackData['message'] ?? "Raison inconnue"}');
        return fallbackData;
      }
    } catch (e) {
      debugPrint('Échec de la méthode de secours: $e');
      return {'success': false, 'message': 'API connection error: ${e.toString()}'};
    }
  } catch (e, stack) {
    debugPrint('Erreur lors de la liaison avec Google: $e');
    // Enregistrement de l'erreur pour analyse
    try {
      // Accès via une méthode d'évaluation dynamique pour éviter des erreurs de compilation
      // en attendant une meilleure implémentation de l'injection de dépendance
      final analytics = getAnalyticsService();
      if (analytics != null) {
        analytics.recordError(e, stack, reason: 'Google authentication error');
      }
    } catch (logError) {
      debugPrint('Impossible d\'enregistrer l\'erreur: $logError');
    }
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
  
  /// Méthode auxiliaire pour accéder au service d'analytique de façon sécurisée
  dynamic getAnalyticsService() {
    // Cette méthode utilise la réflexion ou une injection de dépendance légère
    // pour éviter les problèmes de compilation liés à l'accès direct à serviceLocator
    try {
      // Dans une implémentation réelle, nous accéderions au serviceLocator
      // Mais pour l'instant, nous retournons null pour éviter les erreurs
      return null;
    } catch (e) {
      debugPrint('Erreur lors de l\'accès au service d\'analytique: $e');
      return null;
    }
  }

  /// Rafraîchit le token Google de manière silencieuse
  /// Renvoie le compte Google si le rafraîchissement a réussi, sinon null
  Future<GoogleSignInAccount?> refreshGoogleToken() async {
    try {
      debugPrint('=== RAFRAÎCHISSEMENT SILENCIEUX DU TOKEN GOOGLE ===');
      final googleSignIn = GoogleSignIn();
      
      // Essayer d'obtenir l'utilisateur actuel sans UI
      final GoogleSignInAccount? currentUser = googleSignIn.currentUser;
      
      if (currentUser == null) {
        // Essayer de connecter silencieusement l'utilisateur
        final GoogleSignInAccount? silentUser = await googleSignIn.signInSilently();
        if (silentUser == null) {
          debugPrint('Échec du rafraîchissement silencieux: aucun utilisateur Google');
          return null;
        }
        
        debugPrint('Compte Google récupéré silencieusement: ${silentUser.displayName}');
        return silentUser;
      }
      
      // Rafraîchir l'authentification pour l'utilisateur actuel
      final GoogleSignInAuthentication? googleAuth = await currentUser.authentication;
      
      if (googleAuth != null && googleAuth.idToken != null) {
        debugPrint('Token Google rafraîchi avec succès');
        return currentUser;
      } else {
        debugPrint('Token Google non disponible après rafraîchissement');
        return null;
      }
    } catch (e) {
      debugPrint('Erreur lors du rafraîchissement du token Google: $e');
      return null;
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
