// lib/services/api/api_client.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../api_config.dart';

/// Service client pour communiquer avec le backend API
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  // Configuration de l'API depuis api_config.dart
  // Stockage du token JWT
  String? _authToken;
  DateTime? _tokenExpiration;
  
  // Getters
  String get baseUrl => ApiConfig.apiBaseUrl;
  bool get isAuthenticated => _authToken != null && (_tokenExpiration?.isAfter(DateTime.now()) ?? false);

  // Constructeur interne
  ApiClient._internal();

  // Initialisation du client
  Future<void> initialize() async {
    await _loadAuthToken();
  }

  // Chargement du token depuis le stockage local
  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    
    final expiryString = prefs.getString('token_expiry');
    if (expiryString != null) {
      _tokenExpiration = DateTime.parse(expiryString);
      
      // Vérifier si le token est expiré
      if (_tokenExpiration!.isBefore(DateTime.now())) {
        _authToken = null;
        _tokenExpiration = null;
        await prefs.remove('auth_token');
        await prefs.remove('token_expiry');
      }
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
  }

  // Création des en-têtes HTTP avec authentification si disponible
  Map<String, String> _createHeaders({bool requiresAuth = true, bool isJson = true}) {
    final headers = <String, String>{};
    
    if (isJson) {
      headers['Content-Type'] = 'application/json';
    }
    
    if (requiresAuth && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    
    return headers;
  }

  // Méthode pour gérer les réponses HTTP et les erreurs
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Succès
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      // Non autorisé - token expiré ou invalide
      _authToken = null;
      _tokenExpiration = null;
      throw UnauthorizedException('Non autorisé: ${response.body}');
    } else {
      // Autres erreurs
      throw ApiException(
        'Erreur API: ${response.statusCode}',
        response.statusCode,
        response.body,
      );
    }
  }

  // Méthodes HTTP

  /// Effectue une requête GET
  Future<dynamic> get(String endpoint, {bool requiresAuth = true, Map<String, String>? queryParams}) async {
    final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: queryParams);
    
    try {
      final response = await http.get(
        uri,
        headers: _createHeaders(requiresAuth: requiresAuth),
      );
      return _handleResponse(response);
    } on SocketException {
      throw const ApiException('Pas de connexion internet', 0, 'Vérifiez votre connexion');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erreur lors de la requête GET', 0, e.toString());
    }
  }

  /// Effectue une requête POST
  Future<dynamic> post(String endpoint, {dynamic body, bool requiresAuth = true}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    
    try {
      final response = await http.post(
        uri,
        headers: _createHeaders(requiresAuth: requiresAuth),
        body: body != null ? json.encode(body) : null,
      );
      return _handleResponse(response);
    } on SocketException {
      throw const ApiException('Pas de connexion internet', 0, 'Vérifiez votre connexion');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erreur lors de la requête POST', 0, e.toString());
    }
  }

  /// Effectue une requête PUT
  Future<dynamic> put(String endpoint, {dynamic body, bool requiresAuth = true}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    
    try {
      final response = await http.put(
        uri,
        headers: _createHeaders(requiresAuth: requiresAuth),
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
  Future<dynamic> delete(String endpoint, {bool requiresAuth = true}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    
    try {
      final response = await http.delete(
        uri,
        headers: _createHeaders(requiresAuth: requiresAuth),
      );
      return _handleResponse(response);
    } on SocketException {
      throw const ApiException('Pas de connexion internet', 0, 'Vérifiez votre connexion');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erreur lors de la requête DELETE', 0, e.toString());
    }
  }

  /// Upload d'un fichier
  Future<dynamic> uploadFile(String endpoint, File file, {String? fileName, bool requiresAuth = true}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    
    try {
      final request = http.MultipartRequest('POST', uri);
      
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
        '/auth/login',
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
      rethrow;
    }
  }

  /// Inscription d'un nouvel utilisateur
  Future<Map<String, dynamic>> register(String email, String password, String username) async {
    try {
      final data = await post(
        '/auth/register',
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
  }) async {
    try {
      final data = await post(
        '/auth/provider',
        body: {
          'provider': provider,
          'provider_id': providerId,
          'email': email,
          'username': username,
          'profile_image_url': profileImageUrl,
        },
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
      rethrow;
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    try {
      await post('/auth/logout');
    } finally {
      await clearAuthToken();
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
