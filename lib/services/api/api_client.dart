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
  bool get isAuthenticated =>
      _authToken != null &&
      (_tokenExpiration?.isAfter(DateTime.now()) ?? false);
  String? get authToken => _authToken;
  DateTime? get tokenExpiration => _tokenExpiration;

  // Méthode pour récupérer le token d'authentification
  Future<String?> getAuthToken() async {
    if (_authToken == null ||
        (_tokenExpiration?.isBefore(DateTime.now()) ?? true)) {
      await _loadAuthToken();
    }
    return _authToken;
  }

  // Debugging
  void printConfig() {
    debugPrint('=== API Client Configuration ===');
    debugPrint('Base URL: $baseUrl');
    debugPrint('Is Authenticated: $isAuthenticated');
    debugPrint(
        'Token Expiry: ${_tokenExpiration?.toIso8601String() ?? "null"}');
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
  
  // Alias pour setAuthToken (pour compatibilité)
  Future<void> saveAuthToken(String token, DateTime expiration) async {
    return setAuthToken(token, expiration);
  }

  // Constructeur interne
  ApiClient._internal();

  // Initialisation du client
  Future<void> initialize() async {
    await _loadAuthToken();
    debugPrint(
        '[DEBUG API] API Client initialisé - Auth token présent: ${_authToken != null}, Expiré: ${_tokenExpiration?.isBefore(DateTime.now()) ?? true}');
  }

  // Chargement du token depuis le stockage local
  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    debugPrint(
        '[DEBUG API] Token chargé depuis SharedPreferences: ${_authToken != null ? 'Présent' : 'Absent'}');

    // CORRECTION: Utilisation de la même clé que lors de la sauvegarde
    final expiryString = prefs.getString('token_expiration');
    debugPrint('[DEBUG API] Date d\'expiration string: $expiryString');
    
    if (expiryString != null) {
      try {
        _tokenExpiration = DateTime.parse(expiryString);
        debugPrint(
            '[DEBUG API] Date d\'expiration: ${_tokenExpiration?.toIso8601String()}, Expiré: ${_tokenExpiration?.isBefore(DateTime.now())}');

        // Vérifier si le token est expiré
        if (_tokenExpiration!.isBefore(DateTime.now())) {
          debugPrint('[DEBUG API] Token expiré, suppression...');
          _authToken = null;
          _tokenExpiration = null;
          await prefs.remove('auth_token');
          await prefs.remove('token_expiry');
        }
      } catch (e) {
        debugPrint(
            '[DEBUG API] Erreur lors du parsing de la date d\'expiration: $e');
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
  /// Sauvegarde le token d'accès et sa date d'expiration
  Future<void> _saveAuthToken(String token, DateTime expiry) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('token_expiration', expiry.toIso8601String());

    _authToken = token;
    _tokenExpiration = expiry;
    
    debugPrint('[DEBUG API] Token d\'accès sauvegardé, expire le: $expiry');
  }
  
  /// Sauvegarde le refresh token dans le stockage local
  Future<void> _saveRefreshToken(String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('refresh_token', refreshToken);
    
    debugPrint('[DEBUG API] Refresh token sauvegardé');
  }

  // Effacement du token (déconnexion)
  /// Efface tous les tokens d'authentification stockés localement
  Future<void> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('token_expiration');  // Correction: token_expiry → token_expiration
    await prefs.remove('refresh_token');

    _authToken = null;
    _tokenExpiration = null;
    debugPrint('[DEBUG API] Tous les tokens d\'authentification effacés');
  }

  // Création des en-têtes HTTP avec authentification si disponible
  /// Crée les en-têtes pour une requête API
  /// Note: cette méthode reste synchrone pour éviter de changer toutes les signatures
  Map<String, String> _createHeaders(
      {bool requiresAuth = true,
      bool isJson = true,
      Map<String, String>? additionalHeaders}) {
    final headers = <String, String>{};

    // Ajouter les en-têtes de base
    if (isJson) {
      headers['Content-Type'] = 'application/json';
      headers['Accept'] = 'application/json';
    }
    
    // Ajouter un user agent pour identifier l'app
    headers['User-Agent'] = 'PaperClip2 Flutter App';

    // Ajouter les en-têtes additionnels si fournis
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    // Vérifier si l'authentification est requise
    if (requiresAuth) {
      // Vérifier si le token est présent et valide
      if (_authToken != null) {
        // Vérifier si le token est expiré ou va expirer bientôt (moins de 5 minutes)
        final bool isExpired = _tokenExpiration != null &&
            _tokenExpiration!.isBefore(DateTime.now());
        
        final bool tokenNeedsRefresh = _tokenExpiration != null &&
            _tokenExpiration!.difference(DateTime.now()).inMinutes <= 5;

        if (isExpired) {
          debugPrint('[DEBUG API] ERREUR: Token JWT expiré! Les requêtes vont échouer');
        } else if (tokenNeedsRefresh) {
          debugPrint('[DEBUG API] ATTENTION: Token JWT expirant sous peu!');
        }

        // S'assurer que le token est bien formaté et non vide
        if (_authToken!.trim().isNotEmpty) {
          // Utiliser le token actuel avec exactement un espace entre 'Bearer' et le token
          headers['Authorization'] = 'Bearer $_authToken';
          debugPrint('[DEBUG API] En-tête Authorization ajouté: Bearer ${_authToken!.length > 10 ? "${_authToken!.substring(0, 10)}..." : _authToken}');
        } else {
          debugPrint('[DEBUG API] ATTENTION: Token vide ou mal formaté!');
        }
      } else {
        debugPrint('[DEBUG API] ATTENTION: Requête nécessitant authentification mais aucun token disponible');
      }
    }

    return headers;
  }

  // Méthode pour gérer les réponses HTTP et les erreurs
  // Variable pour éviter les tentatives infinies de refresh token
  bool _isRefreshingToken = false;

  /// Traite la réponse HTTP et gère les erreurs
  /// Si une erreur 401 est reçue, tente de rafraîchir le token automatiquement
  Future<dynamic> _handleResponse(http.Response response) async {
    debugPrint('[DEBUG API] Réponse HTTP: ${response.statusCode} - URL: ${response.request?.url}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Succès
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    } else if (response.statusCode == 401 && !_isRefreshingToken) {
      // Non autorisé - token expiré ou invalide
      debugPrint('[DEBUG API] ERREUR 401: ${response.body} - Tentative de rafraîchissement du token');
      
      // Éviter les boucles infinies de tentatives de refresh
      _isRefreshingToken = true;
      
      try {
        // Tenter de rafraîchir le token
        final refreshSuccess = await _tryRefreshToken();
        _isRefreshingToken = false;
        
        if (refreshSuccess) {
          debugPrint('[DEBUG API] Token rafraîchi avec succès, nouvelle tentative de la requête');
          
          // Recréer la requête avec le nouveau token
          final Uri originalUrl = response.request!.url;
          final String method = response.request!.method;
          
          // Récupérer le body original si disponible
          String? originalBody;
          if (method == 'POST' || method == 'PUT' || method == 'PATCH') {
            try {
              // Tenter de récupérer le body original depuis response.request
              // Cette partie peut nécessiter des ajustements selon l'implémentation de http
              // Pour une approche plus robuste, il faudrait stocker le body original ailleurs
              originalBody = null; // à adapter selon l'implémentation http
            } catch (e) {
              debugPrint('[DEBUG API] Impossible de récupérer le body original: $e');
            }
          }
          
          // Refaire la requête originale avec le nouveau token
          final newHeaders = _createHeaders(requiresAuth: true);
          http.Response newResponse;
          
          switch (method) {
            case 'GET':
              newResponse = await http.get(originalUrl, headers: newHeaders);
              break;
            case 'POST':
              newResponse = await http.post(originalUrl, headers: newHeaders, body: originalBody);
              break;
            case 'PUT':
              newResponse = await http.put(originalUrl, headers: newHeaders, body: originalBody);
              break;
            case 'DELETE':
              newResponse = await http.delete(originalUrl, headers: newHeaders);
              break;
            default:
              throw ApiException('Méthode HTTP non supportée pour le retry: $method', 0, '');
          }
          
          // Traiter la nouvelle réponse (sans tenter un nouveau refresh en cas d'échec)
          if (newResponse.statusCode >= 200 && newResponse.statusCode < 300) {
            if (newResponse.body.isEmpty) return null;
            return json.decode(newResponse.body);
          } else {
            debugPrint('[DEBUG API] Échec après rafraîchissement du token: ${newResponse.statusCode}');
            throw ApiException(
              'Erreur API après rafraîchissement du token: ${newResponse.statusCode}',
              newResponse.statusCode,
              newResponse.body,
            );
          }
        } else {
          // Le rafraîchissement a échoué, effacer les tokens
          _authToken = null;
          _tokenExpiration = null;
          throw UnauthorizedException('Token expiré et rafraîchissement échoué');
        }
      } catch (e) {
        _isRefreshingToken = false;
        debugPrint('[DEBUG API] Erreur lors du rafraîchissement du token: $e');
        
        // En cas d'erreur pendant le processus de refresh, effacer les tokens
        _authToken = null;
        _tokenExpiration = null;
        throw UnauthorizedException('Échec du rafraîchissement du token: $e');
      }
    } else if (response.statusCode == 401) {
      // Si on est déjà en train de rafraîchir le token et qu'on reçoit un 401,
      // c'est un échec définitif
      debugPrint('[DEBUG API] ERREUR 401 pendant le rafraîchissement du token: ${response.body}');
      _authToken = null;
      _tokenExpiration = null;
      throw UnauthorizedException('Non autorisé et impossible de rafraîchir le token: ${response.body}');
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
  Future<dynamic> get(String endpoint,
      {Map<String, dynamic>? queryParams, bool requiresAuth = true}) async {
    try {
      final url = Uri.parse('${ApiConfig.apiBaseUrl}$endpoint').replace(
          queryParameters:
              queryParams?.map((k, v) => MapEntry(k, v.toString())));

      debugPrint('[DEBUG API] GET: $url');

      // Vérification préliminaire d'authentification si requise
      if (requiresAuth && !isAuthenticated) {
        debugPrint(
            '[DEBUG API] GET: Requête authentifiée ignorée car non connecté: $endpoint');
        throw UnauthorizedException('Non authentifié. Connexion requise.');
      }

      final headers = _createHeaders(requiresAuth: requiresAuth);
      final response = await http.get(url, headers: headers);

      return await _handleResponse(response);
    } on SocketException {
      throw const ApiException(
          'Pas de connexion internet', 0, 'Vérifiez votre connexion');
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
        final stringQueryParams = queryParams
            .map((key, value) => MapEntry(key, value.toString()));
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

      return await _handleResponse(response);
    } on SocketException {
      throw NetworkException('Pas de connexion internet');
    } catch (e) {
      debugPrint('[DEBUG API] Erreur POST: $e');
      rethrow;
    }
  }

  /// Effectue une requête PUT
  Future<dynamic> put(String endpoint,
      {Map<String, dynamic>? body, bool requiresAuth = true}) async {
    try {
      final url = Uri.parse('${ApiConfig.apiBaseUrl}$endpoint');

      debugPrint('[DEBUG API] PUT: $url');

      // Vérification préliminaire d'authentification si requise
      if (requiresAuth && !isAuthenticated) {
        debugPrint(
            '[DEBUG API] PUT: Requête authentifiée ignorée car non connecté: $endpoint');
        throw UnauthorizedException('Non authentifié. Connexion requise.');
      }

      final headers = _createHeaders(requiresAuth: requiresAuth);

      final response = await http.put(
        url,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );

      return await _handleResponse(response);
    } on SocketException {
      throw const ApiException(
          'Pas de connexion internet', 0, 'Vérifiez votre connexion');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erreur lors de la requête PUT', 0, e.toString());
    }
  }

  /// Effectue une requête DELETE
  Future<dynamic> delete(String endpoint,
      {Map<String, dynamic>? body,
      Map<String, dynamic>? queryParams,
      bool requiresAuth = true}) async {
    try {
      // Construire l'URL avec les queryParams s'ils existent
      final url = Uri.parse('${ApiConfig.apiBaseUrl}$endpoint').replace(
          queryParameters:
              queryParams?.map((k, v) => MapEntry(k, v.toString())));

      debugPrint('[DEBUG API] DELETE: $url');

      // Vérification préliminaire d'authentification si requise
      if (requiresAuth && !isAuthenticated) {
        debugPrint(
            '[DEBUG API] DELETE: Requête authentifiée ignorée car non connecté: $endpoint');
        throw UnauthorizedException('Non authentifié. Connexion requise.');
      }

      // Préparer la requête DELETE
      final request = http.Request('DELETE', url);
      request.headers.addAll(_createHeaders(requiresAuth: requiresAuth));
      
      if (body != null) {
        request.headers['Content-Type'] = 'application/json';
        request.body = json.encode(body);
        
        // Tronquer le log du body pour éviter des logs trop longs
        final truncatedLength =
          body.toString().length > 100 ? 100 : body.toString().length;
        debugPrint(
            '[DEBUG API] DELETE avec body: ${body.toString().substring(0, truncatedLength)}...');
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return await _handleResponse(response);
    } on SocketException {
      throw const ApiException(
          'Pas de connexion internet', 0, 'Vérifiez votre connexion');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erreur lors de la requête DELETE', 0, e.toString());
    }
  }

  /// Upload d'un fichier
  Future<dynamic> uploadFile(String endpoint, File file,
      {String? fileName,
      bool requiresAuth = true,
      Map<String, dynamic>? queryParams}) async {
    final url = Uri.parse('${ApiConfig.apiBaseUrl}$endpoint').replace(
        queryParameters: queryParams?.map((k, v) => MapEntry(k, v.toString())));

    debugPrint('[DEBUG API] UPLOAD: $url');

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

      debugPrint('[DEBUG API] Upload du fichier ${file.path}');

      // Envoyer la requête
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return await _handleResponse(response);
    } on SocketException {
      throw const ApiException(
          'Pas de connexion internet', 0, 'Vérifiez votre connexion');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
          'Erreur lors de l\'upload du fichier', 0, e.toString());
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

      // Sauvegarder le access token
      if (data['access_token'] != null && data['expires_at'] != null) {
        await _saveAuthToken(
          data['access_token'],
          DateTime.parse(data['expires_at']),
        );
        
        // Sauvegarder le refresh token s'il est présent
        if (data['refresh_token'] != null) {
          await _saveRefreshToken(data['refresh_token']);
        }
      }

      return data;
    } catch (e) {
      debugPrint('Erreur lors de la connexion: $e');
      rethrow;
    }
  }

  /// Inscription d'un nouvel utilisateur
  Future<Map<String, dynamic>> register(
      String email, String password, String username) async {
    try {
      final data = await post(
        _endpoints.registerEndpoint,
        body: {'email': email, 'password': password, 'username': username},
        requiresAuth: false,
      );

      // Sauvegarder le access token
      if (data['access_token'] != null && data['expires_at'] != null) {
        await _saveAuthToken(
          data['access_token'],
          DateTime.parse(data['expires_at']),
        );
        
        // Sauvegarder le refresh token s'il est présent
        if (data['refresh_token'] != null) {
          await _saveRefreshToken(data['refresh_token']);
        }
      }

      return data;
    } catch (e) {
      debugPrint('Erreur lors de l\'inscription: $e');
      rethrow;
    }
  }

  /// Authentification via fournisseur OAuth (Google, Facebook, etc.)
  /// 
  /// Paramètres:
  /// - provider: le fournisseur OAuth (google, facebook, etc.)
  /// - providerId: identifiant unique de l'utilisateur chez le fournisseur
  /// - email: email de l'utilisateur
  /// - displayName: nom d'affichage (optionnel)
  /// - photoUrl: URL de la photo de profil (optionnel)
  /// - idToken: token d'identification OAuth (optionnel selon le fournisseur)
  /// - accessToken: token d'accès OAuth (optionnel selon le fournisseur)
  Future<Map<String, dynamic>> loginWithProvider({
    required String provider,
    required String providerId,
    required String email,
    String? displayName,
    String? photoUrl,
    String? idToken,
    String? accessToken,
  }) async {
    // Vérification de sécurité - au moins un token doit être présent
    if (idToken == null && accessToken == null) {
      debugPrint('[ERREUR] Aucun token (idToken ou accessToken) fourni pour le login $provider');
      return {
        'success': false,
        'message': 'Aucun token fourni pour l\'authentification',
      };
    }

    try {
      // Construire le corps de la requête
      final requestBody = <String, dynamic>{
        'provider': provider,
        'provider_id': providerId,
        'email': email,
      };

      // Ajouter les champs optionnels s'ils sont présents
      if (displayName != null) requestBody['display_name'] = displayName;
      if (photoUrl != null) requestBody['photo_url'] = photoUrl;
      if (idToken != null) requestBody['id_token'] = idToken;
      if (accessToken != null) requestBody['access_token'] = accessToken;

      // Déterminer l'endpoint approprié selon le fournisseur
      String endpoint;
      if (provider == 'google') {
        endpoint = _endpoints.googleOAuthEndpoint;
      } else {
        endpoint = _endpoints.providerAuthEndpoint + '?provider=$provider';
      }
      debugPrint('[ApiClient] Tentative d\'authentification avec $provider via $endpoint');
      
      final data = await post(endpoint, body: requestBody, requiresAuth: false);
      
      // Sauvegarder le access token
      if (data['access_token'] != null && data['expires_at'] != null) {
        await _saveAuthToken(
          data['access_token'],
          DateTime.parse(data['expires_at']),
        );
        
        // Sauvegarder le refresh token s'il est présent
        if (data['refresh_token'] != null) {
          await _saveRefreshToken(data['refresh_token']);
        }
      }

      return data;
    } catch (e) {
      debugPrint('[ApiClient] Erreur lors du login avec $provider: $e');
      return {
        'success': false,
        'message': 'Erreur d\'authentification: $e',
      };
    }
  }

/// Liaison d'un compte utilisateur avec un fournisseur OAuth
/// Cette méthode nécessite que l'utilisateur soit déjà authentifié
/// 
/// Paramètres similaires à loginWithProvider
Future<Map<String, dynamic>?> linkWithProvider({
  required String provider,
  required String providerId,
  required String email,
  String? idToken,
  String? accessToken,
}) async {
  // Vérification de sécurité - au moins un token doit être présent
  if (idToken == null && accessToken == null) {
    debugPrint('[ERREUR] Aucun token (idToken ou accessToken) fourni pour la liaison avec $provider');
    return {'success': false, 'message': 'Aucun token valide fourni'};
  }
  
  // Vérification que l'utilisateur est actuellement authentifié
  if (!isAuthenticated) {
    debugPrint('[ERREUR] Tentative de liaison sans être authentifié');
    return {'success': false, 'message': 'Utilisateur non authentifié'};
  }
  
  try {
    // Déterminer l'endpoint approprié selon le fournisseur
    String endpoint;
    Map<String, dynamic> requestBody = {};
    
    if (provider == 'google') {
      endpoint = ApiConfig.currentPlatform.linkGoogleAccountUrl;
    } else if (provider == 'apple') {
      endpoint = ApiConfig.currentPlatform.linkAppleAccountUrl;
    } else {
      // Endpoint générique pour autres fournisseurs
      endpoint = ApiConfig.currentPlatform.linkProviderUrl + '?provider=$provider';
    }
    
    // Préparer le corps de la requête
    requestBody = {
      'provider_id': providerId,
      'email': email
    };
    
    if (idToken != null) {
      requestBody['id_token'] = idToken;
    }
    
    if (accessToken != null) {
      requestBody['access_token'] = accessToken;
    }
    
    // Headers avec le token d'authentification existant
    final headers = await _createHeaders(requiresAuth: true, isJson: true);
    
    // Faire la requête API
    final response = await http.post(
      Uri.parse(endpoint),
      headers: headers,
      body: json.encode(requestBody),
    );
    
    final data = _handleResponse(response);
    return data;
  } catch (e) {
    debugPrint('[ApiClient] Erreur lors de la liaison avec $provider: $e');
    return {'success': false, 'message': 'Erreur de liaison: $e'};
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
      
      // Vérifier si nous avons un refresh token stocké
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      
      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint('[DEBUG API] Pas de refresh token disponible');
        return false;
      }

      // Utiliser l'endpoint spécifique pour le refresh token
      try {
        final refreshResponse = await http.post(
          Uri.parse('${_endpoints.baseUrl}/auth/refresh'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'refresh_token': refreshToken,
          }),
        );

        if (refreshResponse.statusCode >= 200 &&
            refreshResponse.statusCode < 300) {
          final data = json.decode(refreshResponse.body);

          if (data['access_token'] != null && data['expires_at'] != null) {
            // Sauvegarder le nouveau access token
            await _saveAuthToken(
              data['access_token'],
              DateTime.parse(data['expires_at']),
            );
            
            // Sauvegarder également le nouveau refresh token s'il est fourni
            if (data['refresh_token'] != null) {
              await prefs.setString('refresh_token', data['refresh_token']);
              debugPrint('[DEBUG API] Nouveau refresh token sauvegardé');
            }
            
            debugPrint('[DEBUG API] Token rafraîchi avec succès via endpoint refresh');
            return true;
          }
        } else {
          debugPrint('[DEBUG API] Échec du rafraîchissement: ${refreshResponse.statusCode} - ${refreshResponse.body}');
          
          // Si nous recevons une erreur 401 ou 403, cela signifie que le refresh token est invalidé
          // Dans ce cas, supprimons-le
          if (refreshResponse.statusCode == 401 || refreshResponse.statusCode == 403) {
            await prefs.remove('refresh_token');
            debugPrint('[DEBUG API] Refresh token invalidé et supprimé');
          }
        }
      } catch (e) {
        debugPrint('[DEBUG API] Échec du rafraîchissement via endpoint spécifique: $e');
      }
      
      // Si nous arrivons ici, c'est que le rafraîchissement a échoué
      debugPrint('[DEBUG API] Échec du rafraîchissement du token');
      return false;
    } catch (e) {
      debugPrint('[DEBUG API] Erreur lors du rafraîchissement du token: $e');
      return false;
    }
  }

  @override
  String toString() => 'ApiClient(baseUrl: $baseUrl, isAuthenticated: $isAuthenticated)';
}


