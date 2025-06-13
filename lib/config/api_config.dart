// lib/config/api_config.dart
// Configuration API centralisée (fusion des anciennes implémentations)

import 'package:flutter/foundation.dart';
import 'dart:io';
import '../env_config.dart';

/// Configuration de l'API pour différentes plateformes
class ApiConfig {
  /// URL de base de l'API (constante ou depuis les variables d'environnement)
  static String apiBaseUrl = 'https://paperclip2-api.onrender.com/api';
  
  /// URL de repli pour l'API
  static String fallbackUrl = 'https://paperclip2-api-fallback.onrender.com/api';
  
  /// Valeurs de configuration par défaut (utilisées si le serveur est indisponible)
  static final Map<String, dynamic> defaultConfig = {
    'welcome_message': 'Bienvenue sur Paperclip2!',
    'game_speed': 1.0,
    'initial_metal': 1000,
    'initial_money': 5000,
    'achievements_enabled': true,
    'debug_mode': false,
    'max_auto_save_slots': 3,
    'social_features_enabled': true,
    'max_crisis_level': 5,
    'market_volatility': 0.2
  };
  
  /// Initialiser les URL
  static void initialize(String baseUrl) {
    if (baseUrl.isNotEmpty) {
      // Nettoyer l'URL pour enlever les parenthèses markdown
      apiBaseUrl = baseUrl.replaceAll('\[', '').replaceAll('\]', '').replaceAll('\(', '').replaceAll('\)', '');
      debugPrint('URL nettoyée: $apiBaseUrl');
    } else {
      apiBaseUrl = 'https://paperclip2-api.onrender.com/api';
    }
  }
  
  /// Timeout pour les requêtes API (en secondes)
  static const int timeoutSeconds = 30;
  
  /// Version de l'API
  static const String apiVersion = 'v1';
  
  // Auth endpoints
  // Endpoints modernes OAuth (inutilisables actuellement car retournent 404)
  static const String authOauthGoogle = '/auth/oauth/google'; // 404
  static const String authLinkGoogle = '/auth/link/google'; // 404
  
  // Endpoints de fallback fonctionnels
  static const String authProviderGoogle = '/auth/provider'; // Fonctionne avec ?provider=google
  static const String userLinkGoogle = '/user/link/google'; // À tester
  
  /// En-têtes par défaut
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Obtient la configuration appropriée pour la plateforme actuelle
  static ApiEndpoints get currentPlatform {
    return ApiEndpoints(
      baseUrl: apiBaseUrl,
      authEndpoint: '/auth',
      storageEndpoint: '/storage',
      configEndpoint: '/config',
      socialEndpoint: '/social',
      analyticsEndpoint: '/analytics',
      saveEndpoint: '/save',
      defaultHeaders: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
  }
  
  /// Vérifie si un endpoint est accessible
  static Future<bool> isEndpointAvailable(String url) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      final request = await client.openUrl('HEAD', Uri.parse(url));
      final response = await request.close();
      await response.drain<void>();
      return response.statusCode < 400;
    } catch (e) {
      debugPrint('Erreur lors de la vérification de l\'endpoint $url: $e');
      return false;
    }
  }
}

/// Configuration des endpoints de l'API
class ApiEndpoints {
  final String baseUrl;
  final String authEndpoint;
  final String storageEndpoint;
  final String configEndpoint;
  final String socialEndpoint;
  final String analyticsEndpoint;
  final String saveEndpoint;
  final Map<String, String> defaultHeaders;

  ApiEndpoints({
    required this.baseUrl,
    required this.authEndpoint,
    required this.storageEndpoint,
    required this.configEndpoint,
    required this.socialEndpoint,
    required this.analyticsEndpoint,
    required this.saveEndpoint,
    this.defaultHeaders = const {},
  });

  String get fullAuthEndpoint => '$baseUrl$authEndpoint';
  String get fullStorageEndpoint => '$baseUrl$storageEndpoint';
  String get fullConfigEndpoint => '$baseUrl$configEndpoint';
  String get fullSocialEndpoint => '$baseUrl$socialEndpoint';
  String get fullAnalyticsEndpoint => '$baseUrl$analyticsEndpoint';
  String get fullSaveEndpoint => '$baseUrl$saveEndpoint';
  
  // Endpoints spécifiques d'authentification
  // Endpoints OAuth modernes (actuellement 404)
  String get providerAuthUrl => '$baseUrl$authEndpoint/provider';
  String get googleOAuthUrl => '$baseUrl$authEndpoint/oauth/google';
  String get googleLinkUrl => '$baseUrl$authEndpoint/link/google';
  
  // Endpoints de fallback fonctionnels
  String get providerGoogleAuthUrl => '$baseUrl${ApiConfig.authProviderGoogle}?provider=google';
  String get userLinkGoogleUrl => '$baseUrl${ApiConfig.userLinkGoogle}';
  
  // Endpoints de configuration
  String get activeConfigUrl => '$baseUrl$configEndpoint/active';
  
  // Endpoints de liaison de compte manquants
  String get linkGoogleAccountUrl => '$baseUrl$authEndpoint/link/google';
  String get linkAppleAccountUrl => '$baseUrl$authEndpoint/link/apple';
  String get linkProviderUrl => '$baseUrl$authEndpoint/link';
  
  // Endpoint de déconnexion
  String get logoutEndpoint => '$baseUrl$authEndpoint/logout';
}
