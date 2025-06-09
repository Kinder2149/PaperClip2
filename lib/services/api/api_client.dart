// lib/services/api/api_client.dart

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paperclip2/config/api_endpoints.dart';
// Service locator import supprimé car le fichier n'existe pas
import 'package:paperclip2/config/api_config.dart';

/// Exception lancée en cas de problème réseau
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  
  @override
  String toString() => 'NetworkException: $message';
}

/// Service client pour communiquer avec le backend API
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  // Configuration de l'API depuis api_config.dart
  // Stockage du token JWT
  String? _authToken;
  DateTime? _tokenExpiration;
  
  // Instance du gestionnaire d'endpoints
  final ApiEndpointManager _endpoints = ApiEndpointManager();
  
  // Getters
  String get baseUrl => _endpoints.baseUrl;
  bool get isAuthenticated => _authToken != null && (_tokenExpiration?.isAfter(DateTime.now()) ?? false);
  String? get authToken => _authToken;
  DateTime? get tokenExpiration => _tokenExpiration;
  
  // Debugging
  void printConfig() {
    debugPrint('=== API Client Configuration ===');
    debugPrint('Base URL: $baseUrl');
    debugPrint('Is Authenticated: $isAuthenticated');
    debugPrint('Token Expiry: ${_tokenExpiration?.toIso8601String() ?? "null"}');
  }
  
  // Méthode pour définir le token d'auth et l'expiration
  Future<void> setAuthToken(String token, DateTime expiration) async {
    _authToken = token;
    _tokenExpiration = expiration;
    
    // Sauvegarder dans les SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('auth_token', token);
    prefs.setString('token_expiration', expiration.toIso8601String());
  }

  // Constructeur interne
  ApiClient._internal();

  // Initialisation du client
  Future<void> initialize() async {
    await _loadAuthToken();
    debugPrint('[DEBUG API] API Client initialisé - Auth token présent: ${_authToken != null}, Expiré: ${_tokenExpiration?.isBefore(DateTime.now()) ?? true}');
  }

  // Chargement du token depuis le stockage local
  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    debugPrint('[DEBUG API] Token chargé depuis SharedPreferences: ${_authToken != null ? 'Présent' : 'Absent'}');
    
    final expiryString = prefs.getString('token_expiry');
    if (expiryString != null) {
      try {
        _tokenExpiration = DateTime.parse(expiryString);
        debugPrint('[DEBUG API] Date d\'expiration: ${_tokenExpiration?.toIso8601String()}, Expiré: ${_tokenExpiration?.isBefore(DateTime.now())}');
        
        // Vérifier si le token est expiré
        if (_tokenExpiration!.isBefore(DateTime.now())) {
          debugPrint('[DEBUG API] Token expiré, suppression...');
          _authToken = null;
          _tokenExpiration = null;
          await prefs.remove('auth_token');
          await prefs.remove('token_expiry');
        }
      } catch (e) {
        debugPrint('[DEBUG API] Erreur lors du parsing de la date d\'expiration: $e');
        _authToken = null;
        _tokenExpiration = null;
        await prefs.remove('auth_token');
        await prefs.remove('token_expiry');
      }
    } else {
      debugPrint('[DEBUG API] Aucune date d\'expiration trouvée');
    }
  }

  // Sauvegarde du token dans le stockage local
  Future<void> _saveAuthToken(String token, DateTime expiry) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('token_expiry', expiry.toIso8601String());
    
    _authToken = token;
    _tokenExpiration = expiry;
  }

  // Effacement du token (déconnexion)
  Future<void> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('token_expiry');
    
    _authToken = null;
    _tokenExpiration = null;
    debugPrint('[DEBUG API] Token d\'authentification effacé');
  }

  // Création des en-têtes HTTP avec authentification si disponible
  /// Crée les en-têtes pour une requête API
  /// Note: cette méthode reste synchrone pour éviter de changer toutes les signatures
  Map<String, String> _createHeaders({bool requiresAuth = true, bool isJson = true, Map<String, String>? additionalHeaders}) {
    final headers = <String, String>{};
    
    // Ajouter les en-têtes de base
    if (isJson) {
      headers['Content-Type'] = 'application/json';
      headers['Accept'] = 'application/json';
    }
    
    // Ajouter les en-têtes additionnels si fournis
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }
    
    // Vérifier si l'authentification est requise
    if (requiresAuth) {
      // Vérifier si le token est présent et valide
      if (_authToken != null) {
        // Vérifier si le token est expiré ou va expirer bientôt (moins de 5 minutes)
        final bool tokenNeedsRefresh = _tokenExpiration != null &&
            _tokenExpiration!.difference(DateTime.now()).inMinutes <= 5;
        
        if (tokenNeedsRefresh) {
          // On ne peut pas rafraîchir le token de façon synchrone ici
          // On se contente d'avertir qu'il faudra le rafraîchir bientôt
          debugPrint('[DEBUG API] ATTENTION: Token JWT expiré ou expirant sous peu!');
        }
        
        // Utiliser le token actuel
        headers['Authorization'] = 'Bearer $_authToken';
        debugPrint('[DEBUG API] En-tête Authorization ajouté: Bearer ${_authToken!.length > 10 ? _authToken!.substring(0, 10) : _authToken}...');
      } else {
        debugPrint('[DEBUG API] ATTENTION: Requête nécessitant authentification mais aucun token disponible');
      }
    }
    
    return headers;
  }

  // Méthode pour gérer les réponses HTTP et les erreurs
  dynamic _handleResponse(http.Response response) {
    debugPrint('[DEBUG API] Réponse HTTP: ${response.statusCode} - URL: ${response.request?.url}');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Succès
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      // Non autorisé - token expiré ou invalide
      debugPrint('[DEBUG API] ERREUR 401: ${response.body}');
      _authToken = null;
      _tokenExpiration = null;
      throw UnauthorizedException('Non autorisé: ${response.body}');
    } else {
      // Autres erreurs
      debugPrint('[DEBUG API] ERREUR ${response.statusCode}: ${response.body}');
      throw ApiException(
        'Erreur API: ${response.statusCode}',
        response.statusCode,
        response.body,
      );
    }
  }

  // Méthodes HTTP

  /// Effectue une requête GET
  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParams, bool requiresAuth = true}) async {
    try {
      final url = Uri.parse('${ApiConfig.apiBaseUrl}$endpoint')
          .replace(queryParameters: queryParams?.map((k, v) => MapEntry(k, v.toString())));
      
      // Vérification préliminaire d'authentification si requise
      if (requiresAuth && !isAuthenticated) {
        debugPrint('[DEBUG API] GET: Requête authentifiée ignorée car non connecté: $endpoint');
        throw UnauthorizedException('Non authentifié. Connexion requise.');
      }
      
      final headers = _createHeaders(requiresAuth: requiresAuth);
      final response = await http.get(url, headers: headers);
      
      return _handleResponse(response);
    } on SocketException {
      throw const ApiException('Pas de connexion internet', 0, 'Vérifiez votre connexion');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erreur lors de la requête GET', 0, e.toString());
    }
  }

  /// Effectue une requête POST
  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
    bool requiresAuth = true,
  }) async {
    try {
      final headers = _createHeaders(requiresAuth: requiresAuth);
      
      // Construire l'URL avec les paramètres de requête si nécessaire
      var uri = Uri.parse('${ApiConfig.apiBaseUrl}$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        // Convertir les valeurs en String car Uri.replace attend Map<String, String>
        final stringQueryParams = queryParams.map((key, value) => 
          MapEntry(key, value?.toString() ?? ''));
        uri = uri.replace(queryParameters: stringQueryParams);
        debugPrint('[DEBUG API] POST $uri avec query params: $queryParams');
      } else {
        debugPrint('[DEBUG API] POST $uri');
      }
      
      if (body != null) {
        debugPrint('[DEBUG API] Body: ${json.encode(body)}');
      }
      
      final response = await http.post(
        uri,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );
      
      return _handleResponse(response);
    } on SocketException {
      throw NetworkException('Pas de connexion internet');
    } catch (e) {
      debugPrint('[DEBUG API] Erreur POST: $e');
      rethrow;
    }
  }

  /// Effectue une requête PUT
  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body, bool requiresAuth = true}) async {
    try {
      final url = Uri.parse('${ApiConfig.apiBaseUrl}$endpoint');
      
      // Vérification préliminaire d'authentification si requise
      if (requiresAuth && !isAuthenticated) {
        debugPrint('[DEBUG API] PUT: Requête authentifiée ignorée car non connecté: $endpoint');
        throw UnauthorizedException('Non authentifié. Connexion requise.');
      }
      
      final headers = _createHeaders(requiresAuth: requiresAuth);
      
      final response = await http.put(
        url,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );
      
      return _handleResponse(response);
    } on SocketException {
      throw const ApiException('Pas de connexion internet', 0, 'Vérifiez votre connexion');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erreur lors de la requête PUT', 0, e.toString());
    }
  }

  /// Effectue une requête DELETE
  Future<dynamic> delete(String endpoint, {Map<String, dynamic>? body, Map<String, dynamic>? queryParams, bool requiresAuth = true}) async {
    try {
      // Construire l'URL avec les queryParams s'ils existent
      final url = Uri.parse('${ApiConfig.apiBaseUrl}$endpoint')
          .replace(queryParameters: queryParams?.map((k, v) => MapEntry(k, v.toString())));
      
      debugPrint('[DEBUG API] DELETE: $url');
      
      // Vérification préliminaire d'authentification si requise
      if (requiresAuth && !isAuthenticated) {
        debugPrint('[DEBUG API] DELETE: Requête authentifiée ignorée car non connecté: $endpoint');
        throw UnauthorizedException('Non authentifié. Connexion requise.');
      }
      
      final headers = _createHeaders(requiresAuth: requiresAuth);
      
      final request = http.Request('DELETE', url);
      request.headers.addAll(headers);
      
      if (body != null) {
        request.body = json.encode(body);
        final truncatedLength = body.toString().length > 100 ? 100 : body.toString().length;
        debugPrint('[DEBUG API] DELETE avec body: ${body.toString().substring(0, truncatedLength)}...');
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      return _handleResponse(response);
    } on SocketException {
      throw const ApiException('Pas de connexion internet', 0, 'Vérifiez votre connexion');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erreur lors de la requête DELETE', 0, e.toString());
    }
  }

  /// Upload d'un fichier
  Future<dynamic> uploadFile(String endpoint, File file, {String? fileName, bool requiresAuth = true, Map<String, dynamic>? queryParams}) async {
    final url = Uri.parse('${ApiConfig.apiBaseUrl}$endpoint').replace(queryParameters: queryParams?.map((k, v) => MapEntry(k, v.toString())));
    
    try {
      final request = http.MultipartRequest('POST', url);
      
      // Ajouter les en-têtes d'authentification
      if (requiresAuth && _authToken != null) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }
      
      // Ajouter le fichier
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: fileName ?? file.path.split('/').last,
      ));
      
      // Envoyer la requête
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      return _handleResponse(response);
    } on SocketException {
      throw const ApiException('Pas de connexion internet', 0, 'Vérifiez votre connexion');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erreur lors de l\'upload du fichier', 0, e.toString());
    }
  }

  /// Authentification avec email et mot de passe
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final data = await post(
        _endpoints.loginEndpoint,
        body: {'email': email, 'password': password},
        requiresAuth: false,
      );
      
      // Sauvegarder le token
      if (data['access_token'] != null && data['expires_at'] != null) {
        await _saveAuthToken(
          data['access_token'],
          DateTime.parse(data['expires_at']),
        );
      }
      
      return data;
    } catch (e) {
      debugPrint('Erreur lors de la connexion: $e');
      rethrow;
    }
  }

  /// Inscription d'un nouvel utilisateur
  Future<Map<String, dynamic>> register(String email, String password, String username) async {
    try {
      final data = await post(
        _endpoints.registerEndpoint,
        body: {'email': email, 'password': password, 'username': username},
        requiresAuth: false,
      );
      
      // Sauvegarder le token
      if (data['access_token'] != null && data['expires_at'] != null) {
        await _saveAuthToken(
          data['access_token'],
          DateTime.parse(data['expires_at']),
        );
      }
      
      return data;
    } catch (e) {
      debugPrint('Erreur lors de l\'inscription: $e');
      rethrow;
    }
  }
  
  /// Authentification avec un fournisseur tiers (Google, Apple)
  Future<Map<String, dynamic>> loginWithProvider(
    String provider,
    String providerId,
    String email, {
    String? username,
    String? profileImageUrl,
    String? accessToken,
    String? idToken,
  }) async {
    try {
      // Créer les query parameters pour l'authentification par fournisseur
      final queryParams = {
        'provider': provider,
        'provider_id': providerId,
        'email': email,
      };
      
      // Le corps contient les données optionnelles et l'idToken
      final body = <String, dynamic>{};
      if (username != null) body['username'] = username;
      if (profileImageUrl != null) body['profile_image_url'] = profileImageUrl;
      if (idToken != null) body['id_token'] = idToken; // Ajout explicite de l'idToken au corps
      
      debugPrint('[DEBUG API] Connexion via fournisseur: $provider - QueryParams: $queryParams');
      
      // Utiliser notre méthode post améliorée avec queryParams et headers personnalisés
      Map<String, String> customHeaders = {};
      if (accessToken != null) {
        customHeaders['Authorization'] = 'Bearer $accessToken';
      }
      if (idToken != null) {
        customHeaders['X-Google-IdToken'] = idToken; // Ajout de l'idToken en header personnalisé
      }
      
      // Essayer d'abord avec le nouvel endpoint OAuth
      try {
        final String endpoint = provider == 'google' 
          ? _endpoints.googleOAuthEndpoint 
          : _endpoints.providerAuthEndpoint;
        
        // Note: Nous ne pouvons pas passer customHeaders directement avec post()
        // Utilisation d'une requête HTTP directe 
        var uri = Uri.parse('${ApiConfig.apiBaseUrl}$endpoint');
        if (queryParams != null && queryParams.isNotEmpty) {
          final stringQueryParams = queryParams.map((key, value) => 
            MapEntry(key, value?.toString() ?? ''));
          uri = uri.replace(queryParameters: stringQueryParams);
        }
        
        debugPrint('[DEBUG API] POST $uri avec des en-têtes personnalisés');
        if (body != null) {
          debugPrint('[DEBUG API] Body: ${json.encode(body)}');
        }
        
        final response = await http.post(
          uri,
          headers: customHeaders,
          body: body != null ? json.encode(body) : null,
        );
        
        final data = _handleResponse(response);
        
        // Sauvegarder le token s'il est présent
        if (data['access_token'] != null && data['expires_at'] != null) {
          await _saveAuthToken(
            data['access_token'],
            DateTime.parse(data['expires_at']),
          );
        }
        
        return data;
      } catch (e) {
        // En cas d'erreur (par ex. 404), utiliser l'ancien endpoint
        debugPrint('Erreur avec le nouvel endpoint OAuth: $e, utilisation du fallback');
        
        // Note: Nous ne pouvons pas passer customHeaders directement avec post()
        // Utilisation d'une requête HTTP directe pour le fallback
        var uri = Uri.parse('${ApiConfig.apiBaseUrl}${_endpoints.providerAuthEndpoint}');
        if (queryParams != null && queryParams.isNotEmpty) {
          final stringQueryParams = queryParams.map((key, value) => 
            MapEntry(key, value?.toString() ?? ''));
          uri = uri.replace(queryParameters: stringQueryParams);
        }
        
        debugPrint('[DEBUG API] POST $uri avec des en-têtes personnalisés (fallback)');
        if (body != null) {
          debugPrint('[DEBUG API] Body: ${json.encode(body)}');
        }
        
        final response = await http.post(
          uri,
          headers: customHeaders,
          body: body != null ? json.encode(body) : null,
        );
        
        final data = _handleResponse(response);
        
        // Sauvegarder le token
        if (data['access_token'] != null && data['expires_at'] != null) {
          await _saveAuthToken(
            data['access_token'],
            DateTime.parse(data['expires_at']),
          );
        }
        
        return data;
      }
    } catch (e) {
      debugPrint('Erreur globale lors de l\'authentification avec fournisseur: $e');
      rethrow;
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    try {
      await post(_endpoints.logoutEndpoint);
      debugPrint('Deconnexion reussie via API');
    } catch (e) {
      debugPrint('Erreur lors de la deconnexion API: $e');
    } finally {
      await clearAuthToken();
      debugPrint('Token local efface');
    }
  }

  /// Tente de rafraîchir un token expiré ou sur le point d'expirer
  /// Retourne true si le token a été rafraîchi avec succès
  Future<bool> _tryRefreshToken() async {
    try {
      debugPrint('[DEBUG API] Tentative de rafraîchissement du token...');
      
      // Essayer d'abord avec un endpoint spécifique de refresh token
      try {
        final refreshResponse = await http.post(
          Uri.parse('${_endpoints.baseUrl}/auth/refresh'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_authToken',
          },
        );
        
        if (refreshResponse.statusCode >= 200 && refreshResponse.statusCode < 300) {
          final data = json.decode(refreshResponse.body);
          
          if (data['access_token'] != null && data['expires_at'] != null) {
            await _saveAuthToken(
              data['access_token'],
              DateTime.parse(data['expires_at']),
            );
            debugPrint('[DEBUG API] Token rafraîchi avec succès via endpoint refresh');
            return true;
          }
        }
      } catch (e) {
        debugPrint('[DEBUG API] Échec du rafraîchissement via endpoint spécifique: $e');
        // Continuer avec la méthode alternative
      }
      
      // Si l'endpoint de rafraîchissement n'est pas disponible, tenter une reconnexion silencieuse via Google
      try {
        // On vérifiera plus tard si un service est disponible pour le rafraîchissement
        // Ce code sera modifié pour utiliser une injection de dépendance correcte
        /* À implémenter plus tard
        final authService = getAuthService();
        if (authService != null) {
          debugPrint('[DEBUG API] Tentative de rafraîchissement via AuthService...');
          
          // Utiliser la méthode de rafraîchissement de token Google de l'AuthService
          final freshGoogleAuth = await authService.refreshGoogleToken();
          
          if (freshGoogleAuth != null) {
            // Le token Google a été rafraîchi, maintenant mettre à jour le token JWT
            final success = await authService.signInWithGoogle(silent: true);
            
            if (success) {
              // Récupérer le nouveau token depuis authService
              final newToken = authService.currentJwtToken;
              final tokenExpiry = authService.tokenExpiration;
              
              if (newToken != null && tokenExpiry != null) {
                _authToken = newToken;
                _tokenExpiration = tokenExpiry;
                
                await _saveAuthToken(newToken, tokenExpiry);
                debugPrint('[DEBUG API] Token rafraîchi avec succès via Google Auth');
                return true;
              }
            }
          }
        }
        */
      } catch (e) {
        debugPrint('[DEBUG API] Échec du rafraîchissement via Google: $e');
      }
      
      debugPrint('[DEBUG API] Échec du rafraîchissement du token');
      return false;
    } catch (e) {
      debugPrint('[DEBUG API] Erreur lors du rafraîchissement du token: $e');
      return false;
    }
  }
}

/// Exception pour les erreurs d'API
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final String body;

  const ApiException(this.message, this.statusCode, this.body);

  @override
  String toString() => message;
}

/// Exception pour les erreurs d'authentification
class UnauthorizedException extends ApiException {
  const UnauthorizedException(String message) : super(message, 401, '');
}
