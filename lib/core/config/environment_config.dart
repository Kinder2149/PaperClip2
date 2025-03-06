// lib/core/config/environment_config.dart

enum Environment {
  development,
  staging,
  production
}

class EnvironmentConfig {
  static const Environment currentEnvironment = Environment.development;

  static Map<String, dynamic> getConfig(Environment env) {
    switch (env) {
      case Environment.development:
        return {
          'apiBaseUrl': 'https://dev-api.paperclipempire.com',
          'logLevel': 'debug',
          'enableMockData': true,
          'firebase': {
            'apiKey': 'DEV_FIREBASE_API_KEY',
            'projectId': 'paperclip-dev',
          },
          'features': {
            'betaFeatures': true,
            'experimentalMode': true,
          }
        };

      case Environment.staging:
        return {
          'apiBaseUrl': 'https://staging-api.paperclipempire.com',
          'logLevel': 'info',
          'enableMockData': false,
          'firebase': {
            'apiKey': 'STAGING_FIREBASE_API_KEY',
            'projectId': 'paperclip-staging',
          },
          'features': {
            'betaFeatures': true,
            'experimentalMode': false,
          }
        };

      case Environment.production:
        return {
          'apiBaseUrl': 'https://api.paperclipempire.com',
          'logLevel': 'error',
          'enableMockData': false,
          'firebase': {
            'apiKey': 'PROD_FIREBASE_API_KEY',
            'projectId': 'paperclip-prod',
          },
          'features': {
            'betaFeatures': false,
            'experimentalMode': false,
          }
        };
    }
  }

  /// Récupère la configuration actuelle
  static Map<String, dynamic> get currentConfig =>
      getConfig(currentEnvironment);

  /// Vérifie si une fonctionnalité est activée
  static bool isFeatureEnabled(String featureName) {
    return currentConfig['features'][featureName] ?? false;
  }

  /// Récupère l'URL de base de l'API
  static String get apiBaseUrl => currentConfig['apiBaseUrl'];

  /// Vérifie si l'environnement est de développement
  static bool get isDevelopment =>
      currentEnvironment == Environment.development;

  /// Vérifie si l'environnement est de production
  static bool get isProduction =>
      currentEnvironment == Environment.production;

  /// Récupère le niveau de log
  static String get logLevel => currentConfig['logLevel'];

  /// Vérifie si les données de mock sont activées
  static bool get isMockDataEnabled =>
      currentConfig['enableMockData'] ?? false;
}