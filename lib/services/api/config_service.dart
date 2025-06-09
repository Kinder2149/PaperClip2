// lib/services/api/config_service.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import '../../config/api_config.dart';

/// Service de configuration à distance utilisant le backend personnalisé
/// Remplace les fonctionnalités de Firebase Remote Config
class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;

  // Client API
  final ApiClient _apiClient = ApiClient();
  
  // Clés pour SharedPreferences
  static const String _configCacheKey = 'remote_config_cache';
  static const String _configVersionKey = 'remote_config_version';
  static const String _configLastFetchKey = 'remote_config_last_fetch';
  
  // Configuration par défaut
  final Map<String, dynamic> _defaultConfig = {
    'app_enabled': true,
    'welcome_message': 'Bienvenue sur PaperClip2',
    'maintenance_mode': false,
    'min_supported_version': '1.0.0',
    'latest_version': '1.0.0',
    'force_update': false,
    'social_features_enabled': true,
    'analytics_enabled': true,
    'debug_mode': false,
  };
  
  // Configuration active
  Map<String, dynamic> _activeConfig = {};
  String _configVersion = '0';
  DateTime? _lastFetchTime;
  
  // Durée minimale entre les fetches (12 heures par défaut)
  Duration _minimumFetchInterval = const Duration(hours: 12);
  
  // Événements de changement
  final ValueNotifier<Map<String, dynamic>> configChanged = ValueNotifier<Map<String, dynamic>>({});
  
  // Constructeur interne
  ConfigService._internal();
  
  // Initialisation du service
  Future<void> initialize({
    Map<String, dynamic>? defaultConfig,
    Duration? minimumFetchInterval,
  }) async {
    // Utiliser les valeurs par défaut d'ApiConfig si aucune n'est fournie
    if (defaultConfig != null) {
      _defaultConfig.addAll(defaultConfig);
    } else {
      _defaultConfig.addAll(ApiConfig.defaultConfig);
    }
    
    if (minimumFetchInterval != null) {
      _minimumFetchInterval = minimumFetchInterval;
    }
    
    await _loadCachedConfig();
    
    // Vérifier si une mise à jour est nécessaire
    final now = DateTime.now();
    if (_lastFetchTime == null || now.difference(_lastFetchTime!) > _minimumFetchInterval) {
      // Fetch en arrière-plan
      fetchAndActivate().catchError((e) {
        debugPrint('Erreur lors du fetch de la configuration: $e');
      });
    }
  }
  
  // Chargement de la configuration depuis le cache
  Future<void> _loadCachedConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final cachedConfigString = prefs.getString(_configCacheKey);
      if (cachedConfigString != null) {
        _activeConfig = Map<String, dynamic>.from(json.decode(cachedConfigString));
      } else {
        _activeConfig = Map<String, dynamic>.from(_defaultConfig);
      }
      
      _configVersion = prefs.getString(_configVersionKey) ?? '0';
      
      final lastFetchString = prefs.getString(_configLastFetchKey);
      if (lastFetchString != null) {
        _lastFetchTime = DateTime.parse(lastFetchString);
      }
      
      configChanged.value = Map<String, dynamic>.from(_activeConfig);
    } catch (e) {
      debugPrint('Erreur lors du chargement de la configuration en cache: $e');
      _activeConfig = Map<String, dynamic>.from(_defaultConfig);
    }
  }
  
  // Sauvegarde de la configuration dans le cache
  Future<void> _saveCachedConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString(_configCacheKey, json.encode(_activeConfig));
      await prefs.setString(_configVersionKey, _configVersion);
      
      if (_lastFetchTime != null) {
        await prefs.setString(_configLastFetchKey, _lastFetchTime!.toIso8601String());
      }
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde de la configuration en cache: $e');
    }
  }
  
  // Applique la configuration par défaut quand l'API n'est pas disponible
  void _applyDefaultConfig() {
    _activeConfig = Map<String, dynamic>.from(_defaultConfig);
    _lastFetchTime = DateTime.now(); // Évite les tentatives répétées
    _configVersion = 'default';
    _saveCachedConfig();
    configChanged.value = Map<String, dynamic>.from(_activeConfig);
    debugPrint('Configuration par défaut activée: ${_activeConfig.length} paramètres');
  }
  
  // Récupération de la configuration depuis le serveur
  Future<bool> fetch() async {
    try {
      // Vérifier si l'intervalle minimum est respecté
      if (_lastFetchTime != null) {
        final now = DateTime.now();
        final difference = now.difference(_lastFetchTime!);
        
        if (difference < _minimumFetchInterval) {
          debugPrint('Fetch ignoré: dernier fetch il y a ${difference.inMinutes} minutes, intervalle minimum ${_minimumFetchInterval.inMinutes} minutes');
          return false;
        }
      }
      
      // Récupérer la configuration active depuis l'API
      debugPrint('Récupération de la configuration active depuis l\'API...');
      
      try {
        final result = await _apiClient.get('/config/active');
        
        if (result != null && result is Map<String, dynamic>) {
          // Mettre à jour la dernière heure de fetch
          _lastFetchTime = DateTime.now();
          
          // Extraire la version de la configuration
          if (result.containsKey('version')) {
            _configVersion = result['version'].toString();
          }
          
          // Extraire les données de configuration
          Map<String, dynamic> newConfig;
          if (result.containsKey('data') && result['data'] is Map) {
            newConfig = Map<String, dynamic>.from(result['data']);
          } else {
            // Si la structure ne contient pas de 'data', on considère tout comme configuration
            newConfig = Map<String, dynamic>.from(result);
          }
          
          // Fusionner avec les valeurs par défaut pour assurer la présence de toutes les clés
          _defaultConfig.forEach((key, value) {
            if (!newConfig.containsKey(key)) {
              newConfig[key] = value;
            }
          });
          
          // Appliquer temporairement (sans activer)
          _activeConfig = newConfig;
          await _saveCachedConfig();
          
          debugPrint('Configuration récupérée avec succès: ${_activeConfig.length} paramètres, version $_configVersion');
          return true;
        } else {
          debugPrint('Format de configuration invalide ou vide');
          _applyDefaultConfig();
          return false;
        }
      } catch (apiError) {
        // Gestion spécifique pour le cas où l'endpoint n'existe pas (404) ou autre erreur API
        debugPrint('Endpoint /config/active non disponible (${apiError.toString()}), utilisation de la configuration par défaut');
        _applyDefaultConfig();
        return false;
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération de la configuration: $e');
      _applyDefaultConfig();
      return false;
    }
  }
  
  // Récupération et activation de la configuration
  Future<bool> fetchAndActivate() async {
    final success = await fetch();
    
    if (success) {
      configChanged.value = Map<String, dynamic>.from(_activeConfig);
    }
    
    return success;
  }
  
  // Obtention d'une valeur booléenne
  bool getBool(String key, {bool defaultValue = false}) {
    try {
      final value = _activeConfig[key];
      
      if (value == null) {
        return _defaultConfig[key] ?? defaultValue;
      }
      
      if (value is bool) {
        return value;
      } else if (value is String) {
        return value.toLowerCase() == 'true';
      } else if (value is num) {
        return value != 0;
      }
      
      return defaultValue;
    } catch (e) {
      debugPrint('Erreur lors de l\'obtention de la valeur booléenne: $e');
      return defaultValue;
    }
  }
  
  // Obtention d'une valeur entière
  int getInt(String key, {int defaultValue = 0}) {
    try {
      final value = _activeConfig[key];
      
      if (value == null) {
        return _defaultConfig[key] ?? defaultValue;
      }
      
      if (value is int) {
        return value;
      } else if (value is double) {
        return value.toInt();
      } else if (value is String) {
        return int.tryParse(value) ?? defaultValue;
      }
      
      return defaultValue;
    } catch (e) {
      debugPrint('Erreur lors de l\'obtention de la valeur entière: $e');
      return defaultValue;
    }
  }
  
  // Obtention d'une valeur double
  double getDouble(String key, {double defaultValue = 0.0}) {
    try {
      final value = _activeConfig[key];
      
      if (value == null) {
        return _defaultConfig[key] ?? defaultValue;
      }
      
      if (value is double) {
        return value;
      } else if (value is int) {
        return value.toDouble();
      } else if (value is String) {
        return double.tryParse(value) ?? defaultValue;
      }
      
      return defaultValue;
    } catch (e) {
      debugPrint('Erreur lors de l\'obtention de la valeur double: $e');
      return defaultValue;
    }
  }
  
  // Obtention d'une valeur chaîne
  String getString(String key, {String defaultValue = ''}) {
    try {
      final value = _activeConfig[key];
      
      if (value == null) {
        return _defaultConfig[key] ?? defaultValue;
      }
      
      if (value is String) {
        return value;
      } else {
        return value.toString();
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'obtention de la valeur chaîne: $e');
      return defaultValue;
    }
  }
  
  // Obtention d'une valeur JSON
  Map<String, dynamic> getJson(String key, {Map<String, dynamic>? defaultValue}) {
    try {
      final value = _activeConfig[key];
      final defaultResult = defaultValue ?? _defaultConfig[key] ?? {};
      
      if (value == null) {
        return defaultResult;
      }
      
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      } else if (value is String) {
        try {
          return Map<String, dynamic>.from(json.decode(value));
        } catch (e) {
          return defaultResult;
        }
      }
      
      return defaultResult;
    } catch (e) {
      debugPrint('Erreur lors de l\'obtention de la valeur JSON: $e');
      return defaultValue ?? {};
    }
  }
  
  // Obtention de toutes les valeurs
  Map<String, dynamic> getAll() {
    return Map<String, dynamic>.from(_activeConfig);
  }
  
  // Définition d'une valeur par défaut
  void setDefaultValue(String key, dynamic value) {
    _defaultConfig[key] = value;
    
    // Si la clé n'existe pas dans la configuration active, utiliser la valeur par défaut
    if (!_activeConfig.containsKey(key)) {
      _activeConfig[key] = value;
      configChanged.value = Map<String, dynamic>.from(_activeConfig);
    }
  }
  
  // Définition de plusieurs valeurs par défaut
  void setDefaultValues(Map<String, dynamic> defaults) {
    defaults.forEach((key, value) {
      setDefaultValue(key, value);
    });
  }
  
  /// Récupère les données utilisateur depuis le backend
  /// Remplace la fonction Firestore de récupération des documents utilisateur
  Future<Map<String, dynamic>> getUserData(String userId, String dataType) async {
    try {
      final data = await _apiClient.get(
        '/config/user-data',
        queryParams: {
          'user_id': userId,
          'data_type': dataType,
        },
      );
      
      return {
        'success': data['success'] ?? false, 
        'message': data['message'] ?? '',
        'data': data['data'] ?? {}
      };
    } catch (e) {
      debugPrint('Erreur lors de la récupération des données utilisateur: $e');
      return {
        'success': false,
        'message': e.toString(),
        'data': {}
      };
    }
  }
  
  /// Sauvegarde les données utilisateur sur le backend
  /// Remplace la fonction Firestore de sauvegarde des documents utilisateur
  Future<Map<String, dynamic>> saveUserData(String userId, String dataType, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(
        '/config/user-data',
        body: {
          'user_id': userId,
          'data_type': dataType,
          'data': data,
        },
      );
      
      return {
        'success': response['success'] ?? false,
        'message': response['message'] ?? ''
      };
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde des données utilisateur: $e');
      return {
        'success': false,
        'message': e.toString()
      };
    }
  }
}
