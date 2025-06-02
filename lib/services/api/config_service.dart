// lib/services/api/config_service.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

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
  final Map<String, dynamic> _defaultConfig = {};
  
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
    if (defaultConfig != null) {
      _defaultConfig.addAll(defaultConfig);
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
  
  // Récupération de la configuration depuis le serveur
  Future<bool> fetch() async {
    try {
      final data = await _apiClient.get(
        '/config/active',
        requiresAuth: false,
      );
      
      _activeConfig = Map<String, dynamic>.from(data['parameters'] ?? {});
      _configVersion = data['version'] ?? '0';
      _lastFetchTime = DateTime.now();
      
      await _saveCachedConfig();
      return true;
    } catch (e) {
      debugPrint('Erreur lors du fetch de la configuration: $e');
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
