// lib/api_config.dart
// Remplace firebase_options.dart

import 'env_config.dart';

/// Configuration de l'API pour différentes plateformes
class ApiConfig {
  /// Obtient la configuration appropriée pour la plateforme actuelle
  static ApiEndpoints get currentPlatform {
    // Utiliser les variables d'environnement pour configurer les endpoints
    return ApiEndpoints(
      baseUrl: EnvConfig.apiBaseUrl,
      apiKey: EnvConfig.apiKey,
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
