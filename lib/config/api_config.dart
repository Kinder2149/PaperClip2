// lib/config/api_config.dart
// Configuration API centralisée (fusion des anciennes implémentations)

import 'package:flutter/foundation.dart';
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
  
  /// En-têtes par défaut
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Obtient la configuration appropriée pour la plateforme actuelle
  static ApiEndpoints get currentPlatform {
    return ApiEndpoints(
      baseUrl: apiBaseUrl,
      apiKey: EnvConfig.apiKey ?? '',
      authEndpoint: '/auth',
      storageEndpoint: '/storage',
      configEndpoint: '/config',
      socialEndpoint: '/social',
      analyticsEndpoint: '/analytics',
      saveEndpoint: '/save',
    );
  }
}

/// Configuration des endpoints de l'API
class ApiEndpoints {
  final String baseUrl;
  final String apiKey;
  final String authEndpoint;
  final String storageEndpoint;
  final String configEndpoint;
  final String socialEndpoint;
  final String analyticsEndpoint;
  final String saveEndpoint;

  const ApiEndpoints({
    required this.baseUrl,
    required this.apiKey,
    required this.authEndpoint,
    required this.storageEndpoint,
    required this.configEndpoint,
    required this.socialEndpoint,
    required this.analyticsEndpoint,
    required this.saveEndpoint,
  });

  String get fullAuthEndpoint => '$baseUrl$authEndpoint';
  String get fullStorageEndpoint => '$baseUrl$storageEndpoint';
  String get fullConfigEndpoint => '$baseUrl$configEndpoint';
  String get fullSocialEndpoint => '$baseUrl$socialEndpoint';
  String get fullAnalyticsEndpoint => '$baseUrl$analyticsEndpoint';
  String get fullSaveEndpoint => '$baseUrl$saveEndpoint';
}
