// lib/core/mixins/game_mixins.dart

import 'package:flutter/foundation.dart';

/// Mixin pour la validation de ressources
mixin ResourceValidationMixin {
  bool validatePositiveValue(double value) => value >= 0;

  bool validateResourceAmount(double current, double max) {
    return current >= 0 && current <= max;
  }
}

/// Mixin pour le logging de debug
mixin LoggingMixin {
  void debugLog(String message, {LogLevel level = LogLevel.info}) {
    if (kDebugMode) {
      switch (level) {
        case LogLevel.info:
          print('ℹ️ [INFO] $message');
          break;
        case LogLevel.warning:
          print('⚠️ [WARNING] $message');
          break;
        case LogLevel.error:
          print('❌ [ERROR] $message');
          break;
      }
    }
  }
}

/// Mixin pour la gestion des configurations
mixin ConfigurationMixin {
  Map<String, dynamic> getDefaultConfiguration() {
    return {
      'version': '1.0.3',
      'debug': false,
      'productionMode': true,
    };
  }

  bool isFeatureEnabled(String feature, {Map<String, dynamic>? config}) {
    config ??= getDefaultConfiguration();
    return config[feature] ?? false;
  }
}

/// Mixin pour la conversion de données
mixin ConversionMixin {
  T? safeConvert<T>(dynamic value, T Function(dynamic) converter) {
    try {
      return converter(value);
    } catch (e) {
      return null;
    }
  }
}

/// Énumération pour les niveaux de log
enum LogLevel {
  info,
  warning,
  error
}